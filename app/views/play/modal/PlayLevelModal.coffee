ModalView = require 'views/kinds/ModalView'
template = require 'templates/play/modal/play-level-modal'
ChooseHeroView = require 'views/game-menu/ChooseHeroView'
InventoryView = require 'views/game-menu/InventoryView'
PlayLevelView = require 'views/play/level/PlayLevelView'
LadderView = require 'views/play/ladder/LadderView'
LevelSession = require 'models/LevelSession'

hasGoneFullScreenOnce = false

module.exports = class PlayLevelModal extends ModalView
  className: 'modal fade play-modal'
  template: template
  id: 'play-level-modal'

  events:
    'click #choose-inventory-button': 'onClickChooseInventory'
    'click #choose-hero-button': 'onClickChooseHero'
    'click #play-level-button': 'onClickPlayLevel'

  shortcuts:
    'enter': 'onEnterPressed'

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
    if @options.hadEverChosenHero
      @$el.find('.choose-hero-active').add(@chooseHeroView.$el).addClass 'secret'
      @$el.find('.choose-inventory-active').removeClass 'secret'
      @inventoryView.onShown()
    else
      @$el.find('.choose-inventory-active').add(@inventoryView.$el).addClass 'secret'
      @$el.find('.choose-hero-active').removeClass 'secret'
      @chooseHeroView.onShown()

  onHidden: ->
    unless @navigatingToPlay
      skipSessionSave = not @options.session.get('levelName')?  # Has to have been already started.
      @updateConfig null, skipSessionSave
    Backbone.Mediator.publish 'audio-player:play-sound', trigger: 'game-menu-close', volume: 1
    super()

  updateConfig: (callback, skipSessionSave) ->
    sessionHeroConfig = @options.session.get('heroConfig') ? {}
    lastHeroConfig = me.get('heroConfig') ? {}
    thangType = @subviews.choose_hero_view.selectedHero?.get('original') ? sessionHeroConfig.thangType ? lastHeroConfig.thangType
    inventory = @subviews.inventory_view.getCurrentEquipmentConfig()
    patchSession = patchMe = false
    props = thangType: thangType, inventory: inventory
    for key, val of props when val
      patchSession ||= not _.isEqual val, sessionHeroConfig[key]
      patchMe ||= not _.isEqual val, lastHeroConfig[key]
      sessionHeroConfig[key] = val
      lastHeroConfig[key] = val
    if (codeLanguage = @subviews.choose_hero_view.codeLanguage) and (@subviews.choose_hero_view.codeLanguageChanged or not me.get('aceConfig'))
      patchSession ||= codeLanguage isnt @options.session.get('codeLanguage')
      patchMe ||= codeLanguage isnt me.get('aceConfig')?.language
      @options.session.set 'codeLanguage', codeLanguage
      aceConfig = me.get('aceConfig', true) ? {}
      aceConfig.language = codeLanguage
      me.set 'aceConfig', aceConfig
    if patchMe
      console.log 'setting me.heroConfig to', lastHeroConfig
      me.set 'heroConfig', lastHeroConfig
      me.patch()
    if patchSession
      console.log 'setting session.heroConfig to', sessionHeroConfig
      @options.session.set 'heroConfig', sessionHeroConfig
      @options.session.patch success: callback unless skipSessionSave
    else
      callback?()

  onClickChooseInventory: (e) ->
    @chooseHeroView.$el.add('#choose-inventory-button, #choose-hero-header').addClass 'secret'
    @inventoryView.$el.add('#choose-hero-button, #play-level-button, #choose-inventory-header').removeClass 'secret'
    @inventoryView.selectedHero = @chooseHeroView.selectedHero
    @inventoryView.onShown()
    window.tracker?.trackEvent 'Play Level Modal', Action: 'Choose Inventory'

  onClickChooseHero: (e) ->
    @chooseHeroView.$el.add('#choose-inventory-button, #choose-hero-header').removeClass 'secret'
    @inventoryView.$el.add('#choose-hero-button, #play-level-button, #choose-inventory-header').addClass 'secret'
    @chooseHeroView.onShown()
    @inventoryView.endHighlight()
    window.tracker?.trackEvent 'Play Level Modal', Action: 'Choose Hero'

  onClickPlayLevel: (e) ->
    return if @$el.find('#play-level-button').prop 'disabled'
    @showLoading()
    ua = navigator.userAgent.toLowerCase()
    unless hasGoneFullScreenOnce or (/safari/.test(ua) and not /chrome/.test(ua)) or $(window).height() >= 658  # Min vertical resolution needed at 1366px wide
      @toggleFullscreen()
      hasGoneFullScreenOnce = true
    @updateConfig =>
      @navigatingToPlay = true
      viewClass = if @options.levelPath is 'ladder' then LadderView else PlayLevelView
      Backbone.Mediator.publish 'router:navigate', {
        route: "/play/#{@options.levelPath || 'level'}/#{@options.levelID}"
        viewClass: viewClass
        viewArgs: [{supermodel: @supermodel}, @options.levelID]
      }
    window.tracker?.trackEvent 'Play Level Modal', Action: 'Play'

  onEnterPressed: (e) ->
    (if @chooseHeroView.$el.hasClass('secret') then @onClickPlayLevel else @onClickChooseInventory).apply @
