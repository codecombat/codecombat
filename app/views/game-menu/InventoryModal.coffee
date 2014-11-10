ModalView = require 'views/kinds/ModalView'
template = require 'templates/game-menu/inventory-modal'
{me} = require 'lib/auth'
ThangType = require 'models/ThangType'
CocoCollection = require 'collections/CocoCollection'
ItemView = require './ItemView'
SpriteBuilder = require 'lib/sprites/SpriteBuilder'
LevelOptions = require 'lib/LevelOptions'

hasGoneFullScreenOnce = false

module.exports = class InventoryModal extends ModalView
  id: 'inventory-modal'
  className: 'modal fade play-modal'
  template: template
  slots: ['head', 'eyes', 'neck', 'torso', 'wrists', 'gloves', 'left-ring', 'right-ring', 'right-hand', 'left-hand', 'waist', 'feet', 'programming-book', 'pet', 'minion', 'flag']  #, 'misc-0', 'misc-1']  # TODO: bring in misc slot(s) again when we have space

  events:
    'click .item-slot': 'onItemSlotClick'
    'click #available-equipment .list-group-item:not(.equipped)': 'onAvailableItemClick'
    'dblclick #available-equipment .list-group-item:not(.equipped)': 'onAvailableItemDoubleClick'
    'doubletap #available-equipment .list-group-item:not(.equipped)': 'onAvailableItemDoubleClick'
    'dblclick .item-slot .item-view': 'onEquippedItemDoubleClick'
    'doubletap .item-slot .item-view': 'onEquippedItemDoubleClick'
    'shown.bs.modal': 'onShown'
    'click #choose-hero-button': 'onClickChooseHero'
    'click #play-level-button': 'onClickPlayLevel'

  shortcuts:
    'esc': 'clearSelection'
    'enter': 'onClickPlayLevel'

  initialize: (options) ->
    super(arguments...)
    @items = new CocoCollection([], {model: ThangType})
    @items.url = '/db/thang.type?view=items&project=name,slug,components,original,rasterIcon,gems,description,heroClass'
    @supermodel.loadCollection(@items, 'items')
    @equipment = {}  # Assign for real when we have loaded the session

  destroy: ->
    @stage?.removeAllChildren()
    super()

  onLoaded: ->
    item.notInLevel = true for item in @items.models
    @equipment = @options.equipment or @options.session?.get('heroConfig')?.inventory or me.get('heroConfig')?.inventory or {}
    @equipment = $.extend true, {}, @equipment
    @requireLevelEquipment()
    super()

  getRenderData: (context={}) ->
    context = super(context)
    context.equipped = _.values(@equipment)
    context.items = @items.models

    for item in @items.models
      item.classes = item.getAllowedSlots()
      item.classes.push 'equipped' if item.get('original') in context.equipped
      locked = not (item.get('original') in me.items())
      item.classes.push 'locked' if locked and item.get('slug') isnt 'simple-boots'
      for heroClass in item.getAllowedHeroClasses()
        item.classes.push heroClass
      item.classes.push 'silhouette' if item.isSilhouettedItem()
      item.classes.push 'restricted' if item.get('slug') in _.values(LevelOptions[@options.levelID]?.restrictedGear ? {})

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
    @$el.find('.modal-footer button').css('visibility', 'hidden')
    return unless @supermodel.finished()
    @$el.find('.modal-footer button').css('visibility', 'visible')

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
      continue if $(availableItemEl).hasClass('locked') or $(availableItemEl).hasClass('restricted')
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
          zIndex: 10000
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
      zIndex: 10000

  clearSelection: ->
    @$el.find('.item-slot.selected').removeClass 'selected'
    @$el.find('.list-group-item').removeClass('active')
    @onSelectionChanged()

  onItemSlotClick: (e) ->
    return if @remainingRequiredEquipment?.length  # Don't let them select a slot if we need them to first equip some require gear.
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
    return if itemContainer.hasClass('locked') or itemContainer.hasClass('restricted')
    wasActive = itemContainer.hasClass 'active'
    @unselectAllAvailableEquipment()
    @selectAvailableItem(itemContainer) unless wasActive
    @onSelectionChanged()

  onAvailableItemDoubleClick: (e) ->
    if e
      itemContainer = $(e.target).closest('.list-group-item')
      return if itemContainer.hasClass('locked') or itemContainer.hasClass('restricted')
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
    if unequipped
      @clearSelection()
      @requireLevelEquipment()
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
    # This is temporary, until we have a more general way of awarding items and configuring required/restricted items per level.
    requiredGear = LevelOptions[@options.levelID]?.requiredGear ? {}
    restrictedGear = LevelOptions[@options.levelID]?.restrictedGear ? {}
    if @inserted
      if @supermodel.finished()
        equipment = @getCurrentEquipmentConfig()  # Make sure @equipment is updated
      else
        equipment = @equipment
      hadRequired = @remainingRequiredEquipment?.length
      @remainingRequiredEquipment = []
      @$el.find('.should-equip').removeClass('should-equip')
      inWorldMap = $('#world-map-view').length
      for slot, item of restrictedGear
        equipped = equipment[slot]
        if equipped and equipped is gear[restrictedGear[slot]]
          console.log 'Unequipping restricted item', restrictedGear[slot], 'for', slot, 'before level', @options.levelID
          @unequipItemFromSlot @$el.find(".item-slot[data-slot='#{slot}']")
      for slot, item of requiredGear
        #continue if item is 'leather-tunic' and inWorldMap and @options.levelID is 'the-raised-sword'  # Don't tell them they need it until they need it in the level  # ... when we make it so that you can buy it
        equipped = equipment[slot]
        continue if equipped and not (
          (item is 'builders-hammer' and equipped in [gear['simple-sword'], gear['long-sword']]) or
          (item in ['simple-sword', 'long-sword'] and equipped is gear['builders-hammer']) or
          (item is 'leather-boots' and equipped is gear['simple-boots']) or
          (item is 'simple-boots' and equipped is gear['leather-boots'])
        )
        availableSlotSelector = "#available-equipment li[data-item-id='#{gear[item]}']"
        @highlightElement availableSlotSelector, delay: 500, sides: ['right'], rotation: Math.PI / 2
        @$el.find(availableSlotSelector).addClass 'should-equip'
        @$el.find("#equipped div[data-slot='#{slot}']").addClass 'should-equip'
        @remainingRequiredEquipment.push slot: slot, item: gear[item]
      if hadRequired and not @remainingRequiredEquipment.length
        @endHighlight()
        @highlightElement '#play-level-button', duration: 5000
      $('#play-level-button').prop('disabled', @remainingRequiredEquipment.length > 0)

  setHero: (@selectedHero) ->
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
    super()

  onClickChooseHero: ->
    @hide()
    @trigger 'choose-hero-click'

  onClickPlayLevel: (e) ->
    return if @$el.find('#play-level-button').prop 'disabled'
    @showLoading()
    ua = navigator.userAgent.toLowerCase()
    unless hasGoneFullScreenOnce or (/safari/.test(ua) and not /chrome/.test(ua)) or $(window).height() >= 658  # Min vertical resolution needed at 1366px wide
      @toggleFullscreen()
      hasGoneFullScreenOnce = true
    @updateConfig =>
      @trigger 'play-click'
    window.tracker?.trackEvent 'Play Level Modal', Action: 'Play'

  updateConfig: (callback, skipSessionSave) ->
    sessionHeroConfig = @options.session.get('heroConfig') ? {}
    lastHeroConfig = me.get('heroConfig') ? {}
    inventory = @getCurrentEquipmentConfig()
    patchSession = patchMe = false
    patchSession ||= not _.isEqual inventory, sessionHeroConfig.inventory
    patchMe ||= not _.isEqual inventory, lastHeroConfig.inventory
    sessionHeroConfig.inventory = inventory
    lastHeroConfig.inventory = inventory
    if patchMe
      console.log 'setting me.heroConfig to', JSON.stringify(lastHeroConfig)
      me.set 'heroConfig', lastHeroConfig
      me.patch()
    if patchSession
      console.log 'setting session.heroConfig to', JSON.stringify(sessionHeroConfig)
      @options.session.set 'heroConfig', sessionHeroConfig
      @options.session.patch success: callback unless skipSessionSave
    else
      callback?()

gear =
  'simple-boots': '53e237bf53457600003e3f05'
  'simple-sword': '53e218d853457600003e3ebe'
  'leather-tunic': '53e22eac53457600003e3efc'
  'leather-boots': '53e2384453457600003e3f07'
  'leather-belt': '5437002a7beba4a82024a97d'
  'programmaticon-i': '53e4108204c00d4607a89f78'
  'crude-glasses': '53e238df53457600003e3f0b'
  'builders-hammer': '53f4e6e3d822c23505b74f42'
  'long-sword': '544d7d1f8494308424f564a3'
  'sundial-wristwatch': '53e2396a53457600003e3f0f'
  'bronze-shield': '544c310ae0017993fce214bf'
  'wooden-glasses': '53e2167653457600003e3eb3'
  'basic-flags': '545bacb41e649a4495f887da'
