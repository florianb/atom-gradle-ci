{ScrollView} = require 'atom-space-pen-views'

ResultView = require './gradle-ci-result-view'


class ResultGroupView extends ScrollView
  builder: null

  @content: ->
    @div class: 'gradle-ci', =>
      @div class: 'group-header', =>
        @span 'gradle', class: 'inline-block highlight', outlet: 'buildCommand'
        @span 'GradleCI', class: 'inline-block highlight', outlet: 'gradleCiVersion'
        @span class: 'close-button inline-block', click: 'togglePanel', =>
          @i class: 'icon icon-fold'
      @div class: 'group-results', outlet: 'resultList'

  initialize: (params) ->
    super
    @builder = params.builder
    @builder.log('ResultGroupView: initialized.')

  renderResults: =>
    if @builder.results.length > 0
      @builder.log('GradleCI: ResultGroupView: setting ' +
        @builder.results.length +
        ' result/s.')
      @resultList.empty()
      views = @builder.results.map (result) ->
        new ResultView(result)
      for view in views
        @resultList.append(view)

  togglePanel: =>
    @builder.toggleResults()


module.exports = ResultGroupView
