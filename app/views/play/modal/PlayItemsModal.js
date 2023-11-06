/*
 * decaffeinate suggestions:
 * DS002: Fix invalid constructor
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
let PlayItemsModal;
require('app/styles/play/modal/play-items-modal.sass');
const ModalView = require('views/core/ModalView');
const template = require('app/templates/play/modal/play-items-modal');
const buyGemsPromptTemplate = require('app/templates/play/modal/buy-gems-prompt');
const earnGemsPromptTemplate = require('app/templates/play/modal/earn-gems-prompt');
const subscribeForGemsPrompt = require('app/templates/play/modal/subscribe-for-gems-prompt');
const ItemDetailsView = require('./ItemDetailsView');
const BuyGemsModal = require('views/play/modal/BuyGemsModal');
const CreateAccountModal = require('views/core/CreateAccountModal');
const SubscribeModal = require('views/core/SubscribeModal');

const CocoCollection = require('collections/CocoCollection');
const ThangType = require('models/ThangType');
const LevelComponent = require('models/LevelComponent');
const Level = require('models/Level');
const Purchase = require('models/Purchase');

const utils = require('core/utils');

const PAGE_SIZE = 200;

const slotToCategory = {
  'right-hand': 'primary',

  'left-hand': 'secondary',

  'head': 'armor',
  'torso': 'armor',
  'gloves': 'armor',
  'feet': 'armor',

  'eyes': 'accessories',
  'neck': 'accessories',
  'wrists': 'accessories',
  'left-ring': 'accessories',
  'right-ring': 'accessories',
  'waist': 'accessories',

  'pet': 'misc',
  'minion': 'misc',
  'flag': 'misc',
  'misc-0': 'misc',
  'misc-1': 'misc',

  'programming-book': 'books'
};

module.exports = (PlayItemsModal = (function() {
  PlayItemsModal = class PlayItemsModal extends ModalView {
    static initClass() {
      this.prototype.className = 'modal fade play-modal';
      this.prototype.template = template;
      this.prototype.id = 'play-items-modal';

      this.prototype.events = {
        'click .item': 'onItemClicked',
        'shown.bs.tab': 'onTabClicked',
        'click .unlock-button': 'onUnlockButtonClicked',
        'click .subscribe-button': 'onSubscribeButtonClicked',
        'click .start-subscription-button': 'onSubscribeButtonClicked',
        'click .buy-gems-prompt-button': 'onBuyGemsPromptButtonClicked',
        'click #close-modal': 'hide',
        'click': 'onClickedSomewhere',
        'update .tab-pane .nano': 'showVisibleItemImages',
        'click #hero-type-select label': 'onClickHeroTypeSelect'
      };
    }

    constructor(options) {
      super(options);
      this.showVisibleItemImages = _.throttle(_.bind(this.showVisibleItemImages, this), 200);
      this.items = new Backbone.Collection();
      this.itemCategoryCollections = {};

      const project = [
        'name',
        'components.config',
        'components.original',
        'slug',
        'original',
        'rasterIcon',
        'gems',
        'tier',
        'description',
        'i18n',
        'heroClass',
        'subscriber'
      ];

      const itemFetcher = new CocoCollection([], { url: '/db/thang.type?view=items', project, model: ThangType });
      itemFetcher.skip = 0;
      itemFetcher.fetch({data: {skip: 0, limit: PAGE_SIZE}});
      this.listenTo(itemFetcher, 'sync', this.onItemsFetched);
      this.stopListening(this.supermodel, 'loaded-all');
      this.supermodel.loadCollection(itemFetcher, 'items');
      this.idToItem = {};
      this.trackTimeVisible();
    }

    onItemsFetched(itemFetcher) {
      const gemsOwned = me.gems();
      const needMore = itemFetcher.models.length === PAGE_SIZE;
      for (var model of Array.from(itemFetcher.models)) {
        var cost;
        model.owned = me.ownsItem(model.get('original'));
        if ((!(cost = model.get('gems'))) && !model.owned) { continue; }
        var category = slotToCategory[model.getAllowedSlots()[0]] || 'misc';
        if (this.itemCategoryCollections[category] == null) { this.itemCategoryCollections[category] = new Backbone.Collection(); }
        var collection = this.itemCategoryCollections[category];
        collection.comparator = function(m) { let left;
        return (left = m.get('tier')) != null ? left : m.get('gems'); };
        collection.add(model);
        model.name = utils.i18n(model.attributes, 'name');
        model.affordable = cost <= gemsOwned;
        model.silhouetted = !model.owned && model.isSilhouettedItem();
        if (model.get('tier') != null) { model.level = model.levelRequiredForItem(); }
        model.unequippable = !_.intersection(me.getHeroClasses(), model.getAllowedHeroClasses()).length;
        model.comingSoon = !model.getFrontFacingStats().props.length && !_.size(model.getFrontFacingStats().stats) && !model.owned;  // Temp: while there are placeholder items
        this.idToItem[model.id] = model;
      }

      if (itemFetcher.skip !== 0) {
        // Make sure we render the newly fetched items, except the first time (when it happens automatically).
        this.render();
      }

      if (needMore) {
        itemFetcher.skip += PAGE_SIZE;
        return itemFetcher.fetch({data: {skip: itemFetcher.skip, limit: PAGE_SIZE}});
      }
    }

    getRenderData(context) {
      if (context == null) { context = {}; }
      context = super.getRenderData(context);
      context.itemCategoryCollections = this.itemCategoryCollections;
      context.itemCategories = _.keys(this.itemCategoryCollections);
      context.itemCategoryNames = (Array.from(context.itemCategories).map((category) => $.i18n.t(`items.${category}`)));
      context.gems = me.gems();
      return context;
    }

    afterRender() {
      super.afterRender();
      if (!this.supermodel.finished()) { return; }
      this.playSound('game-menu-open');
      this.$el.find('.nano:visible').nanoScroller({alwaysVisible: true});
      this.itemDetailsView = new ItemDetailsView();
      this.insertSubView(this.itemDetailsView);
      this.$el.find("a[href='#item-category-armor']").click();  // Start on armor tab, if it's there.
      const earnedLevels = __guard__(me.get('earned'), x => x.levels) || [];
      if (!Array.from(earnedLevels).includes(Level.levels['defense-of-plainswood'])) {
        this.$el.find('#misc-tab').hide();
        this.$el.find('#hero-type-select #warrior').click();  // Start on warrior tab, if low level.
      }
      return this.showVisibleItemImages();
    }

    onHidden() {
      super.onHidden();
      return this.playSound('game-menu-close');
    }


    //- Click events

    onItemClicked(e) {
      let item;
      if ($(e.target).closest('.unlock-button').length) { return; }
      if (this.destroyed) { return; }
      this.playSound('menu-button-click');
      const itemEl = $(e.target).closest('.item');
      const wasSelected = itemEl.hasClass('selected');
      this.$el.find('.item.selected').removeClass('selected');
      if (wasSelected) {
        item = null;
      } else {
        item = this.idToItem[itemEl.data('item-id')];
        if (item.silhouetted && !item.owned) {
          item = null;
        } else {
          if (!wasSelected) { itemEl.addClass('selected'); }
        }
      }
      this.itemDetailsView.setItem(item);
      return this.updateViewVisibleTimer();
    }

    currentVisiblePremiumFeature() {
      let needle, needle1;
      const item = this.itemDetailsView != null ? this.itemDetailsView.item : undefined;
      if ((needle = 'pet', Array.from(((item != null ? item.getAllowedSlots() : undefined) || [])).includes(needle)) || (needle1 = item != null ? item.get('heroClass') : undefined, ['Ranger', 'Wizard'].includes(needle1))) {
        return {
          viewName: this.id,
          featureName: 'view-item',
          premiumThang: {
            _id: item.id,
            slug: item.get('slug'),
            heroClass: item.get('heroClass'),
            slots: item.getAllowedSlots()
          }
        };
      } else if (this.$el.find('.tab-content').hasClass('filter-wizard')) {
        return { viewName: this.id, featureName: 'filter-wizard' };
      } else if (this.$el.find('.tab-content').hasClass('filter-ranger')) {
        return { viewName: this.id, featureName: 'filter-ranger' };
      } else {
        return null;
      }
    }

    onTabClicked(e) {
      this.playSound('game-menu-tab-switch');
      const nano = $($(e.target).attr('href')).find('.nano');
      nano.nanoScroller({alwaysVisible: true});
      this.paneNanoContent = nano.find('.nano-content');
      return this.showVisibleItemImages();
    }

    showVisibleItemImages() {
      // dynamically load visible items when the user scrolls enough to see them
      if (!this.paneNanoContent) { return console.error("Couldn't update scroll, since paneNanoContent wasn't initialized."); }
      const items = this.paneNanoContent.find('.item:not(.loaded)');
      const threshold = this.paneNanoContent.height() + 100;
      return (() => {
        const result = [];
        for (var itemEl of Array.from(items)) {
          itemEl = $(itemEl);
          if (itemEl.position().top < threshold) {
            $(itemEl).addClass('loaded');
            var item = this.idToItem[itemEl.data('item-id')];
            result.push(itemEl.find('.item-silhouette, .item-img').attr('src', item.getPortraitURL()));
          } else {
            result.push(undefined);
          }
        }
        return result;
      })();
    }

    onClickHeroTypeSelect(e) {
      const value = $(e.target).closest('label').attr('id');
      const tabContent = this.$el.find('.tab-content');
      tabContent.removeClass('filter-wizard filter-ranger filter-warrior');
      if (value !== 'all') { tabContent.addClass(`filter-${value}`); }
      return this.updateViewVisibleTimer();
    }

    onUnlockButtonClicked(e) {
      let left;
      e.stopPropagation();
      const button = $(e.target).closest('button');
      const item = this.idToItem[button.data('item-id')];
      const gemsOwned = me.gems();
      const cost = (left = item.get('gems')) != null ? left : 0;
      const affordable = cost <= gemsOwned;
      if (!affordable) {
        this.playSound('menu-button-click');
        if (!me.freeOnly() && !application.getHocCampaign()) { return this.askToBuyGemsOrSubscribe(button); }
      } else if (button.hasClass('confirm')) {
        let left1, left2;
        this.playSound('menu-button-unlock-end');
        const purchase = Purchase.makeFor(item);
        purchase.save();

        //- set local changes to mimic what should happen on the server...
        const purchased = (left1 = me.get('purchased')) != null ? left1 : {};
        if (purchased.items == null) { purchased.items = []; }
        purchased.items.push(item.get('original'));
        item.owned = true;
        me.set('purchased', purchased);
        me.set('spent', ((left2 = me.get('spent')) != null ? left2 : 0) + item.get('gems'));

        //- ...then rerender key bits
        this.renderSelectors(`.item[data-item-id='${item.id}']`, "#gems-count");
        console.log('render selectors', `.item[data-item-id='${item.id}']`, "#gems-count");
        this.itemDetailsView.render();
        this.showVisibleItemImages();

        return Backbone.Mediator.publish('store:item-purchased', {item, itemSlug: item.get('slug')});
      } else {
        this.playSound('menu-button-unlock-start');
        button.addClass('confirm').text($.i18n.t('play.confirm'));
        return this.$el.one('click', function(e) {
          if (e.target !== button[0]) { return button.removeClass('confirm').text($.i18n.t('play.unlock')); }
      });
      }
    }

    onSubscribeButtonClicked(e) {
      return this.openModalView(new SubscribeModal());
    }

    askToSignUp() {
      const createAccountModal = new CreateAccountModal({supermodel: this.supermodel});
      return this.openModalView(createAccountModal);
    }

    askToBuyGemsOrSubscribe(unlockButton) {
      let popoverTemplate;
      this.$el.find('.unlock-button').popover('destroy');
      if (me.canBuyGems()) {
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
      __guard__(popover != null ? popover.$tip : undefined, x => x.i18n());  // Doesn't work
      return this.applyRTLIfNeeded();
    }

    onBuyGemsPromptButtonClicked(e) {
      this.playSound('menu-button-click');
      if (me.get('anonymous')) { return this.askToSignUp(); }
      return this.openModalView(new BuyGemsModal());
    }

    onClickedSomewhere(e) {
      if (this.destroyed) { return; }
      return this.$el.find('.unlock-button').popover('destroy');
    }

    destroy() {
      this.$el.find('.unlock-button').popover('destroy');
      return super.destroy();
    }
  };
  PlayItemsModal.initClass();
  return PlayItemsModal;
})());

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}