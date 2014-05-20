
{$$, View, Editor, EditorView} = require 'atom'
shell = require 'shelljs'
chokidar = require 'chokidar'


ResultGroupView = require './gradle-ci-result-group-view'


module.exports =
  class GradleCiStatusView extends View
    resultGroupView: null

    @content: ->
      @div {class: 'gradle-ci-status inline-block', click: 'showResults'}, =>
        @span class: 'status-icon', outlet: 'statusIcon'
        @span 'GradleCI', {outlet: 'statusLabel'}

    initialize: =>
      @results = []
      @running = false
      @gradleCli = 'gradle'
      @execAsyncAndSilent = { async: true, silent: true }

      atom.config.observe 'atom-gradle-ci.runAsDaemon', =>
        @runAsDaemon = atom.config.get 'atom-gradle-ci.runAsDaemon'
        console.log 'GradleCI: atom-gradle-ci.runAsDaemon: ' + @runAsDaemon
      atom.config.observe 'atom-gradle-ci.runTasks', =>
        @runTasks = atom.config.get 'atom-gradle-ci.runTasks'
        console.log 'GradleCI: atom-gradle-ci.runTasks: ' + @runTasks
      atom.config.observe 'atom-gradle-ci.triggerBuildAfterSave', =>
        @triggerBuildAfterSave = atom.config.get 'atom-gradle-ci.triggerBuildAfterSave'
        console.log 'GradleCI: atom-gradle-ci.triggerBuildAfterSave: ' + @triggerBuildAfterSave
      atom.config.observe 'atom-gradle-ci.triggerBuildAfterCommit', =>
        @triggerBuildAfterCommit = atom.config.get 'atom-gradle-ci.triggerBuildAfterCommit'
        console.log 'GradleCI: atom-gradle-ci.triggerBuildAfterCommit: ' + @triggerBuildAfterCommit

      console.log "Gradle CI: initializing chokidar on path: " + atom.project.getPath()
      @projectWatcher = chokidar.watch(atom.project.getPath(), { persistent: true, interval: 500, binaryInterval: 500 });

      shell.exec("#{@gradleCli} --version", @execAsyncAndSilent, this.checkVersion)
      console.log "Gradle CI: initialization done."

    destroy: =>
      atom.config.unobserve 'atom-gradle-ci.runAsDaemon'
      atom.config.unobserve 'atom-gradle-ci.runTasks'
      atom.config.unobserve 'atom-gradle-ci.triggerBuildAfterSave'
      atom.config.unobserve 'atom-gradle-ci.triggerBuildAfterCommit'
      @resultGroupView.destroy
      @projectWatcher.close
      @detach()

    notify: (message) =>
      view = $$ ->
        @div tabIndex: -1, class: 'overlay from-top', =>
          @span class: 'inline-block'
          @span "Gradle CI: #{message}"

      atom.workspaceView.append view

      setTimeout ->
        view.detach()
      , 5000

    checkVersion: (errorcode, output) =>
      versionRegEx = /Gradle ([\d\.]+)/

      if errorcode == 0 and output.length > 0 and versionRegEx.test(output)
        version = versionRegEx.exec(output)[1]
        console.log("GradleCI: Gradle #{version} ready to use.")
        @statusLabel.text "Gradle #{version}"
        @showStatus 'no_tests'
        @projectWatcher.on 'change', @directoryChangedEvent
        @resultGroupView = new ResultGroupView
      else
        console.error("GradleCI: couldn't run Gradle.")
        @statusLabel.text "GradleCI disabled"
        @showStatus 'stopped'

    showStatus: (status) =>
      icon = switch status
        when 'stopped' then 'icon-alert'
        when 'running' then 'icon-hourglass'
        when 'succeeded' then 'icon-beer'
        when 'failed' then 'icon-bug'
        when 'no_tests' then 'icon-circle-slash'
        else                 'icon-circle-slash'

      @statusIcon.removeClass().addClass "icon #{icon}"
      atom.workspaceView.statusBar.appendRight(this)

    hideStatus: =>
      @detach()

    directoryChangedEvent: (path) =>
      console.log 'GradleCI: directory-changed-event triggered.'
      if @triggerBuildAfterSave
        console.log 'GradleCI: build after save-trigger active, i am going to invoke build.'
        @invokeBuild()

    invokeBuild: =>
      console.log 'GradleCI: trying to invoke build.'

      if not @running
        console.log 'GradleCI: no build running, invoking new build.'
        @running = true
        @showStatus 'running'

        commands = [@gradleCli]

        if @runAsDaemon
          commands.push('--daemon')

        commands.push(@runTasks)

        console.log 'GradleCI: prepared build command: ' + commands.join(' ')
        shell.exec(commands.join(' '), @execAsyncAndSilent, @analyzeBuildResults)

    analyzeBuildResults: (errorcode, output) =>
      console.log "GradleCI: analyzing last build."
      if @results.length >= 3
        @results.shift()
      @results.push(output.trim())
      @resultGroupView.setResults(@results)

      if errorcode
        @showStatus 'failed'
      else
        @showStatus 'succeeded'

      @running = false

    showResults: =>
      @resultGroupView.toggle()
