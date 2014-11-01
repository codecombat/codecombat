ModalView = require 'views/kinds/ModalView'
template = require 'templates/game-menu/game-menu-modal'
submenuViews = [
  require 'views/game-menu/InventoryView'
  require 'views/game-menu/ChooseHeroView'
  require 'views/game-menu/SaveLoadView'
  require 'views/game-menu/OptionsView'
  require 'views/game-menu/GuideView'
  require 'views/game-menu/MultiplayerView'
]

module.exports = class GameMenuModal extends ModalView
  template: template
  id: 'game-menu-modal'
  instant: true

  events:
    'change input.select': 'onSelectionChanged'
    'shown.bs.tab #game-menu-nav a': 'onTabShown'

  constructor: (options) ->
    super options
    @options.showDevBits = me.isAdmin() or /https?:\/\/localhost/.test(window.location.href)
    @options.showInventory = @options.level.get('type', true) in ['hero', 'hero-ladder', 'hero-coop']
    @options.showTab = options.showTab
    @options.levelID = @options.level.get('slug')
    @options.startingSessionHeroConfig = $.extend {}, true, (@options.session.get('heroConfig') ? {})
    Backbone.Mediator.publish 'music-player:enter-menu', terrain: @options.level.get('terrain', true) ? 'Dungeon'

  getRenderData: (context={}) ->
    context = super(context)
    context.showDevBits = @options.showDevBits
    context.showInventory = @options.showInventory
    context.showTab = @options.showTab
    docs = @options.level.get('documentation') ? {}
    context.showsGuide = docs.specificArticles?.length or docs.generalArticles?.length
    context

  afterRender: ->
    super()
    @insertSubView new submenuView @options for submenuView in submenuViews
    if @options.showTab
      firstView = switch @options.showTab
        when 'multiplayer' then @subviews.multiplayer_view
    unless firstView?
      firstView = (if @options.showInventory then @subviews.inventory_view else @subviews.choose_hero_view)
    firstView.$el.addClass 'active'
    firstView.onShown?()
    Backbone.Mediator.publish 'audio-player:play-sound', trigger: 'game-menu-open', volume: 1

  onTabShown: (e) ->
    Backbone.Mediator.publish 'audio-player:play-sound', trigger: 'game-menu-tab-switch', volume: 1
    @subviews.inventory_view.selectedHero = @subviews.choose_hero_view.selectedHero
    @subviews[e.target.hash.substring(1).replace(/-/g, '_')].onShown?()

  onHidden: ->
    super()
    subview.onHidden?() for subviewKey, subview of @subviews
    patchingMe = @updateConfig()
    me.patch() unless patchingMe  # Might need to patch for options menu, too
    Backbone.Mediator.publish 'audio-player:play-sound', trigger: 'game-menu-close', volume: 1
    Backbone.Mediator.publish 'music-player:exit-menu', {}

  updateConfig: ->
    sessionHeroConfig = @options.startingSessionHeroConfig
    lastHeroConfig = me.get('heroConfig') ? {}
    thangType = @subviews.choose_hero_view.selectedHero?.get 'original'
    inventory = @subviews.inventory_view.getCurrentEquipmentConfig()
    patchSession = patchMe = false
    props = {}
    if thangType or not sessionHeroConfig.thangType
      props.thangType = thangType ? '529ffbf1cf1818f2be000001'  # Default to Tharin if it somehow doesn't get set.
    if _.size(inventory) or not sessionHeroConfig.inventory
      props.inventory = inventory
    for key, val of props when val
      patchSession ||= not _.isEqual val, sessionHeroConfig[key]
      patchMe ||= not _.isEqual val, lastHeroConfig[key]
      sessionHeroConfig[key] = val
      lastHeroConfig[key] = val
    if (codeLanguage = @subviews.choose_hero_view.codeLanguage) and @subviews.choose_hero_view.codeLanguageChanged
      patchSession ||= codeLanguage isnt @options.session.get('codeLanguage')
      patchMe ||= codeLanguage isnt me.get('aceConfig')?.language
      @options.session.set 'codeLanguage', codeLanguage
      aceConfig = me.get('aceConfig', true) ? {}
      aceConfig.language = codeLanguage
      me.set 'aceConfig', aceConfig
    console.log 'update config from game menu modal; props:', props, 'patch session?', patchSession, 'patch me?', patchMe
    if patchSession
      @options.session.set 'heroConfig', sessionHeroConfig
      success = ->
        _.defer -> Backbone.Mediator.publish 'level:hero-config-changed', {}
      error = (model, res) ->
        console.error 'error patching session', model, res, res.responseJSON, res.status, res.statusText
      @options.session.patch success: success, error: error
    if patchMe
      me.set 'heroConfig', lastHeroConfig
      me.patch()
    patchMe
