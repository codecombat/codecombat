require('ozaria/site/styles/play/menu/game-menu-modal.sass')
ModalView = require 'views/core/ModalView'
template = require 'app/templates/play/menu/game-menu-modal'
OptionsView = require 'ozaria/site/views/play/menu/OptionsView'

module.exports = class GameMenuModal extends ModalView
  className: 'modal fade play-modal'
  template: template
  id: 'game-menu-modal'
  instant: true

  events:
    'click .done-button': 'hide'

  constructor: (options) ->
    super options
    @level = @options.level
    @options.levelID = @options.level.get('slug')
    @options.startingSessionHeroConfig = $.extend {}, true, (@options.session.get('heroConfig') ? {})
    Backbone.Mediator.publish 'music-player:enter-menu', terrain: @options.level.get('terrain', true) ? 'Dungeon'

  afterRender: ->
    super()
    @insertSubView new OptionsView @options
    firstView = @subviews.options_view
    firstView.$el.addClass 'active'
    firstView.onShown?()
    @playSound 'game-menu-open'
    @$el.find('.nano:visible').nanoScroller()

  onHidden: ->
    super()
    subview.onHidden?() for subviewKey, subview of @subviews
    @playSound 'game-menu-close'
    Backbone.Mediator.publish 'music-player:exit-menu', {}
