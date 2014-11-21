ModalView = require 'views/kinds/ModalView'
template = require 'templates/game-menu/inventory-modal'
{me} = require 'lib/auth'
ThangType = require 'models/ThangType'
CocoCollection = require 'collections/CocoCollection'
ItemView = require './ItemView'
SpriteBuilder = require 'lib/sprites/SpriteBuilder'
ItemDetailsView = require 'views/play/modal/ItemDetailsView'
Purchase = require 'models/Purchase'
LevelOptions = require 'lib/LevelOptions'

hasGoneFullScreenOnce = false

module.exports = class InventoryModal extends ModalView
  id: 'inventory-modal'
  className: 'modal fade play-modal'
  template: template
  slots: ['head', 'eyes', 'neck', 'torso', 'wrists', 'gloves', 'left-ring', 'right-ring', 'right-hand', 'left-hand', 'waist', 'feet', 'programming-book', 'pet', 'minion', 'flag']  #, 'misc-0', 'misc-1']  # TODO: bring in misc slot(s) again when we have space
  closesOnClickOutside: false # because draggable somehow triggers hide when you don't drag onto a draggable

  events:
    'click .item-slot': 'onItemSlotClick'
    'click #unequipped .item': 'onUnequippedItemClick'
    'doubletap #unequipped .item': 'onUnequippedItemDoubleClick'
    'doubletap .item-slot .item': 'onEquippedItemDoubleClick'
    'click button.equip-item': 'onClickEquipItemButton'
    'shown.bs.modal': 'onShown'
    'click #choose-hero-button': 'onClickChooseHero'
    'click #play-level-button': 'onClickPlayLevel'
    'click .unlock-button': 'onUnlockButtonClicked'
    'click #equip-item-viewed': 'onClickEquipItemViewed'
    'click #unequip-item-viewed': 'onClickUnequipItemViewed'
    'click #close-modal': 'hide'

  shortcuts:
    'esc': 'clearSelection'
    'enter': 'onClickPlayLevel'


  #- Setup

  initialize: (options) ->
    super(arguments...)
    @items = new CocoCollection([], {model: ThangType})
    # TODO: switch to item store loading system?
    @items.url = '/db/thang.type?view=items'
    @items.setProjection [
      'name'
      'slug'
      'components'
      'original'
      'rasterIcon'
      'gems'
      'tier'
      'description'
      'heroClass'
      'i18n'
    ]
    @supermodel.loadCollection(@items, 'items')
    @equipment = {}  # Assign for real when we have loaded the session and items.

  onItemsLoaded: ->
    item.notInLevel = true for item in @items.models
    @equipment = @options.equipment or @options.session?.get('heroConfig')?.inventory or me.get('heroConfig')?.inventory or {}
    @equipment = $.extend true, {}, @equipment
    @requireLevelEquipment()
    @itemGroups = {}
    @itemGroups.availableItems = new Backbone.Collection()
    @itemGroups.restrictedItems = new Backbone.Collection()
    @itemGroups.lockedItems = new Backbone.Collection()
    itemGroup.comparator = ((m) -> m.get('gems') ? m.get('tier')) for itemGroup in _.values @itemGroups

    equipped = _.values(@equipment)
    @sortItem(item, equipped) for item in @items.models

  sortItem: (item, equipped) ->
    equipped ?= _.values(@equipment)

    # general starting classes
    item.classes = _.clone(item.getAllowedSlots())
    for heroClass in item.getAllowedHeroClasses()
      item.classes.push heroClass
    item.classes.push 'equipped' if item.get('original') in equipped

    # sort into one of the four groups
    locked = not (item.get('original') in me.items())
    locked = false if me.get('slug') is 'nick'

    if not item.getFrontFacingStats().props.length and not _.size(item.getFrontFacingStats().stats) and not locked  # Temp: while there are placeholder items
      null  # Don't put into a collection
    else if locked and item.get('slug') isnt 'simple-boots'
      @itemGroups.lockedItems.add(item)
      item.classes.push 'locked'
      item.classes.push 'silhouette' if item.isSilhouettedItem()
      item.classes.push 'hidden' unless item.get('gems')
    else if item.get('slug') in _.values(LevelOptions[@options.levelID]?.restrictedGear ? {})
      @itemGroups.restrictedItems.add(item)
      item.classes.push 'restricted'
    else
      @itemGroups.availableItems.add(item)

  onLoaded: ->
    # Both items and session have been loaded.
    @onItemsLoaded()
    super()

  getRenderData: (context={}) ->
    context = super(context)
    context.equipped = _.values(@equipment)
    context.items = @items.models
    context.itemGroups = @itemGroups
    context.slots = @slots
    context.selectedHero = @selectedHero
    context.equipment = _.clone @equipment
    context.equipment[slot] = @items.findWhere {original: itemOriginal} for slot, itemOriginal of context.equipment
    context.gems = me.gems()
    context

  afterRender: ->
    super()
    @$el.find('#play-level-button').css('visibility', 'hidden')
    return unless @supermodel.finished()
    @$el.find('#play-level-button').css('visibility', 'visible')

    @setUpDraggableEventsForAvailableEquipment()
    @setUpDraggableEventsForEquippedArea()
    @delegateEvents()
    @itemDetailsView = new ItemDetailsView()
    @insertSubView(@itemDetailsView)
    @requireLevelEquipment()
    @$el.find('.nano').nanoScroller({alwaysVisible: true})
    @onSelectionChanged()

  afterInsert: ->
    super()
    @canvasWidth = @$el.find('canvas').innerWidth()
    @canvasHeight = @$el.find('canvas').innerHeight()
    @inserted = true
    @requireLevelEquipment()

  #- Draggable logic

  setUpDraggableEventsForAvailableEquipment: ->
    for availableItemEl in @$el.find('#unequipped .item')
      availableItemEl = $(availableItemEl)
      continue if availableItemEl.hasClass('locked') or availableItemEl.hasClass('restricted')
      dragHelper = availableItemEl.clone().addClass('draggable-item')
      do (dragHelper, availableItemEl) =>
        availableItemEl.draggable
          revert: 'invalid'
          appendTo: @$el
          cursorAt: {left: 35.5, top: 35.5}
          helper: -> dragHelper
          revertDuration: 200
          distance: 10
          scroll: false
          zIndex: 1100
        availableItemEl.on 'dragstart', => @selectUnequippedItem(availableItemEl)

  setUpDraggableEventsForEquippedArea: ->
    for itemSlot in @$el.find '.item-slot'
      slot = $(itemSlot).data 'slot'
      do (slot, itemSlot) =>
        $(itemSlot).droppable
          drop: (e, ui) => @equipSelectedItem()
          accept: (el) -> $(el).parent().hasClass slot
          activeClass: 'droppable'
          hoverClass: 'droppable-hover'
          tolerance: 'touch'
        @makeEquippedSlotDraggable $(itemSlot)

    @$el.find('#equipped').droppable
      drop: (e, ui) => @equipSelectedItem()
      accept: (el) -> true
      activeClass: 'droppable'
      hoverClass: 'droppable-hover'
      tolerance: 'pointer'

  makeEquippedSlotDraggable: (slot) ->
    unequip = =>
      @unequipItemFromSlot slot
      @requireLevelEquipment()
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
    slot.on 'dragstart', => @selectItemSlot(slot)


  #- Select/equip event handlers

  onItemSlotClick: (e) ->
    return if @remainingRequiredEquipment?.length  # Don't let them select a slot if we need them to first equip some require gear.
    @selectItemSlot($(e.target).closest('.item-slot'))

  onUnequippedItemClick: (e) ->
    return if @justDoubleClicked
    itemEl = $(e.target).closest('.item')
    @selectUnequippedItem(itemEl)

  onUnequippedItemDoubleClick: (e) ->
    itemEl = $(e.target).closest('.item')
    return if itemEl.hasClass('locked') or itemEl.hasClass('restricted')
    @equipSelectedItem()
    @justDoubleClicked = true
    _.defer => @justDoubleClicked = false

  onEquippedItemDoubleClick: -> @unequipSelectedItem()
  onClickEquipItemViewed: -> @equipSelectedItem()
  onClickUnequipItemViewed: -> @unequipSelectedItem()

  onClickEquipItemButton: (e) ->
    itemEl = $(e.target).closest('.item')
    @selectUnequippedItem(itemEl)
    @equipSelectedItem()

  onUnlockButtonClicked: (e) ->
    button = $(e.target).closest('button')
    if button.hasClass('confirm')
      item = @items.get($(e.target).data('item-id'))
      purchase = Purchase.makeFor(item)
      purchase.save()

      #- set local changes to mimic what should happen on the server...
      purchased = me.get('purchased') ? {}
      purchased.items ?= []
      purchased.items.push(item.get('original'))

      me.set('purchased', purchased)
      me.set('spent', (me.get('spent') ? 0) + item.get('gems'))

      #- ...then rerender key bits
      @requireLevelEquipment()
      @itemGroups.lockedItems.remove(item)
      @sortItem(item)
      @renderSelectors("#unequipped", "#gems-count")
      @delegateEvents()
      @setUpDraggableEventsForAvailableEquipment()
      @itemDetailsView.setItem(item)
    else
      button.addClass('confirm').text($.i18n.t('play.confirm'))
      @$el.one 'click', (e) ->
        button.removeClass('confirm').text($.i18n.t('play.unlock')) if e.target isnt button[0]


  #- Select/equip higher-level, all encompassing methods the callbacks all use

  selectItemSlot: (slotEl) ->
    @clearSelection()
    slotEl.addClass('selected')
    selectedSlotItemID = slotEl.find('.item').data('item-id')
    item = @items.get(selectedSlotItemID)
    if item then @showItemDetails(item, 'unequip')
    @onSelectionChanged()

  selectUnequippedItem: (itemEl) ->
    @clearSelection()
    itemEl.addClass('active')
    showExtra = if itemEl.hasClass('restricted') then 'restricted' else if not itemEl.hasClass('locked') then 'equip' else ''
    @showItemDetails(@items.get(itemEl.data('item-id')), showExtra)
    @onSelectionChanged()

  equipSelectedItem: ->
    selectedItemEl = @getSelectedUnequippedItem()
    selectedItem = @items.get(selectedItemEl.data('item-id'))
    return unless selectedItem
    allowedSlots = selectedItem.getAllowedSlots()
    slotEl = @$el.find(".item-slot[data-slot='#{allowedSlots[0]}']")
    selectedItemEl.effect('transfer', to: slotEl, duration: 500, easing: 'easeOutCubic')
    unequipped = @unequipItemFromSlot(slotEl)
    selectedItemEl.addClass('equipped')
    slotEl.append(selectedItemEl.find('img').clone().addClass('item').data('item-id', selectedItem.id))
    @clearSelection()
    @showItemDetails(selectedItem, 'unequip')
    slotEl.addClass('selected')
    selectedItem.classes.push 'equipped'
    @makeEquippedSlotDraggable slotEl
    @requireLevelEquipment()
    @onSelectionChanged()

  unequipSelectedItem: ->
    slotEl = @getSelectedSlot()
    @clearSelection()
    itemEl = @unequipItemFromSlot(slotEl)
    return unless itemEl
    itemEl.addClass('active')
    slotEl.effect('transfer', to: itemEl, duration: 500, easing: 'easeOutCubic')
    selectedSlotItemID = itemEl.data('item-id')
    item = @items.get(selectedSlotItemID)
    item.classes = _.without item.classes, 'equipped'
    @showItemDetails(item, 'equip')
    @requireLevelEquipment()
    @onSelectionChanged()


  #- Select/equip helpers

  clearSelection: ->
    @deselectAllSlots()
    @deselectAllUnequippedItems()
    @hideItemDetails()

  unequipItemFromSlot: (slotEl) ->
    itemEl = slotEl.find('.item')
    itemIDToUnequip = itemEl.data('item-id')
    return unless itemIDToUnequip
    itemEl.remove()
    @$el.find("#unequipped .item[data-item-id=#{itemIDToUnequip}]").removeClass('equipped')

  deselectAllSlots: ->
    @$el.find('#equipped .item-slot.selected').removeClass('selected')

  deselectAllUnequippedItems: ->
    @$el.find('#unequipped .item').removeClass('active')

  getSlot: (name) ->
    @$el.find(".item-slot[data-slot=#{name}]")

  getSelectedSlot: ->
    @$el.find('#equipped .item-slot.selected')

  getSelectedUnequippedItem: ->
    @$el.find('#unequipped .item.active')

  onSelectionChanged: ->
    heroClass = @selectedHero?.get('heroClass')
    itemsCanBeEquipped = @$el.find('#unequipped .item.available:not(.equipped)').filter('.'+heroClass).length
    toShow = @$el.find('#double-click-hint, #available-description')
    if itemsCanBeEquipped then toShow.removeClass('secret') else toShow.addClass('secret')
    @delegateEvents()


  showItemDetails: (item, showExtra) ->
    @itemDetailsView.setItem(item)
    @$el.find('#item-details-extra > *').addClass('secret')
    @$el.find("##{showExtra}-item-viewed").removeClass('secret')

  hideItemDetails: ->
    @itemDetailsView.setItem(null)
    @$el.find('#item-details-extra > *').addClass('secret')

  getCurrentEquipmentConfig: ->
    config = {}
    for slot in @$el.find('.item-slot')
      slotName = $(slot).data('slot')
      slotItemID = $(slot).find('.item').data('item-id')
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
      if heroClass = @selectedHero?.get('heroClass')
        for slot, item of _.clone equipment
          itemModel = @items.findWhere original: item
          unless itemModel and heroClass in itemModel.classes
            console.log 'Unequipping', itemModel.get('heroClass'), 'item', itemModel.get('name'), 'from slot due to class restrictions.'
            @unequipItemFromSlot @$el.find(".item-slot[data-slot='#{slot}']")
      for slot, item of restrictedGear
        equipped = equipment[slot]
        if equipped and equipped is gear[restrictedGear[slot]]
          console.log 'Unequipping restricted item', restrictedGear[slot], 'for', slot, 'before level', @options.levelID
          @unequipItemFromSlot @$el.find(".item-slot[data-slot='#{slot}']")
      if heroClass is 'Warrior'
        # After they switch to a ranger or wizard, we stop being so finicky about gear.
        for slot, item of requiredGear
          #continue if item is 'leather-tunic' and inWorldMap and @options.levelID is 'the-raised-sword'  # Don't tell them they need it until they need it in the level  # ... when we make it so that you can buy it
          equipped = equipment[slot]
          continue if equipped and not (
            (item is 'crude-builders-hammer' and equipped in [gear['simple-sword'], gear['long-sword'], gear['sharpened-sword'], gear['roughedge']]) or
            (item in ['simple-sword', 'long-sword', 'roughedge', 'sharpened-sword'] and equipped is gear['crude-builders-hammer']) or
            (item is 'leather-boots' and equipped is gear['simple-boots']) or
            (item is 'simple-boots' and equipped is gear['leather-boots'])
          )
          itemModel = @items.findWhere {slug: item}
          continue unless itemModel
          availableSlotSelector = "#unequipped .item[data-item-id='#{itemModel.id}']"
          @highlightElement availableSlotSelector, delay: 500, sides: ['right'], rotation: Math.PI / 2
          @$el.find(availableSlotSelector).addClass 'should-equip'
          @$el.find("#equipped div[data-slot='#{slot}']").addClass 'should-equip'
          @remainingRequiredEquipment.push slot: slot, item: gear[item]
      if hadRequired and not @remainingRequiredEquipment.length
        @endHighlight()
        @highlightElement '#play-level-button', duration: 5000
      $('#play-level-button').prop('disabled', @remainingRequiredEquipment.length > 0)

  setHero: (@selectedHero) ->
    if @selectedHero.loading
      @listenToOnce @selectedHero, 'sync', => @setHero? @selectedHero
      return
    @$el.removeClass('Warrior Ranger Wizard').addClass(@selectedHero.get('heroClass'))
    @requireLevelEquipment()
    @render()

  onShown: ->
    # Called when we switch tabs to this within the modal
    @requireLevelEquipment()

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
      @trigger? 'play-click'
    window.tracker?.trackEvent 'Play Level Modal', Action: 'Play', ['Google Analytics']

  updateConfig: (callback, skipSessionSave) ->
    sessionHeroConfig = @options.session.get('heroConfig') ? {}
    lastHeroConfig = me.get('heroConfig') ? {}
    inventory = @getCurrentEquipmentConfig()
    patchSession = patchMe = false
    patchSession ||= not _.isEqual inventory, sessionHeroConfig.inventory
    sessionHeroConfig.inventory = inventory
    if hero = @selectedHero.get('original')
      patchSession ||= not _.isEqual hero, sessionHeroConfig.thangType
      sessionHeroConfig.thangType = hero
    patchMe ||= not _.isEqual inventory, lastHeroConfig.inventory
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

  destroy: ->
    @stage?.removeAllChildren()
    super()




gear =
  'simple-boots': '53e237bf53457600003e3f05'
  'simple-sword': '53e218d853457600003e3ebe'
  'leather-tunic': '53e22eac53457600003e3efc'
  'leather-boots': '53e2384453457600003e3f07'
  'leather-belt': '5437002a7beba4a82024a97d'
  'programmaticon-i': '53e4108204c00d4607a89f78'
  'crude-glasses': '53e238df53457600003e3f0b'
  'crude-builders-hammer': '53f4e6e3d822c23505b74f42'
  'long-sword': '544d7d1f8494308424f564a3'
  'sundial-wristwatch': '53e2396a53457600003e3f0f'
  'bronze-shield': '544c310ae0017993fce214bf'
  'wooden-glasses': '53e2167653457600003e3eb3'
  'basic-flags': '545bacb41e649a4495f887da'
  'roughedge': '544d7d918494308424f564a7'
  'sharpened-sword': '544d7deb8494308424f564ab'
