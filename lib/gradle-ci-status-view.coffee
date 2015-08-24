{$, View} = require 'atom-space-pen-views'
shell = require 'shelljs'


ResultGroupView = require './gradle-ci-result-group-view'


class GradleCiStatusView extends View
  builder: null

  @content: ->
    @div class: 'gradle-ci-status inline-block', click: 'toggleResults', =>
      @span class: 'status-icon', outlet: 'statusIcon'
      @span 'GradleCI', outlet: 'statusLabel'

  constructor: (currentBuilder) ->
    super
    @builder = currentBuilder
    @tile = null
    console.log "GradleCI: statusView initialized."

  registerTile: (statusBar) ->
    @tile = statusBar.addLeftTile(item: this, priority: 0)

  destroy: =>
    @remove()
    if @tile
      @tile.destroy()
    console.log 'GradleCI: statusView destroyed.'

  setLabel: (label) =>
    @statusLabel.text(label)

  setIcon: (status) =>
    if @tile
      icon = switch status
        when 'disabled' then 'alert'
        when 'running' then 'hourglass'
        when 'succeeded' then 'beer'
        when 'failed' then 'bug'
        else 'circle-slash'

      @statusIcon.removeClass().addClass("icon icon-#{icon}")

      iconColor = switch status
        when 'succeeded' then 'text-success'
        when 'failed' then 'text-error'
        else ''

      if @builder.colorStatusIcon and iconColor
        @statusIcon.addClass("#{iconColor}")

  #atom.workspaceView.statusBar.appendRight(this) unless $(this).is(':visible')

  toggleResults: =>
    @builder.toggleResults()

module.exports = GradleCiStatusView
