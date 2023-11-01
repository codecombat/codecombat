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
let PlayLevelView;
require('app/styles/play/level/level-loading-view.sass');
require('app/styles/play/level/tome/spell_palette_entry.sass');
require('app/styles/play/play-level-view.sass');
const RootView = require('views/core/RootView');
const template = require('app/templates/play/play-level-view');
const {me} = require('core/auth');
const ThangType = require('models/ThangType');
const utils = require('core/utils');
const storage = require('core/storage');
const {createAetherOptions} = require('lib/aether_utils');
const loadAetherLanguage = require('lib/loadAetherLanguage');

// tools
const Surface = require('lib/surface/Surface');
const God = require('lib/God');
const GoalManager = require('lib/world/GoalManager');
const ScriptManager = require('lib/scripts/ScriptManager');
const LevelBus = require('lib/LevelBus');
const LevelLoader = require('lib/LevelLoader');
const LevelSession = require('models/LevelSession');
const Level = require('models/Level');
const LevelComponent = require('models/LevelComponent');
const Article = require('models/Article');
const Mandate = require('models/Mandate');
const Camera = require('lib/surface/Camera');
const AudioPlayer = require('lib/AudioPlayer');
const Simulator = require('lib/simulator/Simulator');
const GameUIState = require('models/GameUIState');
const createjs = require('lib/createjs-parts');

// subviews
const LevelLoadingView = require('./LevelLoadingView');
const ProblemAlertView = require('./tome/ProblemAlertView');
const TomeView = require('./tome/TomeView');
const ChatView = require('./LevelChatView');
const HUDView = require('./LevelHUDView');
const LevelDialogueView = require('./LevelDialogueView');
const ControlBarView = require('./ControlBarView');
const LevelPlaybackView = require('./LevelPlaybackView');
const GoalsView = require('./LevelGoalsView');
const LevelFlagsView = require('./LevelFlagsView');
const GoldView = require('./LevelGoldView');
const GameDevTrackView = require('./GameDevTrackView');
const DuelStatsView = require('./DuelStatsView');
const VictoryModal = require('./modal/VictoryModal');
const HeroVictoryModal = require('./modal/HeroVictoryModal');
const CourseVictoryModal = require('./modal/CourseVictoryModal');
const PicoCTFVictoryModal = require('./modal/PicoCTFVictoryModal');
const InfiniteLoopModal = require('./modal/InfiniteLoopModal');
const LevelSetupManager = require('lib/LevelSetupManager');
const ContactModal = require('views/core/ContactModal');
const HintsView = require('./HintsView');
const SurfaceContextMenuView = require('./SurfaceContextMenuView');
const HintsState = require('./HintsState');
const WebSurfaceView = require('./WebSurfaceView');
const SpellPaletteViewMid = require('./tome/SpellPaletteViewMid');
const store = require('core/store');

require('lib/game-libraries');
window.Box2D = require('exports-loader?Box2D!vendor/scripts/Box2dWeb-2.1.a.3');

const PROFILE_ME = false;

const STOP_CHECK_TOURNAMENT_CLOSE = 0;  // tournament ended
const KEEP_CHECK_TOURNAMENT_CLOSE = 1;  // tournament not begin
const STOP_CHECK_TOURNAMENT_OPEN = 2;  // none tournament only level
const KEEP_CHECK_TOURNAMENT_OPEN = 3;  // tournament running

const TOURNAMENT_OPEN = [2, 3];
const STOP_CHECK_TOURNAMENT = [0, 2];

module.exports = (PlayLevelView = (function() {
  PlayLevelView = class PlayLevelView extends RootView {
    static initClass() {
      this.prototype.id = 'level-view';
      this.prototype.template = template;
      this.prototype.cache = false;
      this.prototype.shortcutsEnabled = true;
      this.prototype.isEditorPreview = false;
  
      this.prototype.subscriptions = {
        'level:set-volume': 'onSetVolume',
        'level:show-victory': 'onShowVictory',
        'level:restart': 'onRestartLevel',
        'level:highlight-dom': 'onHighlightDOM',
        'level:end-highlight-dom': 'onEndHighlight',
        'level:focus-dom': 'onFocusDom',
        'level:disable-controls': 'onDisableControls',
        'level:enable-controls': 'onEnableControls',
        'god:world-load-progress-changed': 'onWorldLoadProgressChanged',
        'god:new-world-created': 'onNewWorld',
        'god:streaming-world-updated': 'onNewWorld',
        'god:infinite-loop': 'onInfiniteLoop',
        'level:reload-from-data': 'onLevelReloadFromData',
        'level:reload-thang-type': 'onLevelReloadThangType',
        'level:started': 'onLevelStarted',
        'level:loading-view-unveiling': 'onLoadingViewUnveiling',
        'level:loading-view-unveiled': 'onLoadingViewUnveiled',
        'level:loaded': 'onLevelLoaded',
        'level:session-loaded': 'onSessionLoaded',
        'playback:real-time-playback-started': 'onRealTimePlaybackStarted',
        'playback:real-time-playback-ended': 'onRealTimePlaybackEnded',
        'playback:cinematic-playback-started': 'onCinematicPlaybackStarted',
        'playback:cinematic-playback-ended': 'onCinematicPlaybackEnded',
        'ipad:memory-warning': 'onIPadMemoryWarning',
        'store:item-purchased': 'onItemPurchased',
        'tome:manual-cast': 'onRunCode',
        'world:update-key-value-db': 'updateKeyValueDb'
      };
  
      this.prototype.events = {
        'click #level-done-button': 'onDonePressed',
        'click #stop-real-time-playback-button'() { return Backbone.Mediator.publish('playback:stop-real-time-playback', {}); },
        'click #stop-cinematic-playback-button'() { return Backbone.Mediator.publish('playback:stop-cinematic-playback', {}); },
        'click #fullscreen-editor-background-screen'(e) { return Backbone.Mediator.publish('tome:toggle-maximize', {}); },
        'click .contact-link': 'onContactClicked',
        'contextmenu #webgl-surface': 'onSurfaceContextMenu',
        'click': 'onClick',
        'click .close-solution-btn': 'onCloseSolution'
      };
  
      this.prototype.shortcuts = {
        'ctrl+s': 'onCtrlS',
        'esc': 'onEscapePressed'
      };
    }

    onClick() {
      // workaround to get users out of permanent idle status
      if (application.userIsIdle) {
        application.idleTracker.onVisible();
      }

      //hide context menu if visible
      if (this.$('#surface-context-menu-view').is(":visible")) {
        return Backbone.Mediator.publish('level:surface-context-menu-hide', {});
      }
    }

    // Initial Setup #############################################################

    constructor(options, levelID) {
      this.onWindowResize = this.onWindowResize.bind(this);
      this.onSubmissionComplete = this.onSubmissionComplete.bind(this);
      this.levelID = levelID;
      if (PROFILE_ME) { if (typeof console.profile === 'function') {
        console.profile();
      } }
      super(options);

      this.courseID = options.courseID || utils.getQueryVariable('course');
      this.courseInstanceID = options.courseInstanceID || utils.getQueryVariable('course-instance' || utils.getQueryVariable('instance')); // instance to avoid sessionless to be false when teaching

      this.isEditorPreview = utils.getQueryVariable('dev');
      this.sessionID = (utils.getQueryVariable('session')) || this.options.sessionID;
      this.observing = utils.getQueryVariable('observing');
      this.teaching = utils.getQueryVariable('teaching');

      this.opponentSessionID = utils.getQueryVariable('opponent');
      if (this.opponentSessionID == null) { this.opponentSessionID = this.options.opponent; }
      this.gameUIState = new GameUIState();

      $('flying-focus').remove(); //Causes problems, so yank it out for play view.
      $(window).on('resize', this.onWindowResize);

      if (this.isEditorPreview) {
        this.supermodel.shouldSaveBackups = model => // Make sure to load possibly changed things from localStorage.
        ['Level', 'LevelComponent', 'LevelSystem', 'ThangType'].includes(model.constructor.className);
        const f = () => { if (!this.levelLoader) { return (typeof this.load === 'function' ? this.load() : undefined); } };  // Wait to see if it's just given to us through setLevel.
        setTimeout(f, 100);
      } else {
        this.load();
        if (!this.observing) { if (application.tracker != null) {
          application.tracker.trackEvent('Started Level Load', {category: 'Play Level', level: this.levelID, label: this.levelID});
        } }
      }

      this.calcTimeOffset();
      this.mandate = this.supermodel.loadModel(new Mandate()).model;

      if (features.china) {
        this.checkTournamentEndInterval = setInterval(this.checkTournamentEnd.bind(this), 3000);
      }

      const preloadImages = ['/images/level/code_palette_wood_background.png', '/images/level/code_editor_background_border.png'];
      _.delay((() => Array.from(preloadImages).map((img) => ($('<img/>')[0].src = img))), 1000);
    }

    getMeta() {
      return {
        link: [
          { vmid: 'rel-canonical', rel: 'canonical', content: '/play' }
        ]
      };
    }

    setLevel(level, givenSupermodel) {
      this.level = level;
      this.supermodel.models = givenSupermodel.models;
      this.supermodel.collections = givenSupermodel.collections;
      this.supermodel.shouldSaveBackups = givenSupermodel.shouldSaveBackups;

      const serializedLevel = this.level.serialize({supermodel: this.supermodel, session: this.session, otherSession: this.otherSession, headless: false, sessionless: false});
      if (me.constrainHeroHealth()) {
        serializedLevel.constrainHeroHealth = true;
      }
      if (this.god != null) {
        this.god.setLevel(serializedLevel);
      }
      if (this.world) {
        return this.world.loadFromLevel(serializedLevel, false);
      } else {
        return this.load();
      }
    }

    load() {
      this.loadStartTime = new Date();
      const levelLoaderOptions = { supermodel: this.supermodel, levelID: this.levelID, sessionID: this.sessionID, opponentSessionID: this.opponentSessionID, team: utils.getQueryVariable('team'), observing: this.observing, courseID: this.courseID, courseInstanceID: this.courseInstanceID, teaching: this.teaching };
      if (me.isSessionless()) {
        levelLoaderOptions.fakeSessionConfig = {};
      }
      this.levelLoader = new LevelLoader(levelLoaderOptions);
      this.listenToOnce(this.levelLoader, 'world-necessities-loaded', this.onWorldNecessitiesLoaded);
      this.listenTo(this.levelLoader, 'world-necessity-load-failed', this.onWorldNecessityLoadFailed);

      this.classroomAceConfig = {liveCompletion: true};  // default (home users, teachers, etc.)
      if (this.courseInstanceID) {
        const fetchAceConfig = $.get(`/db/course_instance/${this.courseInstanceID}/classroom?project=aceConfig,members,ownerID`);
        this.supermodel.trackRequest(fetchAceConfig);
        return fetchAceConfig.then(classroom => {
          this.classroomAceConfig.liveCompletion = (classroom.aceConfig != null ? classroom.aceConfig.liveCompletion : undefined) != null ? (classroom.aceConfig != null ? classroom.aceConfig.liveCompletion : undefined) : true;
          this.classroomAceConfig.levelChat = (classroom.aceConfig != null ? classroom.aceConfig.levelChat : undefined) != null ? (classroom.aceConfig != null ? classroom.aceConfig.levelChat : undefined) : 'none';
          this.teacherID = classroom.ownerID;

          if (this.teaching && (!this.teacherID.equals(me.id))) {
            return _.defer(() => application.router.redirectHome());
          }
        });
      }
    }

    hasAccessThroughClan(level) {
      let left, left1;
      return _.intersection((left = level.get('clans')) != null ? left : [], (left1 = me.get('clans')) != null ? left1 : []).length;
    }

    onLevelLoaded(e) {
      let needle;
      if (this.destroyed) { return; }
      if (_.all([
        ((me.isStudent() || me.isTeacher()) && !application.getHocCampaign()),
        !this.courseID,
        !e.level.isType('course-ladder', 'ladder'),

        // TODO: Add a general way for standalone levels to be accessed by students, teachers
        !this.hasAccessThroughClan(e.level),
        (needle = e.level.get('slug'), !['peasants-and-munchkins',
                                    'game-dev-2-tournament-project',
                                    'game-dev-3-tournament-project'].includes(needle))
      ])) {
        return _.defer(() => application.router.redirectHome());
      }

      if (!e.level.isType('web-dev')) {
        this.god = new God({
          gameUIState: this.gameUIState,
          indefiniteLength: e.level.isType('game-dev')
        });
      }
      if (this.waitingToSetUpGod) { this.setupGod(); }
      return this.levelSlug = e.level.get('slug');
    }

    checkTournamentEnd() {
      if (!this.timeOffset) { return; }
      if (!this.mandate.loaded) { return; }
      if (!this.levelSlug) { return; }
      if ((this.level != null ? this.level.get('type') : undefined) !== 'course-ladder') { return; }
      const courseInstanceID = this.courseInstanceID || utils.getQueryVariable('league');
      const mandate = this.mandate.get('0');

      let tournamentState = STOP_CHECK_TOURNAMENT_OPEN;
      if (mandate) {
        tournamentState = this.getTournamentState(mandate, courseInstanceID, this.levelSlug, this.timeOffset);
        if (!me.isAdmin() && !Array.from(TOURNAMENT_OPEN).includes(tournamentState)) {
          window.location.href = '/play/ladder/'+this.levelSlug+(courseInstanceID ? '/course/'+courseInstanceID : "");
        }
      }
      if (Array.from(STOP_CHECK_TOURNAMENT).includes(tournamentState)) {
        return clearInterval(this.checkTournamentEndInterval);
      }
    }

    getTournamentState(mandate, courseInstanceID, levelSlug, timeOffset) {
      const tournament = _.find(mandate.currentTournament || [], t => (t.courseInstanceID === courseInstanceID) && (t.level === levelSlug));
      if (tournament) {
        let delta;
        const currentTime = (Date.now() + timeOffset) / 1000;
        console.log("Current time:", new Date(currentTime * 1000));
        if (currentTime < tournament.startAt) {
          delta = tournament.startAt - currentTime;
          console.log(`Tournament will start at: ${new Date(tournament.startAt * 1000)}, Time left: ${parseInt(delta / 60 / 60) }:${parseInt(delta / 60) % 60}:${parseInt(delta) % 60}`);
          return KEEP_CHECK_TOURNAMENT_CLOSE;
        } else if (currentTime > tournament.endAt) {
          console.log(`Tournament ended at: ${new Date(tournament.endAt * 1000)}`);
          return STOP_CHECK_TOURNAMENT_CLOSE;
        }
        delta = tournament.endAt - currentTime;
        console.log(`Tournament will end at: ${new Date(tournament.endAt * 1000)}, Time left: ${parseInt(delta / 60 / 60) }:${parseInt(delta / 60) % 60}:${parseInt(delta) % 60}`);
        return KEEP_CHECK_TOURNAMENT_OPEN;
      } else {
        if (Array.from(mandate.tournamentOnlyLevels || []).includes(levelSlug)) { return STOP_CHECK_TOURNAMENT_CLOSE; } else { return STOP_CHECK_TOURNAMENT_OPEN; }
      }
    }

    calcTimeOffset() {
      return $.ajax({
        type: 'HEAD',
        success: (result, status, xhr) => {
          return this.timeOffset = new Date(xhr.getResponseHeader("Date")).getTime() - Date.now();
        }
      });
    }

    trackLevelLoadEnd() {
      if (this.isEditorPreview) { return; }
      this.loadEndTime = new Date();
      this.loadDuration = this.loadEndTime - this.loadStartTime;
      console.debug(`Level unveiled after ${(this.loadDuration / 1000).toFixed(2)}s`);
      if (!this.observing && !this.isEditorPreview) {
        if (application.tracker != null) {
          application.tracker.trackEvent('Finished Level Load', {category: 'Play Level', label: this.levelID, level: this.levelID, loadDuration: this.loadDuration});
        }
        return (application.tracker != null ? application.tracker.trackTiming(this.loadDuration, 'Level Load Time', this.levelID, this.levelID) : undefined);
      }
    }

    isCourseMode() { return this.courseID && this.courseInstanceID; }

    // CocoView overridden methods ###############################################

    getRenderData() {
      const c = super.getRenderData();
      c.world = this.world;
      return c;
    }

    afterRender() {
      super.afterRender();
      if (typeof window.onPlayLevelViewLoaded === 'function') {
        window.onPlayLevelViewLoaded(this);
      }  // still a hack
      this.insertSubView(this.loadingView = new LevelLoadingView({autoUnveil: this.options.autoUnveil || this.observing, level: (this.levelLoader != null ? this.levelLoader.level : undefined) != null ? (this.levelLoader != null ? this.levelLoader.level : undefined) : this.level, session: (this.levelLoader != null ? this.levelLoader.session : undefined) != null ? (this.levelLoader != null ? this.levelLoader.session : undefined) : this.session}));  // May not have @level loaded yet
      this.$el.find('#level-done-button').hide();
      $('body').addClass('is-playing');
      if (this.isIPadApp()) { return $('body').bind('touchmove', false); }
    }

    afterInsert() {
      return super.afterInsert();
    }

    // Partially Loaded Setup ####################################################

    onWorldNecessitiesLoaded() {
      // Called when we have enough to build the world, but not everything is loaded
      let left, left1, left2, randomTeam;
      this.grabLevelLoaderData();

      const levelName = utils.i18n(this.level.attributes, 'name');
      this.setMeta({title: $.i18n.t('play.level_title', { level: levelName, interpolation: { escapeValue: false } })});

      if (!this.level.isType('ladder')) {
        randomTeam = this.world != null ? this.world.teamForPlayer() : undefined;  // If no team is set, then we will want to equally distribute players to teams
      }
      const team = (left = (left1 = (left2 = utils.getQueryVariable('team')) != null ? left2 : (this.session != null ? this.session.get('team') : undefined)) != null ? left1 : randomTeam) != null ? left : 'humans';
      this.loadOpponentTeam(team);
      this.setupGod();
      this.setTeam(team);
      this.initGoalManager();
      this.insertSubviews();
      this.initVolume();
      this.register();
      this.controlBar.setBus(this.bus);
      return this.initScriptManager();
    }

    onWorldNecessityLoadFailed(resource) {
      return this.loadingView.onLoadError(resource);
    }

    grabLevelLoaderData() {
      this.session = this.levelLoader.session;
      this.level = this.levelLoader.level;
      store.commit('game/setLevel', this.level.attributes);
      if (this.level.isType('web-dev')) {
        this.$el.addClass('web-dev');  // Hide some of the elements we won't be using
        return;
      }
      this.world = this.levelLoader.world;
      if (this.level.isType('game-dev')) {
        this.$el.addClass('game-dev');
        this.howToPlayText = utils.i18n(this.level.attributes, 'studentPlayInstructions');
        if (this.howToPlayText == null) { this.howToPlayText = $.i18n.t('play_game_dev_level.default_student_instructions'); }
        this.howToPlayText = marked(this.howToPlayText, { sanitize: true });
        this.renderSelectors('#how-to-play-game-dev-panel');
      }
      if (_.any(this.world.thangs, t => (t.programmableProperties && Array.from(t.programmableProperties).includes('findFlags')) || (t.inventory != null ? t.inventory.flag : undefined)) || (this.level.get('slug') === 'sky-span')) { this.$el.addClass('flags'); }
      this.spellPalettePosition = this.getSpellPalettePosition();
      if (this.spellPalettePosition === 'bot') { this.$el.addClass('no-api'); }
      // TODO: Update terminology to always be opponentSession or otherSession
      // TODO: E.g. if it's always opponent right now, then variable names should be opponentSession until we have coop play
      this.otherSession = this.levelLoader.opponentSession;
      if (!this.level.isType('game-dev')) {
        this.worldLoadFakeResources = [];  // first element (0) is 1%, last (99) is 100%
        for (let percent = 1; percent <= 100; percent++) {
          this.worldLoadFakeResources.push(this.supermodel.addSomethingResource(1));
        }
      }
      return this.renderSelectors('#stop-real-time-playback-button');
    }

    onWorldLoadProgressChanged(e) {
      if (e.god !== this.god) { return; }
      if (!this.worldLoadFakeResources) { return; }
      if (this.lastWorldLoadPercent == null) { this.lastWorldLoadPercent = 0; }
      const worldLoadPercent = Math.floor(100 * e.progress);
      for (let percent = this.lastWorldLoadPercent + 1, end = worldLoadPercent; percent <= end; percent++) {
        this.worldLoadFakeResources[percent - 1].markLoaded();
      }
      this.lastWorldLoadPercent = worldLoadPercent;
      if (worldLoadPercent === 100) { return this.worldFakeLoadResources = null; }  // Done, don't need to watch progress any more.
    }

    loadOpponentTeam(myTeam) {
      let opponentSpells = [];
      for (var spellTeam in utils.teamSpells) {
        var spells = utils.teamSpells[spellTeam];
        if ((spellTeam === myTeam) || !myTeam) { continue; }
        opponentSpells = opponentSpells.concat(spells);
      }
      if (!this.session.get('teamSpells')) {
        this.session.set('teamSpells', utils.teamSpells);
      }
      const opponentCode = (this.otherSession != null ? this.otherSession.get('code') : undefined) || {};
      const myCode = this.session.get('code') || {};
      for (var spell of Array.from(opponentSpells)) {
        var thang;
        [thang, spell] = Array.from(spell.split('/'));
        var c = opponentCode[thang] != null ? opponentCode[thang][spell] : undefined;
        if (myCode[thang] == null) { myCode[thang] = {}; }
        if (c) { myCode[thang][spell] = c; } else { delete myCode[thang][spell]; }
      }
      return this.session.set('code', myCode);
    }

    setupGod() {
      if (this.level.isType('web-dev')) { return; }
      if (!this.god) { return this.waitingToSetUpGod = true; }
      this.waitingToSetUpGod = undefined;
      const serializedLevel = this.level.serialize({supermodel: this.supermodel, session: this.session, otherSession: this.otherSession, headless: false, sessionless: false});
      if (me.constrainHeroHealth()) {
        serializedLevel.constrainHeroHealth = true;
      }
      this.god.setLevel(serializedLevel);
      this.god.setLevelSessionIDs(this.otherSession ? [this.session.id, this.otherSession.id] : [this.session.id]);
      return this.god.setWorldClassMap(this.world.classMap);
    }

    setTeam(team) {
      if (!_.isString(team)) { team = team != null ? team.team : undefined; }
      if (team == null) { team = 'humans'; }
      me.team = team;
      this.session.set('team', team);
      Backbone.Mediator.publish('level:team-set', {team});  // Needed for scripts
      return this.team = team;
    }

    initGoalManager() {
      const options = {};

      if (this.level.get('assessment') === 'cumulative') {
        options.minGoalsToComplete = 1;
      }
      this.goalManager = new GoalManager(this.world, this.level.get('goals'), this.team, options);
      return (this.god != null ? this.god.setGoalManager(this.goalManager) : undefined);
    }

    updateGoals(goals) {
      this.level.set('goals', goals);
      this.goalManager.destroy();
      return this.initGoalManager();
    }

    getSpellPalettePosition() {
      let heroThang, position;
      if (this.spellPalettePosition) { return this.spellPalettePosition; }
      if (position = utils.getQueryVariable('apis')) { return position; }
      if (this.level.isType('game-dev', 'web-dev')) { return 'mid'; }
      const heroID = this.team === 'ogres' ? 'Hero Placeholder 1' : 'Hero Placeholder';
      if (!(heroThang = this.world != null ? this.world.getThangByID(heroID) : undefined)) { return 'mid'; }
      let programmablePropCount = 0;
      for (var propStorage of ['programmableProperties', 'programmableSnippets', 'moreProgrammableProperties']) {
        programmablePropCount += (heroThang[propStorage] != null ? heroThang[propStorage].length : undefined) || 0;
      }
      if (programmablePropCount < 16) {
        return 'bot';
      } else {
        return 'mid';
      }
    }

    updateSpellPalette(thang, spell) {
      if (!thang || ((this.spellPaletteView != null ? this.spellPaletteView.thang : undefined) === thang) || (!thang.programmableProperties && !thang.apiProperties && !thang.programmableHTMLProperties)) { return false; }
      const useHero = /hero/.test(spell.getSource()) || !/(self[\.\:]|this\.|\@)/.test(spell.getSource());
      if (this.spellPaletteView && !(this.spellPaletteView != null ? this.spellPaletteView.destroyed : undefined)) { this.removeSubView(this.spellPaletteView); }
      this.spellPaletteView = null;
      if (this.getSpellPalettePosition() === 'bot') {
        // We'l make it inside Tome instead
        this.$el.toggleClass('no-api', true);
        return false;
      }
      // We'll manage it here
      this.spellPaletteView = this.insertSubView(new SpellPaletteViewMid({ thang, supermodel: this.supermodel, programmable: (spell != null ? spell.canRead() : undefined), language: (spell != null ? spell.language : undefined) != null ? (spell != null ? spell.language : undefined) : this.session.get('codeLanguage'), session: this.session, level: this.level, courseID: this.courseID, courseInstanceID: this.courseInstanceID, useHero }));
      if (spell != null ? spell.view : undefined) { this.spellPaletteView.toggleControls({}, spell.view.controlsEnabled); }
      this.$el.toggleClass('no-api', false);
      return true;
    }

    insertSubviews() {
      let needle;
      this.hintsState = new HintsState({ hidden: true }, { session: this.session, level: this.level, supermodel: this.supermodel });
      store.commit('game/setHintsVisible', false);
      this.hintsState.on('change:hidden', (hintsState, newHiddenValue) => store.commit('game/setHintsVisible', !newHiddenValue));
      this.insertSubView(this.tome = new TomeView({ levelID: this.levelID, session: this.session, otherSession: this.otherSession, playLevelView: this, thangs: (this.world != null ? this.world.thangs : undefined) != null ? (this.world != null ? this.world.thangs : undefined) : [], supermodel: this.supermodel, level: this.level, observing: this.observing, courseID: this.courseID, courseInstanceID: this.courseInstanceID, god: this.god, hintsState: this.hintsState, classroomAceConfig: this.classroomAceConfig, teacherID: this.teacherID}));
      if (!this.level.isType('web-dev')) { this.insertSubView(new LevelPlaybackView({session: this.session, level: this.level})); }
      this.insertSubView(new GoalsView({level: this.level, session: this.session}));
      if (this.$el.hasClass('flags')) { this.insertSubView(new LevelFlagsView({levelID: this.levelID, world: this.world})); }
      const goldInDuelStatsView = (needle = this.level.get('slug'), ['wakka-maul', 'cross-bones'].includes(needle));
      if (!this.level.isType('web-dev', 'game-dev') && !goldInDuelStatsView) { this.insertSubView(new GoldView({})); }
      if (this.level.isType('game-dev')) { this.insertSubView(new GameDevTrackView({})); }
      if (!this.level.isType('web-dev')) { this.insertSubView(new HUDView({level: this.level})); }
      this.insertSubView(new LevelDialogueView({level: this.level, sessionID: this.session.id}));
      this.insertSubView(new ChatView({levelID: this.levelID, sessionID: this.session.id, session: this.session, aceConfig: this.classroomAceConfig}));
      this.insertSubView(new ProblemAlertView({session: this.session, level: this.level, supermodel: this.supermodel}));
      this.insertSubView(new SurfaceContextMenuView({session: this.session, level: this.level}));
      if (this.level.isLadder()) { this.insertSubView(new DuelStatsView({level: this.level, session: this.session, otherSession: this.otherSession, supermodel: this.supermodel, thangs: this.world.thangs, showsGold: goldInDuelStatsView})); }
      this.insertSubView(this.controlBar = new ControlBarView({worldName: utils.i18n(this.level.attributes, 'name'), session: this.session, level: this.level, supermodel: this.supermodel, courseID: this.courseID, courseInstanceID: this.courseInstanceID, classroomAceConfig: this.classroomAceConfig}));
      this.insertSubView((this.hintsView = new HintsView({ session: this.session, level: this.level, hintsState: this.hintsState })), this.$('.hints-view'));
      if (this.level.isType('web-dev')) { return this.insertSubView(this.webSurface = new WebSurfaceView({level: this.level, goalManager: this.goalManager})); }
    }
      //_.delay (=> Backbone.Mediator.publish('level:set-debug', debug: true)), 5000 if @isIPadApp()   # if me.displayName() is 'Nick'

    initVolume() {
      let volume = me.get('volume');
      if (volume == null) { volume = 1.0; }
      return Backbone.Mediator.publish('level:set-volume', {volume});
    }

    initScriptManager() {
      if (this.level.isType('web-dev')) { return; }
      this.scriptManager = new ScriptManager({scripts: this.world.scripts || [], view: this, session: this.session, levelID: this.level.get('slug')});
      return this.scriptManager.loadFromSession();
    }

    register() {
      this.bus = LevelBus.get(this.levelID, this.session.id);
      this.bus.setSession(this.session);
      this.bus.setSpells(this.tome.spells);

      if (this.teacherID) {
        return this.bus.subscribeTeacher(this.teacherID);
      }
    }
      //@bus.connect() if @session.get('multiplayer')  # TODO: session's multiplayer flag removed; connect bus another way if we care about it

    // Load Completed Setup ######################################################

    onSessionLoaded(e) {
      let left, left1;
      store.commit('game/setTimesCodeRun', e.session.get('timesCodeRun') || 0);
      store.commit('game/setTimesAutocompleteUsed', e.session.get('timesAutocompleteUsed') || 0);
      if (this.session) { return; }
      Backbone.Mediator.publish("ipad:language-chosen", {language: (left = e.session.get('codeLanguage')) != null ? left : "python"});
      // Just the level and session have been loaded by the level loader
      if (e.level.isType('hero', 'hero-ladder', 'hero-coop') && !_.size((left1 = __guard__(e.session.get('heroConfig'), x => x.inventory)) != null ? left1 : {}) && (e.level.get('assessment') !== 'open-ended')) {
        // Delaying this check briefly so LevelLoader.loadDependenciesForSession has a chance to set the heroConfig on the level session
        return _.defer(() => {
          let left2;
          if (this.destroyed || _.size((left2 = __guard__(e.session.get('heroConfig'), x1 => x1.inventory)) != null ? left2 : {})) { return; }
          // TODO: which scenario is this executed for?
          if (this.setupManager != null) {
            this.setupManager.destroy();
          }
          this.setupManager = new LevelSetupManager({supermodel: this.supermodel, level: e.level, levelID: this.levelID, parent: this, session: e.session, courseID: this.courseID, courseInstanceID: this.courseInstanceID});
          return this.setupManager.open();
        });
      }
    }

    onLoaded() {
      return _.defer(() => (typeof this.onLevelLoaderLoaded === 'function' ? this.onLevelLoaderLoaded() : undefined));
    }

    onLevelLoaderLoaded() {
      // Everything is now loaded
      if (this.levelLoader.progress() !== 1) { return; }  // double check, since closing the guide may trigger this early

      // Save latest level played.
      if (!this.observing && !this.isEditorPreview && !this.levelLoader.level.isType('ladder-tutorial')) {
        me.set('lastLevel', this.levelID);
        me.save();
        if (application.tracker != null) {
          application.tracker.identify();
        }
      }
      if (this.otherSession) { this.saveRecentMatch(); }
      this.levelLoader.destroy();
      this.levelLoader = null;
      if (this.level.isType('web-dev')) {
        return Backbone.Mediator.publish('level:started', {});
      } else {
        return this.initSurface();
      }
    }

    saveRecentMatch() {
      let left;
      const allRecentlyPlayedMatches = (left = storage.load('recently-played-matches')) != null ? left : {};
      const recentlyPlayedMatches = allRecentlyPlayedMatches[this.levelID] != null ? allRecentlyPlayedMatches[this.levelID] : [];
      allRecentlyPlayedMatches[this.levelID] = recentlyPlayedMatches;
      if (!_.find(recentlyPlayedMatches, {otherSessionID: this.otherSession.id})) { recentlyPlayedMatches.unshift({yourTeam: me.team, otherSessionID: this.otherSession.id, opponentName: this.otherSession.get('creatorName')}); }
      recentlyPlayedMatches.splice(8);
      return storage.save('recently-played-matches', allRecentlyPlayedMatches);
    }

    initSurface() {
      const webGLSurface = $('canvas#webgl-surface', this.$el);
      const normalSurface = $('canvas#normal-surface', this.$el);
      const surfaceOptions = {
        thangTypes: this.supermodel.getModels(ThangType),
        observing: this.observing,
        playerNames: this.findPlayerNames(),
        levelType: this.level.get('type', true),
        gameUIState: this.gameUIState,
        level: this.level // TODO: change from levelType to level
      };
      this.surface = new Surface(this.world, normalSurface, webGLSurface, surfaceOptions);
      const worldBounds = this.world.getBounds();
      const bounds = [{x: worldBounds.left, y: worldBounds.top}, {x: worldBounds.right, y: worldBounds.bottom}];
      this.surface.camera.setBounds(bounds);
      this.surface.camera.zoomTo({x: 0, y: 0}, 0.1, 0);
      return this.listenTo(this.surface, 'resize', function({ height }) {
        this.$('#stop-real-time-playback-button').css({ top: height - 30 });
        return this.$('#how-to-play-game-dev-panel').css({ height });
      });
    }

    findPlayerNames() {
      if (!this.level.isType('ladder', 'hero-ladder', 'course-ladder')) { return {}; }
      const playerNames = {};
      for (var session of [this.session, this.otherSession]) {
        if ((session != null ? session.get('team') : undefined)) {
          playerNames[session.get('team')] = utils.getCorrectName(session);
        }
      }
      return playerNames;
    }

    // Once Surface is Loaded ####################################################

    onLevelStarted() {
      if ((this.surface == null) && (this.webSurface == null)) { return; }
      this.loadingView.showReady();
      this.trackLevelLoadEnd();
      if (window.currentModal && !window.currentModal.destroyed && ([VictoryModal, CourseVictoryModal, HeroVictoryModal].indexOf(window.currentModal.constructor) === -1)) {
        return Backbone.Mediator.subscribeOnce('modal:closed', this.onLevelStarted, this);
      }
      if (this.surface != null) {
        this.surface.showLevel();
      }
      Backbone.Mediator.publish('level:set-time', {time: 0});
      if ((this.isEditorPreview || this.observing) && !utils.getQueryVariable('intro')) {
        this.loadingView.startUnveiling();
        return this.loadingView.unveil(true);
      } else {
        return (this.scriptManager != null ? this.scriptManager.initializeCamera() : undefined);
      }
    }

    onLoadingViewUnveiling(e) {
      return this.selectHero();
    }

    onLoadingViewUnveiled(e) {
      if (this.level.isType('course-ladder', 'hero-ladder', 'ladder') || this.observing) {
        // We used to autoplay by default, but now we only do it if the level says to in the introduction script.
        Backbone.Mediator.publish('level:set-playing', {playing: true});
      }
      this.loadingView.$el.remove();
      this.removeSubView(this.loadingView);
      this.loadingView = null;
      this.playAmbientSound();
      // TODO: Is it possible to create a Mongoose ObjectId for 'ls', instead of the string returned from get()?
      if (!this.observing && !this.isEditorPreview) { if (application.tracker != null) {
        application.tracker.trackEvent('Started Level', {category:'Play Level', label: this.levelID, levelID: this.levelID, ls: (this.session != null ? this.session.get('_id') : undefined)});
      } }
      $(window).trigger('resize');
      return _.delay((() => (typeof this.perhapsStartSimulating === 'function' ? this.perhapsStartSimulating() : undefined)), 10 * 1000);
    }

    onSetVolume(e) {
      createjs.Sound.volume = e.volume === 1 ? 0.6 : e.volume;  // Quieter for now until individual sound FX controls work again.
      if (e.volume && !this.ambientSound) {
        return this.playAmbientSound();
      }
    }

    playAmbientSound() {
      let file;
      if (this.destroyed) { return; }
      if (this.ambientSound) { return; }
      if (!me.get('volume')) { return; }
      if (!(file = {Dungeon: 'ambient-dungeon', Grass: 'ambient-grass'}[this.level.get('terrain')])) { return; }
      const src = `/file/interface/${file}${AudioPlayer.ext}`;
      if (!__guard__(AudioPlayer.getStatus(src), x => x.loaded)) {
        AudioPlayer.preloadSound(src);
        Backbone.Mediator.subscribeOnce('audio-player:loaded', this.playAmbientSound, this);
        return;
      }
      this.ambientSound = createjs.Sound.play(src, {loop: -1, volume: 0.1});
      return createjs.Tween.get(this.ambientSound).to({volume: 1.0}, 10000);
    }

    selectHero() {
      Backbone.Mediator.publish('level:suppress-selection-sounds', {suppress: true});
      Backbone.Mediator.publish('tome:select-primary-sprite', {});
      Backbone.Mediator.publish('level:suppress-selection-sounds', {suppress: false});
      return (this.surface != null ? this.surface.focusOnHero() : undefined);
    }

    perhapsStartSimulating() {
      if (!this.shouldSimulate()) { return; }
      let languagesToLoad = ['javascript', 'python', 'coffeescript', 'lua'];  // java, cpp
      return Array.from(languagesToLoad).map((language) =>
        (language => {
          return loadAetherLanguage(language).then(aetherLang => {
            languagesToLoad = _.without(languagesToLoad, language);
            if (!languagesToLoad.length) {
              return this.simulateNextGame();
            }
          });
        })(language));
    }

    simulateNextGame() {
      if (this.simulator) { return this.simulator.fetchAndSimulateOneGame(); }
      const simulatorOptions = {background: true, leagueID: this.courseInstanceID};
      if (this.level.isLadder()) { simulatorOptions.levelID = this.level.get('slug'); }
      this.simulator = new Simulator(simulatorOptions);
      // Crude method of mitigating Simulator memory leak issues
      const fetchAndSimulateOneGameOriginal = this.simulator.fetchAndSimulateOneGame;
      this.simulator.fetchAndSimulateOneGame = () => {
        if (this.simulator.simulatedByYou >= 10) {
          console.log('------------------- Destroying Simulator and making a new one -----------------');
          this.simulator.destroy();
          this.simulator = null;
          return this.simulateNextGame();
        } else {
          return fetchAndSimulateOneGameOriginal.apply(this.simulator);
        }
      };
      return this.simulator.fetchAndSimulateOneGame();
    }

    shouldSimulate() {
      let needle;
      if (utils.getQueryVariable('simulate') === true) { return true; }
      return false;  // Disabled due to unresolved crashing issues
      if (utils.getQueryVariable('simulate') === false) { return false; }
      if (this.isEditorPreview) { return false; }
      const defaultCores = 2;
      const cores = window.navigator.hardwareConcurrency || defaultCores;  // Available on Chrome/Opera, soon Safari
      const defaultHeapLimit = 793000000;
      const heapLimit = __guard__(window.performance != null ? window.performance.memory : undefined, x => x.jsHeapSizeLimit) || defaultHeapLimit;  // Only available on Chrome, basically just says 32- vs. 64-bit
      const gamesSimulated = me.get('simulatedBy');
      console.debug("Should we start simulating? Cores:", window.navigator.hardwareConcurrency, "Heap limit:", __guard__(window.performance != null ? window.performance.memory : undefined, x1 => x1.jsHeapSizeLimit), "Load duration:", this.loadDuration);
      if (!($.browser != null ? $.browser.desktop : undefined)) { return false; }
      if (($.browser != null ? $.browser.msie : undefined) || ($.browser != null ? $.browser.msedge : undefined)) { return false; }
      if ($.browser.linux) { return false; }
      if (me.level() < 8) { return false; }
      if ((needle = this.level.get('slug'), ['zero-sum', 'ace-of-coders', 'elemental-wars'].includes(needle))) { return false; }
      if (this.level.isType('course', 'game-dev', 'web-dev')) {
        return false;
      } else if (this.level.isType('hero') && gamesSimulated) {
        if (cores < 8) { return false; }
        if (heapLimit < defaultHeapLimit) { return false; }
        if (this.loadDuration > 10000) { return false; }
      } else if (this.level.isType('hero-ladder') && gamesSimulated) {
        if (cores < 4) { return false; }
        if (heapLimit < defaultHeapLimit) { return false; }
        if (this.loadDuration > 15000) { return false; }
      } else if (this.level.isType('hero-ladder') && !gamesSimulated) {
        if (cores < 8) { return false; }
        if (heapLimit <= defaultHeapLimit) { return false; }
        if (this.loadDuration > 12000) { return false; }
      } else if (this.level.isType('course-ladder')) {
        if (cores <= defaultCores) { return false; }
        if (heapLimit < defaultHeapLimit) { return false; }
        if (this.loadDuration > 18000) { return false; }
      } else if (this.level.isType('ladder')) {
        if (cores <= defaultCores) { return false; }
        if (heapLimit < defaultHeapLimit) { return false; }
        if (this.loadDuration > 18000) { return false; }
      } else {
        console.warn(`Unwritten level type simulation heuristics; fill these in for new level type ${this.level.get('type')}?`);
        if (cores < 8) { return false; }
        if (heapLimit < defaultHeapLimit) { return false; }
        if (this.loadDuration > 10000) { return false; }
      }
      console.debug("We should have the power. Begin background ladder simulation.");
      return true;
    }

    // callbacks

    onCtrlS(e) {
      return e.preventDefault();
    }

    onEscapePressed(e) {
      if (this.$el.hasClass('real-time')) {
        return Backbone.Mediator.publish('playback:stop-real-time-playback', {});
      } else if (this.$el.hasClass('cinematic')) {
        return Backbone.Mediator.publish('playback:stop-cinematic-playback', {});
      }
    }

    onLevelReloadFromData(e) {
      const isReload = Boolean(this.world);
      if (isReload) {
        // Make sure to share any models we loaded that the parent didn't, like hero equipment, in case the parent relodaed
        for (var url in this.supermodel.models) { var model = this.supermodel.models[url]; if (!e.supermodel.models[url]) { e.supermodel.registerModel(model); } }
      }
      this.setLevel(e.level, e.supermodel);
      if (isReload) {
        this.scriptManager.setScripts(e.level.get('scripts'));
        this.updateGoals(e.level.get('goals'));
        return Backbone.Mediator.publish('tome:cast-spell', {});  // a bit hacky
      }
    }

    onLevelReloadThangType(e) {
      const tt = e.thangType;
      for (var url in this.supermodel.models) {
        var model = this.supermodel.models[url];
        if (model.id === tt.id) {
          for (var key in tt.attributes) {
            var val = tt.attributes[key];
            model.attributes[key] = val;
          }
          break;
        }
      }
      return Backbone.Mediator.publish('tome:cast-spell', {});
    }

    onWindowResize(e) {
      return this.endHighlight();
    }

    onDisableControls(e) {
      if (e.controls && !(Array.from(e.controls).includes('level'))) { return; }
      this.shortcutsEnabled = false;
      this.wasFocusedOn = document.activeElement;
      return $('body').focus();
    }

    onEnableControls(e) {
      if ((e.controls != null) && !(Array.from(e.controls).includes('level'))) { return; }
      this.shortcutsEnabled = true;
      if (this.wasFocusedOn) { $(this.wasFocusedOn).focus(); }
      return this.wasFocusedOn = null;
    }

    onDonePressed() { return this.showVictory(); }

    onShowVictory(e) {
      if (e == null) { e = {}; }
      if (!this.level.isType('hero', 'hero-ladder', 'hero-coop', 'course', 'course-ladder', 'game-dev', 'web-dev', 'ladder')) { $('#level-done-button').show(); }  // TODO: do we ever use this? Should remove if not.
      if (e.showModal) { this.showVictory(_.pick(e, 'manual')); }
      if (this.victorySeen) { return; }
      this.victorySeen = true;
      const victoryTime = (new Date()) - this.loadEndTime;
      if (!this.observing && !this.isEditorPreview && (victoryTime > (10 * 1000))) {   // Don't track it if we're reloading an already-beaten level
        if (application.tracker != null) {
          application.tracker.trackEvent('Saw Victory', {
          category: 'Play Level',
          level: this.level.get('name'),
          label: this.level.get('name'),
          levelID: this.levelID,
          ls: (this.session != null ? this.session.get('_id') : undefined),
          playtime: (this.session != null ? this.session.get('playtime') : undefined)
        }
        );
        }
        return (application.tracker != null ? application.tracker.trackTiming(victoryTime, 'Level Victory Time', this.levelID, this.levelID) : undefined);
      }
    }

    showVictory(options) {
      if (options == null) { options = {}; }
      if (this.level.hasLocalChanges()) { return; }  // Don't award achievements when beating level changed in level editor
      if (this.level.isType('game-dev') && this.level.get('shareable') && !options.manual) { return; }
      if (this.showVictoryHandlingInProgress) { return; }
      this.showVictoryHandlingInProgress=true;
      this.endHighlight();
      options = {level: this.level, supermodel: this.supermodel, session: this.session, hasReceivedMemoryWarning: this.hasReceivedMemoryWarning, courseID: this.courseID, courseInstanceID: this.courseInstanceID, world: this.world, parent: this};
      let ModalClass = this.level.isType('hero', 'hero-ladder', 'hero-coop', 'course', 'course-ladder', 'game-dev', 'web-dev', 'ladder') ? HeroVictoryModal : VictoryModal;
      if (this.isCourseMode() || me.isSessionless()) { ModalClass = CourseVictoryModal; }
      if (this.level.isType('course-ladder') || (this.level.isType('ladder') && this.courseInstanceID)) {
        ModalClass = CourseVictoryModal;
        options.courseInstanceID = utils.getQueryVariable('course-instance') || utils.getQueryVariable('league');
      }
      if (window.serverConfig.picoCTF) { ModalClass = PicoCTFVictoryModal; }
      const victoryModal = new ModalClass(options);
      this.openModalView(victoryModal);
      victoryModal.once('hidden', () => {
        return this.showVictoryHandlingInProgress=false;
      });

      if (me.get('anonymous')) {
        let left;
        return window.nextURL = '/play/' + ((left = this.level.get('campaign')) != null ? left : '');  // Signup will go here on completion instead of reloading.
      }
    }

    onRestartLevel() {
      this.tome.reloadAllCode();
      Backbone.Mediator.publish('level:restarted', {});
      $('#level-done-button', this.$el).hide();
      if (!this.observing && !this.isEditorPreview) { return (application.tracker != null ? application.tracker.trackEvent('Confirmed Restart', {category: 'Play Level', level: this.level.get('name'), label: this.level.get('name')}) : undefined); }
    }

    onInfiniteLoop(e) {
      if (!e.firstWorld || (e.god !== this.god)) { return; }
      this.openModalView(new InfiniteLoopModal({nonUserCodeProblem: e.nonUserCodeProblem, problem: e.problem, timedOut: e.timedOut}));
      if (!this.observing && !this.isEditorPreview) { return (application.tracker != null ? application.tracker.trackEvent('Saw Initial Infinite Loop', {category: 'Play Level', level: this.level.get('name'), label: this.level.get('name')}) : undefined); }
    }

    onHighlightDOM(e) { return this.highlightElement(e.selector, {delay: e.delay, sides: e.sides, offset: e.offset, rotation: e.rotation}); }

    onEndHighlight() { return this.endHighlight(); }

    onFocusDom(e) { return $(e.selector).focus(); }

    onContactClicked(e) {
      let contactModal;
      if (me.isStudent()) {
        console.error("Student clicked contact modal.");
        return;
      }
      Backbone.Mediator.publish('level:contact-button-pressed', {});
      this.openModalView(contactModal = new ContactModal({levelID: this.level.get('slug') || this.level.id, courseID: this.courseID, courseInstanceID: this.courseInstanceID}));
      const screenshot = this.surface.screenshot(1, 'image/png', 1.0, 1);
      const body = {
        b64png: screenshot.replace('data:image/png;base64,', ''),
        filename: `screenshot-${this.levelID}-${_.string.slugify((new Date()).toString())}.png`,
        path: `db/user/${me.id}`,
        mimetype: 'image/png'
      };
      contactModal.screenshotURL = `http://codecombat.com/file/${body.path}/${body.filename}`;
      window.screenshot = screenshot;
      window.screenshotURL = contactModal.screenshotURL;
      return $.ajax('/file', { type: 'POST', data: body, success(e) {
        return (typeof contactModal.updateScreenshot === 'function' ? contactModal.updateScreenshot() : undefined);
      }
    }
      );
    }

    onSurfaceContextMenu(e) {
      __guardMethod__(e, 'preventDefault', o => o.preventDefault());
      if (this.$el.hasClass('real-time')) { return; }
      if (!this.surface.showCoordinates || ( !navigator.clipboard && !document.queryCommandSupported('copy') )) { return; }
      const pos = {x: e.clientX, y: e.clientY};
      const wop = this.surface.coordinateDisplay.lastPos;
      return Backbone.Mediator.publish('level:surface-context-menu-pressed', {posX: pos.x, posY: pos.y, wopX: wop.x, wopY: wop.y});
    }


    // Dynamic sound loading

    onNewWorld(e) {
      if (this.headless) { return; }
      const {
        scripts
      } = this.world;  // Since these worlds don't have scripts, preserve them.
      this.world = e.world;

      // without this check, when removing goals, goals aren't updated properly. Make sure we update
      // the goals once the first frame is finished.
      if ((this.world.age > 0) && this.willUpdateStudentGoals) {
        this.willUpdateStudentGoals = false;
        this.updateStudentGoals();
        this.updateLevelName();
      }

      this.world.scripts = scripts;
      const thangTypes = this.supermodel.getModels(ThangType);
      const startFrame = this.lastWorldFramesLoaded != null ? this.lastWorldFramesLoaded : 0;
      const finishedLoading = this.world.frames.length === this.world.totalFrames;
      this.realTimePlaybackWaitingForFrames = false;
      if (finishedLoading) {
        this.lastWorldFramesLoaded = 0;
        if (this.waitingForSubmissionComplete) {
          _.defer(this.onSubmissionComplete);  // Give it a frame to make sure we have the latest goals
          this.waitingForSubmissionComplete = false;
        }
      } else {
        this.lastWorldFramesLoaded = this.world.frames.length;
      }
      for (var [spriteName, message] of Array.from(this.world.thangDialogueSounds(startFrame))) {
        var sound, thangType;
        if (!(thangType = _.find(thangTypes, m => m.get('name') === spriteName))) { continue; }
        if (!(sound = AudioPlayer.soundForDialogue(message, thangType.get('soundTriggers')))) { continue; }
        AudioPlayer.preloadSoundReference(sound);
      }
      if (this.level.isType('game-dev', 'hero', 'course')) {
        return this.session.updateKeyValueDb(e.keyValueDb);
      }
    }

    // Real-time playback
    onRealTimePlaybackStarted(e) {
      this.$el.addClass('real-time').focus();
      this.willUpdateStudentGoals = true;
      this.updateStudentGoals();
      this.updateLevelName();
      this.onWindowResize();
      return this.realTimePlaybackWaitingForFrames = true;
    }

    updateStudentGoals() {
      if (!this.level.isType('game-dev')) { return; }
      // Set by users. Defined in `game.GameUI` component in the level editor.
      if (__guard__(this.world.uiText != null ? this.world.uiText.directions : undefined, x => x.length)) {
        this.studentGoals = this.world.uiText.directions.map(direction => ({
          type: "user_defined",
          direction
        }));
      } else {
        this.studentGoals = this.world.thangMap['Hero Placeholder'].stringGoals != null ? this.world.thangMap['Hero Placeholder'].stringGoals.map(g => JSON.parse(g)) : undefined;
      }
      this.renderSelectors('#how-to-play-game-dev-panel');
      return this.$('#how-to-play-game-dev-panel').removeClass('hide');
    }

    updateKeyValueDb() {
      if (!(this.world != null ? this.world.keyValueDb : undefined)) { return; }
      this.session.updateKeyValueDb(_.cloneDeep(this.world.keyValueDb));
      return this.session.saveKeyValueDb();
    }

    updateLevelName() {
      if (this.world.uiText != null ? this.world.uiText.levelName : undefined) {
        return this.controlBar.setLevelName(this.world.uiText.levelName);
      }
    }

    onRealTimePlaybackEnded(e) {
      if (!this.$el.hasClass('real-time')) { return; }
      if (this.level.isType('game-dev')) { this.$('#how-to-play-game-dev-panel').addClass('hide'); }
      this.$el.removeClass('real-time');
      this.onWindowResize();
      if (this.level.isType('game-dev', 'hero', 'course')) {
        this.session.saveKeyValueDb();
      }
      if ((this.world.frames.length === this.world.totalFrames) && !(this.surface.countdownScreen != null ? this.surface.countdownScreen.showing : undefined) && !this.realTimePlaybackWaitingForFrames) {
        return _.delay(this.onSubmissionComplete, 750);  // Wait for transition to end.
      } else {
        return this.waitingForSubmissionComplete = true;
      }
    }

    // Cinematice playback
    onCinematicPlaybackStarted(e) {
      this.$el.addClass('cinematic').focus();
      return this.onWindowResize();
    }

    onCinematicPlaybackEnded(e) {
      if (!this.$el.hasClass('cinematic')) { return; }
      this.$el.removeClass('cinematic');
      return this.onWindowResize();
    }

    onSubmissionComplete() {
      if (this.destroyed) { return; }
      Backbone.Mediator.publish('level:set-time', {ratio: 1});
      if (this.level.hasLocalChanges()) { return; }  // Don't award achievements when beating level changed in level editor
      if (this.goalManager.checkOverallStatus() === 'success') {
        const showModalFn = () => Backbone.Mediator.publish('level:show-victory', {showModal: true});
        this.session.recordScores(this.world.scores, this.level);
        if (this.level.get('replayable')) {
          return this.session.increaseDifficulty(showModalFn);
        } else {
          return showModalFn();
        }
      }
    }

    destroy() {
      let ambientSound;
      if (this.levelLoader != null) {
        this.levelLoader.destroy();
      }
      if (this.surface != null) {
        this.surface.destroy();
      }
      if (this.god != null) {
        this.god.destroy();
      }
      if (this.goalManager != null) {
        this.goalManager.destroy();
      }
      if (this.scriptManager != null) {
        this.scriptManager.destroy();
      }
      if (this.setupManager != null) {
        this.setupManager.destroy();
      }
      if (this.simulator != null) {
        this.simulator.destroy();
      }
      if (ambientSound = this.ambientSound) {
        // Doesn't seem to work; stops immediately.
        createjs.Tween.get(ambientSound).to({volume: 0.0}, 1500).call(() => ambientSound.stop());
      }
      $(window).off('resize', this.onWindowResize);
      delete window.world; // not sure where this is set, but this is one way to clean it up
      if (this.bus != null) {
        this.bus.destroy();
      }
      //@instance.save() unless @instance.loading
      delete window.nextURL;
      if (PROFILE_ME) { if (typeof console.profileEnd === 'function') {
        console.profileEnd();
      } }
      if (this.checkTournamentEndInterval) {
        clearInterval(this.checkTournamentEndInterval);
      }
      Backbone.Mediator.unsubscribe('modal:closed', this.onLevelStarted, this);
      Backbone.Mediator.unsubscribe('audio-player:loaded', this.playAmbientSound, this);
      return super.destroy();
    }

    onIPadMemoryWarning(e) {
      return this.hasReceivedMemoryWarning = true;
    }

    onItemPurchased(e) {
      let left;
      const heroConfig = (left = this.session.get('heroConfig')) != null ? left : {};
      const inventory = heroConfig.inventory != null ? heroConfig.inventory : {};
      const slot = e.item.getAllowedSlots()[0];
      if (slot && !inventory[slot]) {
        // Open up the inventory modal so they can equip the new item
        if (this.setupManager != null) {
          this.setupManager.destroy();
        }
        this.setupManager = new LevelSetupManager({supermodel: this.supermodel, level: this.level, levelID: this.levelID, parent: this, session: this.session, hadEverChosenHero: true});
        return this.setupManager.open();
      }
    }

    onCloseSolution() {
      return Backbone.Mediator.publish('level:close-solution', {});
    }

    getLoadTrackingTag() {
      return (this.level != null ? this.level.get('slug') : undefined);
    }

    onRunCode() {
      this.updateKeyValueDb();
      return store.commit('game/incrementTimesCodeRun');
    }
  };
  PlayLevelView.initClass();
  return PlayLevelView;
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