require('app/styles/play/menu/inventory-modal.sass')
require('app/styles/play/modal/play-items-modal.sass')
ModalView = require 'views/core/ModalView'
template = require 'templates/play/menu/inventory-modal'
buyGemsPromptTemplate = require 'templates/play/modal/buy-gems-prompt'
earnGemsPromptTemplate = require 'templates/play/modal/earn-gems-prompt'
subscribeForGemsPrompt = require 'templates/play/modal/subscribe-for-gems-prompt'
{me} = require 'core/auth'
ThangType = require 'models/ThangType'
ThangTypeLib = require 'lib/ThangTypeLib'
CocoCollection = require 'collections/CocoCollection'
ItemView = require './ItemView'
SpriteBuilder = require 'lib/sprites/SpriteBuilder'
ItemDetailsView = require 'views/play/modal/ItemDetailsView'
Purchase = require 'models/Purchase'
BuyGemsModal = require 'views/play/modal/BuyGemsModal'
CreateAccountModal = require 'views/core/CreateAccountModal'
SubscribeModal = require 'views/core/SubscribeModal'
require('vendor/scripts/jquery-ui-1.11.1.custom')
require('vendor/styles/jquery-ui-1.11.1.custom.css')

hasGoneFullScreenOnce = false

module.exports = class InventoryModal extends ModalView
  id: 'inventory-modal'
  className: 'modal fade play-modal'
  template: template
  slots: ['head', 'eyes', 'neck', 'torso', 'wrists', 'gloves', 'left-ring', 'right-ring', 'right-hand', 'left-hand', 'waist', 'feet', 'programming-book', 'pet', 'minion', 'flag']  #, 'misc-0', 'misc-1']  # TODO: bring in misc slot(s) again when we have space
  ringSlots: ['left-ring', 'right-ring']
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
    'click #subscriber-item-viewed': 'onClickSubscribeItemViewed'
    'click #close-modal': 'hide'
    'click .buy-gems-prompt-button': 'onBuyGemsPromptButtonClicked'
    'click .start-subscription-button': 'onSubscribeButtonClicked'
    'click': 'onClickedSomewhere'
    'update #unequipped .nano': 'onScrollUnequipped'

  shortcuts:
    'esc': 'clearSelection'
    'enter': 'onClickPlayLevel'


  #- Setup

  initialize: (options) ->
    if (application.getHocCampaign() is 'game-dev-hoc-2')
      if !me.get('earned')
        me.set('earned', {})
      if !me.get('earned').items
        me.attributes.earned.items = []
      baseItems = [
        '53e2384453457600003e3f07' # leather boots
        '53e218d853457600003e3ebe' # simple sword
        '53e22aa153457600003e3ef5' # wooden shield
        '5744e3683af6bf590cd27371' # cougar
      ]
      for item in baseItems
        unless item in me.get('earned').items
          me.get('earned').items.push(item) # Allow HoC players to access the cat

    @onScrollUnequipped = _.throttle(_.bind(@onScrollUnequipped, @), 200)
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
      'dollImages'
      'gems'
      'tier'
      'description'
      'heroClass'
      'i18n'
      'subscriber'
    ]
    @supermodel.loadCollection(@items, 'items')
    @equipment = {}  # Assign for real when we have loaded the session and items.

  onItemsLoaded: ->
    console.log("Inside onItemsLoaded")
    for item in @items.models
      item.notInLevel = true
      programmableConfig = _.find(item.get('components'), (c) -> c.config?.programmableProperties)?.config
      item.programmableProperties = (programmableConfig?.programmableProperties or []).concat programmableConfig?.moreProgrammableProperties or []
    @itemsProgrammablePropertiesConfigured = true
    if me.isStudent() and not application.getHocCampaign()
      @equipment = me.get('heroConfig')?.inventory or {}
    else
      @equipment = @options.equipment or @options.session?.get('heroConfig')?.inventory or me.get('heroConfig')?.inventory or {}
    @equipment = $.extend true, {}, @equipment
    console.log("requireLevelEquipment called from onItemsLoaded")
    @requireLevelEquipment()
    @itemGroups = {}
    @itemGroups.requiredPurchaseItems = new Backbone.Collection()
    @itemGroups.availableItems = new Backbone.Collection()
    @itemGroups.restrictedItems = new Backbone.Collection()
    @itemGroups.lockedItems = new Backbone.Collection()
    @itemGroups.subscriberItems = new Backbone.Collection()
    itemGroup.comparator = ((m) -> m.get('tier') ? m.get('gems')) for itemGroup in _.values @itemGroups

    equipped = _.values(@equipment)
    @sortItem(item, equipped) for item in @items.models

  sortItem: (item, equipped) ->
    console.log("Inside sortItem")
    equipped ?= _.values(@equipment)

    # general starting classes
    item.classes = _.clone(item.getAllowedSlots())
    for heroClass in item.getAllowedHeroClasses()
      item.classes.push heroClass
    item.classes.push 'equipped' if item.get('original') in equipped

    # sort into one of the five groups
    locked = not me.ownsItem item.get('original')

    subscriber = (not me.isStudent()) and (not me.isPremium()) and item.get('subscriber')
    restrictedGear = @calculateRestrictedGearPerSlot()
    allRestrictedGear = _.flatten(_.values(restrictedGear))
    restricted = item.get('original') in allRestrictedGear

    # TODO: make this re-use result of computation of updateLevelRequiredItems, which we can only do after heroClass is ready...
    requiredToPurchase = false
    inCampaignView = $('#campaign-view').length
    unless gearSlugs[item.get('original')] is 'tarnished-bronze-breastplate' and inCampaignView and @options.level.get('slug') is 'the-raised-sword'
      requiredGear = @calculateRequiredGearPerSlot()
      for slot in item.getAllowedSlots()
        continue unless requiredItems = requiredGear[slot]
        continue if @equipment[slot] and @equipment[slot] not in allRestrictedGear and slot not in @ringSlots
        # Point out that they must buy it if they haven't bought any of the required items for that slot, and it's the first one.
        if item.get('original') is requiredItems[0] and not _.find(requiredItems, (requiredItem) -> me.ownsItem requiredItem)
          requiredToPurchase = true
          break

    if requiredToPurchase and locked and not item.get('gems')
      # Either one of two things has happened:
      # 1. There's a bug and the player doesn't have a required item they should have.
      # 2. The player is trying to play a level they haven't unlocked.
      # We'll just pretend they own it so that they don't get stuck.
      application.tracker?.trackEvent 'Required Item Locked', level: @options.level.get('slug'), label: @options.level.get('slug'), item: item.get('name'), playerLevel: me.level(), levelUnlocked: me.ownsLevel @options.level.get('original')
      locked = false

    placeholder = not item.getFrontFacingStats().props.length and not _.size(item.getFrontFacingStats().stats)

    if placeholder and locked  # The item is not complete, so don't put it into a collection.
      null
    else if locked and requiredToPurchase
      item.classes.push 'locked'
      @itemGroups.requiredPurchaseItems.add item
    else if locked
      item.classes.push 'locked'
      if item.isSilhouettedItem() or not item.get('gems')
        # Don't even load/show these--don't add to a collection. (Bandwidth optimization.)
        null
      else
        @itemGroups.lockedItems.add(item)
    else if restricted
      @itemGroups.restrictedItems.add(item)
      item.classes.push 'restricted'
    else if subscriber and not application.getHocCampaign() # allow HoC players to equip pets
      @itemGroups.subscriberItems.add(item)
      item.classes.push 'subscriber'
    else
      @itemGroups.availableItems.add(item)

    # level to unlock
    item.level = item.levelRequiredForItem() if item.get('tier')?

  onLoaded: ->
    console.log("Inside onLoaded")
    # Both items and session have been loaded.
    @onItemsLoaded()
    super()

  getRenderData: (context={}) ->
    console.log("Inside getRenderData")
    context = super(context)
    context.equipped = _.values(@equipment)
    context.items = @items.models
    context.itemGroups = @itemGroups
    context.slots = @slots
    context.selectedHero = @selectedHero
    context.selectedHeroClass = @selectedHero?.get('heroClass')
    context.equipment = _.clone @equipment
    context.equipment[slot] = @items.findWhere {original: itemOriginal} for slot, itemOriginal of context.equipment
    context.gems = me.gems()
    context

  afterRender: ->
    console.log("Inside afterRender")
    super()
    @$el.find('#play-level-button').css('visibility', 'hidden')
    return unless @supermodel.finished()
    @$el.find('#play-level-button').css('visibility', 'visible')

    @setUpDraggableEventsForAvailableEquipment()
    @setUpDraggableEventsForEquippedArea()
    @delegateEvents()
    @itemDetailsView = new ItemDetailsView()
    @insertSubView(@itemDetailsView)
    console.log("requireLevelEquipment called from afterRender")
    @requireLevelEquipment()
    @$el.find('.nano').nanoScroller({alwaysVisible: true})
    @onSelectionChanged()
    @onEquipmentChanged()

  afterInsert: ->
    console.log("Inside afterInsert")
    super()
    @canvasWidth = @$el.find('canvas').innerWidth()
    @canvasHeight = @$el.find('canvas').innerHeight()
    @inserted = true
    console.log("requireLevelEquipment called from afterInsert")
    @requireLevelEquipment()

  #- Draggable logic

  setUpDraggableEventsForAvailableEquipment: ->
    console.log("Inside setUpDraggableEventForAvailableEquipment")
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
    console.log("Inside setUpDraggableEventsForEquippedArea")
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
    console.log("Inside makeEquippedSlotDraggable")
    unequip = =>
      itemEl = @unequipItemFromSlot slot
      selectedSlotItemID = itemEl.data('item-id')
      item = @items.get(selectedSlotItemID)
      @requireLevelEquipment()
      @showItemDetails(item, 'equip')
      @onSelectionChanged()
      @onEquipmentChanged()
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
    @closePopover()
    return if @remainingRequiredEquipment?.length  # Don't let them select a slot if we need them to first equip some require gear.
    #@playSound 'menu-button-click'
    @selectItemSlot($(e.target).closest('.item-slot'))

  onUnequippedItemClick: (e) ->
    @closePopover()
    return if @justDoubleClicked
    return if @justClickedEquipItemButton
    itemEl = $(e.target).closest('.item')
    #@playSound 'menu-button-click'
    @selectUnequippedItem(itemEl)

  onUnequippedItemDoubleClick: (e) ->
    itemEl = $(e.target).closest('.item')
    return if itemEl.hasClass('locked') or itemEl.hasClass('restricted') or itemEl.hasClass('subscriber')
    @equipSelectedItem()
    @justDoubleClicked = true
    _.defer => @justDoubleClicked = false

  onEquippedItemDoubleClick: -> @unequipSelectedItem()
  onClickEquipItemViewed: -> @equipSelectedItem()
  onClickUnequipItemViewed: -> @unequipSelectedItem()

  onClickEquipItemButton: (e) ->
    @playSound 'menu-button-click'
    itemEl = $(e.target).closest('.item')
    @selectUnequippedItem(itemEl)
    @equipSelectedItem()
    @justClickedEquipItemButton = true
    _.defer => @justClickedEquipItemButton = false

  onClickSubscribeItemViewed: (e) ->
    @openModalView new SubscribeModal()
    itemElem = @$el.find('.item.active')
    item = @items.get(itemElem?.data('item-id'))
    window.tracker?.trackEvent 'Show subscription modal', category: 'Subscription', label: 'inventory modal: ' + (item?.get('slug') or 'unknown')

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
    showExtra = if itemEl.hasClass('restricted') then 'restricted' else if itemEl.hasClass('subscriber') then 'subscriber' else if not itemEl.hasClass('locked') then 'equip' else ''
    @showItemDetails(@items.get(itemEl.data('item-id')), showExtra)
    @onSelectionChanged()

  equipSelectedItem: ->
    selectedItemEl = @getSelectedUnequippedItem()
    selectedItem = @items.get(selectedItemEl.data('item-id'))
    return unless selectedItem
    allowedSlots = selectedItem.getAllowedSlots()
    firstSlot = unequippedSlot = null
    for allowedSlot in allowedSlots
      slotEl = @$el.find(".item-slot[data-slot='#{allowedSlot}']")
      firstSlot ?= slotEl
      unequippedSlot ?= slotEl unless slotEl.find('img').length
    slotEl = unequippedSlot ? firstSlot
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
    @onEquipmentChanged()

  unequipSelectedItem: ->
    slotEl = @getSelectedSlot()
    @clearSelection()
    itemEl = @unequipItemFromSlot(slotEl)
    return unless itemEl?.length
    itemEl.addClass('active')
    slotEl.effect('transfer', to: itemEl, duration: 500, easing: 'easeOutCubic')
    selectedSlotItemID = itemEl.data('item-id')
    item = @items.get(selectedSlotItemID)
    item.classes = _.without item.classes, 'equipped'
    @showItemDetails(item, 'equip')
    @requireLevelEquipment()
    @onSelectionChanged()
    @onEquipmentChanged()

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
    item = @items.get itemIDToUnequip
    item.classes = _.without item.classes, 'equipped'
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
    @itemDetailsView?.setItem(null)
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
    console.log("Inside requireLevelEquipment")
    console.log(@items)
    # This is called frequently to make sure the player isn't using any restricted items and knows she must equip any required items.
    return unless @inserted and @itemsProgrammablePropertiesConfigured
    equipment = if @supermodel.finished() then @getCurrentEquipmentConfig() else @equipment  # Make sure we're using latest equipment.
    hadRequired = @remainingRequiredEquipment?.length
    @remainingRequiredEquipment = []
    @$el.find('.should-equip').removeClass('should-equip')
    @unequipClassRestrictedItems equipment
    @unequipLevelRestrictedItems equipment
    @updateLevelRequiredItems equipment
    console.log("@remainingRequiredEquipment.length: " + @remainingRequiredEquipment.length)
    if hadRequired and not @remainingRequiredEquipment.length
      @endHighlight()
      @highlightElement '#play-level-button', duration: 5000
    $('#play-level-button').prop('disabled', @remainingRequiredEquipment.length > 0)

  unequipClassRestrictedItems: (equipment) ->
    console.log("Inside unequipClassRestrictedItems")
    return unless @supermodel.finished() and heroClass = @selectedHero?.get 'heroClass'
    for slot, item of _.clone equipment
      itemModel = @items.findWhere original: item
      unless itemModel and heroClass in itemModel.classes
        console.log 'Unequipping', itemModel.get('heroClass'), 'item', itemModel.get('name'), 'from slot due to class restrictions.'
        @unequipItemFromSlot @$el.find(".item-slot[data-slot='#{slot}']")
        delete equipment[slot]

  calculateRequiredGearPerSlot: ->
    return {} if me.isStudent() and not application.getHocCampaign() and not me.showGearRestrictionsInClassroom()
    return @requiredGearPerSlot if @requiredGearPerSlot
    requiredGear = _.clone(@options.level.get('requiredGear')) ? {}
    requiredProperties = @options.level.get('requiredProperties') ? []
    restrictedProperties = @options.level.get('restrictedProperties') ? []
    requiredPropertiesPerSlot = {}
    for item in @items.models
      requiredPropertiesOnThisItem = _.intersection(item.programmableProperties, requiredProperties)
      restrictedPropertiesOnThisItem = _.intersection(item.programmableProperties, restrictedProperties)
      continue unless requiredPropertiesOnThisItem.length and not restrictedPropertiesOnThisItem.length
      for slot in item.getAllowedSlots()
        continue if slot isnt 'right-hand' and _.isEqual requiredPropertiesOnThisItem, ['buildXY']  # Don't require things like caltrops belt
        requiredGear[slot] ?= []
        requiredGear[slot].push(item.get('original')) unless item.get('original') in requiredGear[slot]
        requiredPropertiesPerSlot[slot] ?= []
        requiredPropertiesPerSlot[slot].push(prop) for prop in requiredPropertiesOnThisItem when prop not in requiredPropertiesPerSlot[slot]
    @requiredPropertiesPerSlot = requiredPropertiesPerSlot
    @requiredGearPerSlot = requiredGear
    @requiredGearPerSlot

  calculateRestrictedGearPerSlot: ->
    return {} if me.isStudent() and not application.getHocCampaign() and not me.showGearRestrictionsInClassroom()
    return @restrictedGearPerSlot if @restrictedGearPerSlot
    @calculateRequiredGearPerSlot() unless @requiredGearPerSlot
    restrictedGear = _.clone(@options.level.get('restrictedGear')) ? {}
    restrictedProperties = @options.level.get('restrictedProperties') ? []
    for item in @items.models
      restrictedPropertiesOnThisItem = _.intersection(item.programmableProperties, restrictedProperties)
      for slot in item.getAllowedSlots()
        requiredPropertiesNotOnThisItem = _.without(@requiredPropertiesPerSlot[slot], item.programmableProperties...)
        # Let Rangers/Wizards use class specific weapon in 'cleave' levelsm, if it's not restricted
        continue if 'cleave' in requiredPropertiesNotOnThisItem and 'Warrior' not in item.getAllowedHeroClasses() and not restrictedPropertiesOnThisItem.length
        if restrictedPropertiesOnThisItem.length or requiredPropertiesNotOnThisItem.length
          restrictedGear[slot] ?= []
          restrictedGear[slot].push(item.get('original')) unless item.get('original') in restrictedGear[slot]
    @restrictedGearPerSlot = restrictedGear
    @restrictedGearPerSlot

  unequipLevelRestrictedItems: (equipment) ->
    console.log("Inside unequipLevelRestrictedItems")
    restrictedGear = @calculateRestrictedGearPerSlot()
    for slot, items of restrictedGear
      for item in items
        equipped = equipment[slot]
        if equipped and equipped is item
          console.log 'Unequipping restricted item', equipped, 'for', slot, 'before level', @options.level.get('slug')
          @unequipItemFromSlot @$el.find(".item-slot[data-slot='#{slot}']")
          delete equipment[slot]
    null

  updateLevelRequiredItems: (equipment) ->
    console.log("inside updateLevelRequiredItems")
    return unless heroClass = @selectedHero?.get 'heroClass'
    requiredGear = @calculateRequiredGearPerSlot()
    console.log("inside executtion of updateLevelRequiredItems")
    for slot, items of requiredGear when items.length
      if slot in @ringSlots
        validSlots = @ringSlots
      else
        validSlots = [slot]

      continue if validSlots.some (slot) ->
        equipped = equipment[slot]
        equipped in items

      # Actually, just let them play if they have equipped anything in that slot (and we haven't unequipped it due to restrictions).
      # Rings often have unique effects, so this rule does not apply to them (they are still required even if there is a non-restricted ring equipped in the slot).
      continue if equipment[slot] and slot not in @ringSlots

      items = (item for item in items when heroClass in (@items.findWhere(original: item)?.classes ? []))
      continue unless items.length  # If the required items are for another class, then let's not be finicky.

      # We will point out the last (best) element that they own and can use, otherwise the first (cheapest).
      items = _.sortBy items, (item) => @items.findWhere(original: item).get('tier') ? 9001
      bestOwnedItem = _.findLast items, (item) -> me.ownsItem item
      item = bestOwnedItem ? items[0]

      # For the Tarnished Bronze Breastplate only, don't tell them they need it until they need it in the level, so we can show how to buy it.
      slug = gearSlugs[item]
      inCampaignView = $('#campaign-view').length
      continue if slug is 'tarnished-bronze-breastplate' and inCampaignView and @options.level.get('slug') is 'the-raised-sword'

      # Now we're definitely requiring and pointing out an item.
      itemModel = @items.findWhere {original: item}
      availableSlotSelector = "#unequipped .item[data-item-id='#{itemModel.id}']"
      @highlightElement availableSlotSelector, delay: 500, sides: ['right'], rotation: Math.PI / 2
      $itemEl = @$el.find(availableSlotSelector).addClass 'should-equip'
      @$el.find("#equipped div[data-slot='#{slot}']").addClass 'should-equip'
      if itemOffsetTop = $itemEl[0]?.offsetTop
        itemOffsetBottom = itemOffsetTop + $itemEl.outerHeight(true)
        parentHeight = $itemEl.parent().height()
        if itemOffsetBottom > $itemEl.parent().scrollTop() + parentHeight
          $itemEl.parent().scrollTop itemOffsetBottom - parentHeight
        else if itemOffsetTop < $itemEl.parent().scrollTop()
          $itemEl.parent().scrollTop itemOffsetTop
      @remainingRequiredEquipment.push slot: slot, item: item
    null

  setHero: (@selectedHero) ->
    if @selectedHero.loading
      @listenToOnce @selectedHero, 'sync', => @setHero? @selectedHero
      return
    @$el.removeClass('Warrior Ranger Wizard').addClass(@selectedHero.get('heroClass'))
    @requireLevelEquipment()
    @render()
    @onEquipmentChanged()

  onShown: ->
    # Called when we switch tabs to this within the modal
    @requireLevelEquipment()

  onHidden: ->
    # Called when the modal itself is dismissed
    @endHighlight()
    super()
    @playSound 'game-menu-close'

  onClickChooseHero: ->
    @playSound 'menu-button-click'
    @hide()
    @trigger 'choose-hero-click'

  onClickPlayLevel: (e) ->
    return if @$el.find('#play-level-button').prop 'disabled'
    levelSlug = @options.level.get('slug')
    @playSound 'menu-button-click'
    @showLoading()
    ua = navigator.userAgent.toLowerCase()
    isSafari = /safari/.test(ua) and not /chrome/.test(ua)
    isTooShort = $(window).height() < 658  # Min vertical resolution needed at 1366px wide
    if isTooShort and not me.isAdmin() and not hasGoneFullScreenOnce and not isSafari
      @toggleFullscreen()
      hasGoneFullScreenOnce = true
    @updateConfig =>
      @trigger? 'play-click'
    window.tracker?.trackEvent 'Inventory Play', category: 'Play Level', level: levelSlug

  updateConfig: (callback, skipSessionSave) ->
    console.log("Inside updateConfig")
    sessionHeroConfig = @options.session.get('heroConfig') ? {}
    lastHeroConfig = me.get('heroConfig') ? {}
    inventory = @getCurrentEquipmentConfig()
    patchSession = patchMe = false
    patchSession ||= not _.isEqual inventory, sessionHeroConfig.inventory
    sessionHeroConfig.inventory = inventory
    if hero = @selectedHero?.get('original')
      patchSession ||= not _.isEqual hero, sessionHeroConfig.thangType
      sessionHeroConfig.thangType = hero
    patchMe ||= not _.isEqual inventory, lastHeroConfig.inventory
    lastHeroConfig.inventory = inventory
    if patchMe
      console.log 'Inventory Modal: setting me.heroConfig to', JSON.stringify(lastHeroConfig)
      me.set 'heroConfig', lastHeroConfig
      me.patch()
    if patchSession
      console.log 'Inventory Modal: setting session.heroConfig to', JSON.stringify(sessionHeroConfig)
      @options.session.set 'heroConfig', sessionHeroConfig
      @options.session.patch success: callback unless skipSessionSave
    else
      callback?()

  #- TODO: DRY this between PlayItemsModal and InventoryModal and PlayHeroesModal

  onUnlockButtonClicked: (e) ->
    e.stopPropagation()
    button = $(e.target).closest('button')
    item = @items.get(button.data('item-id'))
    affordable = item.affordable
    if not affordable
      @playSound 'menu-button-click'
      @askToBuyGemsOrSubscribe button unless me.freeOnly() or application.getHocCampaign()
    else if button.hasClass('confirm')
      @playSound 'menu-button-unlock-end'
      purchase = Purchase.makeFor(item)
      purchase.save()

      #- set local changes to mimic what should happen on the server...
      purchased = me.get('purchased') ? {}
      purchased.items ?= []
      purchased.items.push(item.get('original'))

      me.set('purchased', purchased)
      me.set('spent', (me.get('spent') ? 0) + item.get('gems'))
      #- ...then rerender key bits
      @itemGroups.lockedItems.remove(item)
      @itemGroups.requiredPurchaseItems.remove(item)
      # Redo all item sorting to make sure that we don't clobber state changes since last render.
      equipped = _.values @getCurrentEquipmentConfig()
      @sortItem(otherItem, equipped) for otherItem in @items.models
      @renderSelectors('#unequipped', '#gems-count')

      @requireLevelEquipment()
      @delegateEvents()
      @setUpDraggableEventsForAvailableEquipment()
      @itemDetailsView.setItem(item)
      @onScrollUnequipped true
      if not me.isStudent()
        Backbone.Mediator.publish 'store:item-purchased', item: item, itemSlug: item.get('slug')
    else
      @playSound 'menu-button-unlock-start'
      button.addClass('confirm').text($.i18n.t('play.confirm'))
      @$el.one 'click', (e) ->
        button.removeClass('confirm').text($.i18n.t('play.unlock')) if e.target isnt button[0]

  askToSignUp: ->
    createAccountModal = new CreateAccountModal supermodel: @supermodel
    return @openModalView createAccountModal

  askToBuyGemsOrSubscribe: (unlockButton) ->
    @$el.find('.unlock-button').popover 'destroy'
    if me.isStudent()
      popoverTemplate = earnGemsPromptTemplate {}
    else if me.canBuyGems()
      popoverTemplate = buyGemsPromptTemplate {}
    else
      if not me.hasSubscription() # user does not have subscription ask him to subscribe to get more gems, china infra does not have 'buy gems' option
        popoverTemplate = subscribeForGemsPrompt {}
      else # user has subscription and yet not enough gems, just ask him to keep playing for more gems
        popoverTemplate = earnGemsPromptTemplate {}

    unlockButton.popover(
      animation: true
      trigger: 'manual'
      placement: 'top'
      content: ' '  # template has it
      container: @$el
      template: popoverTemplate
    ).popover 'show'
    popover = unlockButton.data('bs.popover')
    popover?.$tip?.i18n()
    @applyRTLIfNeeded()

  onBuyGemsPromptButtonClicked: (e) ->
    @playSound 'menu-button-click'
    return @askToSignUp() if me.get('anonymous')
    @openModalView new BuyGemsModal()

  onSubscribeButtonClicked: (e) ->
    @openModalView new SubscribeModal()
    window.tracker?.trackEvent 'Show subscription modal', category: 'Subscription', label: 'hero subscribe modal: ' + ($(e.target).data('heroSlug') or 'unknown')

  onClickedSomewhere: (e) ->
    @closePopover()

  closePopover: ->
    return if @destroyed
    @$el.find('.unlock-button').popover 'destroy'

  #- Dynamic portrait loading

  onScrollUnequipped: (forceLoadAll=false) ->
    # dynamically load visible items when the user scrolls enough to see them
    return if @destroyed
    nanoContent = @$el.find('#unequipped .nano-content')
    items = nanoContent.find('.item:visible:not(.loaded)')
    threshold = nanoContent.height() + 100
    for itemEl in items
      itemEl = $(itemEl)
      if itemEl.position().top < threshold or forceLoadAll
        itemEl.addClass('loaded')
        item = @items.get(itemEl.data('item-id'))
        itemEl.find('img').attr('src', item.getPortraitURL())


  #- Paper doll equipment updating
  onEquipmentChanged: ->
    heroClass = @selectedHero?.get('heroClass') ? 'Warrior'
    gender = ThangTypeLib.getGender @selectedHero
    @$el.find('#hero-image, #hero-image-hair, #hero-image-head, #hero-image-thumb').removeClass().addClass "#{gender} #{heroClass}"
    equipment = @getCurrentEquipmentConfig()
    @onScrollUnequipped()
    return unless _.size(equipment) and @supermodel.finished()
    @removeDollImages()
    slotsWithImages = []
    for slot, original of equipment
      item = _.find @items.models, (item) -> item.get('original') is original
      continue unless dollImages = item?.get('dollImages')
      didAdd = @addDollImage slot, dollImages, heroClass, gender, item
      slotsWithImages.push slot if didAdd if item.get('original') isnt '54ea39342b7506e891ca70f2'  # Circlet of the Magi needs hair under it
    @$el.find('#hero-image-hair').toggle not ('head' in slotsWithImages)
    @$el.find('#hero-image-thumb').toggle not ('gloves' in slotsWithImages)

    @equipment = @options.equipment = equipment
    @updateConfig (() -> return), true if me.isStudent() and not application.getHocCampaign()  # Save the player's heroConfig if they're a student, whenever they change gear.

  removeDollImages: ->
    @$el.find('.doll-image').remove()

  addDollImage: (slot, dollImages, heroClass, gender, item) ->
    heroClass = @selectedHero?.get('heroClass') ? 'Warrior'
    gender = ThangTypeLib.getGender @selectedHero
    didAdd = false
    if slot is 'pet'
      imageKeys = ["pet"]
    else if slot is 'gloves'
      if heroClass is 'Ranger'
        imageKeys = ["#{gender}#{heroClass}", "#{gender}#{heroClass}Thumb"]
      else
        imageKeys = ["#{gender}", "#{gender}Thumb"]
    else if heroClass is 'Wizard' and slot is 'torso'
      imageKeys = [gender, "#{gender}Back"]
    else if heroClass is 'Ranger' and slot is 'head' and item.get('original') in ['5441c2be4e9aeb727cc97105', '5441c3144e9aeb727cc97111']
      # All-class headgear like faux fur hat, viking helmet is abusing ranger glove slot
      imageKeys = ["#{gender}Ranger"]
    else
      imageKeys = [gender]
    for imageKey in imageKeys
      imageURL = dollImages[imageKey]
      if not imageURL
        console.log "Hmm, should have #{slot} #{imageKey} paper doll image, but don't have it."
      else
        imageEl = $('<img>').attr('src', "/file/#{imageURL}").addClass("doll-image #{slot} #{heroClass} #{gender} #{_.string.underscored(imageKey).replace(/_/g, '-')}").attr('draggable', false)
        @$el.find('#equipped').append imageEl
        didAdd = true
    didAdd

  destroy: ->
    @$el.find('.unlock-button').popover 'destroy'
    @$el.find('.ui-droppable').droppable 'destroy'
    @$el.find('.ui-draggable').draggable('destroy').off 'dragstart'
    @$el.find('.item-slot').off 'dragstart'
    @stage?.removeAllChildren()
    super()

gear =
  'simple-boots': '53e237bf53457600003e3f05'
  'simple-sword': '53e218d853457600003e3ebe'
  'tarnished-bronze-breastplate': '53e22eac53457600003e3efc'
  'leather-boots': '53e2384453457600003e3f07'
  'leather-belt': '5437002a7beba4a82024a97d'
  'programmaticon-i': '53e4108204c00d4607a89f78'
  'programmaticon-ii': '546e25d99df4a17d0d449be1'
  'crude-glasses': '53e238df53457600003e3f0b'
  'crude-builders-hammer': '53f4e6e3d822c23505b74f42'
  'long-sword': '544d7d1f8494308424f564a3'
  'sundial-wristwatch': '53e2396a53457600003e3f0f'
  'bronze-shield': '544c310ae0017993fce214bf'
  'wooden-glasses': '53e2167653457600003e3eb3'
  'basic-flags': '545bacb41e649a4495f887da'
  'roughedge': '544d7d918494308424f564a7'
  'sharpened-sword': '544d7deb8494308424f564ab'
  'crude-crossbow': '544d7ffd8494308424f564c3'
  'crude-dagger': '544d952b8494308424f56517'
  'weak-charge': '544d957d8494308424f5651f'
  'enchanted-stick': '544d87188494308424f564f1'
  'unholy-tome-i': '546374bc3839c6e02811d308'
  'book-of-life-i': '546375653839c6e02811d30b'
  'rough-sense-stone': '54693140a2b1f53ce79443bc'
  'polished-sense-stone': '53e215a253457600003e3eaf'
  'quartz-sense-stone': '54693240a2b1f53ce79443c5'
  'wooden-builders-hammer': '54694ba3a2b1f53ce794444d'
  'simple-wristwatch': '54693797a2b1f53ce79443e9'

gearSlugs = _.invert gear
