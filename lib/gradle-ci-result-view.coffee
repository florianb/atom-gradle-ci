{View} = require 'atom-space-pen-views'
timeAgo = require 'damals'


class ResultView extends View
  @content: ->
    @div class: 'result-container', =>
      @div outlet: 'header', class: 'result-header text-subtle'
      @div =>
        @pre outlet: 'output', class: 'result-output'

  constructor: (params) ->
    super
    @header.text(timeAgo(params.timestamp))
    @output.text(params.output)
    console.log('GradleCi: ResultView: initialized.')


module.exports = ResultView
