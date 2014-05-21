

GradleCiStatusView = require './gradle-ci-status-view'


module.exports =
  configDefaults:
    runAsDaemon: true
    runTasks: "test"
    triggerBuildAfterSave: true
    #triggerBuildAfterCommit: true

  currentStatusView: null

  activate: (state) ->
    if atom.workspaceView.statusBar?
      @enableStatusView(state)
    else
      atom.packages.once 'activated', @enableStatusView()

  deactivate: ->
    @disableStatusView()

  serialize: ->
    JSON.stringify(@currentStatusView.results)

  enableStatusView: (state) =>
    @currentStatusView ?= new GradleCiStatusView
    @currentStatusView.initialize
    @currentStatusView.results = JSON.parse(state)

  disableStatusView: ->
    if @currentStatusView
      @currentStatusView.destroy()
      @currentStatusView = null
