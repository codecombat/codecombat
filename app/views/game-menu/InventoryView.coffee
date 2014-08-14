CocoView = require 'views/kinds/CocoView'
template = require 'templates/game-menu/inventory-view'
{me} = require 'lib/auth'
ThangType = require 'models/ThangType'
CocoCollection = require 'collections/CocoCollection'
ItemView = require './ItemView'

DEFAULT_EQUIPMENT = {
  'right-hand': '53e21249b82921000051ce11'
  'feet':'53e214f153457600003e3eab'
  'eyes': '53e2167653457600003e3eb3'
  'left-hand': '53e22aa153457600003e3ef5'
}

module.exports = class InventoryView extends CocoView
  id: 'inventory-view'
  className: 'tab-pane'
  template: template
  slots: ["head","eyes","neck","torso","wrists","gloves","left-ring","right-ring","right-hand","left-hand","waist","feet","spellbook","programming-book","pet","minion","misc-0","misc-1","misc-2","misc-3","misc-4"]
  
  events:
    'click .item-slot': 'onItemSlotClick'
    'click #available-equipment .list-group-item': 'onAvailableItemClick'
    'dblclick #available-equipment .list-group-item': 'onAvailableItemDoubleClick'
    'dblclick .item-slot .item-view': 'onEquippedItemDoubleClick'
    
  shortcuts:
    'esc': 'clearSelection'
  
  initialize: (options) ->
    super(arguments...)
    @items = new CocoCollection([], { model: ThangType })
    @equipment = options.equipment or DEFAULT_EQUIPMENT
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
      itemView = new ItemView({item:item, includes:{name:true}})
      itemView.render()
      $(slottedItemStub).replaceWith(itemView.$el)
      @registerSubView(itemView)

    for availableItemEl in @$el.find('#available-equipment .list-group-item')
      itemID = $(availableItemEl).data('item-id')
      item = itemMap[itemID]
      itemView = new ItemView({item:item, includes:{name:true}})
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
    @$el.find('#equipped .panel').removeClass('panel-info')
    @$el.find('#available-equipment .list-group-item').removeClass('active') if slot.hasClass('disabled')
    slot.addClass('panel-info') # unless wasActive
    @onSelectionChanged()
    
  onAvailableItemClick: (e) ->
    itemEl = $(e.target).closest('.list-group-item')
    @$el.find('#available-equipment .list-group-item').removeClass('active')
    itemEl.addClass('active')
    @onSelectionChanged()

  onAvailableItemDoubleClick: ->
    slot = @$el.find('#equipped .item-slot.panel-info')
    slot = $('.panel:not(.disabled):first') if not slot.length
    @unequipItemFromSlot(slot)
    @equipSelectedItemToSlot(slot)
    @onSelectionChanged()
    
  onEquippedItemDoubleClick: (e) ->
    slot = $(e.target).closest('.item-slot')
    @unequipItemFromSlot(slot)
    @onSelectionChanged()
    
  unequipItemFromSlot: (slot) ->
    itemIDToUnequip = slot.find('.item-view').data('item-id')
    return unless itemIDToUnequip
    slot.find('.item-view').detach()
    for el in @$el.find('#available-equipment .list-group-item')
      itemID = $(el).find('.item-view').data('item-id')
      if itemID is itemIDToUnequip
        $(el).removeClass('equipped')

  equipSelectedItemToSlot: (slot) ->
    selectedItemContainer = @$el.find('#available-equipment .list-group-item.active')
    newItemHTML = selectedItemContainer.html()
    @$el.find('#available-equipment .list-group-item.active').addClass('equipped')
    container = slot.find('.panel-body')
    container.html(newItemHTML)
    container.find('.item-view').data('item-id', selectedItemContainer.find('.item-view').data('item-id'))
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
        
        if not @selectedEquippedItemView
          @selectedEquippedItemView = new ItemView({
            item: item, includes: {name: true, stats: true}})
          @insertSubView(@selectedEquippedItemView, @$el.find('#selected-equipped-item .item-view-stub'))
          
        else
          @selectedEquippedItemView.$el.show()
          @selectedEquippedItemView.item = item
          @selectedEquippedItemView.render()
          
      else
        @selectedEquippedItemView?.$el.hide()

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

      # updated selected item view
      if not @selectedAvailableItemView
        @selectedAvailableItemView = new ItemView({
          item: item, includes: {name: true, stats: true}})
        @insertSubView(@selectedAvailableItemView, @$el.find('#selected-available-item .item-view-stub'))
      
      else
        @selectedAvailableItemView.$el.show()
        @selectedAvailableItemView.item = item
        @selectedAvailableItemView.render()
        
    else
      @selectedAvailableItemView?.$el.hide()
    
    @delegateEvents()

  getCurrentEquipmentConfig: ->
    config = {}
    for slot in @$el.find('.item-slot')
      slotName = $(slot).data('slot')
      slotItemID = $(slot).find('.item-view').data('item-id')
      continue unless slotItemID
      item = _.find @items.models, {id:slotItemID}
      config[slotName] = item.get('original')
      
    config 