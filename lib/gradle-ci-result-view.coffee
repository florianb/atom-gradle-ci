{View} = require 'atom'
timeAgo = require 'damals'


class ResultView extends View
  @content: ->
    @div class: 'result-container', =>
      @div outlet: 'header', class: 'result-header text-subtle'
      @div =>
        @pre outlet: 'output', class: 'result-output'

  constructor: (result) ->
    super
    @header.text(timeAgo(result.timestamp))
    @output.text(result.output)
    console.log 'GradleCI: ResultView: initialize'

module.exports = ResultView
