View = require 'views/kinds/CocoView'
template = require 'templates/play/level/control_bar'

DocsModal = require './modal/docs_modal'
MultiplayerModal = require './modal/multiplayer_modal'
ReloadModal = require './modal/reload_modal'

module.exports = class ControlBarView extends View
  id: "control-bar-view"
  template: template

  subscriptions:
    'bus:player-states-changed': 'onPlayerStatesChanged'

  events:
    'click #multiplayer-button': ->
      window.tracker?.trackEvent 'Clicked Multiplayer', level: @worldName, label: @worldName
      @showMultiplayerModal()

    'click #docs-button': ->
      window.tracker?.trackEvent 'Clicked Docs', level: @worldName, label: @worldName
      @showGuideModal()

    'click #restart-button': ->
      window.tracker?.trackEvent 'Clicked Restart', level: @worldName, label: @worldName
      @showRestartModal()

    'click': -> Backbone.Mediator.publish 'focus-editor'

  constructor: (options) ->
    @worldName = options.worldName
    @session = options.session
    @level = options.level
    @playableTeams = options.playableTeams
    super options

  setBus: (@bus) ->

  onPlayerStatesChanged: (e) ->
    # TODO: this doesn't fire any more. Replacement?
    return unless @bus is e.bus
    numPlayers = _.keys(e.players).length
    return if numPlayers is @numPlayers
    @numPlayers = numPlayers
    text = 'Multiplayer'
    text += " (#{numPlayers})" if numPlayers > 1
    $('#multiplayer-button', @$el).text(text)

  getRenderData: (context={}) ->
    super context
    context.worldName = @worldName
    context.multiplayerEnabled = @session.get('multiplayer')
    context

  showGuideModal: ->
    options = {docs: @level.get('documentation'), supermodel: @supermodel}
    @openModalView(new DocsModal(options))

  showMultiplayerModal: ->
    @openModalView(new MultiplayerModal(session: @session, playableTeams: @playableTeams, level: @level))

  showRestartModal: ->
    @openModalView(new ReloadModal())
