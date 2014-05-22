{View} = require 'atom'
timeAgo = require 'damals'

module.exports =
class ResultView extends View
  @content: ->
    @div class: 'result-container', =>
      @div outlet: 'header', class: 'result-header text-subtle'
      @div =>
        @pre outlet: 'output', class: 'result-output'

  constructor: (centralBuilder) ->
    super
    @header.text(timeAgo(result.timestamp))
    @output.text(result.output)
    console.log 'GradleCI: ResultView: initialize'
