CocoView = require 'views/kinds/CocoView'
template = require 'templates/play/level/control_bar'
{me} = require 'lib/auth'

GameMenuModal = require 'views/game-menu/GameMenuModal'
RealTimeCollection = require 'collections/RealTimeCollection'

module.exports = class ControlBarView extends CocoView
  id: 'control-bar-view'
  template: template

  subscriptions:
    'bus:player-states-changed': 'onPlayerStatesChanged'

  events:
    'click #next-game-button': -> Backbone.Mediator.publish 'level:next-game-pressed', {}
    'click #game-menu-button': 'showGameMenuModal'
    'click': -> Backbone.Mediator.publish 'tome:focus-editor', {}
    'click .home a': 'onClickHome'

  constructor: (options) ->
    @worldName = options.worldName
    @session = options.session
    @level = options.level
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
    c.ladderGame = @level.get('type') in ['ladder', 'hero-ladder']
    c.spectateGame = @spectateGame
    @homeViewArgs = [{supermodel: @supermodel}]
    if @level.get('type', true) in ['ladder', 'ladder-tutorial', 'hero-ladder']
      levelID = @level.get('slug').replace /\-tutorial$/, ''
      @homeLink = c.homeLink = '/play/ladder/' + levelID
      @homeViewClass = require 'views/play/ladder/LadderView'
      @homeViewArgs.push levelID
    else if @level.get('type', true) in ['hero', 'hero-coop']
      @homeLink = c.homeLink = '/play'
      @homeViewClass = require 'views/play/WorldMapView'
      # TODO: dynamically figure out which world map to return to
      if @level.get('slug') in ['defense-of-plainswood', 'winding-trail', 'thornbush-farm', 'a-fiery-trap']
        @homeLink += '/forest'
        @homeViewArgs.push 'forest'
    else
      @homeLink = c.homeLink = '/'
      @homeViewClass = require 'views/HomeView'
    c.editorLink = "/editor/level/#{@level.get('slug')}"
    c

  showGameMenuModal: ->
    @openModalView new GameMenuModal level: @level, session: @session, supermodel: @supermodel

  onClickHome: (e) ->
    e.preventDefault()
    e.stopImmediatePropagation()
    Backbone.Mediator.publish 'router:navigate', route: @homeLink, viewClass: @homeViewClass, viewArgs: @homeViewArgs
