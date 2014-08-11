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

  events:
    'change input.select': 'onSelectionChanged'

  getRenderData: (context={}) ->
    context = super(context)
    context

  afterRender: ->
    super()
    @insertSubView new submenuView @options for submenuView in submenuViews
    @subviews.inventory_view.$el.addClass 'active'

  onHidden: ->
    subview.onHidden?() for subviewKey, subview of @subviews
    me.patch()
