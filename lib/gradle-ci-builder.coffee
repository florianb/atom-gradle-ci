require 'atom'
shell = require 'shelljs'
chokidar = require 'chokidar'


GradleCiStatusView = require './gradle-ci-status-view'
GradleCiResultGroupView = require './gradle-ci-result-group-view'


class GradleCiBuilder
  statusView: null
  resultGroupView: null

  constructor: ->
    console.log 'GradleCI: initializing builder.'
    @enabled = false
    @running = false
    @results = []
    @gradleCli = 'gradle'
    @execAsyncAndSilent = { async: true, silent: true }

    @statusView ?= new GradleCiStatusView this
    @resultGroupView ?= new GradleCiResultGroupView this

    atom.config.observe 'gradle-ci.runAsDaemon', =>
      @runAsDaemon = atom.config.get 'gradle-ci.runAsDaemon'
    atom.config.observe 'gradle-ci.runTasks', =>
      @runTasks = atom.config.get 'gradle-ci.runTasks'
    atom.config.observe 'gradle-ci.triggerBuildAfterSave', =>
      @triggerBuildAfterSave = atom.config.get 'gradle-ci.triggerBuildAfterSave'
    #atom.config.observe 'gradle-ci.triggerBuildAfterCommit', =>
      #@triggerBuildAfterCommit = atom.config.get('gradle-ci.triggerBuildAfterCommit')
    atom.config.observe 'gradle-ci.maximumResultHistory', =>
      @historyLimitChanged()

    console.log "GradleCI: setting up chokidar on path: " + atom.project.getPath()
    @projectWatcher = chokidar.watch(atom.project.getPath(), { persistent: true, interval: 500, binaryInterval: 500 })

    shell.exec("#{@gradleCli} --version", @execAsyncAndSilent, this.checkVersion)
    console.log "GradleCI: pre-initialization of the builder done."

  destroy: =>
    console.log 'GradleCI: destroying builder.'
    atom.config.unobserve 'gradle-ci.runAsDaemon'
    atom.config.unobserve 'gradle-ci.runTasks'
    atom.config.unobserve 'gradle-ci.triggerBuildAfterSave'
    #atom.config.unobserve 'gradle-ci.triggerBuildAfterCommit'
    atom.config.unobserve 'gradle-ci.maximumResultHistory'
    @projectWatcher.close()

  historyLimitChanged: =>
    console.log "GradleCI: the history-limit did change"
    @maximumResultHistory = atom.config.getPositiveInt('gradle-ci.maximumResultHistory', 3)
    if @results? and @results.length > @maximumResultHistory
      @results = @results.splice(0, @maximumResultHistory)
      if @resultGroupView?
        @resultGroupView.renderResults()

  checkVersion: (errorcode, output) =>
    versionRegEx = /Gradle ([\d\.]+)/
    console.log("GradleCI: going for version-check.")

    if errorcode == 0 and output.length > 0 and versionRegEx.test(output)
      version = versionRegEx.exec(output)[1]
      @projectWatcher.on 'change', @directoryChangedEvent
      @enabled = true
      @statusView.setLabel('Gradle ' + version)
      console.log("GradleCI: Gradle #{version} ready to use.")
    else
      @statusView.setIcon('disabled')
      console.error("GradleCI: Gradle wasn't executable: " + output)

  directoryChangedEvent: (path) =>
    console.log 'GradleCI: the project-directory did change.'
    if @triggerBuildAfterSave
      @invokeBuild()

  invokeBuild: =>
    console.log 'GradleCI: invoking build.'
    unless @running
      @running = true # block build-runner

      commands = [@gradleCli]
      commands.push("--project-dir " + atom.project.getPath())
      if @runAsDaemon
        commands.push('--daemon')
      commands.push(@runTasks)

      console.log 'GradleCI: prepared build command: ' + commands.join(' ')
      shell.exec(commands.join(' '), @execAsyncAndSilent, @analyzeBuildResults)
      @statusView.setIcon('running')

  analyzeBuildResults: (errorcode, output) =>
    console.log "GradleCI: analyzing last build."
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
    @resultGroupView.renderResults()
    @running = false # free build runner

module.exports = GradleCiBuilder
