GradleCiBuilder = require './gradle-ci-builder'


module.exports =
  configDefaults:
    runAsDaemon: true
    runTasks: "test"
    triggerBuildAfterSave: true
    maximumResultHistory: 3
    colorStatusIcon: true
    #triggerBuildAfterCommit: true

  builder: null

  activate: ->
    @builder ?= new GradleCiBuilder

  deactivate: ->
    @builder.destroy()
    @builder = null
