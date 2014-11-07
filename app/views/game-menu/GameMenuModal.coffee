ModalView = require 'views/kinds/ModalView'
template = require 'templates/game-menu/game-menu-modal'
submenuViews = [
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
    @options.showTab = options.showTab
    @options.levelID = @options.level.get('slug')
    @options.startingSessionHeroConfig = $.extend {}, true, (@options.session.get('heroConfig') ? {})
    Backbone.Mediator.publish 'music-player:enter-menu', terrain: @options.level.get('terrain', true) ? 'Dungeon'

  getRenderData: (context={}) ->
    context = super(context)
    context.showDevBits = @options.showDevBits
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
      firstView = (@subviews.options_view)
    firstView.$el.addClass 'active'
    firstView.onShown?()
    Backbone.Mediator.publish 'audio-player:play-sound', trigger: 'game-menu-open', volume: 1

  onTabShown: (e) ->
    Backbone.Mediator.publish 'audio-player:play-sound', trigger: 'game-menu-tab-switch', volume: 1
    @subviews[e.target.hash.substring(1).replace(/-/g, '_')].onShown?()

  onHidden: ->
    super()
    subview.onHidden?() for subviewKey, subview of @subviews
    Backbone.Mediator.publish 'audio-player:play-sound', trigger: 'game-menu-close', volume: 1
    Backbone.Mediator.publish 'music-player:exit-menu', {}
