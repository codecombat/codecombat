// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS002: Fix invalid constructor
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__, or convert again using --optional-chaining
 * DS104: Avoid inline assignments
 * DS204: Change includes calls to have a more natural evaluation order
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let LevelLoader;
const Level = require('models/Level');
const LevelComponent = require('models/LevelComponent');
const LevelSystem = require('models/LevelSystem');
const Article = require('models/Article');
const LevelSession = require('models/LevelSession');
const {me} = require('core/auth');
const ThangType = require('models/ThangType');
const ThangNamesCollection = require('collections/ThangNamesCollection');
const LZString = require('lz-string');

const CocoClass = require('core/CocoClass');
const AudioPlayer = require('lib/AudioPlayer');
const World = require('lib/world/world');
const utils = require('core/utils');
const loadAetherLanguage = require('lib/loadAetherLanguage');

const LOG = false;

// This is an initial stab at unifying loading and setup into a single place which can
// monitor everything and keep a LoadingScreen visible overall progress.
//
// Would also like to incorporate into here:
//  * World Building
//  * Sprite map generation
//  * Connecting to Firebase

// LevelLoader depends on SuperModel retrying timed out requests, as these occasionally happen during play.
// If LevelLoader ever moves away from SuperModel, it will have to manage its own retries.

const reportedLoadErrorAlready = false;

module.exports = (LevelLoader = class LevelLoader extends CocoClass {

  constructor(options) {
    super()
    this.preloadTeamForSession = this.preloadTeamForSession.bind(this);
    this.preloadTokenForOpponentSession = this.preloadTokenForOpponentSession.bind(this);
    this.buildLoop = this.buildLoop.bind(this);
    this.t0 = new Date().getTime();
    this.supermodel = options.supermodel;
    this.supermodel.setMaxProgress(0.2);
    this.levelID = options.levelID;
    this.sessionID = options.sessionID;
    this.opponentSessionID = options.opponentSessionID;
    this.tournament = options.tournament != null ? options.tournament : false;
    this.team = options.team;
    this.headless = options.headless;
    this.loadArticles = options.loadArticles;
    this.sessionless = options.sessionless;
    this.fakeSessionConfig = options.fakeSessionConfig;
    this.spectateMode = options.spectateMode != null ? options.spectateMode : false;
    this.observing = options.observing;
    this.courseID = options.courseID;
    this.courseInstanceID = options.courseInstanceID;

    this.worldNecessities = [];
    this.listenTo(this.supermodel, 'resource-loaded', this.onWorldNecessityLoaded);
    this.listenTo(this.supermodel, 'failed', this.onWorldNecessityLoadFailed);
    this.loadLevel();
    this.loadAudio();
    this.playJingle();
    if (this.supermodel.finished()) {
      this.onSupermodelLoaded();
    } else {
      this.loadTimeoutID = setTimeout(this.reportLoadError.bind(this), 30000);
      this.listenToOnce(this.supermodel, 'loaded-all', this.onSupermodelLoaded);
    }
  }

  // Supermodel (Level) Loading

  loadWorldNecessities() {
    // TODO: Actually trigger loading, instead of in the constructor
    return new Promise((resolve, reject) => {
      if (this.world) { return resolve(this); }
      this.once('world-necessities-loaded', () => resolve(this));
      return this.once('world-necessity-load-failed', function({resource}) {
        const { jqxhr } = resource;
        return reject({message: (jqxhr.responseJSON != null ? jqxhr.responseJSON.message : undefined) || jqxhr.responseText || 'Unknown Error'});
    });
    });
  }

  loadLevel() {
    this.level = this.supermodel.getModel(Level, this.levelID) || new Level({_id: this.levelID});
    if (this.level.loaded) {
      return this.onLevelLoaded();
    } else {
      this.level = this.supermodel.loadModel(this.level, 'level').model;
      return this.listenToOnce(this.level, 'sync', this.onLevelLoaded);
    }
  }

  reportLoadError() {
    if (this.destroyed) { return; }
    return window.tracker != null ? window.tracker.trackEvent('LevelLoadError', {
      category: 'Error',
      levelSlug: __guard__(this.work != null ? this.work.level : undefined, x => x.slug),
      unloaded: JSON.stringify(this.supermodel.report().map(m => _.result(m.model, 'url')))
    }
    ) : undefined;
  }

  onLevelLoaded() {
    let originalGet;
    if (!this.sessionless && this.level.isType('hero', 'hero-ladder', 'hero-coop', 'course')) {
      this.sessionDependenciesRegistered = {};
    }
    if (this.level.isType('web-dev')) {
      this.headless = true;
      if (this.sessionless) {
        // When loading a web-dev level in the level editor, pretend it's a normal hero level so we can put down our placeholder Thang.
        // TODO: avoid this whole roundabout Thang-based way of doing web-dev levels
        originalGet = this.level.get;
        this.level.get = function() {
          if (arguments[0] === 'type') { return 'hero'; }
          if (arguments[0] === 'realType') { return 'web-dev'; }
          return originalGet.apply(this, arguments);
        };
      }
    }
    // I think the modification from https://github.com/codecombat/codecombat/commit/09e354177cb5df7e82cc66668f4c9b6d66d1d740#diff-0aef265179ff51db5b47a0f5be07eea7765664222fcbea6780439f50cd374209L105-R105
    // Can go to Ozaria as well
    if ((this.courseID && !this.level.isType('course', 'course-ladder', 'game-dev', 'web-dev', 'ladder')) || window.serverConfig.picoCTF) {
      // Because we now use original hero levels for both hero and course levels, we fake being a course level in this context.
      originalGet = this.level.get;
      const realType = this.level.get('type');
      this.level.get = function() {
        if (arguments[0] === 'type') { return 'course'; }
        if (arguments[0] === 'realType') { return realType; }
        return originalGet.apply(this, arguments);
      };
    }
    if (window.serverConfig.picoCTF) {
      this.supermodel.addRequestResource({url: '/picoctf/problems', success: picoCTFProblems => {
        return (this.level != null ? this.level.picoCTFProblem = _.find(picoCTFProblems, {pid: this.level.get('picoCTFProblem')}) : undefined);
      }
      }).load();
    }
    if (this.sessionless) {
      null;
    } else if (this.fakeSessionConfig != null) {
      this.loadFakeSession();
    } else {
      this.loadSession();
    }
    return this.populateLevel();
  }

  // Session Loading

  loadFakeSession() {
    const initVals = {
      level: {
        original: this.level.get('original'),
        majorVersion: this.level.get('version').major
      },
      creator: me.id,
      state: {
        complete: false,
        scripts: {}
      },
      permissions: [
        {target: me.id, access: 'owner'},
        {target: 'public', access: 'write'}
      ],
      codeLanguage: this.fakeSessionConfig.codeLanguage || __guard__(me.get('aceConfig'), x => x.language) || 'python',
      _id: LevelSession.fakeID
    };
    this.session = new LevelSession(initVals);
    this.session.loaded = true;
    if (typeof this.fakeSessionConfig.callback === 'function') {
      this.fakeSessionConfig.callback(this.session, this.level);
    }

    // TODO: set the team if we need to, for multiplayer
    // TODO: just finish the part where we make the submit button do what is right when we are fake
    // TODO: anything else to make teacher session-less play make sense when we are fake
    // TODO: make sure we are not actually calling extra save/patch/put things throwing warnings because we know we are fake and so we shouldn't try to do that
    for (var method of ['save', 'patch', 'put']) {
      this.session[method] = () => console.error(`We shouldn't be doing a session.${method}, since it's a fake session.`);
    }
    this.session.fake = true;
    return this.loadDependenciesForSession(this.session);
  }

  loadSession() {
    let opponentSession, url;
    const league = utils.getQueryVariable('league');
    if (this.sessionID) {
      url = `/db/level.session/${this.sessionID}`;
      if (this.spectateMode) {
        url += "?interpret=true";
        if (league) {
          url = `/db/spectate/${league}/level.session/${this.sessionID}`;
        }
      }
    } else {
      let codeLanguage, password;
      url = `/db/level/${this.levelID}/session`;
      if (this.team) {
        if (this.level.isType('ladder')) {
          url += '?team=humans'; // only query for humans when type ladder
        } else {
          url += `?team=${this.team}`;
        }
        if (this.level.isType('course-ladder') && league && !this.courseInstanceID) {
          url += `&courseInstance=${league}`;
        } else if (utils.isCodeCombat && this.courseID) {
          url += `&course=${this.courseID}`;
          if (this.courseInstanceID) {
            url += `&courseInstance=${this.courseInstanceID}`;
          }
        }
      } else if (this.courseID) {
        url += `?course=${this.courseID}`;
        if (this.courseInstanceID) {
          url += `&courseInstance=${this.courseInstanceID}`;
        }
      } else if (codeLanguage = utils.getQueryVariable('codeLanguage')) {
        url += `?codeLanguage=${codeLanguage}`; // For non-classroom anonymous users
      }
      if (password = utils.getQueryVariable('password')) {
        const delimiter = /\?/.test(url) ? '&' : '?';
        url += delimiter + 'password=' + password;
      }
    }

    if (this.tournament) {
      url = `/db/level.session/${this.sessionID}/tournament-snapshot/${this.tournament}`;
    }
    const session = new LevelSession().setURL(url);
    if (this.headless && !this.level.isType('web-dev')) {
      session.project = ['creator', 'team', 'heroConfig', 'codeLanguage', 'submittedCodeLanguage', 'state', 'submittedCode', 'submitted'];
    }
    this.sessionResource = this.supermodel.loadModel(session, 'level_session', {cache: false});
    this.session = this.sessionResource.model;
    if (this.opponentSessionID) {
      let opponentURL = `/db/level.session/${this.opponentSessionID}?interpret=true`;
      if (league) {
        opponentURL = `/db/spectate/${league}/level.session/${this.opponentSessionID}`;
      }
      if (this.tournament) {
        opponentURL = `/db/level.session/${this.opponentSessionID}/tournament-snapshot/${this.tournament}`; // this url also get interpret
      }
      opponentSession = new LevelSession().setURL(opponentURL);
      if (this.headless) { opponentSession.project = session.project; }
      this.opponentSessionResource = this.supermodel.loadModel(opponentSession, 'opponent_session', {cache: false});
      this.opponentSession = this.opponentSessionResource.model;
    }

    if (this.session.loaded) {
      if (LOG) { console.debug('LevelLoader: session already loaded:', this.session); }
      this.session.setURL('/db/level.session/' + this.session.id);
      this.preloadTeamForSession(this.session);
    } else {
      if (LOG) { console.debug('LevelLoader: loading session:', this.session); }
      this.listenToOnce(this.session, 'sync', function() {
        this.session.setURL('/db/level.session/' + this.session.id);
        return this.preloadTeamForSession(this.session);
      });
    }
    if (this.opponentSession) {
      if (this.opponentSession.loaded) {
        if (LOG) { console.debug('LevelLoader: opponent session already loaded:', this.opponentSession); }
        return this.preloadTokenForOpponentSession(this.opponentSession);
      } else {
        if (LOG) { console.debug('LevelLoader: loading opponent session:', this.opponentSession); }
        return this.listenToOnce(this.opponentSession, 'sync', this.preloadTokenForOpponentSession);
      }
    }
  }

  preloadTeamForSession(session) {
    if (this.level.isType('ladder') && (this.team === 'ogres') && (session.get('team') === 'humans')) {
      session.set('team', 'ogres');
      if (!session.get('interpret')) {
        let code = session.get('code');
        if (_.isEmpty(code)) {
          code = session.get('submittedCode');
        }
        code['hero-placeholder-1'] = JSON.parse(JSON.stringify(code['hero-placeholder']));
        session.set('code', code);
      }
    }
    return this.loadDependenciesForSession(session);
  }

  preloadTokenForOpponentSession(session) {
    if (this.level.isType('ladder') && (this.team !== 'ogres') && (session.get('team') === 'humans')) {
      session.set('team', 'ogres');
    }
      // since opponentSession always get interpret, so we don't need to copy code

    const language = session.get('codeLanguage');
    const compressed = session.get('interpret');
    if (!['java', 'cpp'].includes(language) || !compressed) {
      return this.loadDependenciesForSession(session);
    } else {
      const uncompressed = LZString.decompressFromUTF16(compressed);
      const code = session.get('code');

      const headers =  { 'Accept': 'application/json', 'Content-Type': 'application/json' };
      const m = document.cookie.match(/JWT=([a-zA-Z0-9.]+)/);
      const service = __guard__(typeof window !== 'undefined' && window !== null ? window.localStorage : undefined, x => x.kodeKeeperService) || "https://asm14w94nk.execute-api.us-east-1.amazonaws.com/service/parse-code-kodekeeper";
      return fetch(service, {method: 'POST', mode:'cors', headers, body:JSON.stringify({code: uncompressed, language})})
      .then(x => x.json())
      .then(x => {
        code[session.get('team') === 'humans' ? 'hero-placeholder' : 'hero-placeholder-1'].plan = x.token;
        session.set('code', code);
        session.unset('interpret');
        return this.loadDependenciesForSession(session);
      });
    }
  }

  loadDependenciesForSession(session) {
    let codeLanguage, compressed, heroResource, heroThangType, needle, url;
    if (LOG) { console.debug("Loading dependencies for session: ", session); }
    if ((me.id !== session.get('creator')) || this.spectateMode) {
      session.patch = (session.save = (session.put = () => console.error("Not saving session, since we didn't create it.")));
    } else if (codeLanguage = utils.getQueryVariable('codeLanguage')) {
      session.set('codeLanguage', codeLanguage);
    }
    if (me.id === session.get('creator')) {
      // do not use .set since we won't update fullName to server
      session.fullName = _.filter([me.get('firstName'), me.get('lastName')]).join(' ');
    }
    this.worldNecessities = this.worldNecessities.concat(this.loadCodeLanguagesForSession(session));
    if (compressed = session.get('interpret')) {
      const uncompressed = LZString.decompressFromUTF16(compressed);
      const code = session.get('code');
      code[session.get('team') === 'humans' ? 'hero-placeholder' : 'hero-placeholder-1'].plan = uncompressed;
      session.set('code', code);
      session.unset('interpret');
    }
    if ((needle = session.get('codeLanguage'), ['io', 'clojure'].includes(needle))) {
      session.set('codeLanguage', 'python');
    }
    if (session === this.session) {
      this.addSessionBrowserInfo(session);
      // hero-ladder games require the correct session team in level:loaded
      const team = this.team != null ? this.team : this.session.get('team');
      Backbone.Mediator.publish('level:loaded', {level: this.level, team});
      this.publishedLevelLoaded = true;
      Backbone.Mediator.publish('level:session-loaded', {level: this.level, session: this.session});
      if (this.opponentSession != null ? this.opponentSession.loaded : undefined) { this.consolidateFlagHistory(); }
    } else if (session === this.opponentSession) {
      if (this.session.loaded) { this.consolidateFlagHistory(); }
    }
    // course-ladder is hard to handle because there's 2 sessions
    if (this.level.isType('course') && (!me.showHeroAndInventoryModalsToStudents() || this.level.isAssessment())) {
      if (utils.isOzaria) {
        heroThangType = __guard__(me.get('ozariaUserOptions'), x => x.isometricThangTypeOriginal) || ThangType.heroes['hero-b'];
      } else {
        heroThangType = __guard__(me.get('heroConfig'), x1 => x1.thangType) || ThangType.heroes.captain;
      }
      // set default hero for assessment levels in class if classroomItems is on
      if (this.level.isAssessment() && me.showHeroAndInventoryModalsToStudents()) {
        heroThangType = utils.isOzaria ? ThangType.heroes['hero-b'] : ThangType.heroes.captain;
      }
      if (LOG) { console.debug("Course mode, loading custom hero: ", heroThangType); }
      url = `/db/thang.type/${heroThangType}/version`;
      if (heroResource = this.maybeLoadURL(url, ThangType, 'thang')) {
        if (LOG) { console.debug("Pushing resource: ", heroResource); }
        this.worldNecessities.push(heroResource);
      }
      this.sessionDependenciesRegistered[session.id] = true;
    }
    if (!this.level.isType('hero', 'hero-ladder', 'hero-coop')) {
      if (!this.level.isType('course') || !me.showHeroAndInventoryModalsToStudents() || !!this.level.isAssessment()) {
        // Return before loading heroConfig ThangTypes. Finish if all world necessities were completed by the time the session loaded.
        if (this.checkAllWorldNecessitiesRegisteredAndLoaded()) {
          this.onWorldNecessitiesLoaded();
        }
        return;
      }
    }
    // Load the ThangTypes needed for the session's heroConfig for these types of levels
    let heroConfig = _.cloneDeep(session.get('heroConfig'));
    if ((session === this.session) && !this.headless) { if (heroConfig == null) { heroConfig = _.cloneDeep(me.get('heroConfig')); } }
    if (heroConfig == null) { heroConfig = {}; }
    if (heroConfig.inventory == null) { heroConfig.inventory = {feet: '53e237bf53457600003e3f05'}; }  // If all else fails, assign simple boots.
    if (utils.isOzaria) {
      // This is where ozaria hero is being loaded from.
      heroConfig.thangType = __guard__(me.get('ozariaUserOptions'), x2 => x2.isometricThangTypeOriginal) || ThangType.heroes['hero-b'];  // If all else fails, assign Hero B as the hero.
    } else {
      if (heroConfig.thangType == null) { heroConfig.thangType = '529ffbf1cf1818f2be000001'; }  // If all else fails, assign Tharin as the hero.
    }
    if (!_.isEqual(heroConfig, session.get('heroConfig'))) { session.set('heroConfig', heroConfig); }
    url = `/db/thang.type/${heroConfig.thangType}/version`;
    if (heroResource = this.maybeLoadURL(url, ThangType, 'thang')) {
      this.worldNecessities.push(heroResource);
    } else {
      heroThangType = this.supermodel.getModel(url);
      this.loadDefaultComponentsForThangType(heroThangType);
      this.loadThangsRequiredByThangType(heroThangType);
    }

    for (var itemThangType of Array.from(_.values(heroConfig.inventory))) {
      var itemResource;
      url = `/db/thang.type/${itemThangType}/version?project=name,components,original,rasterIcon,kind`;
      if (itemResource = this.maybeLoadURL(url, ThangType, 'thang')) {
        this.worldNecessities.push(itemResource);
      } else {
        itemThangType = this.supermodel.getModel(url);
        this.loadDefaultComponentsForThangType(itemThangType);
        this.loadThangsRequiredByThangType(itemThangType);
      }
    }
    this.sessionDependenciesRegistered[session.id] = true;
    if ((_.size(this.sessionDependenciesRegistered) === 2) && this.checkAllWorldNecessitiesRegisteredAndLoaded()) {
      return this.onWorldNecessitiesLoaded();
    }
  }

  loadCodeLanguagesForSession(session) {
    const codeLanguages = _.uniq(_.filter([session.get('codeLanguage') || 'python', session.get('submittedCodeLanguage')]));
    const resources = [];
    for (var codeLanguage of Array.from(codeLanguages)) {
      if (['clojure', 'io'].includes(codeLanguage)) { continue; }
      (codeLanguage => { // Prevents looped variables from being reassigned when async callbacks happen
        const languageModuleResource = this.supermodel.addSomethingResource(`language_module_${codeLanguage}`);
        resources.push(languageModuleResource);
        return loadAetherLanguage(codeLanguage).then(aetherLang => {
          return languageModuleResource.markLoaded();
        });
      })(codeLanguage);
    }
    return resources;
  }

  addSessionBrowserInfo(session) {
    if (me.id !== session.get('creator')) { return; }
    if ($.browser == null) { return; }
    if (this.spectateMode) { return; }
    if (session.fake) { return; }
    const browser = {};
    if ($.browser.desktop) { browser['desktop'] = $.browser.desktop; }
    if ($.browser.name) { browser['name'] = $.browser.name; }
    if ($.browser.platform) { browser['platform'] = $.browser.platform; }
    if ($.browser.version) { browser['version'] = $.browser.version; }
    if (_.isEqual(session.get('browser'), browser)) { return; }
    session.set('browser', browser);
    return session.save({browser}, {patch: true, type: 'PUT'});
  }

  consolidateFlagHistory() {
    let left, left1;
    const state = (left = this.session.get('state')) != null ? left : {};
    const myFlagHistory = _.filter(state.flagHistory != null ? state.flagHistory : [], {team: this.session.get('team')});
    const opponentFlagHistory = _.filter((left1 = __guard__(this.opponentSession.get('state'), x => x.flagHistory)) != null ? left1 : [], {team: this.opponentSession.get('team')});
    state.flagHistory = myFlagHistory.concat(opponentFlagHistory);
    return this.session.set('state', state);
  }

  // Grabbing the rest of the required data for the level

  populateLevel() {
    let obj, url;
    const thangIDs = [];
    const componentVersions = [];
    const systemVersions = [];
    const articleVersions = [];

    const flagThang = {thangType: '53fa25f25bc220000052c2be', id: 'Placeholder Flag', components: []};
    for (var thang of Array.from((this.level.get('thangs') || []).concat([flagThang]))) {
      thangIDs.push(thang.thangType);
      this.loadThangsRequiredByLevelThang(thang);
      for (var comp of Array.from(thang.components || [])) {
        componentVersions.push(_.pick(comp, ['original', 'majorVersion']));
      }
    }

    for (var system of Array.from(this.level.get('systems') || [])) {
      var indieSprites;
      systemVersions.push(_.pick(system, ['original', 'majorVersion']));
      if (indieSprites = __guard__(system != null ? system.config : undefined, x => x.indieSprites)) {
        for (var indieSprite of Array.from(indieSprites)) {
          thangIDs.push(indieSprite.thangType);
        }
      }
    }

    if (!this.headless || !!this.loadArticles) {
      for (var article of Array.from(__guard__(this.level.get('documentation'), x1 => x1.generalArticles) || [])) {
        articleVersions.push(_.pick(article, ['original', 'majorVersion']));
      }
    }

    const objUniq = array => _.uniq(array, false, arg => JSON.stringify(arg));

    const worldNecessities = [];

    this.thangIDs = _.uniq(thangIDs);
    this.thangNames = new ThangNamesCollection(this.thangIDs);
    worldNecessities.push(this.supermodel.loadCollection(this.thangNames, 'thang_names'));
    this.listenToOnce(this.thangNames, 'sync', this.onThangNamesLoaded);
    if (this.sessionResource != null ? this.sessionResource.isLoading : undefined) { worldNecessities.push(this.sessionResource); }
    if (this.opponentSessionResource != null ? this.opponentSessionResource.isLoading : undefined) { worldNecessities.push(this.opponentSessionResource); }

    for (obj of Array.from(objUniq(componentVersions))) {
      url = `/db/level.component/${obj.original}/version/${obj.majorVersion}`;
      worldNecessities.push(this.maybeLoadURL(url, LevelComponent, 'component'));
    }
    for (obj of Array.from(objUniq(systemVersions))) {
      url = `/db/level.system/${obj.original}/version/${obj.majorVersion}`;
      worldNecessities.push(this.maybeLoadURL(url, LevelSystem, 'system'));
    }
    for (obj of Array.from(objUniq(articleVersions))) {
      url = `/db/article/${obj.original}/version/${obj.majorVersion}`;
      this.maybeLoadURL(url, Article, 'article');
    }
    if (obj = this.level.get('nextLevel')) {  // TODO: update to get next level from campaigns, not this old property
      url = `/db/level/${obj.original}/version/${obj.majorVersion}`;
      this.maybeLoadURL(url, Level, 'level');
    }

    return this.worldNecessities = this.worldNecessities.concat(worldNecessities);
  }

  loadThangsRequiredByLevelThang(levelThang) {
    return this.loadThangsRequiredFromComponentList(levelThang.components);
  }

  loadThangsRequiredByThangType(thangType) {
    return this.loadThangsRequiredFromComponentList(thangType.get('components'));
  }

  loadThangsRequiredFromComponentList(components) {
    if (!components) { return; }
    let requiredThangTypes = [];
    for (var component of Array.from(components)) {
      if (component.config) {
        if (component.original === LevelComponent.EquipsID) {
          for (var itemThangType of Array.from(_.values((component.config.inventory != null ? component.config.inventory : {})))) { requiredThangTypes.push(itemThangType); }
        } else if (component.config.requiredThangTypes) {
          requiredThangTypes = requiredThangTypes.concat(component.config.requiredThangTypes);
        }
      }
    }
    const extantRequiredThangTypes = _.filter(requiredThangTypes);
    if (extantRequiredThangTypes.length < requiredThangTypes.length) {
      console.error("Some Thang had a blank required ThangType in components list:", components);
    }
    return (() => {
      const result = [];
      for (var thangType of Array.from(extantRequiredThangTypes)) {
        if ((thangType + '') === '[object Object]') {
          result.push(console.error("Some Thang had an improperly stringified required ThangType in components list:", thangType, components));
        } else {
          var url = `/db/thang.type/${thangType}/version?project=name,components,original,rasterIcon,kind,prerenderedSpriteSheetData`;
          result.push(this.worldNecessities.push(this.maybeLoadURL(url, ThangType, 'thang')));
        }
      }
      return result;
    })();
  }

  onThangNamesLoaded(thangNames) {
    for (var thangType of Array.from(thangNames.models)) {
      this.loadDefaultComponentsForThangType(thangType);
      this.loadThangsRequiredByThangType(thangType);
    }
    this.thangNamesLoaded = true;
    if (this.checkAllWorldNecessitiesRegisteredAndLoaded()) { return this.onWorldNecessitiesLoaded(); }
  }

  loadDefaultComponentsForThangType(thangType) {
    let components;
    if (!(components = thangType.get('components'))) { return; }
    return (() => {
      const result = [];
      for (var component of Array.from(components)) {
        var url = `/db/level.component/${component.original}/version/${component.majorVersion}`;
        result.push(this.worldNecessities.push(this.maybeLoadURL(url, LevelComponent, 'component')));
      }
      return result;
    })();
  }

  onWorldNecessityLoaded(resource) {
    // Note: this can also be called when session, opponentSession, or other resources with dedicated load handlers are loaded, before those handlers
    const index = this.worldNecessities.indexOf(resource);
    if (resource.name === 'thang') {
      this.loadDefaultComponentsForThangType(resource.model);
      this.loadThangsRequiredByThangType(resource.model);
    }

    if (!(index >= 0)) { return; }
    this.worldNecessities.splice(index, 1);
    this.worldNecessities = ((() => {
      const result = [];
      for (var r of Array.from(this.worldNecessities)) {         if (r != null) {
          result.push(r);
        }
      }
      return result;
    })());
    if (this.checkAllWorldNecessitiesRegisteredAndLoaded()) { return this.onWorldNecessitiesLoaded(); }
  }

  onWorldNecessityLoadFailed(event) {
    this.reportLoadError();
    return this.trigger('world-necessity-load-failed', event);
  }

  checkAllWorldNecessitiesRegisteredAndLoaded() {
    const reason = this.getReasonForNotYetLoaded();
    if (reason && LOG) { console.debug('LevelLoader: Reason not loaded:', reason); }
    return !reason;
  }

  getReasonForNotYetLoaded() {
    if (_.filter(this.worldNecessities).length !== 0) { return 'worldNecessities still loading'; }
    if (!this.thangNamesLoaded) { return 'thang names need to load'; }
    if (this.sessionDependenciesRegistered && !this.sessionDependenciesRegistered[this.session.id] && !this.sessionless) { return 'not all session dependencies registered'; }
    if (this.sessionDependenciesRegistered && this.opponentSession && !this.sessionDependenciesRegistered[this.opponentSession.id] && !this.sessionless) { return 'not all opponent session dependencies registered'; }
    if (!(this.session != null ? this.session.loaded : undefined) && !this.sessionless) { return 'session is not loaded'; }
    if (this.opponentSession && (!this.opponentSession.loaded || this.opponentSession.get('interpret'))) { return 'opponent session is not loaded'; }
    if (!this.publishedLevelLoaded && !this.sessionless) { return 'have not published level loaded'; }
    if (this.opponentSession && this.opponentSession.get('interpret')) { return 'cpp/java token is still fetching'; }
    return '';
  }

  onWorldNecessitiesLoaded() {
    if (LOG) { console.debug("World necessities loaded."); }
    if (this.initialized) { return; }
    this.initialized = true;
    this.initWorld();
    this.supermodel.clearMaxProgress();
    this.trigger('world-necessities-loaded');
    if (this.headless) { return; }
    const thangsToLoad = _.uniq( (Array.from(this.world.thangs).filter((t) => t.exists).map((t) => t.spriteName)) );
    const nameModelTuples = (Array.from(this.thangNames.models).map((thangType) => [thangType.get('name'), thangType]));
    const nameModelMap = _.zipObject(nameModelTuples);
    if (this.spriteSheetsToBuild == null) { this.spriteSheetsToBuild = []; }

//    for thangTypeName in thangsToLoad
//      thangType = nameModelMap[thangTypeName]
//      continue if not thangType or thangType.isFullyLoaded()
//      thangType.fetch()
//      thangType = @supermodel.loadModel(thangType, 'thang').model
//      res = @supermodel.addSomethingResource 'sprite_sheet', 5
//      res.thangType = thangType
//      res.markLoading()
//      @spriteSheetsToBuild.push res

    if (this.spriteSheetsToBuild.length) { return this.buildLoopInterval = setInterval(this.buildLoop, 5); }
  }

  maybeLoadURL(url, Model, resourceName) {
    if (this.supermodel.getModel(url)) { return; }
    const model = new Model().setURL(url);
    return this.supermodel.loadModel(model, resourceName);
  }

  onSupermodelLoaded() {
    clearTimeout(this.loadTimeoutID);
    if (this.destroyed) { return; }
    if (LOG) { console.debug('SuperModel for Level loaded in', new Date().getTime() - this.t0, 'ms'); }
    this.loadLevelSounds();
    return this.denormalizeSession();
  }

  buildLoop() {
    let someLeft = false;
    const iterable = this.spriteSheetsToBuild != null ? this.spriteSheetsToBuild : [];
    for (let i = 0; i < iterable.length; i++) {
      var spriteSheetResource = iterable[i];
      if (spriteSheetResource.spriteSheetKeys) { continue; }
      someLeft = true;
      var {
        thangType
      } = spriteSheetResource;
      if (thangType.loaded && !thangType.loading) {
        var keys = this.buildSpriteSheetsForThangType(spriteSheetResource.thangType);
        if (keys && keys.length) {
          this.listenTo(spriteSheetResource.thangType, 'build-complete', this.onBuildComplete);
          spriteSheetResource.spriteSheetKeys = keys;
        } else {
          spriteSheetResource.markLoaded();
        }
      }
    }

    if (!someLeft) { return clearInterval(this.buildLoopInterval); }
  }

  onBuildComplete(e) {
    let resource = null;
    for (resource of Array.from(this.spriteSheetsToBuild)) {
      if (e.thangType === resource.thangType) { break; }
    }
    if (!resource) { return console.error('Did not find spriteSheetToBuildResource for', e); }
    resource.spriteSheetKeys = (Array.from(resource.spriteSheetKeys).filter((k) => k !== e.key));
    if (resource.spriteSheetKeys.length === 0) { return resource.markLoaded(); }
  }

  denormalizeSession() {
    let key, value;
    if (this.sessionDenormalized || this.spectateMode || this.sessionless || me.isSessionless()) { return; }
    if (this.headless && !this.level.isType('web-dev')) { return; }
    // This is a way (the way?) PUT /db/level.sessions/undefined was happening
    // See commit c242317d9
    if (!this.session.id) { return; }
    const patch = {
      'levelName': this.level.get('name'),
      'levelID': this.level.get('slug') || this.level.id
    };
    if (me.id === this.session.get('creator')) {
      let currentAge;
      patch.creatorName = me.get('name');
      if (currentAge = me.age()) {
        patch.creatorAge = currentAge;
      }
    }
    for (key in patch) {
      value = patch[key];
      if (this.session.get(key) === value) {
        delete patch[key];
      }
    }
    if (!_.isEmpty(patch)) {
      if (this.level.isLadder() && this.session.get('team')) {
        patch.team = this.session.get('team');
        if (this.level.isType('ladder')) {
          patch.team = 'humans';  // Save the team in case we just assigned it in PlayLevelView, since sometimes that wasn't getting saved and we don't want to save ogres team in ladder
        }
      }
      for (key in patch) { value = patch[key]; this.session.set(key, value); }
      const tempSession = new LevelSession({_id: this.session.id});
      tempSession.save(patch, {patch: true, type: 'PUT'});
    }
    return this.sessionDenormalized = true;
  }

  // Building sprite sheets

  buildSpriteSheetsForThangType(thangType) {
    let left;
    if (this.headless) { return; }
    // TODO: Finish making sure the supermodel loads the raster image before triggering load complete, and that the cocosprite has access to the asset.
//    if f = thangType.get('raster')
//      queue = new createjs.LoadQueue()
//      queue.loadFile('/file/'+f)
    if (!this.thangTypeTeams) { this.grabThangTypeTeams(); }
    const keys = [];
    for (var team of Array.from((left = this.thangTypeTeams[thangType.get('original')]) != null ? left : [null])) {
      var color;
      var spriteOptions = {resolutionFactor: SPRITE_RESOLUTION_FACTOR, async: true};
      if (thangType.get('kind') === 'Floor') {
        spriteOptions.resolutionFactor = 2;
      }
      if (team && (color = this.teamConfigs[team] != null ? this.teamConfigs[team].color : undefined)) {
        spriteOptions.colorConfig = {team: color};
      }
      var key = this.buildSpriteSheet(thangType, spriteOptions);
      if (_.isString(key)) { keys.push(key); }
    }
    return keys;
  }

  grabThangTypeTeams() {
    this.grabTeamConfigs();
    this.thangTypeTeams = {};
    for (var thang of Array.from(this.level.get('thangs'))) {
      if (this.level.isType('hero', 'course') && (thang.id === 'Hero Placeholder')) {
        continue;  // No team colors for heroes on single-player levels
      }
      for (var component of Array.from(thang.components)) {
        var team;
        if (team = component.config != null ? component.config.team : undefined) {
          if (this.thangTypeTeams[thang.thangType] == null) { this.thangTypeTeams[thang.thangType] = []; }
          if (!Array.from(this.thangTypeTeams[thang.thangType]).includes(team)) { this.thangTypeTeams[thang.thangType].push(team); }
          break;
        }
      }
    }
    return this.thangTypeTeams;
  }

  grabTeamConfigs() {
    for (var system of Array.from(this.level.get('systems'))) {
      if (this.teamConfigs = system.config != null ? system.config.teamConfigs : undefined) {
        break;
      }
    }
    if (!this.teamConfigs) {
      // Hack: pulled from Alliance System code. TODO: put in just one place.
      this.teamConfigs = {'humans': {'superteam': 'humans', 'color': {'hue': 0, 'saturation': 0.75, 'lightness': 0.5}, 'playable': true}, 'ogres': {'superteam': 'ogres', 'color': {'hue': 0.66, 'saturation': 0.75, 'lightness': 0.5}, 'playable': false}, 'neutral': {'superteam': 'neutral', 'color': {'hue': 0.33, 'saturation': 0.75, 'lightness': 0.5}}};
    }
    return this.teamConfigs;
  }

  buildSpriteSheet(thangType, options) {
    if (thangType.get('name') === 'Wizard') {
      options.colorConfig = __guard__(me.get('wizard'), x => x.colorConfig) || {};
    }
    return thangType.buildSpriteSheet(options);
  }

  // World init

  initWorld() {
    let left, left1, left2;
    if (this.level.isType('web-dev')) { return; }
    this.world = new World();
    this.world.levelSessionIDs = this.opponentSessionID ? [this.sessionID, this.opponentSessionID] : [this.sessionID];
    this.world.submissionCount = (left = __guard__(this.session != null ? this.session.get('state') : undefined, x => x.submissionCount)) != null ? left : 0;
    this.world.flagHistory = (left1 = __guard__(this.session != null ? this.session.get('state') : undefined, x1 => x1.flagHistory)) != null ? left1 : [];
    this.world.difficulty = (left2 = __guard__(this.session != null ? this.session.get('state') : undefined, x2 => x2.difficulty)) != null ? left2 : 0;
    if (this.observing) {
      this.world.difficulty = Math.max(0, this.world.difficulty - 1);  // Show the difficulty they won, not the next one.
    }
    const serializedLevel = this.level.serialize({supermodel: this.supermodel, session: this.session, opponentSession: this.opponentSession, headless: this.headless, sessionless: this.sessionless});
    if (me.constrainHeroHealth()) {
      serializedLevel.constrainHeroHealth = true;
    }
    this.world.loadFromLevel(serializedLevel, false);
    if (LOG) { return console.debug('World has been initialized from level loader.'); }
  }

  // Initial Sound Loading

  playJingle() {
    if (utils.isOzaria) { return; } // TODO: replace with Ozaria level loading jingles
    if (this.headless || !me.get('volume')) { return; }
    let volume = 0.5;
    if (me.level() < 3) {
      volume = 0.25;  // Start softly, since they may not be expecting it
    }
    // Apparently the jingle, when it tries to play immediately during all this loading, you can't hear it.
    // Add the timeout to fix this weird behavior.
    const f = function() {
      const jingles = ['ident_1', 'ident_2'];
      return AudioPlayer.playInterfaceSound(jingles[Math.floor(Math.random() * jingles.length)], volume);
    };
    return setTimeout(f, 500);
  }

  loadAudio() {
    if (utils.isOzaria) { return; }  // TODO: replace with Ozaria sound
    if (this.headless || !me.get('volume')) { return; }
    return AudioPlayer.preloadInterfaceSounds(['victory']);
  }

  loadLevelSounds() {
    if (this.headless || !me.get('volume')) { return; }
    const scripts = this.level.get('scripts');
    if (!scripts) { return; }

    for (var script of Array.from(scripts)) {
      if (script.noteChain) {
        for (var noteGroup of Array.from(script.noteChain)) {
          if (noteGroup.sprites) {
            for (var sprite of Array.from(noteGroup.sprites)) {
              if ((sprite.say != null ? sprite.say.sound : undefined)) {
                AudioPlayer.preloadSoundReference(sprite.say.sound);
              }
            }
          }
        }
      }
    }

    const thangTypes = this.supermodel.getModels(ThangType);
    return Array.from(thangTypes).map((thangType) =>
      (() => {
        const result = [];
        const object = thangType.get('soundTriggers') || {};
        for (var trigger in object) {
          var sounds = object[trigger];
          if (trigger !== 'say') {
            result.push((() => {
              const result1 = [];
              for (var sound of Array.from(sounds)) {                 result1.push(AudioPlayer.preloadSoundReference(sound));
              }
              return result1;
            })());
          }
        }
        return result;
      })());
  }

  // everything else sound wise is loaded as needed as worlds are generated

  progress() { return this.supermodel.progress; }

  destroy() {
    if (this.buildLoopInterval) { clearInterval(this.buildLoopInterval); }
    return super.destroy();
  }
});

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}