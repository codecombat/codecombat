require('app/styles/play/menu/game-menu-modal.sass')
ModalView = require 'views/core/ModalView'
CreateAccountModal = require 'views/core/CreateAccountModal'
template = require 'templates/play/menu/game-menu-modal'
submenuViews = [
  require 'views/play/menu/SaveLoadView'
  require 'views/play/menu/OptionsView'
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
    'click [data-toggle="coco-modal"][data-target="core/CreateAccountModal"]': 'openCreateAccountModal'

  constructor: (options) ->
    super options
    @level = @options.level
    @options.levelID = @options.level.get('slug')
    @options.startingSessionHeroConfig = $.extend {}, true, (@options.session.get('heroConfig') ? {})
    Backbone.Mediator.publish 'music-player:enter-menu', terrain: @options.level.get('terrain', true) ? 'Dungeon'

  getRenderData: (context={}) ->
    context = super(context)
    docs = @options.level.get('documentation') ? {}
    submenus = ['options', 'save-load']
    submenus = _.without submenus, 'options' if window.serverConfig.picoCTF
    submenus = _.without submenus, 'save-load' unless me.isAdmin() or /https?:\/\/localhost/.test(window.location.href)
    @includedSubmenus = submenus
    context.showTab = @options.showTab ? submenus[0]
    context.submenus = submenus
    context.iconMap =
      'options': 'cog'
      'save-load': 'floppy-disk'
    context

  showsChooseHero: ->
    return false if @level?.isType('course', 'course-ladder', 'game-dev', 'web-dev')
    return false if @level?.get('assessment') is 'open-ended'
    return false if @level?.usesConfiguredMultiplayerHero()
    return true

  afterRender: ->
    super()
    @insertSubView new submenuView @options for submenuView in submenuViews
    firstView = @subviews.options_view
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

  openCreateAccountModal: (e) ->
    e.stopPropagation()
    @openModalView new CreateAccountModal()

  onClickSignupButton: (e) ->
    window.tracker?.trackEvent 'Started Signup', category: 'Play Level', label: 'Game Menu', level: @options.levelID
    # TODO: Default already seems to be prevented.  Need to be explicit?
    e.preventDefault()
    @openModalView new CreateAccountModal()
