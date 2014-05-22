{$, View} = require 'atom'
shell = require 'shelljs'
chokidar = require 'chokidar'


ResultGroupView = require './gradle-ci-result-group-view'


class GradleCiStatusView extends View
  builder: null

  @content: ->
    @div class: 'gradle-ci-status inline-block', click: 'toggleResultGroup', =>
      @span class: 'status-icon', outlet: 'statusIcon'
      @span 'GradleCI', outlet: 'statusLabel'

  constructor: (currentBuilder) ->
    super
    @builder = currentBuilder
    if atom.workspaceView.statusBar?
      @setIcon()
    else
      atom.packages.once 'activated', =>
        @setIcon()
    console.log "GradleCI: statusView initialized."

  destroy: =>
    @remove()
    console.log 'GradleCI: statusView destroyed.'

  setLabel: (label) =>
    @statusLabel.text(label)

  setIcon: (status) =>
    if atom.workspaceView.statusBar?
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

      atom.workspaceView.statusBar.appendRight(this) unless $(this).is(':visible')

  toggleResultGroup: =>
    @builder.resultGroupView.toggle()

module.exports = GradleCiStatusView
