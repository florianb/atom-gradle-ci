require 'atom'
fs = require 'fs'
path = require 'path'

{Directory} = require 'pathwatcher'

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
  buildfiles: []
  buildQueue: []
  textEditorObservers: {}
  results: []
  gradleCli: 'gradle'
  execAsyncAndSilent: { async: true, silent: true }

  constructor: ->
    @log 'initializing builder.'

    # initialize the statsview immediately
    @statusView = new GradleCiStatusView({ builder: this })

    setTimeout(@lazyLoad, 0)

  lazyLoad: () =>
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
    atom.config.observe 'gradle-ci.buildFileName', =>
      @buildfileName = atom.config.get 'gradle-ci.buildfileName'

    # register editor commands
    atom.commands.add 'atom-text-editor',
      "gradle-ci:toggle-results", => @toggleResults()
    atom.commands.add 'atom-text-editor',
      "gradle-ci:invoke-build", => @enqueueAllBuildPaths()

    # observe buildpaths
    atom.project.onDidChangePaths(@setBuildFiles)
    # initially set the buildfiles after startup
    @setBuildFiles()

    # observe TextEditors to watch save-events
    @textEditorsObserver = atom.workspace.observeTextEditors(@hookInTextEditorEvents)

    # start asynchronous gradle-check
    shell.exec(
      "#{@gradleCli} --version",
      @execAsyncAndSilent,
      @checkVersion
    )
    @log "pre-initialization of the builder done."


  destroy: =>
    @log 'destroying builder.'
    @enabled = false
    # dispose dedicated textEditor-observers for onDidSave and onDidDestroy
    for currentObserver in @textEditorObservers
      for handler in currentObserver.handlers
        handler.dispose()
    @textEditorsObserver.dispose() if @textEditorsObserver
    @statusView.destroy()
    @panel.destroy()

  hookInTextEditorEvents: (textEditor) =>
    currentPath = textEditor.getPath()
    currentObserver = @textEditorObservers[currentPath]

    unless currentObserver
      @log "hooking into save-events for '#{currentPath}'."
      observer = {
        path: currentPath
        invoker: () =>
          @enqueueBuild(currentPath)
        remover: () =>
          @removeHooks(currentPath)
        handlers: []
      }
      observer.handlers.push(textEditor.onDidSave(observer.invoker))
      observer.handlers.push(textEditor.onDidDestroy(observer.remover))
      @textEditorObservers[currentPath] = observer

  removeHooks: (givenPath) =>
    currentObserver = @textEditorObservers[givenPath]

    if currentObserver
      @log "removing hooks for '#{givenPath}'."
      handler.dispose() for handler in currentObserver.handlers
      @textEditorObservers[givenPath] = null

  setBuildFiles: =>
    @log "fetching projectpaths, searching for build-files."

    @buildfiles = []
    projectPaths = atom.project.getPaths()
    for currentPath in projectPaths
      @log "examining path #{currentPath}"
      checkBuildFileAccess = (projectPath, buildfileName) =>
        file = path.join(projectPath, buildfileName)
        fs.access(file, fs.R_OK, (err) =>
          if err
            console.error "the buildfile '#{file}' is inaccessible."
            if @buildfiles.length <= 0
              @disableBuilder("No buildfiles found.")
          else
            console.log "registering buildfile '#{file}'."
            @buildfiles.push({
              buildfile: file
              projectPath: projectPath
            })
        )
      checkBuildFileAccess(currentPath, @buildfileName)

  disableBuilder: (message, errormessage) =>
    # dispose dedicated textEditor-observers for onDidSave and onDidDestroy
    @statusView.setIcon() # remove icon from status-bar
    @statusView.setTooltip(message)
    @enabled = false
    @error errormessage if errormessage

  checkVersion: (errorcode, output) =>
    versionRegEx = /Gradle ([\d\.]+)/
    @log("going for version-check.")

    # if gradle was sucessfully invoked
    if errorcode == 0 and output.length > 0 and versionRegEx.test(output)
      version = versionRegEx.exec(output)[1]
      @enabled = true # enable builder
      @statusView.setLabel('Gradle ' + version)
      @statusView.setTooltip('You don\'t have any builds yet.')
      @log("Gradle #{version} ready to use.")
    else # otherwise display an error
      @disableBuilder("I'm not able to execute `gradle`.", "Gradle wasn't executable: " + output)

  enqueueAllBuildPaths: () =>
    for currentTexteditor in atom.workspace.getTextEditors()
      @enqueueBuild(currentTexteditor.getPath())

  enqueueBuild: (currentPath) =>
    [projectPath, relativePath] = atom.project.relativizePath(currentPath)
    for buildfile in @buildfiles
      if buildfile.projectPath == projectPath
        if projectPath not in @buildQueue
          @log "enqueuing build on: #{buildfile.buildfile}"
          @buildQueue.push(projectPath)
          @invokeBuild()

  invokeBuild: =>
    if not @running and @buildQueue.length > 0
      @running = true # block build-runner

      currentPath = @buildQueue.shift()

      commands = [@gradleCli]
      commands.push("--build-file #{path.join(currentPath, @buildfileName)}")
      commands.push("--project-dir #{currentPath}")
      commands.push('--daemon') if @runAsDaemon
      commands.push(@runTasks)

      command = commands.join(' ')

      @log 'prepared build command: ' + command
      shell.exec(command, @execAsyncAndSilent, @analyzeBuildResults)
      @statusView.setIcon('running')

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
    if @buildQueue.length > 0
      @invokeBuild()
    else
      @running = false # free the build runner

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
