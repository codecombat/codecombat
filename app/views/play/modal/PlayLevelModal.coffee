ModalView = require 'views/kinds/ModalView'
template = require 'templates/play/modal/play-level-modal'
ChooseHeroView = require 'views/game-menu/ChooseHeroView'
InventoryView = require 'views/game-menu/InventoryView'

module.exports = class PlayLevelModal extends ModalView
  className: 'modal fade play-modal'
  template: template
  modalWidthPercent: 90
  id: 'play-level-modal'
  #instant: true

  #events:
  #  'change input.select': 'onSelectionChanged'

  constructor: (options) ->
    super options
    @options.showDevBits = true

  getRenderData: (context={}) ->
    context = super(context)
    context.levelID = @options.levelID
    context.levelPath = @options.levelPath
    context.levelName = @options.levelName
    context

  afterRender: ->
    super()
    return unless @supermodel.finished()
    Backbone.Mediator.publish 'audio-player:play-sound', trigger: 'game-menu-open', volume: 1
    @addChooseHeroView()
    @addInventoryView()

  onHidden: ->
    super()
    Backbone.Mediator.publish 'audio-player:play-sound', trigger: 'game-menu-close', volume: 1

  addChooseHeroView: ->
    @insertSubView new ChooseHeroView @options

  addInventoryView: ->
    @insertSubView new InventoryView @options
