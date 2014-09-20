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
  modalWidthPercent: 95
  id: 'game-menu-modal'
  instant: true

  events:
    'change input.select': 'onSelectionChanged'
    'shown.bs.tab .nav-tabs a': 'onTabShown'

  constructor: (options) ->
    super options
    @options.showDevBits = me.isAdmin() or /https?:\/\/localhost/.test(window.location.href)
    @options.showInventory = @options.level.get('type', true) is 'hero'

  getRenderData: (context={}) ->
    context = super(context)
    context.showDevBits = @options.showDevBits
    context.showInventory = @options.showInventory
    context

  afterRender: ->
    super()
    @$el.toggleClas
    @insertSubView new submenuView @options for submenuView in submenuViews
    (if @options.showInventory then @subviews.inventory_view else @subviews.choose_hero_view).$el.addClass 'active'
    Backbone.Mediator.publish 'audio-player:play-sound', trigger: 'game-menu-open', volume: 1

  onTabShown: ->
    Backbone.Mediator.publish 'audio-player:play-sound', trigger: 'game-menu-tab-switch', volume: 1

  onHidden: ->
    super()
    subview.onHidden?() for subviewKey, subview of @subviews
    patchingMe = @updateHeroConfig()
    me.patch() unless patchingMe  # Might need to patch for options menu
    Backbone.Mediator.publish 'audio-player:play-sound', trigger: 'game-menu-close', volume: 1

  updateHeroConfig: ->
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
    if patchSession
      @options.session.set 'heroConfig', sessionHeroConfig
      @options.session.patch success: ->
        _.defer -> Backbone.Mediator.publish 'level:hero-config-changed', {}
    if patchMe
      me.set 'heroConfig', lastHeroConfig
      me.patch()
    patchMe
