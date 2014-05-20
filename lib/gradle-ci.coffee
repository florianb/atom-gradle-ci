

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
      @enableStatusView()
    else
      atom.packages.once 'activated', @enableStatusView()

  deactivate: ->
    @disableStatusView()

  serialize: ->
    {}

  enableStatusView: =>
    @currentStatusView ?= new GradleCiStatusView
    @currentStatusView.initialize

  disableStatusView: ->
    @currentStatusView.destroy()
    @currentStatusView = null
