{$,$$,ScrollView} = require 'atom'
ResultView = require './gradle-ci-result-view'

module.exports =
class ResultGroupView extends ScrollView
  @content: ->
    @div class: 'gradle-ci', =>
      @div {class: 'resize-handle', outlet: 'resizeHandle'}, =>
        @span class: 'icon icon-primitive-dot'
      @div {class: 'group-header'}, =>
        @div 'GradleCI ', {class: 'inline-block highlight', outlet: 'header'}
      @div {class: 'group-results', outlet: 'resultList'}

  initialize: (statusView) ->
    super()
    @statusView = statusView
    @resized = false
    atom.workspaceView.command "gradle-ci:toggle-results", => @toggle()
    @on 'mousedown', '.resize-handle', (e) => @resizeStarted(e)
    console.log 'GradleCI: ResultGroupView: initialized'

  resizeStarted: =>
    @resized = true
    $(document.body).on 'mousemove', @resizeView
    $(document.body).on 'mouseup', @resizeStop

  resizeStop: =>
    $(document.body).off 'mousemove', @resizeView
    $(document.body).off 'mouseup', @resizeStop

  resizeView: ({pageY}) =>
    @height($(document.body).height() - pageY)

  setResults: =>
    console.log 'GradleCI: ResultGroupView: setting ' + @statusView.results.length + ' results'
    @resultList.empty()
    views =  @statusView.results.map (result) ->
      new ResultView(result)
    views.forEach (view) =>
      @resultList.append(view)

  toggle: =>
    console.log 'GradleCI: ResultGroupView: toggle'
    if @hasParent()
      @detach()
    else
      if @statusView.results? and @statusView.results.length > 0
        @header.text('gradle ' + atom.packages.getActivePackage('gradle-ci').metadata.version)
        @setResults()
        atom.workspaceView.appendToBottom(this)
        @height($(document.body).height() / 3) unless @resized
