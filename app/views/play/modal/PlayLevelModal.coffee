ModalView = require 'views/kinds/ModalView'
template = require 'templates/play/modal/play-level-modal'
ChooseHeroView = require 'views/game-menu/ChooseHeroView'
InventoryView = require 'views/game-menu/InventoryView'

module.exports = class PlayLevelModal extends ModalView
  className: 'modal fade play-modal'
  template: template
  id: 'play-level-modal'

  events:
    'click #choose-inventory-button': 'onClickChooseInventory'
    'click #choose-hero-button': 'onClickChooseHero'
    'click #play-level-button': 'onClickPlayLevel'

  subscriptions:
    'options:hero-changed': 'onHeroChanged'

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
    @insertSubView @chooseHeroView = new ChooseHeroView @options
    @insertSubView @inventoryView = new InventoryView @options
    @inventoryView.$el.addClass 'secret'

  onHidden: ->
    super()
    Backbone.Mediator.publish 'audio-player:play-sound', trigger: 'game-menu-close', volume: 1

  onClickChooseInventory: (e) ->
    @chooseHeroView.$el.add('#choose-inventory-button, #choose-hero-header').addClass 'secret'
    @inventoryView.$el.add('#choose-hero-button, #play-level-button, #choose-inventory-header').removeClass 'secret'

  onClickChooseHero: (e) ->
    @chooseHeroView.$el.add('#choose-inventory-button, #choose-hero-header').removeClass 'secret'
    @inventoryView.$el.add('#choose-hero-button, #play-level-button, #choose-inventory-header').addClass 'secret'

  onClickPlayLevel: (e) ->
    console.log 'should play!'

  onHeroChanged: (e) ->
    @$el.find('#choose-inventory-button').prop 'disabled', Boolean e.locked
    @hero = e.hero
