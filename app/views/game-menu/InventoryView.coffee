CocoView = require 'views/kinds/CocoView'
template = require 'templates/game-menu/inventory-view'
{me} = require 'lib/auth'
ThangType = require 'models/ThangType'
CocoCollection = require 'collections/CocoCollection'
ItemView = require './ItemView'

module.exports = class InventoryView extends CocoView
  id: 'inventory-view'
  className: 'tab-pane'
  template: template
  slots: ['head', 'eyes', 'neck', 'torso', 'wrists', 'gloves', 'left-ring', 'right-ring', 'right-hand', 'left-hand', 'waist', 'feet', 'spellbook', 'programming-book', 'pet', 'minion', 'misc-0', 'misc-1', 'misc-2', 'misc-3', 'misc-4']

  events:
    'click .item-slot': 'onItemSlotClick'
    'click #available-equipment .list-group-item': 'onAvailableItemClick'
    'dblclick #available-equipment .list-group-item': 'onAvailableItemDoubleClick'
    'dblclick .item-slot .item-view': 'onEquippedItemDoubleClick'
    'click #swap-button': 'onClickSwapButton'

  shortcuts:
    'esc': 'clearSelection'

  initialize: (options) ->
    super(arguments...)
    @items = new CocoCollection([], {model: ThangType})
    @equipment = options.equipment or @options.session?.get('heroConfig')?.inventory or {}
    @items.url = '/db/thang.type?view=items&project=name,description,components,original'
    @supermodel.loadCollection(@items, 'items')

  onLoaded: ->
    super()

  getRenderData: (context={}) ->
    context = super(context)
    context.equipped = _.values(@equipment)
    context.items = @items.models

    for item in @items.models
      item.classes = item.getAllowedSlots()
      item.classes.push 'equipped' if item.get('original') in context.equipped

    context.slots = @slots
    context.equipment = _.clone @equipment
    for slot, itemOriginal of context.equipment
      item = _.find @items.models, (item) -> item.get('original') is itemOriginal
      context.equipment[slot] = item
    context

  afterRender: ->
    super()
    return unless @supermodel.finished()

    keys = (item.id for item in @items.models)
    itemMap = _.zipObject keys, @items.models

    # Fill in equipped items
    for slottedItemStub in @$el.find('.replace-me')
      itemID = $(slottedItemStub).data('item-id')
      item = itemMap[itemID]
      itemView = new ItemView({item: item, includes: {name: true}})
      itemView.render()
      $(slottedItemStub).replaceWith(itemView.$el)
      @registerSubView(itemView)

    for availableItemEl in @$el.find('#available-equipment .list-group-item')
      itemID = $(availableItemEl).data('item-id')
      item = itemMap[itemID]
      itemView = new ItemView({item: item, includes: {name: true}})
      itemView.render()
      $(availableItemEl).append(itemView.$el)
      @registerSubView(itemView)

    @delegateEvents()

  clearSelection: ->
    @$el.find('.panel-info').removeClass('panel-info')
    @$el.find('.list-group-item').removeClass('active')
    @onSelectionChanged()

  onItemSlotClick: (e) ->
    slot = $(e.target).closest('.panel')
    wasActive = slot.hasClass('panel-info')
    @unselectAllSlots()
    @unselectAllAvailableEquipment() if slot.hasClass('disabled')
    @selectSlot(slot) unless wasActive and not $(e.target).closest('.item-view')[0]
    @onSelectionChanged()

  onAvailableItemClick: (e) ->
    itemContainer = $(e.target).closest('.list-group-item')
    @unselectAllAvailableEquipment()
    @selectAvailableItem(itemContainer)
    @onSelectionChanged()

  onAvailableItemDoubleClick: (e) ->
    slot = @getSelectedSlot()
    slot = @$el.find('.panel:not(.disabled):first') if not slot.length
    @unequipItemFromSlot(slot)
    @equipSelectedItemToSlot(slot)
    @onSelectionChanged()

  onEquippedItemDoubleClick: (e) ->
    @unselectAllAvailableEquipment()
    slot = $(e.target).closest('.item-slot')
    @selectAvailableItem(@unequipItemFromSlot(slot))
    @onSelectionChanged()

  onClickSwapButton: ->
    slot = @getSelectedSlot()
    selectedItemContainer = @$el.find('#available-equipment .list-group-item.active')
    return unless slot[0] or selectedItemContainer[0]
    slot = @$el.find('.panel:not(.disabled):first') if not slot.length
    itemContainer = @unequipItemFromSlot(slot)
    @equipSelectedItemToSlot(slot)
    @selectAvailableItem(itemContainer)
    @selectSlot(slot)
    @onSelectionChanged()

  getSelectedSlot: ->
    @$el.find('#equipped .item-slot.panel-info')

  unselectAllAvailableEquipment: ->
    @$el.find('#available-equipment .list-group-item').removeClass('active')

  unselectAllSlots: ->
    @$el.find('#equipped .panel').removeClass('panel-info')

  selectSlot: (slot) ->
    slot.addClass('panel-info')

  getSlot: (name) ->
    @$el.find(".item-slot[data-slot=#{name}]")

  getSelectedAvailableItemContainer: ->
    @$el.find('#available-equipment .list-group-item.active')

  getAvailableItemContainer: (itemID) ->
    @$el.find("#available-equipment .list-group-item[data-item-id='#{itemID}']")

  selectAvailableItem: (itemContainer) ->
    itemContainer?.addClass('active')

  unequipItemFromSlot: (slot) ->
    itemIDToUnequip = slot.find('.item-view').data('item-id')
    return unless itemIDToUnequip
    slot.find('.item-view').detach()
    for el in @$el.find('#available-equipment .list-group-item')
      itemID = $(el).find('.item-view').data('item-id')
      if itemID is itemIDToUnequip
        return $(el).removeClass('equipped')

  equipSelectedItemToSlot: (slot) ->
    selectedItemContainer = @getSelectedAvailableItemContainer()
    newItemHTML = selectedItemContainer.html()
    selectedItemContainer .addClass('equipped')
    slotContainer = slot.find('.panel-body')
    slotContainer.html(newItemHTML)
    slotContainer.find('.item-view').data('item-id', selectedItemContainer.find('.item-view').data('item-id'))
    @$el.find('.list-group-item').removeClass('active')

  onSelectionChanged: ->
    @$el.find('.item-slot').show()

    selectedSlot = @$el.find('.panel.panel-info')
    selectedItem = @$el.find('#available-equipment .list-group-item.active')

    if selectedSlot.length
      @$el.find('#available-equipment .list-group-item').hide()
      @$el.find("#available-equipment .list-group-item.#{selectedSlot.data('slot')}").show()

      selectedSlotItemID = selectedSlot.find('.item-view').data('item-id')
      if selectedSlotItemID
        item = _.find @items.models, {id:selectedSlotItemID}
        @showSelectedSlotItem(item)

      else
        @hideSelectedSlotItem()

    else
      @$el.find('#available-equipment .list-group-item').show()
    @$el.find('#available-equipment .list-group-item.equipped').hide()

    @$el.find('.item-slot').removeClass('disabled')
    if selectedItem.length
      item = _.find @items.models, {id:selectedItem.find('.item-view').data('item-id')}

      # update which slots are enabled
      allowedSlots = item.getAllowedSlots()
      for slotEl in @$el.find('.item-slot')
        slotName = $(slotEl).data('slot')
        if slotName not in allowedSlots
          $(slotEl).addClass('disabled')

      @showSelectedAvailableItem(item)

    else
      @hideSelectedAvailableItem()

    @delegateEvents()

  showSelectedSlotItem: (item) ->
    if not @selectedEquippedItemView
      @selectedEquippedItemView = new ItemView({
        item: item, includes: {name: true, stats: true}})
      @insertSubView(@selectedEquippedItemView, @$el.find('#selected-equipped-item .item-view-stub'))

    else
      @selectedEquippedItemView.$el.show()
      @selectedEquippedItemView.item = item
      @selectedEquippedItemView.render()

  hideSelectedSlotItem: ->
    @selectedEquippedItemView?.$el.hide()

  showSelectedAvailableItem: (item) ->
    if not @selectedAvailableItemView
      @selectedAvailableItemView = new ItemView({
        item: item, includes: {name: true, stats: true}})
      @insertSubView(@selectedAvailableItemView, @$el.find('#selected-available-item .item-view-stub'))

    else
      @selectedAvailableItemView.$el.show()
      @selectedAvailableItemView.item = item
      @selectedAvailableItemView.render()

  hideSelectedAvailableItem: ->
    @selectedAvailableItemView?.$el.hide()

  getCurrentEquipmentConfig: ->
    config = {}
    for slot in @$el.find('.item-slot')
      slotName = $(slot).data('slot')
      slotItemID = $(slot).find('.item-view').data('item-id')
      continue unless slotItemID
      item = _.find @items.models, {id:slotItemID}
      config[slotName] = item.get('original')

    config

  onHidden: ->
    inventory = @getCurrentEquipmentConfig()
    heroConfig = @options.session.get('heroConfig') ? {}
    unless _.isEqual inventory, heroConfig.inventory
      heroConfig.inventory = inventory
      heroConfig.thangType ?= '529ffbf1cf1818f2be000001'  # Temp: assign Tharin as the hero
      @options.session.set 'heroConfig', heroConfig
      @options.session.patch()
