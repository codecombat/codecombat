ModalView = require 'views/kinds/ModalView'
template = require 'templates/play/modal/play-items-modal'
CocoCollection = require 'collections/CocoCollection'
ThangType = require 'models/ThangType'
ItemView = require 'views/game-menu/ItemView'

module.exports = class PlayItemsModal extends ModalView
  className: 'modal fade play-modal'
  template: template
  modalWidthPercent: 90
  id: 'play-items-modal'
  #instant: true
  slotGroups:
    armor: ['torso', 'head', 'gloves', 'feet']
    hands: ['right-hand', 'left-hand']
    accessories: ['eyes', 'neck', 'left-ring', 'right-ring', 'waist']
    books: ['programming-book', 'spellbook']
    minions: ['minion', 'pet']
    misc: ['misc-0', 'misc-1', 'misc-2', 'misc-3', 'misc-4']

  #events:
  #  'change input.select': 'onSelectionChanged'

  constructor: (options) ->
    super options
    @items = new CocoCollection([], {model: ThangType})
    @items.url = '/db/thang.type?view=items&project=name,description,components,original,rasterIcon'
    @supermodel.loadCollection(@items, 'items')

  groupItems: ->
    groups = {}
    for item in @items.models
      itemSlots = item.getAllowedSlots()
      for group, groupSlots of @slotGroups
        if _.find itemSlots, ((slot) -> slot in groupSlots)
          groups[group] ?= []
          groups[group].push item
    groups

  getRenderData: (context={}) ->
    context = super(context)
    context.slotGroups = @groupItems()
    context.slotGroupsArray = _.keys context.slotGroups
    context.slotGroupsNames = ($.i18n.t "items.#{slotGroup}" for slotGroup in context.slotGroupsArray)
    context

  afterRender: ->
    super()
    return unless @supermodel.finished()
    Backbone.Mediator.publish 'audio-player:play-sound', trigger: 'game-menu-open', volume: 1
    @addItemViews()

  onHidden: ->
    super()
    Backbone.Mediator.publish 'audio-player:play-sound', trigger: 'game-menu-close', volume: 1

  addItemViews: ->
    keys = (item.id for item in @items.models)
    itemMap = _.zipObject keys, @items.models
    for itemStub in @$el.find('.replace-me')
      itemID = $(itemStub).data('item-id')
      item = itemMap[itemID]
      itemView = new ItemView({item: item, includes: {name: true, stats: true, props: true}})
      itemView.render()
      $(itemStub).replaceWith(itemView.$el)
      @registerSubView(itemView)
