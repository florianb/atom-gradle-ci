
{$$, View, Editor, EditorView} = require 'atom'
shell = require 'shelljs'
chokidar = require 'chokidar'


ResultGroupView = require './gradle-ci-result-group-view'


module.exports =
  class GradleCiStatusView extends View
    resultGroupView: null

    @content: ->
      @div {class: 'gradle-ci-status inline-block', click: 'toggleResults'}, =>
        @span class: 'status-icon', outlet: 'statusIcon'
        @span 'GradleCI', {outlet: 'statusLabel'}

    initialize: =>
      @enabled = false
      @running = false
      @gradleCli = 'gradle'
      @execAsyncAndSilent = { async: true, silent: true }

      atom.config.observe 'gradle-ci.runAsDaemon', =>
        @runAsDaemon = atom.config.get 'gradle-ci.runAsDaemon'
        console.log 'GradleCI: gradle-ci.runAsDaemon: ' + @runAsDaemon
      atom.config.observe 'gradle-ci.runTasks', =>
        @runTasks = atom.config.get 'gradle-ci.runTasks'
        console.log 'GradleCI: gradle-ci.runTasks: ' + @runTasks
      atom.config.observe 'gradle-ci.triggerBuildAfterSave', =>
        @triggerBuildAfterSave =
          atom.config.get 'gradle-ci.triggerBuildAfterSave'

        console.log 'GradleCI: gradle-ci.triggerBuildAfterSave: ' +
          @triggerBuildAfterSave

      atom.config.observe 'gradle-ci.triggerBuildAfterCommit', =>
        @triggerBuildAfterCommit =
          atom.config.get 'gradle-ci.triggerBuildAfterCommit'
        console.log 'GradleCI: gradle-ci.triggerBuildAfterCommit: ' +
          @triggerBuildAfterCommit

      atom.config.observe 'gradle-ci.maximumResultHistory', =>
        @maximumResultHistory = atom.config.get 'gradle-ci.maximumResultHistory'
        console.log 'GradleCI: gradle-ci.maximumResultHistory: ' +
          @maximumResultHistory

      console.log "Gradle CI: initializing chokidar on path: " +
        atom.project.getPath()
      @projectWatcher = chokidar.watch(atom.project.getPath(),
        { persistent: true, interval: 500, binaryInterval: 500 })

      shell.exec("#{@gradleCli} --version",
        @execAsyncAndSilent,
        this.checkVersion)
      console.log "Gradle CI: initialization done."

    destroy: =>
      atom.config.unobserve 'gradle-ci.runAsDaemon'
      atom.config.unobserve 'gradle-ci.runTasks'
      atom.config.unobserve 'gradle-ci.triggerBuildAfterSave'
      atom.config.unobserve 'gradle-ci.triggerBuildAfterCommit'
      atom.config.unobserve 'gradle-ci.maximumResultHistory'
      @resultGroupView.destroy
      @projectWatcher.close
      @detach()

    checkVersion: (errorcode, output) =>
      versionRegEx = /Gradle ([\d\.]+)/

      if errorcode == 0 and output.length > 0 and versionRegEx.test(output)
        version = versionRegEx.exec(output)[1]
        console.log("GradleCI: Gradle #{version} ready to use.")
        @statusLabel.text "Gradle #{version}"
        @showStatus 'no_tests'
        @projectWatcher.on 'change', @directoryChangedEvent
        @resultGroupView = new ResultGroupView this
        @enabled = true
        if @results
          @resultGroupView.setResults()
          @showStatus(@results[0].status)
        else
          @results = []

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
        else 'icon-circle-slash'

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
      console.log 'GradleCI: trying to e build.'

      if not @running
        console.log 'GradleCI: no build running, invoking new build.'
        @running = true
        @showStatus 'running'

        commands = [@gradleCli]

        commands.push("--project-dir " + atom.project.getPath())

        if @runAsDaemon
          commands.push('--daemon')

        commands.push(@runTasks)

        console.log 'GradleCI: prepared build command: ' + commands.join(' ')
        shell.exec(commands.join(' '),
          @execAsyncAndSilent,
          @analyzeBuildResults)

    analyzeBuildResults: (errorcode, output) =>
      console.log "GradleCI: analyzing last build."
      if @results.length >= @maximumResultHistory
        @results.pop()

      if errorcode
        status = 'failed'
      else
        status = 'succeeded'

      @showStatus status

      @results.unshift({
        timestamp: (new Date).getTime(),
        status: status,
        output: output.trim()
      })

      @resultGroupView.setResults()
      @running = false

    toggleResults: =>
      if @enabled
        @resultGroupView.toggle()
