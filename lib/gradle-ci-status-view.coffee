{View} = require 'atom-space-pen-views'


ResultGroupView = require './gradle-ci-result-group-view'


class GradleCiStatusView extends View
  builder: null

  @content: ->
    @div class: 'gradle-ci-status inline-block', click: 'toggleResults', =>
      @span class: 'status-icon', outlet: 'statusIcon'
      @span 'GradleCI', outlet: 'statusLabel'

  constructor: (params) ->
    super
    @builder = params.builder
    @tile = null
    @builder.log("StatusView: initialized.")

  registerTile: (statusBar) ->
    @tile = statusBar.addRightTile(item: this)

  destroy: =>
    @remove()
    @tile.destroy() if @tile
    @tooltip.dispose() if @tooltip
    @builder.log('StatusView: destroyed.')

  setTooltip: (message) =>
    @tooltip.dispose() if @tooltip
    @tooltip = atom.tooltips.add(this, {title: message})

  setLabel: (label) =>
    @statusLabel.text(label)

  setIcon: (status) =>
    if @tile
      @statusIcon.removeClass()
      if status
        icon = switch status
          when 'exception' then 'alert'
          when 'running' then 'hourglass'
          when 'succeeded' then 'check'
          when 'failed' then 'bug'

        @statusIcon.addClass("icon icon-#{icon}")

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
