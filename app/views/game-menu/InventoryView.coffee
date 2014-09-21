CocoView = require 'views/kinds/CocoView'
template = require 'templates/game-menu/inventory-view'
{me} = require 'lib/auth'
ThangType = require 'models/ThangType'
CocoCollection = require 'collections/CocoCollection'
ItemView = require './ItemView'
SpriteBuilder = require 'lib/sprites/SpriteBuilder'

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

  subscriptions:
    'level:hero-selection-updated': 'onHeroSelectionUpdated'

  shortcuts:
    'esc': 'clearSelection'

  initialize: (options) ->
    super(arguments...)
    @items = new CocoCollection([], {model: ThangType})
    @equipment = options.equipment or @options.session?.get('heroConfig')?.inventory or me.get('heroConfig')?.inventory or {}
    @assignLevelEquipment()
    @items.url = '/db/thang.type?view=items&project=name,components,original,rasterIcon'
    @supermodel.loadCollection(@items, 'items')

  destroy: ->
    @stage?.removeAllChildren()
    super()

  onLoaded: ->
    @items.models = _.filter(@items.models, (item) => item.get('original') in @allowedItems) if @allowedItems
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

    keys = (item.get('original') for item in @items.models)
    itemMap = _.zipObject keys, @items.models

    # Fill in equipped items
    for slottedItemStub in @$el.find('.replace-me')
      itemID = $(slottedItemStub).data('item-id')
      item = itemMap[itemID]
      itemView = new ItemView({item: item, includes: {}})
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
      dragHelper = itemView.$el.find('img').clone().addClass('draggable-item')
      do (dragHelper, itemView) =>
        itemView.$el.draggable
          revert: 'invalid'
          appendTo: @$el
          cursorAt: {left: 35.5, top: 35.5}
          helper: -> dragHelper
          revertDuration: 200
          scroll: false
          zIndex: 100
        itemView.$el.on 'dragstart', =>
          @onAvailableItemClick target: itemView.$el.parent() unless itemView.$el.parent().hasClass 'active'

    for itemSlot in @$el.find '.item-slot'
      slot = $(itemSlot).data 'slot'
      $(itemSlot).find('.placeholder').css('background-image', "url(/images/pages/game-menu/slot-#{slot}.png)")
      do (slot) =>
        $(itemSlot).droppable
          drop: (e, ui) => @onAvailableItemDoubleClick()
          accept: (el) -> $(el).parent().hasClass slot
          activeClass: 'droppable'
          hoverClass: 'droppable-hover'
          tolerance: 'touch'

    @$el.find('#selected-items').hide()  # Hide until one is selected
    @delegateEvents()

  afterInsert: ->
    super()
    @canvasWidth = @$el.find('canvas').innerWidth()
    @canvasHeight = @$el.find('canvas').innerHeight()

  clearSelection: ->
    @$el.find('.item-slot.selected').removeClass 'selected'
    @$el.find('.list-group-item').removeClass('active')
    @onSelectionChanged()

  onItemSlotClick: (e) ->
    slot = $(e.target).closest('.item-slot')
    wasActive = slot.hasClass('selected')
    @unselectAllSlots()
    @unselectAllAvailableEquipment() if slot.hasClass('disabled')
    if wasActive
      @hideSelectedSlotItem()
      @unselectAllAvailableEquipment()
    else
      @selectSlot(slot)
    @onSelectionChanged()

  onAvailableItemClick: (e) ->
    itemContainer = $(e.target).closest('.list-group-item')
    wasActive = itemContainer.hasClass 'active'
    @unselectAllAvailableEquipment()
    @selectAvailableItem(itemContainer) unless wasActive
    @onSelectionChanged()

  onAvailableItemDoubleClick: (e) ->
    slot = @getSelectedSlot()
    slot = @$el.find('.item-slot:not(.disabled):first') if not slot.length
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
    slot = @$el.find('.item-slot:not(.disabled):first') if not slot.length
    itemContainer = @unequipItemFromSlot(slot)
    @equipSelectedItemToSlot(slot)
    @selectAvailableItem(itemContainer)
    @selectSlot(slot)
    @onSelectionChanged()

  getSelectedSlot: ->
    @$el.find('#equipped .item-slot.selected')

  unselectAllAvailableEquipment: ->
    @$el.find('#available-equipment .list-group-item').removeClass('active')

  unselectAllSlots: ->
    @$el.find('#equipped .item-slot.selected').removeClass('selected')

  selectSlot: (slot) ->
    slot.addClass('selected')

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
    selectedItemContainer.addClass('equipped')
    slotContainer = slot.find('.item-container')
    slotContainer.html(newItemHTML)
    slotContainer.find('.item-view').data('item-id', selectedItemContainer.find('.item-view').data('item-id'))
    @$el.find('.list-group-item').removeClass('active')

  onSelectionChanged: ->
    @$el.find('.item-slot').show()

    selectedSlot = @$el.find('.item-slot.selected')
    selectedItem = @$el.find('#available-equipment .list-group-item.active')

    if selectedSlot.length
      @$el.find('#available-equipment .list-group-item').hide()
      count = @$el.find("#available-equipment .list-group-item.#{selectedSlot.data('slot')}").show().length
      @$el.find('#stash-description').text "#{count} #{selectedSlot.data('slot')} items owned"

      selectedSlotItemID = selectedSlot.find('.item-view').data('item-id')
      if selectedSlotItemID
        item = _.find @items.models, {id:selectedSlotItemID}
        @showSelectedSlotItem(item)

      else
        @hideSelectedSlotItem()

    else
      count = @$el.find('#available-equipment .list-group-item').show().length
      @$el.find('#stash-description').text "#{count} items owned"
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
        item: item, includes: {name: true, stats: true, props: true}})
      @insertSubView(@selectedEquippedItemView, @$el.find('#selected-equipped-item .item-view-stub'))
    else
      @selectedEquippedItemView.$el.show()
      @selectedEquippedItemView.item = item
      @selectedEquippedItemView.render()
    @$el.find('#selected-items').show()

  hideSelectedSlotItem: ->
    @selectedEquippedItemView?.$el.hide()
    @$el.find('#selected-items').hide() unless @selectedEquippedItemView?.$el?.is(':visible')

  showSelectedAvailableItem: (item) ->
    if not @selectedAvailableItemView
      @selectedAvailableItemView = new ItemView({
        item: item, includes: {name: true, stats: true, props: true}})
      @insertSubView(@selectedAvailableItemView, @$el.find('#selected-available-item .item-view-stub'))
    else
      @selectedAvailableItemView.$el.show()
      @selectedAvailableItemView.item = item
      @selectedAvailableItemView.render()
    @$el.find('#selected-items').show()

  hideSelectedAvailableItem: ->
    @selectedAvailableItemView?.$el.hide()
    @$el.find('#selected-items').hide() unless @selectedEquippedItemView?.$el?.is(':visible')

  getCurrentEquipmentConfig: ->
    config = {}
    for slot in @$el.find('.item-slot')
      slotName = $(slot).data('slot')
      slotItemID = $(slot).find('.item-view').data('item-id')
      continue unless slotItemID
      item = _.find @items.models, {id:slotItemID}
      config[slotName] = item.get('original')
    config

  assignLevelEquipment: ->
    # This is temporary, until we have a more general way of awarding items and configuring needed/restricted items per level.
    gear =
      'simple-boots': '53e237bf53457600003e3f05'
      'longsword': '53e218d853457600003e3ebe'
      'leather-tunic': '53e22eac53457600003e3efc'
      'programmaticon-i': '53e4108204c00d4607a89f78'
      'crude-glasses': '53e238df53457600003e3f0b'
      'builders-hammer': '53f4e6e3d822c23505b74f42'
    gearByLevel =
      'dungeons-of-kithgard': {feet: 'simple-boots'}
      'gems-in-the-deep': {feet: 'simple-boots'}
      'shadow-guard': {feet: 'simple-boots'}
      'true-names': {feet: 'simple-boots', 'right-hand': 'longsword'}
      'the-raised-sword': {feet: 'simple-boots', 'right-hand': 'longsword', torso: 'leather-tunic'}
      'the-first-kithmaze': {feet: 'simple-boots', 'right-hand': 'longsword', torso: 'leather-tunic', 'programming-book': 'programmaticon-i'}
      'the-second-kithmaze': {feet: 'simple-boots', 'right-hand': 'longsword', torso: 'leather-tunic', 'programming-book': 'programmaticon-i'}
      'new-sight': {feet: 'simple-boots', 'right-hand': 'longsword', torso: 'leather-tunic', 'programming-book': 'programmaticon-i'}
      'lowly-kithmen': {feet: 'simple-boots', 'right-hand': 'longsword', torso: 'leather-tunic', 'programming-book': 'programmaticon-i', eyes: 'crude-glasses'}
      'a-bolt-in-the-dark': {feet: 'simple-boots', 'right-hand': 'longsword', torso: 'leather-tunic', 'programming-book': 'programmaticon-i', eyes: 'crude-glasses'}
      'the-final-kithmaze': {feet: 'simple-boots', 'right-hand': 'longsword', torso: 'leather-tunic', 'programming-book': 'programmaticon-i', eyes: 'crude-glasses'}
      'kithgard-gates': {feet: 'simple-boots', 'right-hand': 'builders-hammer', torso: 'leather-tunic', 'programming-book': 'programmaticon-i', eyes: 'crude-glasses'}
      'defence-of-plainswood': {feet: 'simple-boots', 'right-hand': 'builders-hammer', torso: 'leather-tunic', 'programming-book': 'programmaticon-i', eyes: 'crude-glasses'}
    necessaryGear = gearByLevel[@options.levelID]
    for slot, item of necessaryGear ? {}
      @equipment[slot] ?= gear[item]
    @allowedItems = _.values gear if necessaryGear  # If it's one of these levels, don't show the extra items.

  onHeroSelectionUpdated: (e) ->
    @selectedHero = e.hero
    @loadHero()

  loadHero: ->
    return unless @selectedHero and not @$el.hasClass 'secret'
    @stage?.removeAllChildren()
    if @selectedHero.loaded and movieClip = @movieClips?[@selectedHero.get('original')]
      @stage.addChild(movieClip)
      @stage.update()
      return
    onLoaded = =>
      return unless canvas = $(".equipped-hero-canvas")
      @canvasWidth ||= canvas.width()
      @canvasHeight ||= canvas.height()
      canvas.prop width: @canvasWidth, height: @canvasHeight
      builder = new SpriteBuilder(@selectedHero)
      movieClip = builder.buildMovieClip(@selectedHero.get('actions').attack?.animation ? @selectedHero.get('actions').idle.animation)
      movieClip.scaleX = movieClip.scaleY = canvas.prop('height') / 120  # Average hero height is ~110px at normal resolution
      if @selectedHero.get('name') in ['Knight', 'Robot Walker']  # These are too big, so shrink them.
        movieClip.scaleX *= 0.7
        movieClip.scaleY *= 0.7
      movieClip.regX = -@selectedHero.get('positions').registration.x
      movieClip.regY = -@selectedHero.get('positions').registration.y
      movieClip.x = canvas.prop('width') * 0.5
      movieClip.y = canvas.prop('height') * 0.95  # This is where the feet go.
      movieClip.gotoAndPlay 0
      @stage ?= new createjs.Stage(canvas[0])
      @stage.addChild movieClip
      @stage.update()
      @movieClips ?= {}
      @movieClips[@selectedHero.get('original')] = movieClip
    if @selectedHero.loaded
      if @selectedHero.isFullyLoaded()
        _.defer onLoaded
      else
        console.error 'Hmm, trying to render a hero we have not loaded...?', @selectedHero
    else
      @listenToOnce @selectedHero, 'sync', onLoaded

  onShown: ->
    # Called when we switch tabs to this within the modal
    @loadHero()

  onHidden: ->
    # Called when the modal itself is dismissed
