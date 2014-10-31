CocoView = require 'views/kinds/CocoView'
template = require 'templates/play/level/multiplayer-status'
{me} = require 'lib/auth'
RealTimeModel = require 'models/RealTimeModel'
RealTimeCollection = require 'collections/RealTimeCollection'
GameMenuModal = require 'views/game-menu/GameMenuModal'

# Real-time Multiplayer ######################################################
#
# This view displays the real-time multiplayer status for the current level.
#
# It performs these actions:
#   Multiplayer button into game-menu multiplayer section
#   Display number of players waiting for an opponent in this level
#   Display number of players current playing a pvp game in this level
#   Status for user's current real-time multiplayer session
#
# It monitors these:
#   Real-time multiplayer players
#   Internal multiplayer status
#
# Real-time state variables:
#   @playersCollection - Real-time multiplayer players

module.exports = class MultiplayerStatusView extends CocoView
  id: 'multiplayer-status-view'
  template: template

  subscriptions:
    'real-time-multiplayer:player-status': 'onRealTimeMultiplayerPlayerStatus'

  events:
    'click #multiplayer-button': 'onClickMultiplayerButton'

  constructor: (options) ->
    super(options)
    @session = options.session
    @level = options.level
    @levelID = options.levelID
    @status = ''
    @players = {}
    @playersCollection = new RealTimeCollection('multiplayer_players/' + @levelID)
    @playersCollection.on 'add', @onPlayerAdded
    @playersCollection.each (player) => @onPlayerAdded player
    
  destroy: ->
    @playersCollection?.off 'add', @onPlayerAdded
    player.off 'change', @onPlayerChanged for id, player of @players
    super()

  getRenderData: ->
    c = super()
    c.playerCount = @playerCount
    c.playersAvailable = @playersCollectionAvailable
    c.playersUnavailable = @playersCollectionUnavailable
    c.status = @status
    c

  onRealTimeMultiplayerPlayerStatus: (e) ->
    @status = e.status
    @render?()

  onClickMultiplayerButton: (e) ->
    @openModalView new GameMenuModal showTab: 'multiplayer', level: @level, session: @session, supermodel: @supermodel

  onPlayerAdded: (player) =>
    # console.log 'MultiplayerStatusView onPlayerAdded', player
    unless player.id is me.id
      @players[player.id] = new RealTimeModel('multiplayer_players/' + @levelID + '/' + player.id)
      @players[player.id].on 'change', @onPlayerChanged
    @countPlayers player

  onPlayerChanged: (player) =>
    # console.log 'MultiplayerStatusView onPlayerChanged', player
    @countPlayers player

  countPlayers: (changedPlayer) =>
    # TODO: save this stale hearbeat threshold setting somewhere
    staleHeartbeat = new Date()
    staleHeartbeat.setMinutes staleHeartbeat.getMinutes() - 3
    @playerCount = 0
    @playersCollectionAvailable = 0
    @playersCollectionUnavailable = 0
    @playersCollection.each (player) =>
      # Assume changedPlayer is fresher than entry in @playersCollection collection
      player = changedPlayer if changedPlayer? and player.id is changedPlayer.id
      unless staleHeartbeat >= new Date(player.get('heartbeat'))
        @playerCount++
        @playersCollectionAvailable++ if player.get('state') is 'available'
        @playersCollectionUnavailable++ if player.get('state') is 'unavailable'
    # console.log 'MultiplayerStatusView countPlayers', @playerCount, @playersCollectionAvailable, @playersCollectionUnavailable
    @render()

