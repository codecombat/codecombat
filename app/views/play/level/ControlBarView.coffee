CocoView = require 'views/kinds/CocoView'
template = require 'templates/play/level/control_bar'
{me} = require 'lib/auth'

LevelGuideModal = require './modal/LevelGuideModal'
GameMenuModal = require 'views/game-menu/GameMenuModal'
RealTimeCollection = require 'collections/RealTimeCollection'

module.exports = class ControlBarView extends CocoView
  id: 'control-bar-view'
  template: template

  subscriptions:
    'bus:player-states-changed': 'onPlayerStatesChanged'
    'real-time-multiplayer:joined-game': 'onJoinedRealTimeMultiplayerGame'
    'real-time-multiplayer:left-game': 'onLeftRealTimeMultiplayerGame'

  events:
    'click #docs-button': ->
      window.tracker?.trackEvent 'Clicked Docs', level: @level.get('name'), label: @level.get('name')
      @showGuideModal()

    'click #next-game-button': -> Backbone.Mediator.publish 'level:next-game-pressed', {}

    'click #game-menu-button': 'showGameMenuModal'

    'click #stop-real-time-playback-button': -> Backbone.Mediator.publish 'playback:stop-real-time-playback', {}

    'click': -> Backbone.Mediator.publish 'tome:focus-editor', {}

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
    if @level.get('type') in ['ladder', 'ladder-tutorial']
      c.homeLink = '/play/ladder/' + @level.get('slug').replace /\-tutorial$/, ''
    else
      c.homeLink = '/'
    c.editorLink = "/editor/level/#{@level.get('slug')}"
    c.multiplayerSession = @multiplayerSession if @multiplayerSession
    c.multiplayerPlayers = @multiplayerPlayers if @multiplayerPlayers
    c.meID = me.id
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
    @openModalView(new LevelGuideModal(options))
    clearInterval @guideHighlightInterval
    @guideHighlightInterval = null

  showGameMenuModal: ->
    @openModalView new GameMenuModal level: @level, session: @session, playableTeams: @playableTeams

  onJoinedRealTimeMultiplayerGame: (e) ->
    @multiplayerSession = e.session
    @multiplayerPlayers = new RealTimeCollection('multiplayer_level_sessions/' + @multiplayerSession.id + '/players')
    @multiplayerPlayers.on 'add', @onRealTimeMultiplayerPlayerAdded
    @multiplayerPlayers.on 'remove', @onRealTimeMultiplayerPlayerRemoved
    @render()

  onLeftRealTimeMultiplayerGame: (e) ->
    @multiplayerSession = null
    @multiplayerPlayers.off()
    @multiplayerPlayers = null
    @render()

  onRealTimeMultiplayerPlayerAdded: (e) =>
    @render() unless @destroyed

  onRealTimeMultiplayerPlayerRemoved: (e) =>
    @render() unless @destroyed
