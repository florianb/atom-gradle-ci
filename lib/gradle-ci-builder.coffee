require 'atom'
shell = require 'shelljs'

GradleCiStatusView = require './gradle-ci-status-view'
GradleCiResultGroupView = require './gradle-ci-result-group-view'


class GradleCiBuilder
  statusView: null
  groupView: null

  constructor: ->
    console.log 'GradleCI: initializing builder.'
    @enabled = false
    @running = false
    @results = []
    @gradleCli = 'gradle'
    @execAsyncAndSilent = { async: true, silent: true }
    @tooltip = null

    @statusView = new GradleCiStatusView({ builder: this })
    @panel = atom.workspace.addBottomPanel(
      {
        item: new GradleCiResultGroupView({ builder: this }),
        visible: false
      }
    )
    @groupView = @panel.getItem()

    atom.config.observe 'gradle-ci.colorStatusIcon', =>
      @colorStatusIcon = atom.config.get 'gradle-ci.colorStatusIcon'
    atom.config.observe 'gradle-ci.runAsDaemon', =>
      @runAsDaemon = atom.config.get 'gradle-ci.runAsDaemon'
    atom.config.observe 'gradle-ci.runTasks', =>
      @runTasks = atom.config.get 'gradle-ci.runTasks'
    atom.config.observe 'gradle-ci.triggerBuildAfterSave', =>
      @triggerBuildAfterSave = atom.config.get 'gradle-ci.triggerBuildAfterSave'
    atom.config.observe 'gradle-ci.maximumResultHistory', =>
      @historyLimitChanged()

    atom.commands.add 'atom-text-editor',
      "gradle-ci:toggle-results", => @toggleResults()

    # @groupView = new GradleCiResultGroupView({ builder: this })
    # @opener = atom.workspace.addOpener (uri) ->
    #   console.log 'called for uri: ' + uri
    #   if uri.match(new RegExp(/results\.gradleci/))
    #     return @groupView

    console.log "GradleCI: fetching project-directories, searching for build-files."
    @projectDirectories = atom.project.getDirectories()
    @projectDirectories.filter (currentDirectory) -> currentDirectory.contains('build.gradle')

    for currentDirectory in @projectDirectories
      path = currentDirectory.getPath()
      console.log "GradleCI: activating watch for: " + path
      currentDirectory.onDidChange(
        => @directoryChangedEvent(path)
      )

    shell.exec(
      "#{@gradleCli} --version",
      @execAsyncAndSilent,
      this.checkVersion
    )
    console.log "GradleCI: pre-initialization of the builder done."

  destroy: =>
    console.log 'GradleCI: destroying builder.'
    atom.config.unobserve 'gradle-ci.colorStatusIcon'
    atom.config.unobserve 'gradle-ci.runAsDaemon'
    atom.config.unobserve 'gradle-ci.runTasks'
    atom.config.unobserve 'gradle-ci.triggerBuildAfterSave'
    atom.config.unobserve 'gradle-ci.maximumResultHistory'
    if @tooltip
      @tooltip.dispose()
    @statusView.destroy()
    @opener.dispose()
    @panel.destroy()

  historyLimitChanged: =>
    @maximumResultHistory =
      atom.config.get('gradle-ci.maximumResultHistory')
    console.log "GradleCI: the history-limit did change to #{@maximumResultHistory}."

    if @groupView
      @groupView.renderResults()

  checkVersion: (errorcode, output) =>
    versionRegEx = /Gradle ([\d\.]+)/
    console.log("GradleCI: going for version-check.")

    if @tooltip
      @tooltip.dispose()

    if errorcode == 0 and output.length > 0 and versionRegEx.test(output)
      version = versionRegEx.exec(output)[1]
      @enabled = true
      @statusView.setLabel('Gradle ' + version)
      @tooltip = atom.tooltips.add(@statusView, {title: 'You don\'t have any builds yet.'})
      console.log("GradleCI: Gradle #{version} ready to use.")
    else
      @statusView.setIcon('disabled')
      @tooltip = atom.tooltips.add(@statusView, {title: "I'm not able to execute `gradle`."})

      console.error("GradleCI: Gradle wasn't executable: " + output)

  directoryChangedEvent: (path) =>
    console.log 'GradleCI: the project-directory "' + path + '" did change.'
    if @triggerBuildAfterSave
      @invokeBuild(path)

  invokeBuild: (path) =>
    console.log 'GradleCI: invoking build.'
    unless @running
      @running = true # block build-runner

      commands = [@gradleCli]
      commands.push("--project-dir " + path)
      if @runAsDaemon
        commands.push('--daemon')
      commands.push(@runTasks)

      console.log 'GradleCI: prepared build command: ' + commands.join(' ')
      shell.exec(commands.join(' '), @execAsyncAndSilent, @analyzeBuildResults)
      @statusView.setIcon('running')

  analyzeBuildResults: (errorcode, output) =>
    console.log "GradleCI: analyzing last build."
    if @results.length == 0
      #@pane.active = true

      if @tooltip
        @tooltip.dispose()
        @tooltip = atom.tooltips.add(@statusView, {title: "Click me to toggle your build-reports."})

      @groupView.header.text('GradleCI ' +
        atom.packages.getActivePackage('gradle-ci').metadata.version)

    if @results.length >= @maximumResultHistory
      @results.pop()

    status = 'undefined'
    if errorcode
      status = 'failed'
    else
      status = 'succeeded'

    @results.unshift({
      timestamp: (new Date).getTime(),
      status: status,
      output: output.trim()
    })

    @statusView.setIcon(status)
    if @panel.isVisible()
      @groupView.renderResults()
    @running = false # free the build runner

  toggleResults: =>
    # if @resultpane
    #   @resultpane.destroy()
    # else
    #   atom.workspace.open(
    #     'results.gradleci',
    #     split: atom.config.get('gradle-ci.splitDirection'),
    #     activatePane: false
    #   )

    if @panel.isVisible()
      @panel.hide()
    else
      @groupView.renderResults()
      @panel.show()

module.exports = GradleCiBuilder
