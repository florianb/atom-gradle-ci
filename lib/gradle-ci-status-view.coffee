
{$$, View, Editor, EditorView} = require 'atom'
shell = require 'shelljs'
chokidar = require 'chokidar'


ResultGroupView = require './gradle-ci-result-group-view'


module.exports =
class GradleCiStatusView extends View
  @content: ->
    @div class: 'gradle-ci-status inline-block', click: 'toggleResults', =>
      @span class: 'status-icon', outlet: 'statusIcon'
      @span 'GradleCI', outlet: 'statusLabel'

  constructor: (centralBuilder) ->
    super
    @builder = centralBuilder
    console.log "GradleCI: statusView initialized."

  destroy: =>
    @remove()
    console.log 'GradleCI: statusView destroyed.'

  setStatus: (status) =>
    icon = switch status
      when 'stopped' then 'icon-alert'
      when 'running' then 'icon-hourglass'
      when 'succeeded' then 'icon-beer'
      when 'failed' then 'icon-bug'
      else 'icon-circle-slash'
    @statusIcon.removeClass().addClass "icon #{icon}"
    atom.workspaceView.statusBar.appendRight(this)

  hide: =>
    @detach()
