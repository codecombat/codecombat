ModalView = require 'views/core/ModalView'
CreateAccountModal = require 'views/core/CreateAccountModal'
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
    @level = @options.level
    @options.levelID = @options.level.get('slug')
    @options.startingSessionHeroConfig = $.extend {}, true, (@options.session.get('heroConfig') ? {})
    Backbone.Mediator.publish 'music-player:enter-menu', terrain: @options.level.get('terrain', true) ? 'Dungeon'

  getRenderData: (context={}) ->
    context = super(context)
    docs = @options.level.get('documentation') ? {}
    submenus = ['guide', 'options', 'save-load', 'multiplayer']
    submenus = _.without submenus, 'options' if window.serverConfig.picoCTF
    submenus = _.without submenus, 'guide' unless docs.specificArticles?.length or docs.generalArticles?.length or window.serverConfig.picoCTF
    submenus = _.without submenus, 'save-load' unless me.isAdmin() or /https?:\/\/localhost/.test(window.location.href)
    submenus = _.without submenus, 'multiplayer' unless me.isAdmin() or (@level?.get('type') in ['ladder', 'hero-ladder', 'course-ladder'] and @level.get('slug') not in ['ace-of-coders', 'elemental-wars'])
    @includedSubmenus = submenus
    context.showTab = @options.showTab ? submenus[0]
    context.submenus = submenus
    context.iconMap =
      'options': 'cog'
      'guide': 'list'
      'save-load': 'floppy-disk'
      'multiplayer': 'globe'
    context

  showsChooseHero: ->
    return false if @level?.get('type') in ['course', 'course-ladder']
    return false if @options.levelID in ['zero-sum', 'ace-of-coders', 'elemental-wars']
    return true

  afterRender: ->
    super()
    @insertSubView new submenuView @options for submenuView in submenuViews
    firstView = switch @options.showTab
      when 'multiplayer' then @subviews.multiplayer_view
      when 'guide' then @subviews.guide_view
      else
        if 'guide' in @includedSubmenus then @subviews.guide_view else @subviews.options_view
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
    @openModalView new CreateAccountModal()
