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
    buildfileName:
      title: 'Buildfile-name to search for.'
      type: 'string'
      default: 'build.gradle'
    gradleWrappers:
      title: 'Build-commands to try for build-invokation.'
      description: 'Comma separated list of build-commands which will be checked immediately after the package-startup. The given commands will be tested from left to right and must support the same command-line-interface as Gradle itself. As default the availability of `gw` (http://www.gdub.rocks/) will be checked before the `gradle`-command is used.'
      type: 'array'
      default: ['gw', 'gradle']
      items:
        type: 'string'

  builder: null

  activate: ->
    @builder ?= new GradleCiBuilder

  deactivate: ->
    @builder.destroy()
    @builder = null

  # use the statusBar-service to register the tile for the status-view
  consumeStatusBar: (statusBar) ->
    @builder.statusView.registerTile(statusBar)
