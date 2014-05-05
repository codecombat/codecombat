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

    'click #next-game-button': ->
      Backbone.Mediator.publish 'next-game-pressed'

    'click': -> Backbone.Mediator.publish 'focus-editor'

  constructor: (options) ->
    @worldName = options.worldName
    @session = options.session
    @level = options.level
    @playableTeams = options.playableTeams
    @spectateGame = options.spectateGame ? false
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

  getRenderData: (c={}) ->
    super c
    c.worldName = @worldName
    c.multiplayerEnabled = @session.get('multiplayer')
    c.ladderGame = @level.get('type') is 'ladder'
    c.spectateGame = @spectateGame
    console.log "level type is", @level.get('type')
    if @level.get('type') in ['ladder', 'ladder-tutorial']
      c.homeLink = '/play/ladder/' + @level.get('slug').replace /\-tutorial$/, ''
    else
      c.homeLink = '/'
    c

  afterRender: ->
    super()
    @guideHighlightInterval ?= setInterval @onGuideHighlight, 5 * 60 * 1000

  destroy: ->
    clearInterval @guideHighlightInterval if @guideHighlightInterval
    super()

  onGuideHighlight: =>
    return if @destroyed or @guideShownOnce
    @$el.find('#docs-button').hide().show('highlight', 4000)

  showGuideModal: ->
    options = {docs: @level.get('documentation'), supermodel: @supermodel}
    @openModalView(new DocsModal(options))
    clearInterval @guideHighlightInterval
    @guideHighlightInterval = null

  showMultiplayerModal: ->
    @openModalView(new MultiplayerModal(session: @session, playableTeams: @playableTeams, level: @level, ladderGame: @ladderGame))

  showRestartModal: ->
    @openModalView(new ReloadModal())
