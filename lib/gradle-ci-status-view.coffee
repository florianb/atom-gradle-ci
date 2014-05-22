{$$, View} = require 'atom'
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
        when 'disabled' then 'icon-alert'
        when 'running' then 'icon-hourglass'
        when 'succeeded' then 'icon-beer'
        when 'failed' then 'icon-bug'
        else 'icon-circle-slash'
      @statusIcon.removeClass().addClass("icon #{icon}")
      atom.workspaceView.statusBar.appendRight(this)

  hide: =>
    @detach()

  toggleResultGroup: =>
    @builder.resultGroupView.toggle()

module.exports = GradleCiStatusView
