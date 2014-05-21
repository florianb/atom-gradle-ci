

GradleCiStatusView = require './gradle-ci-status-view'


module.exports =
  configDefaults:
    runAsDaemon: true
    runTasks: "test"
    triggerBuildAfterSave: true
    maximumResultHistory: 3
    #triggerBuildAfterCommit: true

  currentStatusView: null

  activate: (state) ->
    if atom.workspaceView.statusBar?
      @enableStatusView(state)
    else
      atom.packages.once 'activated', @enableStatusView(state)

  deactivate: ->
    @disableStatusView()

  serialize: ->
    JSON.stringify(@currentStatusView.results)

  enableStatusView: (state) =>
    console.log 'GradleCI: enabling with state: ' + state
    @currentStatusView ?= new GradleCiStatusView
    @currentStatusView.results = JSON.parse(state)
    @currentStatusView.initialize()

  disableStatusView: ->
    if @currentStatusView
      @currentStatusView.destroy()
      @currentStatusView = null
