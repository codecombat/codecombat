ModalView = require 'views/core/ModalView'
AuthModal = require 'views/core/AuthModal'
template = require 'templates/play/menu/game-menu-modal'
submenuViews = [
  require 'views/play/menu/SaveLoadView'
  require 'views/play/menu/OptionsView'
  require 'views/play/menu/GuideView'
  require 'views/play/menu/MultiplayerView'
]

module.exports = class GameMenuModal extends ModalView
  className: 'modal fade play-modal'
  template: template
  id: 'game-menu-modal'
  instant: true

  events:
    'change input.select': 'onSelectionChanged'
    'shown.bs.tab #game-menu-nav a': 'onTabShown'
    'click #change-hero-tab': -> @trigger 'change-hero'
    'click #close-modal': 'hide'
    'click .auth-tab': 'onClickSignupButton'

  constructor: (options) ->
    super options
    @options.showTab = options.showTab
    @options.levelID = @options.level.get('slug')
    @options.startingSessionHeroConfig = $.extend {}, true, (@options.session.get('heroConfig') ? {})
    Backbone.Mediator.publish 'music-player:enter-menu', terrain: @options.level.get('terrain', true) ? 'Dungeon'

  getRenderData: (context={}) ->
    context = super(context)
    docs = @options.level.get('documentation') ? {}
    submenus = ["options", "save-load", "guide", "multiplayer"]
    submenus = _.without submenus, 'guide' unless docs.specificArticles?.length or docs.generalArticles?.length
    submenus = _.without submenus, 'save-load' unless me.isAdmin() or /https?:\/\/localhost/.test(window.location.href)
    submenus = _.without submenus, 'multiplayer' unless me.isAdmin() or @level?.get('type') in ['ladder', 'hero-ladder']
    context.showTab = @options.showTab ? submenus[0]
    context.submenus = submenus
    context.iconMap =
      'options': 'cog'
      'guide': 'list'
      'save-load': 'floppy-disk'
      'multiplayer': 'globe'
    context

  afterRender: ->
    super()
    @insertSubView new submenuView @options for submenuView in submenuViews
    if @options.showTab
      firstView = switch @options.showTab
        when 'multiplayer' then @subviews.multiplayer_view
        when 'guide' then @subviews.guide_view
    unless firstView?
      firstView = (@subviews.options_view)
    firstView.$el.addClass 'active'
    firstView.onShown?()
    @playSound 'game-menu-open'
    @$el.find('.nano:visible').nanoScroller()

  onTabShown: (e) ->
    @playSound 'game-menu-tab-switch'
    shownSubviewKey = e.target.hash.substring(1).replace(/-/g, '_')
    @subviews[shownSubviewKey].onShown?()
    subview.onHidden?() for subviewKey, subview of @subviews when subviewKey isnt shownSubviewKey

  onHidden: ->
    super()
    subview.onHidden?() for subviewKey, subview of @subviews
    @playSound 'game-menu-close'
    Backbone.Mediator.publish 'music-player:exit-menu', {}
    
  onClickSignupButton: (e) ->
    window.tracker?.trackEvent 'Started Signup', category: 'Play Level', label: 'Game Menu', level: @options.levelID
    # TODO: Default already seems to be prevented.  Need to be explicit?
    e.preventDefault()
    @openModalView new AuthModal {mode: 'signup'}
