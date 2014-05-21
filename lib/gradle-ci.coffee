

GradleCiStatusView = require './gradle-ci-status-view'


module.exports =
  configDefaults:
    runAsDaemon: true
    runTasks: "test"
    triggerBuildAfterSave: true
    maximumResultHistory: 3
    #triggerBuildAfterCommit: true

  currentStatusView: null

  activate: () ->
    if atom.workspaceView.statusBar?
      @enableStatusView()
    else
      atom.packages.once 'activated', @enableStatusView(state)

  deactivate: ->
    @disableStatusView()

  enableStatusView: (state) =>
    @currentStatusView ?= new GradleCiStatusView
    @currentStatusView.initialize()

  disableStatusView: ->
    if @currentStatusView
      @currentStatusView.destroy()
      @currentStatusView = null
