GradleCiBuilder = require './gradle-ci-builder'


module.exports =
  config:
    runAsDaemon:
      title: 'Run Gradle as Daemon.'
      description: 'Invokes Gradle with the `--daemon`-switch, which typically improves the performance of subsequential builds.'
      type: 'boolean'
      default: true
    runTasks:
      title: 'Task/s to run with Gradle.'
      description: 'Tasks you\'d like to run with Gradle. This String is completly appended to the Gradle-call.'
      type: 'string'
      default: 'test'
    triggerBuildAfterSave:
      title: 'Trigger the Gradle-Build after any File-Change.'
      description: 'If activated, Gradle will be invoked after every File-Change, if Gradle is currently not running. If Gradle is running, a subsequent run is scheduled.'
      type: 'boolean'
      default: true
    maximumResultHistory:
      title: 'The maximum number of results to keep.'
      description: 'The maximum number of results which will be kept in memory. The results will all be shown in the result-pane. A higher number results in higher memory consumption and may lead to a worse overall performance of Atom.'
      type: 'integer'
      default: 3
      minimum: 1
    colorStatusIcon:
      title: 'Colorize the status-bar-icons.'
      description: 'Colorizes the status-bar-icons in green/red, to recognize them faster. You may disable the colors to let the icons be less disturbing.'
      type: 'boolean'
      default: true
    #triggerBuildAfterCommit: true

  builder: null

  activate: ->
    @builder ?= new GradleCiBuilder

  deactivate: ->
    @builder.destroy()
    @builder = null
