{$,$$,ScrollView} = require 'atom'
ResultView = require './gradle-ci-result-view'

module.exports =
class ResultGroupView extends ScrollView
  @content: ->
    @div class: 'gradle-ci', =>
      @div {class: 'resize-handle', outlet: 'resizeHandle'}, =>
        @span class: 'icon icon-primitive-dot'
      @div {class: 'gradle-ci-results', outlet: 'resultList'}

  initialize: (state) ->
    @latestHeight = $(document.body).height() / 3
    atom.workspaceView.command "gradle-ci:toggle-results", => @toggle()
    @on 'mousedown', '.resize-handle', (e) => @resizeStarted(e)
    super()
    console.log 'GradleCI: ResultGroupView: initialized'

  resizeStarted: =>
    $(document.body).on 'mousemove', @resizeView
    $(document.body).on 'mouseup', @resizeStop

  resizeStop: =>
    $(document.body).off 'mousemove', @resizeView
    $(document.body).off 'mouseup', @resizeStop

  resizeView: ({pageY}) =>
    @height($(document.body).height() - pageY)

  setResults: (results) =>
    console.log 'GradleCI: ResultGroupView: setting ' + results.length + ' results'
    @resultList.empty()
    views = results.map (result) ->
      new ResultView(result)
    views.forEach (view) =>
      @resultList.append(view)

  toggle: =>
    console.log 'GradleCI: ResultGroupView: toggle'
    if @hasParent()
      @detach()
    else
      if @children.length > 0
        atom.workspaceView.appendToBottom(this)
