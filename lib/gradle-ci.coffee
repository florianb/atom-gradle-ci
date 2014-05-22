GradleCiBuilder = require './gradle-ci-builder'
GradleCiStatusView = require './gradle-ci-status-view'
GradleCiResultGroupView = require './gradle-ci-result-group-view'

module.exports =
configDefaults:
  runAsDaemon: true
  runTasks: "test"
  triggerBuildAfterSave: true
  maximumResultHistory: 3
  #triggerBuildAfterCommit: true

builder: null
statusView: null
resultGroupView: null

activate: ->
  @builder ?= new GradleCiBuilder
  @statusView ?= new GradleCiStatusView @builder
  @resultGroupView ?= new GradleCiResultGroupView @builder

  if atom.workspaceView.statusBar?
    @enableStatusView()
  else
    atom.packages.once 'activated', @enableStatusView()

deactivate: ->
  @builder.destroy()
  @builder = null
  @statusView = null
  @resultGroupView = null
