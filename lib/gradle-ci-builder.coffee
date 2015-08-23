require 'atom'
shell = require 'shelljs'
Panetastic = require 'atom-panetastic'


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

    @statusView ?= new GradleCiStatusView this
    @pane ?= new Panetastic(
      {
        view: GradleCiResultGroupView,
        active: false,
        params: { builder: this }
      }
    )
    @groupView = @pane.subview

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

    atom.workspaceView.command "gradle-ci:toggle-results", => @toggleResults()

    console.log "GradleCI: fetching project-directories, searching for build-files."
    @projectDirectories = atom.project.getDirectories()
    @projectDirectories.filter (currentDirectory) -> !currentDirectory.contains('build.gradle')

    console.log "GradleCI: activating watch for directory-changes."
    @projectDirectories.each (currentDirectory) ->
      currentDirectory.onDidChange(@directoryChangedEvent(currentDirectory.getPath()))

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
    #@projectWatcher.close()
    @statusView.destroy()
    @pane.destroy()

  historyLimitChanged: =>
    console.log "GradleCI: the history-limit did change"
    @maximumResultHistory =
      atom.config.getPositiveInt('gradle-ci.maximumResultHistory', 3)
    if @results? and @results.length > @maximumResultHistory
      @results = @results.splice(0, @maximumResultHistory)
      if @groupView?
        @groupView.renderResults()

  checkVersion: (errorcode, output) =>
    versionRegEx = /Gradle ([\d\.]+)/
    console.log("GradleCI: going for version-check.")

    if errorcode == 0 and output.length > 0 and versionRegEx.test(output)
      version = versionRegEx.exec(output)[1]
      #@projectWatcher.on 'change', @directoryChangedEvent
      @enabled = true
      @statusView.setLabel('Gradle ' + version)
      @statusView.setTooltip "You don't have any builds yet."
      console.log("GradleCI: Gradle #{version} ready to use.")
    else
      @statusView.setIcon('disabled')
      @statusView.setTooltip "I'm not able to execute `gradle`."
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
      @pane.active = true
      @statusView.destroyTooltip()
      @statusView.setTooltip "Click me to toggle your build-reports."
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
    @groupView.renderResults()
    @running = false # free build runner

  toggleResults: =>
    @pane.toggle()
    @groupView.renderResults()

module.exports = GradleCiBuilder
