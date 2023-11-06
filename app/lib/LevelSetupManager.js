// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS002: Fix invalid constructor
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__, or convert again using --optional-chaining
 * DS104: Avoid inline assignments
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let left, left1, LevelSetupManager;
const CocoClass = require('core/CocoClass');
const PlayHeroesModal = require('views/play/modal/PlayHeroesModal');
const InventoryModal = require('views/play/menu/InventoryModal');
const Level = require('models/Level');
const LevelSession = require('models/LevelSession');
const SuperModel = require('models/SuperModel');
const ThangType = require('models/ThangType');
const utils = require('core/utils');

let lastHeroesEarned = (left = __guard__(me.get('earned'), x => x.heroes)) != null ? left : [];
let lastHeroesPurchased = (left1 = __guard__(me.get('purchased'), x1 => x1.heroes)) != null ? left1 : [];

module.exports = (LevelSetupManager = class LevelSetupManager extends CocoClass {

  constructor(options) {
    super();
    this.options = options;
    this.supermodel = this.options.supermodel != null ? this.options.supermodel : new SuperModel();
    this.session = this.options.session;
    if (!(this.level = this.options.level)) {
      this.loadLevel();
    }
    if (this.session) {
      console.log('LevelSetupManager given preloaded session:', this.session.cid);
      this.fillSessionWithDefaults();
    } else {
      console.log('LevelSetupManager given no preloaded session.');
      this.loadSession();
    }
  }

  loadLevel() {
    const levelURL = `/db/level/${this.options.levelID}`;
    this.level = new Level().setURL(levelURL);
    this.level = this.supermodel.loadModel(this.level).model;
    if (this.level.loaded) { return this.onLevelSync(); } else { return this.listenToOnce(this.level, 'sync', this.onLevelSync); }
  }

  loadSession() {
    let sessionURL = `/db/level/${this.options.levelID}/session`;
    //sessionURL += "?team=#{@team}" if @options.team  # TODO: figure out how to get the teams for multiplayer PVP hero style
    if (this.options.courseID) {
      sessionURL += `?course=${this.options.courseID}`;
      if (this.options.courseInstanceID) {
          sessionURL += `&courseInstance=${this.options.courseInstanceID}`;
        }
    }
    this.session = new LevelSession().setURL(sessionURL);
    const originalCid = this.session.cid;
    this.session = this.supermodel.loadModel(this.session).model;
    if (originalCid === this.session.cid) {
      console.log('LevelSetupManager made a new Level Session', this.session);
    } else {
      console.log('LevelSetupManager used a Level Session from the SuperModel', this.session);
    }
    if (this.session.loaded) { return this.onSessionSync(); } else { return this.listenToOnce(this.session, 'sync', this.onSessionSync); }
  }

  onLevelSync() {
    if (this.destroyed) { return; }
    if (this.waitingToLoadModals) {
      this.waitingToLoadModals = false;
      return this.loadModals();
    }
  }

  onSessionSync() {
    if (this.destroyed) { return; }
    this.session.url = function() { return '/db/level.session/' + this.id; };
    return this.fillSessionWithDefaults();
  }

  fillSessionWithDefaults() {
    if (this.options.codeLanguage) {
      this.session.set('codeLanguage', this.options.codeLanguage);
    }
    const heroConfig = _.merge({}, _.cloneDeep(me.get('heroConfig')), this.session.get('heroConfig'));
    this.session.set('heroConfig', heroConfig);
    if (this.level.loaded) {
      return this.loadModals();
    } else {
      return this.waitingToLoadModals = true;
    }
  }

  loadModals() {
    // build modals and prevent them from disappearing.
    if (this.level.usesConfiguredMultiplayerHero()) {
     this.onInventoryModalPlayClicked();
     return;
   }

    if (this.level.isType('course-ladder', 'game-dev', 'web-dev') || (utils.isCodeCombat && this.level.isType('ladder')) || (this.level.isType('course') && (!me.showHeroAndInventoryModalsToStudents() || this.level.isAssessment())) || window.serverConfig.picoCTF) {
      this.onInventoryModalPlayClicked();
      return;
    }

    if (this.level.isSummative()) {
      this.onInventoryModalPlayClicked();
      return;
    }

    this.heroesModal = new PlayHeroesModal({supermodel: this.supermodel, session: this.session, confirmButtonI18N: 'play.next', level: this.level, hadEverChosenHero: this.options.hadEverChosenHero});
    this.inventoryModal = new InventoryModal({supermodel: this.supermodel, session: this.session, level: this.level});
    this.heroesModalDestroy = this.heroesModal.destroy;
    this.inventoryModalDestroy = this.inventoryModal.destroy;
    this.heroesModal.destroy = (this.inventoryModal.destroy = _.noop);
    this.listenTo(this.heroesModal, 'confirm-click', this.onHeroesModalConfirmClicked);
    this.listenToOnce(this.heroesModal, 'hero-loaded', this.onceHeroLoaded);
    this.listenTo(this.inventoryModal, 'choose-hero-click', this.onChooseHeroClicked);
    this.listenTo(this.inventoryModal, 'play-click', this.onInventoryModalPlayClicked);
    this.modalsLoaded = true;
    if (this.waitingToOpen) {
      this.waitingToOpen = false;
      return this.open();
    }
  }

  open() {
    let allowedHeroOriginals, left2, left3, left4, left5;
    if (!this.modalsLoaded) { return this.waitingToOpen = true; }
    let firstModal = this.options.hadEverChosenHero ? this.inventoryModal : this.heroesModal;
    if ((!_.isEqual(lastHeroesEarned, (left2 = __guard__(me.get('earned'), x2 => x2.heroes)) != null ? left2 : []) ||
        !_.isEqual(lastHeroesPurchased, (left3 = __guard__(me.get('purchased'), x3 => x3.heroes)) != null ? left3 : [])) &&
        (utils.isOzaria || !(me.isAnonymous() && me.isInHourOfCode()))) {
      console.log('Showing hero picker because heroes earned/purchased has changed.');
      firstModal = this.heroesModal;
    } else if (allowedHeroOriginals = this.level.get('allowedHeroes')) {
      if ((!utils.isOzaria || !_.contains(allowedHeroOriginals, __guard__(me.get('ozariaUserOptions'), x4 => x4.isometricThangTypeOriginal))) && (!utils.isCodeCombat || !_.contains(allowedHeroOriginals, __guard__(me.get('heroConfig'), x5 => x5.thangType)))) {
        firstModal = this.heroesModal;
      }
    }


    lastHeroesEarned = (left4 = __guard__(me.get('earned'), x6 => x6.heroes)) != null ? left4 : [];
    lastHeroesPurchased = (left5 = __guard__(me.get('purchased'), x7 => x7.heroes)) != null ? left5 : [];
    this.options.parent.openModalView(firstModal);
    return this.trigger('open');
  }
    //    @inventoryModal.onShown() # replace?

  //- Modal events

  onceHeroLoaded(e) {
     if (window.currentModal === this.inventoryModal) { return this.inventoryModal.setHero(e.hero); }
   }

  onHeroesModalConfirmClicked(e) {
    this.options.parent.openModalView(this.inventoryModal);
    this.inventoryModal.render();
    this.inventoryModal.didReappear();
    this.inventoryModal.onShown();
    if (e.hero) { this.inventoryModal.setHero(e.hero); }
    return (window.tracker != null ? window.tracker.trackEvent('Choose Inventory', {category: 'Play Level'}) : undefined);
  }

  onChooseHeroClicked() {
    this.options.parent.openModalView(this.heroesModal);
    this.heroesModal.render();
    this.heroesModal.didReappear();
    this.inventoryModal.endHighlight();
    return (window.tracker != null ? window.tracker.trackEvent('Change Hero', {category: 'Play Level'}) : undefined);
  }

  onInventoryModalPlayClicked() {
    this.navigatingToPlay = true;
    const PlayLevelView = 'views/play/level/PlayLevelView';
    const LadderView = 'views/ladder/LadderView';
    const viewClass = this.options.levelPath === 'ladder' ? LadderView : PlayLevelView;
    let route = `/play/${this.options.levelPath || 'level'}/${this.options.levelID}?`;
    if (this.level.get('primerLanguage')) { route += "&codeLanguage=" + this.level.get('primerLanguage'); }
    if ((this.options.courseID != null) && (this.options.courseInstanceID != null)) {
      route += `&course=${this.options.courseID}&course-instance=${this.options.courseInstanceID}`;
    }
    this.supermodel.registerModel(this.session);
    return Backbone.Mediator.publish('router:navigate', {
      route, viewClass,
      viewArgs: [{supermodel: this.supermodel, sessionID: this.session.id}, this.options.levelID]
    });
  }

  destroy() {
    if (!(this.heroesModal != null ? this.heroesModal.destroyed : undefined)) { if (this.heroesModalDestroy != null) {
      this.heroesModalDestroy.call(this.heroesModal);
    } }
    if (!(this.inventoryModal != null ? this.inventoryModal.destroyed : undefined)) { if (this.inventoryModalDestroy != null) {
      this.inventoryModalDestroy.call(this.inventoryModal);
    } }
    return super.destroy();
  }
});

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}