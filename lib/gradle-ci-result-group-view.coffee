{$, ScrollView} = require 'atom-space-pen-views'

ResultView = require './gradle-ci-result-view'


class ResultGroupView extends ScrollView
  builder: null

  @content: ->
    @div class: 'gradle-ci', =>
      @div class: 'group-header', =>
        @div 'GradleCI', class: 'inline-block highlight', outlet: 'header'
      @div class: 'group-results', outlet: 'resultList'

  initialize: (params) ->
    super
    @builder = params.builder
    console.log 'GradleCI: ResultGroupView: initialized'

  renderResults: =>
    #if @parentView.isVisible()
    console.log 'GradleCI: ResultGroupView: setting ' +
      @builder.results.length +
      ' result/s'
    @resultList.empty()
    views = @builder.results.map (result) ->
      new ResultView(result)
    for view in views
      @resultList.append(view)


module.exports = ResultGroupView
