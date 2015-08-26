require 'atom'
shell = require 'shelljs'


Panetastic = require 'atom-panetastic'
GradleCiStatusView = require './gradle-ci-status-view'
GradleCiResultGroupView = require './gradle-ci-result-group-view'


class GradleCiBuilder
  statusView: null
  groupView: null
  tooltip: null
  enabled: false
  runnning: false
  pending: false
  results: []
  gradleCli: 'gradle'
  execAsyncAndSilent: { async: true, silent: true }

  constructor: ->
    @log 'initializing builder.'

    # initialize views
    @statusView = new GradleCiStatusView({ builder: this })

    # create panetastic-instance
    @panel = new Panetastic(
      view: GradleCiResultGroupView,
      params: { builder: this },
      active: false
    )
    @groupView = @panel.subview

    # observe config-changes, they're mostly mapped to the attributes
    atom.config.observe 'gradle-ci.colorStatusIcon', =>
      @colorStatusIcon = atom.config.get 'gradle-ci.colorStatusIcon'
    atom.config.observe 'gradle-ci.runAsDaemon', =>
      @runAsDaemon = atom.config.get 'gradle-ci.runAsDaemon'
    atom.config.observe 'gradle-ci.runTasks', =>
      @runTasks = atom.config.get 'gradle-ci.runTasks'
    atom.config.observe 'gradle-ci.maximumResultHistory', =>
      @maximumResultHistory = atom.config.get 'gradle-ci.maximumResultHistory'

    # register editor commands
    atom.commands.add 'atom-text-editor',
      "gradle-ci:toggle-results", => @toggleResults()
    atom.commands.add 'atom-text-editor',
      "gradle-ci:invoke-build", => @invokeBuild()

    # create build-paths
    # TODO: implement use of git-repositories
    @setBuildFiles()


    # start asynchronous gradle-check
    shell.exec(
      "#{@gradleCli} --version",
      @execAsyncAndSilent,
      this.checkVersion
    )
    @log "pre-initialization of the builder done."

  destroy: =>
    @log 'destroying builder.'
    @statusView.destroy()
    @panel.destroy()

  historyLimitChanged: =>
    @maximumResultHistory =
      atom.config.get('gradle-ci.maximumResultHistory')
    @log "the history-limit did change to #{@maximumResultHistory}."
    if @groupView
      @groupView.renderResults()

  setBuildFiles: =>
    @log "fetching project-repositories, searching for build-files."

    Promise.all(
      atom.project.getDirectories().map(
        atom.project.repositoryForDirectory.bind(atom.project)
      )
    ).then(
      (repositories) =>
        @log "sucessfully fetched #{repositories.length} repository/ies"
        if repositories.length > 0
        else
          @tooltip.dispose() if @tooltip
      (failure) =>
        @disableBuilder("An error occured during the search for repositories.", "could not fetch repositories: " + failure)
    )


  disableBuilder: (message, errormessage) =>
    @statusView.setIcon('disabled')
    @statusView.setTooltip(message)
    @enabled = false
    @error errormessage if errormessage

  checkVersion: (errorcode, output) =>
    versionRegEx = /Gradle ([\d\.]+)/
    @log("going for version-check.")

    # if gradle was sucessfully invoked
    if errorcode == 0 and output.length > 0 and versionRegEx.test(output)
      version = versionRegEx.exec(output)[1]
      @enabled = true # enable the builder
      @statusView.setLabel('Gradle ' + version)
      @statusView.setTooltip('You don\'t have any builds yet.')
      @log("Gradle #{version} ready to use.")
    else # otherwise display an error
      disableBuilder("I'm not able to execute `gradle`.", "Gradle wasn't executable: " + output)

  directoryChangedEvent: (path) =>
    @log 'the project-directory "' + path + '" did change.'
    if @triggerBuildAfterSave
      @invokeBuild(path)

  invokeBuild: (path) =>
    @log "invoking build on: #{path}"
    unless @running
      @running = true # block build-runner

      commands = [@gradleCli]
      commands.push("--project-dir " + path)
      if @runAsDaemon
        commands.push('--daemon')
      commands.push(@runTasks)

      @log 'prepared build command: ' + commands.join(' ')
      shell.exec(commands.join(' '), @execAsyncAndSilent, @analyzeBuildResults)
      @statusView.setIcon('running')
    else
      unless @pending
        @pending = path

  analyzeBuildResults: (errorcode, output) =>
    @log "analyzing last build."
    if @results.length == 0
      unless @panel.active
        @panel.active = true

      @statusView.setTooltip("Click me to toggle your build-reports.")

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

    # free the build-runner or invoke pending build
    unless @pending
      @running = false # free the build runner
    else
      invokeBuild(@pending)
      @pending = false

  # toggles the result-panel - this works only if the @panel is previously set to active
  toggleResults: =>
    if !@panel.isVisible()
      @groupView.renderResults()
    @panel.toggle()

  log: (text) =>
   @logger 'log', text

  error: (text) =>
   @logger 'error', text

  logger: (level, text) =>
    text = "GradleCi: " + text
    switch level
      when "log"
        console.log text
      when "error"
        console.error text

module.exports = GradleCiBuilder
