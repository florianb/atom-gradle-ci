{View} = require 'atom'

module.exports =
class ResultView extends View
  @content: ->
    @div class: 'gradle-ci-result', =>
      @pre outlet: 'output'

  initialize: (result) ->
    console.log 'GradleCI: ResultView: initialize'
    @output.text(result)
