/*
 * decaffeinate suggestions:
 * DS002: Fix invalid constructor
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__, or convert again using --optional-chaining
 * DS104: Avoid inline assignments
 * DS204: Change includes calls to have a more natural evaluation order
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let PlayHeroesModal;
require('app/styles/play/modal/play-heroes-modal.sass');
const ModalView = require('views/core/ModalView');
const template = require('app/templates/play/modal/play-heroes-modal');
const buyGemsPromptTemplate = require('app/templates/play/modal/buy-gems-prompt');
const earnGemsPromptTemplate = require('app/templates/play/modal/earn-gems-prompt');
const subscribeForGemsPrompt = require('app/templates/play/modal/subscribe-for-gems-prompt');
const CocoCollection = require('collections/CocoCollection');
const ThangType = require('models/ThangType');
const SpriteBuilder = require('lib/sprites/SpriteBuilder');
const AudioPlayer = require('lib/AudioPlayer');
const utils = require('core/utils');
const BuyGemsModal = require('views/play/modal/BuyGemsModal');
const CreateAccountModal = require('views/core/CreateAccountModal');
const SubscribeModal = require('views/core/SubscribeModal');
const Purchase = require('models/Purchase');
const LayerAdapter = require('lib/surface/LayerAdapter');
const Lank = require('lib/surface/Lank');
const store = require('core/store');
const createjs = require('lib/createjs-parts');
const ThangTypeConstants = require('lib/ThangTypeConstants');

module.exports = (PlayHeroesModal = (function() {
  PlayHeroesModal = class PlayHeroesModal extends ModalView {
    static initClass() {
      this.prototype.className = 'modal fade play-modal';
      this.prototype.template = template;
      this.prototype.id = 'play-heroes-modal';
      this.prototype.trapsFocus = false;

      this.prototype.events = {
        'slide.bs.carousel #hero-carousel': 'onHeroChanged',
        'change #option-code-language': 'onCodeLanguageChanged',
        'click #close-modal': 'hide',
        'click #confirm-button': 'saveAndHide',
        'click .unlock-button': 'onUnlockButtonClicked',
        'click .subscribe-button': 'onSubscribeButtonClicked',
        'click .buy-gems-prompt-button': 'onBuyGemsPromptButtonClicked',
        'click .start-subscription-button': 'onSubscribeButtonClicked',
        'click': 'onClickedSomewhere'
      };

      this.prototype.shortcuts = {
        'left'() { if (this.heroes.models.length && !this.$el.hasClass('secret')) { return this.$el.find('#hero-carousel').carousel('prev'); } },
        'right'() { if (this.heroes.models.length && !this.$el.hasClass('secret')) { return this.$el.find('#hero-carousel').carousel('next'); } },
        'enter'() { if (this.visibleHero && !this.visibleHero.locked) { return this.saveAndHide(); } }
      };
    }

    constructor(options) {
      super(options);
      this.animateHeroes = this.animateHeroes.bind(this);
      if (options == null) { options = {}; }
      this.confirmButtonI18N = options.confirmButtonI18N != null ? options.confirmButtonI18N : "common.save";
      this.heroes = new CocoCollection([], {model: ThangType});
      this.heroes.url = '/db/thang.type?view=heroes';
      this.heroes.setProjection(['original','name','slug','soundTriggers','featureImages','gems','heroClass','description','components','extendedName','shortName','unlockLevelName','i18n','poseImage','tier','releasePhase','ozaria']);
      this.heroes.comparator = 'gems';
      this.listenToOnce(this.heroes, 'sync', this.onHeroesLoaded);
      this.supermodel.loadCollection(this.heroes, 'heroes');
      this.stages = {};
      this.layers = [];
      this.session = options.session;
      this.initCodeLanguageList(options.hadEverChosenHero);
      this.heroAnimationInterval = setInterval(this.animateHeroes, 1000);
      this.trackTimeVisible();
    }

    onHeroesLoaded() {
      this.heroes.reset(this.heroes.filter(hero => !hero.get('ozaria')));
      for (var hero of Array.from(this.heroes.models)) { this.formatHero(hero); }
      this.heroes.reset(this.heroes.filter(hero => !hero.hidden));
      if (me.isStudent() && me.showHeroAndInventoryModalsToStudents()) {
        this.heroes.reset(this.heroes.filter(hero => hero.get('heroClass') === 'Warrior'));
      } else if (me.freeOnly() || application.getHocCampaign()) {
        this.heroes.reset(this.heroes.filter(hero => !hero.locked));
      }
      if (!me.isAdmin()) {
        return this.heroes.reset(this.heroes.filter(hero => hero.get('releasePhase') !== 'beta'));
      }
    }

    formatHero(hero) {
      let allowedHeroes, clanHero;
      hero.name = utils.i18n(hero.attributes, 'extendedName');
      if (hero.name == null) { hero.name = utils.i18n(hero.attributes, 'shortName'); }
      if (hero.name == null) { hero.name = utils.i18n(hero.attributes, 'name'); }
      hero.description = utils.i18n(hero.attributes, 'description');
      hero.unlockLevelName = utils.i18n(hero.attributes, 'unlockLevelName');
      const original = hero.get('original');
      hero.free = ['captain', 'knight', 'champion', 'duelist'].includes(hero.attributes.slug);
      hero.unlockBySubscribing = ['samurai', 'ninja', 'librarian'].includes(hero.attributes.slug);
      hero.premium = !hero.free && !hero.unlockBySubscribing;
      hero.locked = !me.ownsHero(original) && !(hero.unlockBySubscribing && me.isPremium());
      if (me.isStudent() && me.showHeroAndInventoryModalsToStudents() && (hero.get('heroClass') === 'Warrior')) { hero.locked = false; }
      hero.purchasable = hero.locked && me.isPremium();
      if (this.options.level && (allowedHeroes = this.options.level.get('allowedHeroes'))) {
        let needle;
        hero.restricted = !((needle = hero.get('original'), Array.from(allowedHeroes).includes(needle)));
      }
      hero.class = (hero.get('heroClass') || 'warrior').toLowerCase();
      hero.stats = hero.getHeroStats();
      if (clanHero = _.find(utils.clanHeroes, {thangTypeOriginal: hero.get('original')})) {
        let left, needle1;
        if ((needle1 = clanHero.clanId, !Array.from(((left = me.get('clans')) != null ? left : [])).includes(needle1))) { hero.hidden = true; }
      }
      if (hero.get('original') === ThangTypeConstants.heroes['code-ninja']) {
        return hero.hidden = window.location.host !== 'coco.code.ninja';
      }
    }

    currentVisiblePremiumFeature() {
      const isPremium = this.visibleHero && !((this.visibleHero.class === 'warrior') && (this.visibleHero.get('tier') === 0));
      if (isPremium) {
        return {
          viewName: this.id,
          featureName: 'view-hero',
          premiumThang: {
            _id: this.visibleHero.id,
            slug: this.visibleHero.get('slug')
          }
        };
      } else {
        return null;
      }
    }

    getRenderData(context) {
      let left, left1;
      if (context == null) { context = {}; }
      context = super.getRenderData(context);
      context.heroes = this.heroes.models;
      context.level = this.options.level;
      context.codeLanguages = this.codeLanguageList;
      context.codeLanguage = (this.codeLanguage = (left = (left1 = __guard__(this.options != null ? this.options.session : undefined, x => x.get('codeLanguage'))) != null ? left1 : __guard__(me.get('aceConfig'), x1 => x1.language)) != null ? left : 'python');
      context.confirmButtonI18N = this.confirmButtonI18N;
      context.visibleHero = this.visibleHero;
      context.gems = me.gems();
      context.isIE = this.isIE();
      return context;
    }

    afterInsert() {
      this.updateViewVisibleTimer();
      return super.afterInsert();
    }

    afterRender() {
      let left, left1;
      super.afterRender();
      if (!this.supermodel.finished()) { return; }
      this.playSound('game-menu-open');
      if (this.isIE()) { this.$el.find('.hero-avatar').addClass('ie'); }
      const heroes = this.heroes.models;
      this.$el.find('.hero-indicator').each(function() {
        const heroID = $(this).data('hero-id');
        const hero = _.find(heroes, hero => hero.get('original') === heroID);
        return $(this).find('.hero-avatar').css('background-image', `url(${hero.getPortraitURL()})`).addClass('has-tooltip').tooltip();
      });
      this.canvasWidth = 313;  // @$el.find('canvas').width() # unreliable, whatever
      this.canvasHeight = this.$el.find('canvas').height();
      const heroConfig = (left = (left1 = __guard__(this.options != null ? this.options.session : undefined, x => x.get('heroConfig'))) != null ? left1 : me.get('heroConfig')) != null ? left : {};
      const heroIndex = Math.max(0, _.findIndex(heroes, (hero => hero.get('original') === heroConfig.thangType)));
      this.$el.find(`.hero-item:nth-child(${heroIndex + 1}), .hero-indicator:nth-child(${heroIndex + 1})`).addClass('active');
      this.onHeroChanged({direction: null, relatedTarget: this.$el.find('.hero-item')[heroIndex]});
      this.$el.find('.hero-stat').addClass('has-tooltip').tooltip();
      return this.buildCodeLanguages();
    }

    rerenderFooter() {
      this.formatHero(this.visibleHero);
      this.renderSelectors('#hero-footer');
      this.buildCodeLanguages();
      return this.$el.find('#gems-count-container').toggle(Boolean(this.visibleHero.purchasable));
    }

    initCodeLanguageList(hadEverChosenHero) {
      if (application.isIPadApp) {
        return this.codeLanguageList = [
          {id: 'python', name: `Python (${$.i18n.t('choose_hero.default')})`},
          {id: 'javascript', name: 'JavaScript'}
        ];
      } else {
        this.subscriberCodeLanguageList = [
          {id: 'cpp', name: "C++"},
          {id: 'java', name: `Java (${$.i18n.t('choose_hero.experimental')})`}
        ];
        return this.codeLanguageList = [
          {id: 'python', name: `Python (${$.i18n.t('choose_hero.default')})`},
          {id: 'javascript', name: 'JavaScript'},
          {id: 'coffeescript', name: "CoffeeScript"},
          {id: 'lua', name: "Lua"},
          ...Array.from(this.subscriberCodeLanguageList)
        ];
      }
    }

    onHeroChanged(e) {
      const {
        direction
      } = e;  // 'left' or 'right'
      const heroItem = $(e.relatedTarget);
      let hero = _.find(this.heroes.models, hero => hero.get('original') === heroItem.data('hero-id'));
      if (!hero) { return console.error("Couldn't find hero from heroItem:", heroItem); }
      const heroIndex = heroItem.index();
      hero = this.loadHero(hero);
      this.preloadHero(heroIndex + 1);
      this.preloadHero(heroIndex - 1);
      if (!hero.locked) { this.selectedHero = hero; }
      this.visibleHero = hero;
      this.rerenderFooter();
      this.trigger('hero-loaded', {hero});
      return this.updateViewVisibleTimer();
    }

    getFullHero(original) {
      let fullHero;
      const url = `/db/thang.type/${original}/version`;
      if (fullHero = this.supermodel.getModel(url)) {
        return fullHero;
      }
      fullHero = new ThangType();
      fullHero.setURL(url);
      fullHero = (this.supermodel.loadModel(fullHero)).model;
      return fullHero;
    }

    preloadHero(heroIndex) {
      let hero;
      if (!(hero = this.heroes.models[heroIndex])) { return; }
      return this.loadHero(hero, true);
    }

    loadHero(hero, preloading) {
      let poseImage;
      if (preloading == null) { preloading = false; }
      if (poseImage = hero.get('poseImage')) {
        $(`.hero-item[data-hero-id='${hero.get('original')}'] canvas`).hide();
        $(`.hero-item[data-hero-id='${hero.get('original')}'] .hero-pose-image`).show().find('img').prop('src', '/file/' + poseImage);
        if (!preloading) { this.playSelectionSound(hero); }
        return hero;
      } else {
        throw new Error(`Don't have poseImage for ${hero.get('original')}`);
      }
    }

    animateHeroes() {
      if (!this.visibleHero) { return; }
      const heroIndex = Math.max(0, _.findIndex(this.heroes.models, (hero => hero.get('original') === this.visibleHero.get('original'))));
      const animation = _.sample(['attack', 'move_side', 'move_fore']);  // Must be in LayerAdapter default actions.
      return __guardMethod__(__guard__(__guard__(__guard__(this.stages[heroIndex] != null ? this.stages[heroIndex].children : undefined, x2 => x2[0]), x1 => x1.children), x => x[0]), 'gotoAndPlay', o => o.gotoAndPlay(animation));
    }

    playSelectionSound(hero) {
      let sound, sounds, soundTriggers;
      if (this.$el.hasClass('secret')) { return; }
      if (this.currentSoundInstance != null) {
        this.currentSoundInstance.stop();
      }
      if (!(soundTriggers = utils.i18n(hero.attributes, 'soundTriggers'))) { return; }
      if (!(sounds = soundTriggers.selected)) { return; }
      if (!(sound = sounds[Math.floor(Math.random() * sounds.length)])) { return; }
      const name = AudioPlayer.nameForSoundReference(sound);
      AudioPlayer.preloadSoundReference(sound);
      this.currentSoundInstance = AudioPlayer.playSound(name, 1);
      return this.currentSoundInstance;
    }

    buildCodeLanguages() {
      const $select = this.$el.find('#option-code-language');
      return $select.fancySelect().parent().find('.options li').each(function() {
        const languageName = $(this).text();
        const languageID = $(this).data('value');
        const blurb = $.i18n.t(`choose_hero.${languageID}_blurb`);
        if (languageName.indexOf(blurb) === -1) {  // Avoid doubling blurb if this is called 2x
          return $(this).text(`${languageName} - ${blurb}`);
        }
      });
    }

    onCodeLanguageChanged(e) {
      this.codeLanguage = this.$el.find('#option-code-language').val();
      this.codeLanguageChanged = true;
      return (window.tracker != null ? window.tracker.trackEvent('Campaign changed code language', {category: 'Campaign Hero Select', codeLanguage: this.codeLanguage, levelSlug: (this.options.level != null ? this.options.level.get('slug') : undefined)}) : undefined);
    }

    //- Purchasing the hero

    onUnlockButtonClicked(e) {
      e.stopPropagation();
      const button = $(e.target).closest('button');
      const affordable = this.visibleHero.get('gems') <= me.gems();
      if (!affordable) {
        this.playSound('menu-button-click');
        if (!me.freeOnly()) { return this.askToBuyGemsOrSubscribe(button); }
      } else if (button.hasClass('confirm')) {
        let left, left1;
        this.playSound('menu-button-unlock-end');
        const purchase = Purchase.makeFor(this.visibleHero);
        purchase.save();

        //- set local changes to mimic what should happen on the server...
        const purchased = (left = me.get('purchased')) != null ? left : {};
        if (purchased.heroes == null) { purchased.heroes = []; }
        purchased.heroes.push(this.visibleHero.get('original'));
        me.set('purchased', purchased);
        me.set('spent', ((left1 = me.get('spent')) != null ? left1 : 0) + this.visibleHero.get('gems'));

        //- ...then rerender visible hero
        const heroEntry = this.$el.find(`.hero-item[data-hero-id='${this.visibleHero.get('original')}']`);
        heroEntry.find('.hero-status-value').attr('data-i18n', 'play.available').i18n();
        this.applyRTLIfNeeded();
        heroEntry.removeClass('locked purchasable');
        this.selectedHero = this.visibleHero;
        this.rerenderFooter();

        return Backbone.Mediator.publish('store:hero-purchased', {hero: this.visibleHero, heroSlug: this.visibleHero.get('slug')});
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
        placement: 'left',
        content: ' ',  // template has it
        container: this.$el,
        template: popoverTemplate
      }).popover('show');
      const popover = unlockButton.data('bs.popover');
      __guard__(popover != null ? popover.$tip : undefined, x => x.i18n());  // Doesn't work
      return this.applyRTLIfNeeded();
    }

    onBuyGemsPromptButtonClicked(e) {
      if (me.get('anonymous')) { return this.askToSignUp(); }
      return this.openModalView(new BuyGemsModal());
    }

    onClickedSomewhere(e) {
      if (this.destroyed) { return; }
      return this.$el.find('.unlock-button').popover('destroy');
    }

    onSubscribeButtonClicked(e) {
      this.openModalView(new SubscribeModal());
      return (window.tracker != null ? window.tracker.trackEvent('Show subscription modal', {category: 'Subscription', label: 'hero subscribe modal: ' + ($(e.target).data('heroSlug') || 'unknown')}) : undefined);
    }

    //- Exiting

    saveAndHide() {
      let changed;
      if (!me.hasSubscription() && this.subscriberCodeLanguageList.find(l => l.id === this.codeLanguage) && !me.isStudent()) {
        this.openModalView(new SubscribeModal());
        if (window.tracker != null) {
          window.tracker.trackEvent('Show subscription modal', {category: 'Subscription', label: 'hero subscribe modal: experimental language'});
        }
        return;
      }

      let hero = this.selectedHero != null ? this.selectedHero.get('original') : undefined;
      if ((this.visibleHero != null ? this.visibleHero.loaded : undefined) && !this.visibleHero.locked) { if (hero == null) { hero = this.visibleHero != null ? this.visibleHero.get('original') : undefined; } }
      if (!hero) {
        console.error('Somehow we tried to hide without having a hero selected yet...');
        noty({
          text: "Error: hero not loaded. If this keeps happening, please report the bug.",
          layout: 'topCenter',
          timeout: 10000,
          type: 'error'
        });
        return;
      }

      if (this.session) {
        changed = this.updateHeroConfig(this.session, hero);
        if (this.session.get('codeLanguage') !== this.codeLanguage) {
          this.session.set('codeLanguage', this.codeLanguage);
          changed = true;
        }
          //Backbone.Mediator.publish 'tome:change-language', language: @codeLanguage, reload: true  # We'll reload the PlayLevelView instead.

        if (changed) { this.session.patch(); }
      }

      changed = this.updateHeroConfig(me, hero);
      const aceConfig = _.clone(me.get('aceConfig')) || {};
      if (this.codeLanguage !== aceConfig.language) {
        aceConfig.language = this.codeLanguage;
        me.set('aceConfig', aceConfig);
        changed = true;
      }

      if (changed) { me.patch(); }

      this.hide();
      return (typeof this.trigger === 'function' ? this.trigger('confirm-click', {hero: this.selectedHero}) : undefined);
    }

    updateHeroConfig(model, hero) {
      if (!hero) { return false; }
      const heroConfig = _.clone(model.get('heroConfig')) || {};
      if (heroConfig.thangType !== hero) {
        heroConfig.thangType = hero;
        model.set('heroConfig', heroConfig);
        return true;
      }
    }

    onHidden() {
      super.onHidden();
      return this.playSound('game-menu-close');
    }

    destroy() {
      clearInterval(this.heroAnimationInterval);
      for (var heroIndex in this.stages) {
        var stage = this.stages[heroIndex];
        createjs.Ticker.removeEventListener("tick", stage);
        stage.removeAllChildren();
      }
      for (var layer of Array.from(this.layers)) { layer.destroy(); }
      return super.destroy();
    }
  };
  PlayHeroesModal.initClass();
  return PlayHeroesModal;
})());

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}
function __guardMethod__(obj, methodName, transform) {
  if (typeof obj !== 'undefined' && obj !== null && typeof obj[methodName] === 'function') {
    return transform(obj, methodName);
  } else {
    return undefined;
  }
}