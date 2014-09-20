ModalView = require 'views/kinds/ModalView'
template = require 'templates/play/modal/play-level-modal'
ChooseHeroView = require 'views/game-menu/ChooseHeroView'
InventoryView = require 'views/game-menu/InventoryView'
PlayLevelView = require 'views/play/level/PlayLevelView'
LevelSession = require 'models/LevelSession'

module.exports = class PlayLevelModal extends ModalView
  className: 'modal fade play-modal'
  template: template
  id: 'play-level-modal'

  events:
    'click #choose-inventory-button': 'onClickChooseInventory'
    'click #choose-hero-button': 'onClickChooseHero'
    'click #play-level-button': 'onClickPlayLevel'

  constructor: (options) ->
    super options
    @options.showDevBits = true
    @loadSession()

  loadSession: ->
    url = "/db/level/#{@options.levelID}/session"
    #url += "?team=#{@team}" if @options.team  # TODO: figure out how to get the teams for multiplayer PVP hero style
    session = new LevelSession().setURL url
    @session = @supermodel.loadModel(session, 'level_session').model
    @options.session = @session

  getRenderData: (context={}) ->
    context = super(context)
    context.levelID = @options.levelID
    context.levelPath = @options.levelPath
    context.levelName = @options.levelName
    context

  afterRender: ->
    super()
    return unless @supermodel.finished()
    @session.url = -> '/db/level.session/' + @id
    Backbone.Mediator.publish 'audio-player:play-sound', trigger: 'game-menu-open', volume: 1
    @insertSubView @chooseHeroView = new ChooseHeroView @options
    @insertSubView @inventoryView = new InventoryView @options
    @inventoryView.$el.addClass 'secret'

  onHidden: ->
    unless @navigatingToPlay
      skipSessionSave = not @options.session.get('levelName')?  # Has to have been already started.
      @updateHeroConfig null, skipSessionSave
    Backbone.Mediator.publish 'audio-player:play-sound', trigger: 'game-menu-close', volume: 1
    super()

  updateHeroConfig: (callback, skipSessionSave) ->
    sessionHeroConfig = @options.session.get('heroConfig') ? {}
    lastHeroConfig = me.get('heroConfig') ? {}
    thangType = @subviews.choose_hero_view.selectedHero.get 'original'
    inventory = @subviews.inventory_view.getCurrentEquipmentConfig()
    patchSession = patchMe = false
    props = thangType: thangType, inventory: inventory
    for key, val of props when val
      patchSession ||= not _.isEqual val, sessionHeroConfig[key]
      patchMe ||= not _.isEqual val, lastHeroConfig[key]
      sessionHeroConfig[key] = val
      lastHeroConfig[key] = val
    if patchMe
      me.set 'heroConfig', lastHeroConfig
      me.patch()
    if patchSession
      @options.session.set 'heroConfig', sessionHeroConfig
      @options.session.patch success: callback unless skipSessionSave
    else
      callback?()

  onClickChooseInventory: (e) ->
    @chooseHeroView.$el.add('#choose-inventory-button, #choose-hero-header').addClass 'secret'
    @inventoryView.$el.add('#choose-hero-button, #play-level-button, #choose-inventory-header').removeClass 'secret'

  onClickChooseHero: (e) ->
    @chooseHeroView.$el.add('#choose-inventory-button, #choose-hero-header').removeClass 'secret'
    @inventoryView.$el.add('#choose-hero-button, #play-level-button, #choose-inventory-header').addClass 'secret'

  onClickPlayLevel: (e) ->
    @showLoading()
    @updateHeroConfig =>
      @navigatingToPlay = true
      Backbone.Mediator.publish 'router:navigate', {
        route: "/play/#{@options.levelPath || 'level'}/#{@options.levelID}",
        viewClass: PlayLevelView,
        viewArgs: [{supermodel: @supermodel}, @options.levelID]}
