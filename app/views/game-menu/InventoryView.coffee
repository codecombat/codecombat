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
  slots: ['head', 'eyes', 'neck', 'torso', 'wrists', 'gloves', 'left-ring', 'right-ring', 'right-hand', 'left-hand', 'waist', 'feet', 'programming-book', 'pet', 'minion', 'flag']  #, 'misc-0', 'misc-1']  # TODO: bring in misc slot(s) again when we have space

  events:
    'click .item-slot': 'onItemSlotClick'
    'click #available-equipment .list-group-item:not(.equipped)': 'onAvailableItemClick'
    'dblclick #available-equipment .list-group-item:not(.equipped)': 'onAvailableItemDoubleClick'
    'doubletap #available-equipment .list-group-item:not(.equipped)': 'onAvailableItemDoubleClick'
    'dblclick .item-slot .item-view': 'onEquippedItemDoubleClick'
    'doubletap .item-slot .item-view': 'onEquippedItemDoubleClick'

  subscriptions:
    'level:hero-selection-updated': 'onHeroSelectionUpdated'

  shortcuts:
    'esc': 'clearSelection'

  initialize: (options) ->
    super(arguments...)
    @items = new CocoCollection([], {model: ThangType})
    @equipment = options.equipment or @options.session?.get('heroConfig')?.inventory or me.get('heroConfig')?.inventory or {}
    @equipment = $.extend true, {}, @equipment
    @requireLevelEquipment()
    @items.url = '/db/thang.type?view=items&project=name,components,original,rasterIcon,gems,description,heroClass'
    @supermodel.loadCollection(@items, 'items')

  destroy: ->
    @stage?.removeAllChildren()
    super()

  onLoaded: ->
    item.notInLevel = true for item in @items.models
    super()

  getRenderData: (context={}) ->
    context = super(context)
    context.equipped = _.values(@equipment)
    context.items = @items.models

    for item in @items.models
      item.classes = item.getAllowedSlots()
      item.classes.push 'equipped' if item.get('original') in context.equipped
      locked = @allowedItems and not (item.get('original') in @allowedItems)
      item.classes.push 'locked' if locked and item.get('slug') isnt 'simple-boots'
      for heroClass in item.getAllowedHeroClasses()
        item.classes.push heroClass
      item.classes.push 'silhouette' if item.isSilhouettedItem()

    @items.models.sort (a, b) ->
      lockScore = 90019001 * (('locked' in a.classes) - ('locked' in b.classes))
      gemScore = a.get('gems') - b.get('gems')
      lockScore + gemScore

    context.unlockedItems = []
    context.lockedItems = []
    for item in @items.models
      (if 'locked' in item.classes then context.lockedItems else context.unlockedItems).push item

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
      continue if $(availableItemEl).hasClass 'locked'
      dragHelper = itemView.$el.find('img').clone().addClass('draggable-item')
      do (dragHelper, itemView) =>
        itemView.$el.draggable
          revert: 'invalid'
          appendTo: @$el
          cursorAt: {left: 35.5, top: 35.5}
          helper: -> dragHelper
          revertDuration: 200
          distance: 10
          scroll: false
          zIndex: 100
        itemView.$el.on 'dragstart', =>
          @onAvailableItemClick target: itemView.$el.parent() unless itemView.$el.parent().hasClass 'active'

    for itemSlot in @$el.find '.item-slot'
      slot = $(itemSlot).data 'slot'
      do (slot, itemSlot) =>
        $(itemSlot).droppable
          drop: (e, ui) => @onAvailableItemDoubleClick()
          accept: (el) -> $(el).parent().hasClass slot
          activeClass: 'droppable'
          hoverClass: 'droppable-hover'
          tolerance: 'touch'
        @makeEquippedSlotDraggable $(itemSlot)

    @$el.find('.hero-container').droppable
      drop: (e, ui) => @onAvailableItemDoubleClick()
      accept: (el) -> true
      activeClass: 'droppable'
      hoverClass: 'droppable-hover'
      tolerance: 'pointer'

    @$el.find('#selected-items').hide()  # Hide until one is selected
    @delegateEvents()

    if @selectedHero and not @startedLoadingFirstHero
      @loadHero()
    @requireLevelEquipment()

  afterInsert: ->
    super()
    @canvasWidth = @$el.find('canvas').innerWidth()
    @canvasHeight = @$el.find('canvas').innerHeight()
    @inserted = true

  makeEquippedSlotDraggable: (slot) ->
    unequip = => @unequipItemFromSlot slot
    shouldStayEquippedWhenDropped = (isValidDrop) ->
      pos = $(@).position()
      revert = Math.abs(pos.left) < $(@).outerWidth() and Math.abs(pos.top) < $(@).outerHeight()
      unequip() if not revert
      revert
    # TODO: figure out how to make this actually above the available items list (the .ui-draggable-helper img is still inside .item-view and so underlaps...)
    $(slot).find('img').draggable
      revert: shouldStayEquippedWhenDropped
      appendTo: @$el
      cursorAt: {left: 35.5, top: 35.5}
      revertDuration: 200
      distance: 10
      scroll: false
      zIndex: 100

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
    return if itemContainer.hasClass 'locked'
    wasActive = itemContainer.hasClass 'active'
    @unselectAllAvailableEquipment()
    @selectAvailableItem(itemContainer) unless wasActive
    @onSelectionChanged()

  onAvailableItemDoubleClick: (e) ->
    if e
      itemContainer = $(e.target).closest('.list-group-item')
      return if itemContainer.hasClass 'locked'
      @selectAvailableItem itemContainer
    @onSelectionChanged()
    slot = @getSelectedSlot()
    slot = @$el.find('.item-slot:not(.disabled):first') if not slot.length
    $(e.target).effect('transfer', to: slot, duration: 500, easing: 'easeOutCubic') if e
    @unequipItemFromSlot(slot)
    @equipSelectedItemToSlot(slot)
    @onSelectionChanged()

  onEquippedItemDoubleClick: (e) ->
    @unselectAllAvailableEquipment()
    slot = $(e.target).closest('.item-slot')
    @selectAvailableItem(@unequipItemFromSlot(slot))
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
        unequipped = $(el).removeClass('equipped')
        break
    @requireLevelEquipment() if unequipped
    return unequipped

  equipSelectedItemToSlot: (slot) ->
    selectedItemContainer = @getSelectedAvailableItemContainer()
    newItemHTML = selectedItemContainer.html()
    selectedItemContainer.addClass('equipped')
    slotContainer = slot.find('.item-container')
    slotContainer.html(newItemHTML)
    slotContainer.find('.item-view').data('item-id', selectedItemContainer.find('.item-view').data('item-id'))
    @$el.find('.list-group-item').removeClass('active')
    @makeEquippedSlotDraggable slot
    @requireLevelEquipment()

  onSelectionChanged: ->
    @$el.find('.item-slot').show()

    selectedSlot = @$el.find('.item-slot.selected')
    selectedItem = @$el.find('#available-equipment .list-group-item.active')

    if selectedSlot.length
      @$el.find('#available-equipment .list-group-item').hide()
      unlockedCount = @$el.find("#available-equipment .list-group-item.#{selectedSlot.data('slot')}:not(.locked)").show().length
      lockedCount = @$el.find("#available-equipment .list-group-item.#{selectedSlot.data('slot')}.locked").show().length
      @$el.find('#unlocked-description').text("#{unlockedCount} #{selectedSlot.data('slot')} items owned").toggle unlockedCount > 0
      @$el.find('#locked-description').text("#{lockedCount} #{selectedSlot.data('slot')} items locked").toggle lockedCount > 0
      selectedSlotItemID = selectedSlot.find('.item-view').data('item-id')
      if selectedSlotItemID
        item = _.find @items.models, {id: selectedSlotItemID}
        @showSelectedSlotItem(item)
      else
        @hideSelectedSlotItem()
    else
      unlockedCount = @$el.find('#available-equipment .list-group-item:not(.locked)').show().length
      @$el.find('#available-equipment .list-group-item.locked').hide()
      @$el.find('#unlocked-description').text("#{unlockedCount} items owned").toggle unlockedCount > 0
      @$el.find('#locked-description').text("#{lockedCount} items locked").hide()
    #@$el.find('#available-equipment .list-group-item.equipped').hide()

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
    @$el.find('#selected-equipped-item').show()

  hideSelectedSlotItem: ->
    @selectedEquippedItemView?.$el.hide().parent().hide()
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
    @$el.find('#selected-available-item').show()

  hideSelectedAvailableItem: ->
    @selectedAvailableItemView?.$el.hide().parent().hide()
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

  requireLevelEquipment: ->
    # This is temporary, until we have a more general way of awarding items and configuring needed/locked items per level.
    gear =
      'simple-boots': '53e237bf53457600003e3f05'
      'simple-sword': '53e218d853457600003e3ebe'
      'leather-tunic': '53e22eac53457600003e3efc'
      'leather-boots': '53e2384453457600003e3f07'
      'programmaticon-i': '53e4108204c00d4607a89f78'
      'crude-wooden-glasses': '53e238df53457600003e3f0b'
      'builders-hammer': '53f4e6e3d822c23505b74f42'
    gearByLevel =
      'dungeons-of-kithgard': {feet: 'simple-boots'}
      'gems-in-the-deep': {feet: 'simple-boots'}
      'forgetful-gemsmith': {feet: 'simple-boots'}
      'shadow-guard': {feet: 'simple-boots'}
      'true-names': {feet: 'simple-boots', 'right-hand': 'simple-sword'}
      'the-raised-sword': {feet: 'simple-boots', 'right-hand': 'simple-sword', torso: 'leather-tunic'}
      'the-first-kithmaze': {feet: 'simple-boots', 'programming-book': 'programmaticon-i'}
      'the-second-kithmaze': {feet: 'simple-boots', 'programming-book': 'programmaticon-i'}
      'new-sight': {'right-hand': 'simple-sword', 'programming-book': 'programmaticon-i'}
      'lowly-kithmen': {feet: 'simple-boots', 'right-hand': 'simple-sword', 'programming-book': 'programmaticon-i', eyes: 'crude-wooden-glasses'}
      'closing-the-distance': {feet: 'simple-boots', 'right-hand': 'simple-sword', torso: 'leather-tunic', eyes: 'crude-wooden-glasses'}
      'the-final-kithmaze': {feet: 'simple-boots', 'right-hand': 'simple-sword', torso: 'leather-tunic', 'programming-book': 'programmaticon-i', eyes: 'crude-wooden-glasses'}
      'kithgard-gates': {feet: 'simple-boots', 'right-hand': 'builders-hammer', torso: 'leather-tunic'}
      'defense-of-plainswood': {feet: 'simple-boots', 'right-hand': 'builders-hammer'}
      'winding-trail': {feet: 'leather-boots', 'right-hand': 'builders-hammer'}
      'thornbush-farm': {feet: 'leather-boots', 'right-hand': 'builders-hammer', eyes: 'crude-wooden-glasses'}
      'a-fiery-trap': {feet: 'leather-boots', 'right-hand': 'builders-hammer', eyes: 'crude-wooden-glasses'}
    return unless necessaryGear = gearByLevel[@options.levelID]
    if @inserted
      if @supermodel.finished()
        equipment = @getCurrentEquipmentConfig()  # Make sure @equipment is updated
      else
        equipment = @equipment
      hadRequired = @remainingRequiredEquipment?.length
      @remainingRequiredEquipment = []
      @$el.find('.should-equip').removeClass('should-equip')
      inWorldMap = $('#world-map-view').length
      for slot, item of necessaryGear
        continue if item is 'leather-tunic' and inWorldMap  # Don't tell them they need it until they need it in the level
        continue if equipment[slot] and not ((item is 'builders-hammer' and equipment[slot] is gear['simple-sword']) or (item is 'leather-boots' and equipment[slot] is gear['simple-boots']))
        availableSlotSelector = "#available-equipment li[data-item-id='#{gear[item]}']"
        @highlightElement availableSlotSelector, delay: 500, sides: ['right'], rotation: Math.PI / 2
        @$el.find(availableSlotSelector).addClass 'should-equip'
        @$el.find("#equipped div[data-slot='#{slot}']").addClass 'should-equip'
        @remainingRequiredEquipment.push slot: slot, item: gear[item]
      if hadRequired and not @remainingRequiredEquipment.length
        @endHighlight()
        @highlightElement (if inWorldMap then '#play-level-button' else '.overlaid-close-button'), duration: 5000
      $('#play-level-button').prop('disabled', @remainingRequiredEquipment.length > 0)

    # Restrict available items to those that would be available by this item.
    @allowedItems = []
    for level, items of gearByLevel
      for slot, item of items
        @allowedItems.push gear[item] unless gear[item] in @allowedItems
      break if level is @options.levelID
    for item in me.get('earned')?.items ? [] when not (item in @allowedItems)
      @allowedItems.push item

  onHeroSelectionUpdated: (e) ->
    @selectedHero = e.hero
    @loadHero()
    @$el.removeClass('Warrior Ranger Wizard').addClass(@selectedHero.get('heroClass'))

  loadHero: ->
    return unless @supermodel.finished() and @selectedHero and not @$el.hasClass 'secret'
    @startedLoadingFirstHero = true
    @stage?.removeAllChildren()
    if featureImage = @selectedHero.get 'featureImage'
      @$el.find(".equipped-hero-canvas").hide()
      @$el.find(".hero-feature-image").show().find('img').prop('src', '/file/' + featureImage)
      return
    if @selectedHero.loaded and movieClip = @movieClips?[@selectedHero.get('original')]
      @stage.addChild(movieClip)
      @stage.update()
      return
    onLoaded = =>
      return unless canvas = @$el.find(".equipped-hero-canvas")
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
    @requireLevelEquipment()
    @loadHero()

  onHidden: ->
    # Called when the modal itself is dismissed
    @endHighlight()
