/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__, or convert again using --optional-chaining
 * DS104: Avoid inline assignments
 * DS204: Change includes calls to have a more natural evaluation order
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let InventoryModal;
require('app/styles/play/menu/inventory-modal.sass');
require('app/styles/play/modal/play-items-modal.sass');
const ModalView = require('views/core/ModalView');
const template = require('app/templates/play/menu/inventory-modal');
const buyGemsPromptTemplate = require('app/templates/play/modal/buy-gems-prompt');
const earnGemsPromptTemplate = require('app/templates/play/modal/earn-gems-prompt');
const subscribeForGemsPrompt = require('app/templates/play/modal/subscribe-for-gems-prompt');
const {me} = require('core/auth');
const ThangType = require('models/ThangType');
const ThangTypeLib = require('lib/ThangTypeLib');
const CocoCollection = require('collections/CocoCollection');
const ItemView = require('./ItemView');
const SpriteBuilder = require('lib/sprites/SpriteBuilder');
const ItemDetailsView = require('views/play/modal/ItemDetailsView');
const Purchase = require('models/Purchase');
const BuyGemsModal = require('views/play/modal/BuyGemsModal');
const CreateAccountModal = require('views/core/CreateAccountModal');
const SubscribeModal = require('views/core/SubscribeModal');
require('vendor/scripts/jquery-ui-1.11.1.custom');
require('vendor/styles/jquery-ui-1.11.1.custom.css');
const utils = require('core/utils');

let hasGoneFullScreenOnce = false;
const debugInventory = false;

module.exports = (InventoryModal = (function() {
  InventoryModal = class InventoryModal extends ModalView {
    static initClass() {
      this.prototype.id = 'inventory-modal';
      this.prototype.className = 'modal fade play-modal';
      this.prototype.template = template;
      this.prototype.slots = ['head', 'eyes', 'neck', 'torso', 'wrists', 'gloves', 'left-ring', 'right-ring', 'right-hand', 'left-hand', 'waist', 'feet', 'programming-book', 'pet', 'minion', 'flag'];  //, 'misc-0', 'misc-1']  # TODO: bring in misc slot(s) again when we have space
      this.prototype.ringSlots = ['left-ring', 'right-ring'];
      this.prototype.closesOnClickOutside = false; // because draggable somehow triggers hide when you don't drag onto a draggable
      this.prototype.trapsFocus = false;

      this.prototype.events = {
        'click .item-slot': 'onItemSlotClick',
        'click #unequipped .item': 'onUnequippedItemClick',
        'doubletap #unequipped .item': 'onUnequippedItemDoubleClick',
        'doubletap .item-slot .item': 'onEquippedItemDoubleClick',
        'click button.equip-item': 'onClickEquipItemButton',
        'shown.bs.modal': 'onShown',
        'click #choose-hero-button': 'onClickChooseHero',
        'click #play-level-button': 'onClickPlayLevel',
        'click .unlock-button': 'onUnlockButtonClicked',
        'click #equip-item-viewed': 'onClickEquipItemViewed',
        'click #unequip-item-viewed': 'onClickUnequipItemViewed',
        'click #subscriber-item-viewed': 'onClickSubscribeItemViewed',
        'click #close-modal': 'hide',
        'click .buy-gems-prompt-button': 'onBuyGemsPromptButtonClicked',
        'click .start-subscription-button': 'onSubscribeButtonClicked',
        'click': 'onClickedSomewhere',
        'update #unequipped .nano': 'onScrollUnequipped'
      };

      this.prototype.shortcuts = {
        'esc': 'clearSelection',
        'enter': 'onClickPlayLevel'
      };
    }

    constructor (options) {
      super(...arguments)
      this.supermodel.loadCollection(this.items, 'items')
    }

    //- Setup

    initialize(options) {
      super.initialize(...arguments)
      if (application.getHocCampaign() === 'game-dev-hoc-2') {
        if (!me.get('earned')) {
          me.set('earned', {});
        }
        if (!me.get('earned').items) {
          me.attributes.earned.items = [];
        }
        const baseItems = [
          '53e2384453457600003e3f07', // leather boots
          '53e218d853457600003e3ebe', // simple sword
          '53e22aa153457600003e3ef5', // wooden shield
          '5744e3683af6bf590cd27371' // cougar
        ];
        for (var item of Array.from(baseItems)) {
          var needle;
          if ((needle = item, !Array.from(me.get('earned').items).includes(needle))) {
            me.get('earned').items.push(item); // Allow HoC players to access the cat
          }
        }
      }

      this.onScrollUnequipped = _.throttle(_.bind(this.onScrollUnequipped, this), 200)
      this.items = new CocoCollection([], { model: ThangType })
      // TODO: switch to item store loading system?
      this.items.url = '/db/thang.type?view=items';
      this.items.setProjection([
        'name',
        'slug',
        'components',
        'original',
        'rasterIcon',
        'dollImages',
        'gems',
        'tier',
        'description',
        'heroClass',
        'i18n',
        'subscriber'
      ]);
      this.equipment = {} // Assign for real when we have loaded the session and items.
    }

    onItemsLoaded() {
      let item;
      if (debugInventory) { console.log("Inside onItemsLoaded"); }
      for (item of Array.from(this.items.models)) {
        item.notInLevel = true;
        var programmableConfig = __guard__(_.find(item.get('components'), c => c.config != null ? c.config.programmableProperties : undefined), x => x.config);
        item.programmableProperties = ((programmableConfig != null ? programmableConfig.programmableProperties : undefined) || []).concat((programmableConfig != null ? programmableConfig.moreProgrammableProperties : undefined) || []);
      }
      this.itemsProgrammablePropertiesConfigured = true;
      if (me.isStudent() && !application.getHocCampaign()) {
        this.equipment = __guard__(me.get('heroConfig'), x1 => x1.inventory) || {};
      } else {
        this.equipment = this.options.equipment || __guard__(this.options.session != null ? this.options.session.get('heroConfig') : undefined, x2 => x2.inventory) || __guard__(me.get('heroConfig'), x3 => x3.inventory) || {};
      }
      this.equipment = $.extend(true, {}, this.equipment);
      if (debugInventory) { console.log("requireLevelEquipment called from onItemsLoaded"); }
      this.requireLevelEquipment();
      this.itemGroups = {};
      this.itemGroups.requiredPurchaseItems = new Backbone.Collection();
      this.itemGroups.availableItems = new Backbone.Collection();
      this.itemGroups.restrictedItems = new Backbone.Collection();
      this.itemGroups.lockedItems = new Backbone.Collection();
      this.itemGroups.subscriberItems = new Backbone.Collection();
      for (var itemGroup of Array.from(_.values(this.itemGroups))) { itemGroup.comparator = (function(m) { let left;
      return (left = m.get('tier')) != null ? left : m.get('gems'); }); }

      const equipped = _.values(this.equipment);
      return (() => {
        const result = [];
        for (item of Array.from(this.items.models)) {           result.push(this.sortItem(item, equipped));
        }
        return result;
      })();
    }

    sortItem(item, equipped) {
      let needle, needle1;
      if (debugInventory) { console.log("Inside sortItem"); }
      if (equipped == null) { equipped = _.values(this.equipment); }

      // general starting classes
      item.classes = _.clone(item.getAllowedSlots());
      for (var heroClass of Array.from(item.getAllowedHeroClasses())) {
        item.classes.push(heroClass);
      }
      if ((needle = item.get('original'), Array.from(equipped).includes(needle))) { item.classes.push('equipped'); }

      // sort into one of the five groups
      let locked = !me.ownsItem(item.get('original'));

      const subscriber = (!me.isStudent()) && (!me.isPremium()) && item.get('subscriber');
      const restrictedGear = this.calculateRestrictedGearPerSlot();
      const allRestrictedGear = _.flatten(_.values(restrictedGear));
      const restricted = (needle1 = item.get('original'), Array.from(allRestrictedGear).includes(needle1));

      // TODO: make this re-use result of computation of updateLevelRequiredItems, which we can only do after heroClass is ready...
      let requiredToPurchase = false;
      const inCampaignView = $('#campaign-view').length;
      if ((gearSlugs[item.get('original')] !== 'tarnished-bronze-breastplate') || !inCampaignView || (this.options.level.get('slug') !== 'the-raised-sword')) {
        const requiredGear = this.calculateRequiredGearPerSlot();
        for (var slot of Array.from(item.getAllowedSlots())) {
          var requiredItems;
          if (!(requiredItems = requiredGear[slot])) { continue; }
          if (this.equipment[slot] && !Array.from(allRestrictedGear).includes(this.equipment[slot]) && !Array.from(this.ringSlots).includes(slot)) { continue; }
          // Point out that they must buy it if they haven't bought any of the required items for that slot, and it's the first one.
          if ((item.get('original') === requiredItems[0]) && !_.find(requiredItems, requiredItem => me.ownsItem(requiredItem))) {
            requiredToPurchase = true;
            break;
          }
        }
      }

      if (requiredToPurchase && locked && !item.get('gems')) {
        // Either one of two things has happened:
        // 1. There's a bug and the player doesn't have a required item they should have.
        // 2. The player is trying to play a level they haven't unlocked.
        // We'll just pretend they own it so that they don't get stuck.
        if (application.tracker != null) {
          application.tracker.trackEvent('Required Item Locked', {level: this.options.level.get('slug'), label: this.options.level.get('slug'), item: item.get('name'), playerLevel: me.level(), levelUnlocked: me.ownsLevel(this.options.level.get('original'))});
        }
        locked = false;
      }

      const placeholder = !item.getFrontFacingStats().props.length && !_.size(item.getFrontFacingStats().stats);

      if (placeholder && locked) {  // The item is not complete, so don't put it into a collection.
        null;
      } else if (locked && requiredToPurchase) {
        item.classes.push('locked');
        this.itemGroups.requiredPurchaseItems.add(item);
      } else if (locked) {
        item.classes.push('locked');
        if (item.isSilhouettedItem() || !item.get('gems')) {
          // Don't even load/show these--don't add to a collection. (Bandwidth optimization.)
          null;
        } else {
          this.itemGroups.lockedItems.add(item);
        }
      } else if (restricted) {
        this.itemGroups.restrictedItems.add(item);
        item.classes.push('restricted');
      } else if (subscriber && !application.getHocCampaign()) { // allow HoC players to equip pets
        this.itemGroups.subscriberItems.add(item);
        item.classes.push('subscriber');
      } else {
        this.itemGroups.availableItems.add(item);
      }

      // level to unlock
      if (item.get('tier') != null) { return item.level = item.levelRequiredForItem(); }
    }

    onLoaded() {
      if (debugInventory) { console.log("Inside onLoaded"); }
      // Both items and session have been loaded.
      this.onItemsLoaded();
      return super.onLoaded();
    }

    getRenderData(context) {
      if (context == null) { context = {}; }
      if (debugInventory) { console.log("Inside getRenderData"); }
      context = super.getRenderData(context);
      context.equipped = _.values(this.equipment);
      context.items = this.items.models;
      context.itemGroups = this.itemGroups;
      context.slots = this.slots;
      context.selectedHero = this.selectedHero;
      context.selectedHeroClass = this.selectedHero != null ? this.selectedHero.get('heroClass') : undefined;
      context.equipment = _.clone(this.equipment);
      for (var slot in context.equipment) { var itemOriginal = context.equipment[slot]; context.equipment[slot] = this.items.findWhere({original: itemOriginal}); }
      context.gems = me.gems();
      return context;
    }

    afterRender() {
      if (debugInventory) { console.log("Inside afterRender"); }
      super.afterRender();
      this.$el.find('#play-level-button').css('visibility', 'hidden');
      if (!this.supermodel.finished()) { return; }
      this.$el.find('#play-level-button').css('visibility', 'visible');

      this.setUpDraggableEventsForAvailableEquipment();
      this.setUpDraggableEventsForEquippedArea();
      this.delegateEvents();
      this.itemDetailsView = new ItemDetailsView();
      this.insertSubView(this.itemDetailsView);
      if (debugInventory) { console.log("requireLevelEquipment called from afterRender"); }
      this.requireLevelEquipment();
      this.$el.find('.nano').nanoScroller({alwaysVisible: true});
      this.onSelectionChanged();
      return this.onEquipmentChanged();
    }

    afterInsert() {
      if (debugInventory) { console.log("Inside afterInsert"); }
      super.afterInsert();
      this.canvasWidth = this.$el.find('canvas').innerWidth();
      this.canvasHeight = this.$el.find('canvas').innerHeight();
      this.inserted = true;
      if (debugInventory) { console.log("requireLevelEquipment called from afterInsert"); }
      return this.requireLevelEquipment();
    }

    //- Draggable logic

    setUpDraggableEventsForAvailableEquipment() {
      if (debugInventory) { console.log("Inside setUpDraggableEventForAvailableEquipment"); }
      return (() => {
        const result = [];
        for (var availableItemEl of Array.from(this.$el.find('#unequipped .item'))) {
          availableItemEl = $(availableItemEl);
          if (availableItemEl.hasClass('locked') || availableItemEl.hasClass('restricted')) { continue; }
          var dragHelper = availableItemEl.clone().addClass('draggable-item');
          result.push(((dragHelper, availableItemEl) => {
            availableItemEl.draggable({
              revert: 'invalid',
              appendTo: this.$el,
              cursorAt: {left: 35.5, top: 35.5},
              helper() { return dragHelper; },
              revertDuration: 200,
              distance: 10,
              scroll: false,
              zIndex: 1100
            });
            return availableItemEl.on('dragstart', () => this.selectUnequippedItem(availableItemEl));
          })(dragHelper, availableItemEl));
        }
        return result;
      })();
    }

    setUpDraggableEventsForEquippedArea() {
      if (debugInventory) { console.log("Inside setUpDraggableEventsForEquippedArea"); }
      for (var itemSlot of Array.from(this.$el.find('.item-slot'))) {
        var slot = $(itemSlot).data('slot');
        ((slot, itemSlot) => {
          $(itemSlot).droppable({
            drop: (e, ui) => this.equipSelectedItem(),
            accept(el) { return $(el).parent().hasClass(slot); },
            activeClass: 'droppable',
            hoverClass: 'droppable-hover',
            tolerance: 'touch'
          });
          return this.makeEquippedSlotDraggable($(itemSlot));
        })(slot, itemSlot);
      }

      return this.$el.find('#equipped').droppable({
        drop: (e, ui) => this.equipSelectedItem(),
        accept(el) { return true; },
        activeClass: 'droppable',
        hoverClass: 'droppable-hover',
        tolerance: 'pointer'
      });
    }

    makeEquippedSlotDraggable(slot) {
      if (debugInventory) { console.log("Inside makeEquippedSlotDraggable"); }
      const unequip = () => {
        const itemEl = this.unequipItemFromSlot(slot);
        const selectedSlotItemID = itemEl.data('item-id');
        const item = this.items.get(selectedSlotItemID);
        this.requireLevelEquipment();
        this.showItemDetails(item, 'equip');
        this.onSelectionChanged();
        return this.onEquipmentChanged();
      };
      const shouldStayEquippedWhenDropped = function(isValidDrop) {
        const pos = $(this).position();
        const revert = (Math.abs(pos.left) < $(this).outerWidth()) && (Math.abs(pos.top) < $(this).outerHeight());
        if (!revert) { unequip(); }
        return revert;
      };
      // TODO: figure out how to make this actually above the available items list (the .ui-draggable-helper img is still inside .item-view and so underlaps...)
      $(slot).find('img').draggable({
        revert: shouldStayEquippedWhenDropped,
        appendTo: this.$el,
        cursorAt: {left: 35.5, top: 35.5},
        revertDuration: 200,
        distance: 10,
        scroll: false,
        zIndex: 100
      });
      return slot.on('dragstart', () => this.selectItemSlot(slot));
    }


    //- Select/equip event handlers

    onItemSlotClick(e) {
      this.closePopover();
      if (this.remainingRequiredEquipment != null ? this.remainingRequiredEquipment.length : undefined) { return; }  // Don't let them select a slot if we need them to first equip some require gear.
      //@playSound 'menu-button-click'
      return this.selectItemSlot($(e.target).closest('.item-slot'));
    }

    onUnequippedItemClick(e) {
      this.closePopover();
      if (this.justDoubleClicked) { return; }
      if (this.justClickedEquipItemButton) { return; }
      const itemEl = $(e.target).closest('.item');
      //@playSound 'menu-button-click'
      return this.selectUnequippedItem(itemEl);
    }

    onUnequippedItemDoubleClick(e) {
      const itemEl = $(e.target).closest('.item');
      if (itemEl.hasClass('locked') || itemEl.hasClass('restricted') || itemEl.hasClass('subscriber')) { return; }
      this.equipSelectedItem();
      this.justDoubleClicked = true;
      return _.defer(() => { return this.justDoubleClicked = false; });
    }

    onEquippedItemDoubleClick() { return this.unequipSelectedItem(); }
    onClickEquipItemViewed() { return this.equipSelectedItem(); }
    onClickUnequipItemViewed() { return this.unequipSelectedItem(); }

    onClickEquipItemButton(e) {
      this.playSound('menu-button-click');
      const itemEl = $(e.target).closest('.item');
      this.selectUnequippedItem(itemEl);
      this.equipSelectedItem();
      this.justClickedEquipItemButton = true;
      return _.defer(() => { return this.justClickedEquipItemButton = false; });
    }

    onClickSubscribeItemViewed(e) {
      this.openModalView(new SubscribeModal());
      const itemElem = this.$el.find('.item.active');
      const item = this.items.get(itemElem != null ? itemElem.data('item-id') : undefined);
      return (window.tracker != null ? window.tracker.trackEvent('Show subscription modal', {category: 'Subscription', label: 'inventory modal: ' + ((item != null ? item.get('slug') : undefined) || 'unknown')}) : undefined);
    }

    //- Select/equip higher-level, all encompassing methods the callbacks all use

    selectItemSlot(slotEl) {
      this.clearSelection();
      slotEl.addClass('selected');
      const selectedSlotItemID = slotEl.find('.item').data('item-id');
      const item = this.items.get(selectedSlotItemID);
      if (item) { this.showItemDetails(item, 'unequip'); }
      return this.onSelectionChanged();
    }

    selectUnequippedItem(itemEl) {
      this.clearSelection();
      itemEl.addClass('active');
      const showExtra = itemEl.hasClass('restricted') ? 'restricted' : itemEl.hasClass('subscriber') ? 'subscriber' : !itemEl.hasClass('locked') ? 'equip' : '';
      this.showItemDetails(this.items.get(itemEl.data('item-id')), showExtra);
      return this.onSelectionChanged();
    }

    equipSelectedItem() {
      let slotEl, unequippedSlot;
      const selectedItemEl = this.getSelectedUnequippedItem();
      const selectedItem = this.items.get(selectedItemEl.data('item-id'));
      if (!selectedItem) { return; }
      const allowedSlots = selectedItem.getAllowedSlots();
      let firstSlot = (unequippedSlot = null);
      for (var allowedSlot of Array.from(allowedSlots)) {
        slotEl = this.$el.find(`.item-slot[data-slot='${allowedSlot}']`);
        if (firstSlot == null) { firstSlot = slotEl; }
        if (!slotEl.find('img').length) { if (unequippedSlot == null) { unequippedSlot = slotEl; } }
      }
      slotEl = unequippedSlot != null ? unequippedSlot : firstSlot;
      selectedItemEl.effect('transfer', {to: slotEl, duration: 500, easing: 'easeOutCubic'});
      const unequipped = this.unequipItemFromSlot(slotEl);
      selectedItemEl.addClass('equipped');
      slotEl.append(selectedItemEl.find('img').clone().addClass('item').data('item-id', selectedItem.id));
      this.clearSelection();
      this.showItemDetails(selectedItem, 'unequip');
      slotEl.addClass('selected');
      selectedItem.classes.push('equipped');
      this.makeEquippedSlotDraggable(slotEl);
      this.requireLevelEquipment();
      this.onSelectionChanged();
      return this.onEquipmentChanged();
    }

    unequipSelectedItem() {
      const slotEl = this.getSelectedSlot();
      this.clearSelection();
      const itemEl = this.unequipItemFromSlot(slotEl);
      if (!(itemEl != null ? itemEl.length : undefined)) { return; }
      itemEl.addClass('active');
      slotEl.effect('transfer', {to: itemEl, duration: 500, easing: 'easeOutCubic'});
      const selectedSlotItemID = itemEl.data('item-id');
      const item = this.items.get(selectedSlotItemID);
      item.classes = _.without(item.classes, 'equipped');
      this.showItemDetails(item, 'equip');
      this.requireLevelEquipment();
      this.onSelectionChanged();
      return this.onEquipmentChanged();
    }

    //- Select/equip helpers

    clearSelection() {
      this.deselectAllSlots();
      this.deselectAllUnequippedItems();
      return this.hideItemDetails();
    }

    unequipItemFromSlot(slotEl) {
      const itemEl = slotEl.find('.item');
      const itemIDToUnequip = itemEl.data('item-id');
      if (!itemIDToUnequip) { return; }
      itemEl.remove();
      const item = this.items.get(itemIDToUnequip);
      item.classes = _.without(item.classes, 'equipped');
      return this.$el.find(`#unequipped .item[data-item-id=${itemIDToUnequip}]`).removeClass('equipped');
    }

    deselectAllSlots() {
      return this.$el.find('#equipped .item-slot.selected').removeClass('selected');
    }

    deselectAllUnequippedItems() {
      return this.$el.find('#unequipped .item').removeClass('active');
    }

    getSlot(name) {
      return this.$el.find(`.item-slot[data-slot=${name}]`);
    }

    getSelectedSlot() {
      return this.$el.find('#equipped .item-slot.selected');
    }

    getSelectedUnequippedItem() {
      return this.$el.find('#unequipped .item.active');
    }

    onSelectionChanged() {
      const heroClass = this.selectedHero != null ? this.selectedHero.get('heroClass') : undefined;
      const itemsCanBeEquipped = this.$el.find('#unequipped .item.available:not(.equipped)').filter('.'+heroClass).length;
      const toShow = this.$el.find('#double-click-hint, #available-description');
      if (itemsCanBeEquipped) { toShow.removeClass('secret'); } else { toShow.addClass('secret'); }
      return this.delegateEvents();
    }


    showItemDetails(item, showExtra) {
      this.itemDetailsView.setItem(item);
      this.$el.find('#item-details-extra > *').addClass('secret');
      return this.$el.find(`#${showExtra}-item-viewed`).removeClass('secret');
    }

    hideItemDetails() {
      if (this.itemDetailsView != null) {
        this.itemDetailsView.setItem(null);
      }
      return this.$el.find('#item-details-extra > *').addClass('secret');
    }

    getCurrentEquipmentConfig() {
      const config = {};
      for (var slot of Array.from(this.$el.find('.item-slot'))) {
        var slotName = $(slot).data('slot');
        var slotItemID = $(slot).find('.item').data('item-id');
        if (!slotItemID) { continue; }
        var item = _.find(this.items.models, {id:slotItemID});
        config[slotName] = item.get('original');
      }
      return config;
    }

    requireLevelEquipment() {
      if (debugInventory) { console.log("Inside requireLevelEquipment"); }
      if (debugInventory) { console.log(this.items); }
      // This is called frequently to make sure the player isn't using any restricted items and knows she must equip any required items.
      if (!this.inserted || !this.itemsProgrammablePropertiesConfigured) { return; }
      const equipment = this.supermodel.finished() ? this.getCurrentEquipmentConfig() : this.equipment;  // Make sure we're using latest equipment.
      const hadRequired = this.remainingRequiredEquipment != null ? this.remainingRequiredEquipment.length : undefined;
      this.remainingRequiredEquipment = [];
      this.$el.find('.should-equip').removeClass('should-equip');
      this.unequipClassRestrictedItems(equipment);
      this.unequipLevelRestrictedItems(equipment);
      this.updateLevelRequiredItems(equipment);
      if (debugInventory) { console.log("@remainingRequiredEquipment.length: " + this.remainingRequiredEquipment.length); }
      if (hadRequired && !this.remainingRequiredEquipment.length) {
        this.endHighlight();
        this.highlightElement('#play-level-button', {duration: 5000});
      }
      return $('#play-level-button').prop('disabled', this.remainingRequiredEquipment.length > 0);
    }

    unequipClassRestrictedItems(equipment) {
      let heroClass;
      if (debugInventory) { console.log("Inside unequipClassRestrictedItems"); }
      if (!this.supermodel.finished() || !(heroClass = this.selectedHero != null ? this.selectedHero.get('heroClass') : undefined)) { return; }
      return (() => {
        const result = [];
        const object = _.clone(equipment);
        for (var slot in object) {
          var item = object[slot];
          var itemModel = this.items.findWhere({original: item});
          if (!itemModel || !Array.from(itemModel.classes).includes(heroClass)) {
            if (debugInventory) { console.log('Unequipping', itemModel.get('heroClass'), 'item', itemModel.get('name'), 'from slot due to class restrictions.'); }
            this.unequipItemFromSlot(this.$el.find(`.item-slot[data-slot='${slot}']`));
            result.push(delete equipment[slot]);
          } else {
            result.push(undefined);
          }
        }
        return result;
      })();
    }

    calculateRequiredGearPerSlot() {
      let left, left1, left2;
      if (me.isStudent() && !application.getHocCampaign() && !me.showGearRestrictionsInClassroom()) { return {}; }
      if (this.requiredGearPerSlot) { return this.requiredGearPerSlot; }
      const requiredGear = (left = _.clone(this.options.level.get('requiredGear'))) != null ? left : {};
      const requiredProperties = (left1 = this.options.level.get('requiredProperties')) != null ? left1 : [];
      const restrictedProperties = (left2 = this.options.level.get('restrictedProperties')) != null ? left2 : [];
      const requiredPropertiesPerSlot = {};
      for (var item of Array.from(this.items.models)) {
        var requiredPropertiesOnThisItem = _.intersection(item.programmableProperties, requiredProperties);
        var restrictedPropertiesOnThisItem = _.intersection(item.programmableProperties, restrictedProperties);
        if (!requiredPropertiesOnThisItem.length || !!restrictedPropertiesOnThisItem.length) { continue; }
        for (var slot of Array.from(item.getAllowedSlots())) {
          var needle;
          var requiredPropertiesNotOnThisItem = _.without(requiredPropertiesPerSlot[slot] != null ? requiredPropertiesPerSlot[slot] : [], ...Array.from(item.programmableProperties));
          if ((slot !== 'right-hand') && _.isEqual(requiredPropertiesOnThisItem, ['buildXY'])) { continue; }  // Don't require things like caltrops belt
          if (requiredPropertiesNotOnThisItem.length) { continue; }
          if (requiredGear[slot] == null) { requiredGear[slot] = []; }
          if ((needle = item.get('original'), !Array.from(requiredGear[slot]).includes(needle))) { requiredGear[slot].push(item.get('original')); }
          if (requiredPropertiesPerSlot[slot] == null) { requiredPropertiesPerSlot[slot] = []; }
          for (var prop of Array.from(requiredPropertiesOnThisItem)) { if (!Array.from(requiredPropertiesPerSlot[slot]).includes(prop)) { requiredPropertiesPerSlot[slot].push(prop); } }
          if (debugInventory) { console.log(slot, 'has required item', item, 'because restrictedPropertiesOnThisItem is', restrictedPropertiesOnThisItem, 'and requiredPropertiesOnThisItem is', requiredPropertiesOnThisItem); }
        }
      }
      this.requiredPropertiesPerSlot = requiredPropertiesPerSlot;
      this.requiredGearPerSlot = requiredGear;
      return this.requiredGearPerSlot;
    }

    calculateRestrictedGearPerSlot() {
      let left, left1;
      if (me.isStudent() && !application.getHocCampaign() && !me.showGearRestrictionsInClassroom()) { return {}; }
      if (this.restrictedGearPerSlot) { return this.restrictedGearPerSlot; }
      if (!this.requiredGearPerSlot) { this.calculateRequiredGearPerSlot(); }
      const restrictedGear = (left = _.clone(this.options.level.get('restrictedGear'))) != null ? left : {};
      const restrictedProperties = (left1 = this.options.level.get('restrictedProperties')) != null ? left1 : [];
      for (var item of Array.from(this.items.models)) {
        var restrictedPropertiesOnThisItem = _.intersection(item.programmableProperties, restrictedProperties);
        for (var slot of Array.from(item.getAllowedSlots())) {
          var needle;
          var requiredPropertiesNotOnThisItem = _.without(this.requiredPropertiesPerSlot[slot], ...Array.from(item.programmableProperties));
          // Let Rangers/Wizards use class specific weapon in 'cleave' levelsm, if it's not restricted
          if (Array.from(requiredPropertiesNotOnThisItem).includes('cleave') && (needle = 'Warrior', !Array.from(item.getAllowedHeroClasses()).includes(needle)) && !restrictedPropertiesOnThisItem.length) { continue; }
          if (restrictedPropertiesOnThisItem.length || requiredPropertiesNotOnThisItem.length) {
            var needle1;
            if (restrictedGear[slot] == null) { restrictedGear[slot] = []; }
            if ((needle1 = item.get('original'), !Array.from(restrictedGear[slot]).includes(needle1))) { restrictedGear[slot].push(item.get('original')); }
            if (debugInventory) { console.log(slot, 'has restricted item', item, 'because restrictedPropertiesOnThisItem is', restrictedPropertiesOnThisItem, 'and requiredPropertiesNotOnThisItem is', requiredPropertiesNotOnThisItem); }
          }
        }
      }
      this.restrictedGearPerSlot = restrictedGear;
      return this.restrictedGearPerSlot;
    }

    unequipLevelRestrictedItems(equipment) {
      if (debugInventory) { console.log("Inside unequipLevelRestrictedItems"); }
      const restrictedGear = this.calculateRestrictedGearPerSlot();
      for (var slot in restrictedGear) {
        var items = restrictedGear[slot];
        for (var item of Array.from(items)) {
          var equipped = equipment[slot];
          if (equipped && (equipped === item)) {
            if (debugInventory) { console.log('Unequipping restricted item', equipped, 'for', slot, 'before level', this.options.level.get('slug')); }
            this.unequipItemFromSlot(this.$el.find(`.item-slot[data-slot='${slot}']`));
            delete equipment[slot];
          }
        }
      }
      return null;
    }

    updateLevelRequiredItems(equipment) {
      let heroClass;
      let item;
      if (debugInventory) { console.log("inside updateLevelRequiredItems"); }
      if (!(heroClass = this.selectedHero != null ? this.selectedHero.get('heroClass') : undefined)) { return; }
      const requiredGear = this.calculateRequiredGearPerSlot();
      if (debugInventory) { console.log("inside executtion of updateLevelRequiredItems"); }
      for (var slot in requiredGear) {
        var items = requiredGear[slot];
        if (items.length) {var left1;
        var itemOffsetTop, validSlots;

          if (Array.from(this.ringSlots).includes(slot)) {
            validSlots = this.ringSlots;
          } else {
            validSlots = [slot];
          }

          if (validSlots.some(function(slot) {
            const equipped = equipment[slot];
            return Array.from(items).includes(equipped);
          })) { continue; }

          // Actually, just let them play if they have equipped anything in that slot (and we haven't unequipped it due to restrictions).
          // Rings often have unique effects, so this rule does not apply to them (they are still required even if there is a non-restricted ring equipped in the slot).
          if (equipment[slot] && !Array.from(this.ringSlots).includes(slot)) { continue; }

          items = ((() => {
            const result = [];
            for (item of Array.from(items)) {               var left, needle;
            if ((needle = heroClass, Array.from(((left = __guard__(this.items.findWhere({original: item}), x => x.classes)) != null ? left : [])).includes(needle))) {
                result.push(item);
              }
            }
            return result;
          })());
          if (!items.length) { continue; }  // If the required items are for another class, then let's not be finicky.

          // We will point out the last (best) element that they own and can use, otherwise the first (cheapest).
          items = _.sortBy(items, item => (left1 = this.items.findWhere({original: item}).get('tier')) != null ? left1 : 9001);
          var bestOwnedItem = _.findLast(items, item => me.ownsItem(item));
          item = bestOwnedItem != null ? bestOwnedItem : items[0];

          // For the Tarnished Bronze Breastplate only, don't tell them they need it until they need it in the level, so we can show how to buy it.
          var slug = gearSlugs[item];
          var inCampaignView = $('#campaign-view').length;
          if ((slug === 'tarnished-bronze-breastplate') && inCampaignView && (this.options.level.get('slug') === 'the-raised-sword')) { continue; }

          // Now we're definitely requiring and pointing out an item.
          var itemModel = this.items.findWhere({original: item});
          var availableSlotSelector = `#unequipped .item[data-item-id='${itemModel.id}']`;
          this.highlightElement(availableSlotSelector, {delay: 500, sides: ['right'], rotation: Math.PI / 2});
          var $itemEl = this.$el.find(availableSlotSelector).addClass('should-equip');
          this.$el.find(`#equipped div[data-slot='${slot}']`).addClass('should-equip');
          if (itemOffsetTop = $itemEl[0] != null ? $itemEl[0].offsetTop : undefined) {
            var itemOffsetBottom = itemOffsetTop + $itemEl.outerHeight(true);
            var parentHeight = $itemEl.parent().height();
            if (itemOffsetBottom > ($itemEl.parent().scrollTop() + parentHeight)) {
              $itemEl.parent().scrollTop(itemOffsetBottom - parentHeight);
            } else if (itemOffsetTop < $itemEl.parent().scrollTop()) {
              $itemEl.parent().scrollTop(itemOffsetTop);
            }
          }
          this.remainingRequiredEquipment.push({slot, item});
        }
      }
      return null;
    }

    setHero(selectedHero) {
      this.selectedHero = selectedHero;
      if (this.selectedHero.loading) {
        this.listenToOnce(this.selectedHero, 'sync', () => (typeof this.setHero === 'function' ? this.setHero(this.selectedHero) : undefined));
        return;
      }
      this.$el.removeClass('Warrior Ranger Wizard').addClass(this.selectedHero.get('heroClass'));
      this.requireLevelEquipment();
      this.render();
      return this.onEquipmentChanged();
    }

    onShown() {
      // Called when we switch tabs to this within the modal
      return this.requireLevelEquipment();
    }

    onHidden() {
      // Called when the modal itself is dismissed
      this.endHighlight();
      super.onHidden();
      return this.playSound('game-menu-close');
    }

    onClickChooseHero() {
      this.playSound('menu-button-click');
      this.hide();
      return this.trigger('choose-hero-click');
    }

    onClickPlayLevel(e) {
      if (this.$el.find('#play-level-button').prop('disabled')) { return; }
      const levelSlug = this.options.level.get('slug');
      this.playSound('menu-button-click');
      this.showLoading();
      const ua = navigator.userAgent.toLowerCase();
      const isSafari = /safari/.test(ua) && !/chrome/.test(ua);
      const isTooShort = $(window).height() < 658;  // Min vertical resolution needed at 1366px wide
      if (isTooShort && !me.isAdmin() && !hasGoneFullScreenOnce && !isSafari) {
        this.toggleFullscreen();
        hasGoneFullScreenOnce = true;
      }
      this.updateConfig(() => {
        return (typeof this.trigger === 'function' ? this.trigger('play-click') : undefined);
      });
      return (window.tracker != null ? window.tracker.trackEvent('Inventory Play', {category: 'Play Level', level: levelSlug}) : undefined);
    }

    updateConfig(callback, skipSessionSave) {
      let hero, left, left1, patchMe;
      if (debugInventory) { console.log("Inside updateConfig"); }
      const sessionHeroConfig = (left = this.options.session.get('heroConfig')) != null ? left : {};
      const lastHeroConfig = (left1 = me.get('heroConfig')) != null ? left1 : {};
      const inventory = this.getCurrentEquipmentConfig();
      let patchSession = (patchMe = false);
      if (!patchSession) { patchSession = !_.isEqual(inventory, sessionHeroConfig.inventory); }
      sessionHeroConfig.inventory = inventory;
      if (hero = this.selectedHero != null ? this.selectedHero.get('original') : undefined) {
        if (!patchSession) { patchSession = !_.isEqual(hero, sessionHeroConfig.thangType); }
        sessionHeroConfig.thangType = hero;
      }
      if (!patchMe) { patchMe = !_.isEqual(inventory, lastHeroConfig.inventory); }
      lastHeroConfig.inventory = inventory;
      if (patchMe) {
        if (debugInventory) { console.log('Inventory Modal: setting me.heroConfig to', JSON.stringify(lastHeroConfig)); }
        me.set('heroConfig', lastHeroConfig);
        me.patch();
      }
      if (patchSession) {
        if (debugInventory) { console.log('Inventory Modal: setting session.heroConfig to', JSON.stringify(sessionHeroConfig)); }
        this.options.session.set('heroConfig', sessionHeroConfig);
        if (!skipSessionSave) { return this.options.session.patch({success: callback}); }
      } else {
        return (typeof callback === 'function' ? callback() : undefined);
      }
    }

    //- TODO: DRY this between PlayItemsModal and InventoryModal and PlayHeroesModal

    onUnlockButtonClicked(e) {
      e.stopPropagation();
      const button = $(e.target).closest('button');
      const item = this.items.get(button.data('item-id'));
      const {
        affordable
      } = item;
      if (!affordable) {
        this.playSound('menu-button-click');
        if (!me.freeOnly() && !application.getHocCampaign()) { return this.askToBuyGemsOrSubscribe(button); }
      } else if (button.hasClass('confirm')) {
        let left, left1;
        this.playSound('menu-button-unlock-end');
        const purchase = Purchase.makeFor(item);
        purchase.save();

        //- set local changes to mimic what should happen on the server...
        const purchased = (left = me.get('purchased')) != null ? left : {};
        if (purchased.items == null) { purchased.items = []; }
        purchased.items.push(item.get('original'));

        me.set('purchased', purchased);
        me.set('spent', ((left1 = me.get('spent')) != null ? left1 : 0) + item.get('gems'));
        //- ...then rerender key bits
        this.itemGroups.lockedItems.remove(item);
        this.itemGroups.requiredPurchaseItems.remove(item);
        // Redo all item sorting to make sure that we don't clobber state changes since last render.
        const equipped = _.values(this.getCurrentEquipmentConfig());
        for (var otherItem of Array.from(this.items.models)) { this.sortItem(otherItem, equipped); }
        this.renderSelectors('#unequipped', '#gems-count');

        this.requireLevelEquipment();
        this.delegateEvents();
        this.setUpDraggableEventsForAvailableEquipment();
        this.itemDetailsView.setItem(item);
        this.onScrollUnequipped(true);
        if (!me.isStudent()) {
          return Backbone.Mediator.publish('store:item-purchased', {item, itemSlug: item.get('slug')});
        }
      } else {
        this.playSound('menu-button-unlock-start');
        button.addClass('confirm').text($.i18n.t('play.confirm'));
        return this.$el.one('click', function(e) {
          if (e.target !== button[0]) { return button.removeClass('confirm').text($.i18n.t('play.unlock')); }
      });
      }
    }

    askToSignUp() {
      const createAccountModal = new CreateAccountModal({supermodel: this.supermodel});
      return this.openModalView(createAccountModal);
    }

    askToBuyGemsOrSubscribe(unlockButton) {
      let popoverTemplate;
      this.$el.find('.unlock-button').popover('destroy');
      if (me.isStudent()) {
        popoverTemplate = earnGemsPromptTemplate({});
      } else if (me.canBuyGems()) {
        popoverTemplate = buyGemsPromptTemplate({});
      } else {
        if (!me.hasSubscription()) { // user does not have subscription ask him to subscribe to get more gems, china infra does not have 'buy gems' option
          popoverTemplate = subscribeForGemsPrompt({});
        } else { // user has subscription and yet not enough gems, just ask him to keep playing for more gems
          popoverTemplate = earnGemsPromptTemplate({});
        }
      }

      unlockButton.popover({
        animation: true,
        trigger: 'manual',
        placement: 'top',
        content: ' ',  // template has it
        container: this.$el,
        template: popoverTemplate
      }).popover('show');
      const popover = unlockButton.data('bs.popover');
      __guard__(popover != null ? popover.$tip : undefined, x => x.i18n());
      return this.applyRTLIfNeeded();
    }

    onBuyGemsPromptButtonClicked(e) {
      this.playSound('menu-button-click');
      if (me.get('anonymous')) { return this.askToSignUp(); }
      return this.openModalView(new BuyGemsModal());
    }

    onSubscribeButtonClicked(e) {
      this.openModalView(new SubscribeModal());
      return (window.tracker != null ? window.tracker.trackEvent('Show subscription modal', {category: 'Subscription', label: 'hero subscribe modal: ' + ($(e.target).data('heroSlug') || 'unknown')}) : undefined);
    }

    onClickedSomewhere(e) {
      return this.closePopover();
    }

    closePopover() {
      if (this.destroyed) { return; }
      return this.$el.find('.unlock-button').popover('destroy');
    }

    //- Dynamic portrait loading

    onScrollUnequipped(forceLoadAll) {
      // dynamically load visible items when the user scrolls enough to see them
      if (forceLoadAll == null) { forceLoadAll = false; }
      if (this.destroyed) { return; }
      const nanoContent = this.$el.find('#unequipped .nano-content');
      const items = nanoContent.find('.item:visible:not(.loaded)');
      const threshold = nanoContent.height() + 100;
      return (() => {
        const result = [];
        for (var itemEl of Array.from(items)) {
          itemEl = $(itemEl);
          if ((itemEl.position().top < threshold) || forceLoadAll) {
            itemEl.addClass('loaded');
            var item = this.items.get(itemEl.data('item-id'));
            result.push(itemEl.find('img').attr('src', item.getPortraitURL()));
          } else {
            result.push(undefined);
          }
        }
        return result;
      })();
    }


    //- Paper doll equipment updating
    onEquipmentChanged() {
      let heroSlug, left;
      const heroClass = (left = (this.selectedHero != null ? this.selectedHero.get('heroClass') : undefined)) != null ? left : 'Warrior';
      if (utils.isCodeCombat) {
        let left1;
        heroSlug = (left1 = (this.selectedHero != null ? this.selectedHero.get('slug') : undefined)) != null ? left1 : '';
      }
      const gender = ThangTypeLib.getGender(this.selectedHero);
      if (utils.isCodeCombat) {
        this.$el.find('#hero-image, #hero-image-hair, #hero-image-head, #hero-image-thumb').removeClass().addClass(`${gender} ${heroClass} ${heroSlug}`);
      } else {
        this.$el.find('#hero-image, #hero-image-hair, #hero-image-head, #hero-image-thumb').removeClass().addClass(`${gender} ${heroClass}`);
      }
      const equipment = this.getCurrentEquipmentConfig();
      this.onScrollUnequipped();
      if (!_.size(equipment) || !this.supermodel.finished()) { return; }
      this.removeDollImages();
      const slotsWithImages = [];
      for (var slot in equipment) {
        var dollImages;
        var original = equipment[slot];
        var item = _.find(this.items.models, item => item.get('original') === original);
        if (!(dollImages = item != null ? item.get('dollImages') : undefined)) { continue; }
        var didAdd = this.addDollImage(slot, dollImages, heroClass, gender, item);
        if (item.get('original') !== '54ea39342b7506e891ca70f2') { if (didAdd) { slotsWithImages.push(slot); } }
      }  // Circlet of the Magi needs hair under it
      this.$el.find('#hero-image-hair').toggle(!(Array.from(slotsWithImages).includes('head')));
      this.$el.find('#hero-image-thumb').toggle(!(Array.from(slotsWithImages).includes('gloves')));

      this.equipment = (this.options.equipment = equipment);
      if (me.isStudent() && !application.getHocCampaign()) { return this.updateConfig((function() {  }), true); }  // Save the player's heroConfig if they're a student, whenever they change gear.
    }

    removeDollImages() {
      return this.$el.find('.doll-image').remove();
    }

    addDollImage(slot, dollImages, heroClass, gender, item) {
      let heroSlug, imageKeys, left, needle;
      heroClass = (left = (this.selectedHero != null ? this.selectedHero.get('heroClass') : undefined)) != null ? left : 'Warrior';
      if (utils.isCodeCombat) {
        let left1;
        heroSlug = (left1 = (this.selectedHero != null ? this.selectedHero.get('slug') : undefined)) != null ? left1 : '';
      }
      gender = ThangTypeLib.getGender(this.selectedHero);
      let didAdd = false;
      if (slot === 'pet') {
        imageKeys = ["pet"];
      } else if (slot === 'gloves') {
        if (heroClass === 'Ranger') {
          imageKeys = [`${gender}${heroClass}`, `${gender}${heroClass}Thumb`];
        } else {
          imageKeys = [`${gender}`, `${gender}Thumb`];
        }
      } else if ((heroClass === 'Wizard') && (slot === 'torso')) {
        imageKeys = [gender, `${gender}Back`];
      } else if ((heroClass === 'Ranger') && (slot === 'head') && (needle = item.get('original'), ['5441c2be4e9aeb727cc97105', '5441c3144e9aeb727cc97111'].includes(needle))) {
        // All-class headgear like faux fur hat, viking helmet is abusing ranger glove slot
        imageKeys = [`${gender}Ranger`];
      } else {
        imageKeys = [gender];
      }
      for (var imageKey of Array.from(imageKeys)) {
        var imageURL = dollImages[imageKey];
        if (!imageURL) {
          console.log(`Hmm, should have ${slot} ${imageKey} paper doll image, but don't have it.`);
        } else {
          var imageEl;
          if (utils.isCodeCombat) {
            imageEl = $('<img>').attr('src', `/file/${imageURL}`).addClass(`doll-image ${slot} ${heroClass} ${heroSlug} ${gender} ${_.string.underscored(imageKey).replace(/_/g, '-')}`).attr('draggable', false);
          } else {
            imageEl = $('<img>').attr('src', `/file/${imageURL}`).addClass(`doll-image ${slot} ${heroClass} ${gender} ${_.string.underscored(imageKey).replace(/_/g, '-')}`).attr('draggable', false);
          }
          this.$el.find('#equipped').append(imageEl);
          didAdd = true;
        }
      }
      return didAdd;
    }

    destroy() {
      this.$el.find('.unlock-button').popover('destroy');
      this.$el.find('.ui-droppable').droppable('destroy');
      this.$el.find('.ui-draggable').draggable('destroy').off('dragstart');
      this.$el.find('.item-slot').off('dragstart');
      if (this.stage != null) {
        this.stage.removeAllChildren();
      }
      return super.destroy();
    }
  };
  InventoryModal.initClass();
  return InventoryModal;
})());

const gear = {
  'simple-boots': '53e237bf53457600003e3f05',
  'simple-sword': '53e218d853457600003e3ebe',
  'tarnished-bronze-breastplate': '53e22eac53457600003e3efc',
  'leather-boots': '53e2384453457600003e3f07',
  'leather-belt': '5437002a7beba4a82024a97d',
  'programmaticon-i': '53e4108204c00d4607a89f78',
  'programmaticon-ii': '546e25d99df4a17d0d449be1',
  'crude-glasses': '53e238df53457600003e3f0b',
  'crude-builders-hammer': '53f4e6e3d822c23505b74f42',
  'long-sword': '544d7d1f8494308424f564a3',
  'sundial-wristwatch': '53e2396a53457600003e3f0f',
  'bronze-shield': '544c310ae0017993fce214bf',
  'wooden-glasses': '53e2167653457600003e3eb3',
  'basic-flags': '545bacb41e649a4495f887da',
  'roughedge': '544d7d918494308424f564a7',
  'sharpened-sword': '544d7deb8494308424f564ab',
  'crude-crossbow': '544d7ffd8494308424f564c3',
  'crude-dagger': '544d952b8494308424f56517',
  'weak-charge': '544d957d8494308424f5651f',
  'enchanted-stick': '544d87188494308424f564f1',
  'unholy-tome-i': '546374bc3839c6e02811d308',
  'book-of-life-i': '546375653839c6e02811d30b',
  'rough-sense-stone': '54693140a2b1f53ce79443bc',
  'polished-sense-stone': '53e215a253457600003e3eaf',
  'quartz-sense-stone': '54693240a2b1f53ce79443c5',
  'wooden-builders-hammer': '54694ba3a2b1f53ce794444d',
  'simple-wristwatch': '54693797a2b1f53ce79443e9'
};

var gearSlugs = _.invert(gear);

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}