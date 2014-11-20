CocoView = require 'views/kinds/CocoView'
template = require 'templates/play/level/control_bar'
{me} = require 'lib/auth'

GameMenuModal = require 'views/game-menu/GameMenuModal'
RealTimeModel = require 'models/RealTimeModel'
RealTimeCollection = require 'collections/RealTimeCollection'
LevelSetupManager = require 'lib/LevelSetupManager'
GameMenuModal = require 'views/game-menu/GameMenuModal'
CampaignOptions = require 'lib/CampaignOptions'

module.exports = class ControlBarView extends CocoView
  id: 'control-bar-view'
  template: template

  subscriptions:
    'bus:player-states-changed': 'onPlayerStatesChanged'
    'level:disable-controls': 'onDisableControls'
    'level:enable-controls': 'onEnableControls'
    'ipad:memory-warning': 'onIPadMemoryWarning'

  events:
    'click #next-game-button': -> Backbone.Mediator.publish 'level:next-game-pressed', {}
    'click #game-menu-button': 'showGameMenuModal'
    'click': -> Backbone.Mediator.publish 'tome:focus-editor', {}
    'click .levels-link-area': 'onClickHome'
    'click .home a': 'onClickHome'
    'click .multiplayer-area': 'onClickMultiplayer'

  constructor: (options) ->
    @worldName = options.worldName
    @session = options.session
    @level = options.level
    @levelID = @level.get('slug')
    @spectateGame = options.spectateGame ? false
    super options
    if @isMultiplayerLevel = @level.get('type') in ['hero-ladder']
      @multiplayerStatusManager = new MultiplayerStatusManager @levelID, @onMultiplayerStateChanged

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

  onMultiplayerStateChanged: => @render?()

  getRenderData: (c={}) ->
    super c
    c.worldName = @worldName
    c.multiplayerEnabled = @session.get('multiplayer')
    c.ladderGame = @level.get('type') in ['ladder', 'hero-ladder']
    if c.isMultiplayerLevel = @isMultiplayerLevel
      c.multiplayerStatus = @multiplayerStatusManager?.status
    c.spectateGame = @spectateGame
    @homeViewArgs = [{supermodel: if @hasReceivedMemoryWarning then null else @supermodel}]
    if @level.get('type', true) in ['ladder', 'ladder-tutorial', 'hero-ladder']
      levelID = @level.get('slug').replace /\-tutorial$/, ''
      @homeLink = c.homeLink = '/play/ladder/' + levelID
      @homeViewClass = require 'views/play/ladder/LadderView'
      @homeViewArgs.push levelID
    else if @level.get('type', true) in ['hero', 'hero-coop']
      @homeLink = c.homeLink = '/play'
      @homeViewClass = require 'views/play/WorldMapView'
      campaign = CampaignOptions.getCampaignForSlug @level.get 'slug'
      if campaign isnt 'dungeon'
        @homeLink += '/' + campaign
        @homeViewArgs.push campaign
    else
      @homeLink = c.homeLink = '/'
      @homeViewClass = require 'views/HomeView'
    c.editorLink = "/editor/level/#{@level.get('slug')}"
    c.homeLink = @homeLink
    c

  showGameMenuModal: ->
    gameMenuModal = new GameMenuModal level: @level, session: @session, supermodel: @supermodel
    @openModalView gameMenuModal
    @listenToOnce gameMenuModal, 'change-hero', ->
      @setupManager?.destroy()
      @setupManager = new LevelSetupManager({supermodel: @supermodel, levelID: @levelID, parent: @, session: @session})
      @setupManager.open()

  onClickHome: (e) ->
    e.preventDefault()
    e.stopImmediatePropagation()
    Backbone.Mediator.publish 'router:navigate', route: @homeLink, viewClass: @homeViewClass, viewArgs: @homeViewArgs

  onClickMultiplayer: (e) ->
    @openModalView new GameMenuModal showTab: 'multiplayer', level: @level, session: @session, supermodel: @supermodel

  onDisableControls: (e) -> @toggleControls e, false
  onEnableControls: (e) -> @toggleControls e, true
  toggleControls: (e, enabled) ->
    return if e.controls and not ('level' in e.controls)
    return if enabled is @controlsEnabled
    @controlsEnabled = enabled
    @$el.toggleClass 'controls-disabled', not enabled

  onIPadMemoryWarning: (e) ->
    @hasReceivedMemoryWarning = true

  destroy: ->
    @setupManager?.destroy()
    @multiplayerStatusManager?.destroy()
    super()

# MultiplayerStatusManager ######################################################
#
# Manages the multiplayer status, and calls @statusChangedCallback when it changes.
#
# It monitors these:
#   Real-time multiplayer players
#   Internal multiplayer status
#
# Real-time state variables:
#   @playersCollection - Real-time multiplayer players
#
# TODO: Not currently using player counts.  Should remove if we keep simple design.
#
class MultiplayerStatusManager

  constructor: (@levelID, @statusChangedCallback) ->
    @status = ''
    # @players = {}
    # @playersCollection = new RealTimeCollection('multiplayer_players/' + @levelID)
    # @playersCollection.on 'add', @onPlayerAdded
    # @playersCollection.each (player) => @onPlayerAdded player
    Backbone.Mediator.subscribe 'real-time-multiplayer:player-status', @onMultiplayerPlayerStatus

  destroy: ->
    Backbone.Mediator.unsubscribe 'real-time-multiplayer:player-status', @onMultiplayerPlayerStatus
    # @playersCollection?.off 'add', @onPlayerAdded
    # player.off 'change', @onPlayerChanged for id, player of @players

  onMultiplayerPlayerStatus: (e) =>
    @status = e.status
    @statusChangedCallback()

  # onPlayerAdded: (player) =>
  #   unless player.id is me.id
  #     @players[player.id] = new RealTimeModel('multiplayer_players/' + @levelID + '/' + player.id)
  #     @players[player.id].on 'change', @onPlayerChanged
  #   @countPlayers player
  #
  # onPlayerChanged: (player) =>
  #   @countPlayers player
  #
  # countPlayers: (changedPlayer) =>
  #   # TODO: save this stale hearbeat threshold setting somewhere
  #   staleHeartbeat = new Date()
  #   staleHeartbeat.setMinutes staleHeartbeat.getMinutes() - 3
  #   @playerCount = 0
  #   @playersCollectionAvailable = 0
  #   @playersCollectionUnavailable = 0
  #   @playersCollection.each (player) =>
  #     # Assume changedPlayer is fresher than entry in @playersCollection collection
  #     player = changedPlayer if changedPlayer? and player.id is changedPlayer.id
  #     unless staleHeartbeat >= new Date(player.get('heartbeat'))
  #       @playerCount++
  #       @playersCollectionAvailable++ if player.get('state') is 'available'
  #       @playersCollectionUnavailable++ if player.get('state') is 'unavailable'
  #   @statusChangedCallback()
