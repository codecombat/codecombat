// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS002: Fix invalid constructor
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__, or convert again using --optional-chaining
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let VerifierTest;
const CocoClass = require('core/CocoClass');
const SuperModel = require('models/SuperModel');
const {createAetherOptions} = require('lib/aether_utils');
const God = require('lib/God');
const GoalManager = require('lib/world/GoalManager');
const LevelLoader = require('lib/LevelLoader');
const utils = require('core/utils');
const aetherUtils = require('lib/aether_utils');

module.exports = (VerifierTest = class VerifierTest extends CocoClass {
  constructor(levelID, updateCallback, supermodel, language, options) {
    super();
    this.onWorldNecessitiesLoaded = this.onWorldNecessitiesLoaded.bind(this);
    this.fetchToken = this.fetchToken.bind(this);
    this.configureSession = this.configureSession.bind(this);
    this.cleanup = this.cleanup.bind(this);
    this.levelID = levelID;
    this.updateCallback = updateCallback;
    this.supermodel = supermodel;
    this.language = language;
    this.options = options;
    // TODO: turn this into a Subview
    // TODO: listen to the progress report from Angel to show a simulation progress bar (maybe even out of the number of frames we actually know it'll take)
    if (this.supermodel == null) { this.supermodel = new SuperModel(); }

    if (utils.getQueryVariable('dev') || this.options.devMode) {
      this.supermodel.shouldSaveBackups = model => // Make sure to load possibly changed things from localStorage.
      ['Level', 'LevelComponent', 'LevelSystem', 'ThangType'].includes(model.constructor.className);
    }
    this.solution = this.options.solution;
    this.simpleDescription = "";
    this.name = "";
    if (this.language == null) { this.language = 'python'; }
    this.userCodeProblems = [];
    this.load();
  }

  load() {
    this.loadStartTime = new Date();
    this.god = new God({maxAngels: 1, headless: true});
    this.levelLoader = new LevelLoader({supermodel: this.supermodel, levelID: this.levelID, headless: true, fakeSessionConfig: {codeLanguage: this.language, callback: this.configureSession}});
    return this.listenToOnce(this.levelLoader, 'world-necessities-loaded', function() { return _.defer(this.onWorldNecessitiesLoaded); });
  }

  onWorldNecessitiesLoaded() {
    // Called when we have enough to build the world, but not everything is loaded
    this.grabLevelLoaderData();

    if (!this.solution) {
      this.error = 'No solution present...';
      this.state = 'no-solution';
      if (typeof this.updateCallback === 'function') {
        this.updateCallback({test: this, state: 'no-solution'});
      }
      return;
    }

    this.simpleDescription = this.solution.description ? `- ${this.solution.description}` : "";
    this.name = `${this.solution.testOnly ? '' : '[Solution]'} ${this.level.get('name')}`;

    me.team = (this.team = 'humans');
    this.setupGod();
    this.initGoalManager();
    return this.fetchToken(this.solution.source, this.language)
      .then(token => this.register(token));
  }

  fetchToken(source, language) {
    if (!['java', 'cpp'].includes(language)) {
      return Promise.resolve(source);
    }

    const headers =  { 'Accept': 'application/json', 'Content-Type': 'application/json' };
    const m = document.cookie.match(/JWT=([a-zA-Z0-9.]+)/);
    const service = __guard__(typeof window !== 'undefined' && window !== null ? window.localStorage : undefined, x => x.kodeKeeperService) || "https://asm14w94nk.execute-api.us-east-1.amazonaws.com/service/parse-code-kodekeeper";
    return fetch(service, {method: 'POST', mode:'cors', headers, body:JSON.stringify({code: source, language})})
    .then(x => x.json())
    .then(x => x.token);
  }

  configureSession(session, level) {
    let state;
    try {
      if (session.solution == null) { session.solution = this.solution; }
      session.set('heroConfig', session.solution.heroConfig);
      session.set('code', {'hero-placeholder': {plan: session.solution.source}});
      state = session.get('state');
      state.flagHistory = session.solution.flagHistory;
      state.realTimeInputEvents = session.solution.realTimeInputEvents;
      state.difficulty = session.solution.difficulty || 0;
      if (!_.isNumber(session.solution.seed)) { return session.solution.seed = undefined; }  // TODO: migrate away from submissionCount/sessionID seed objects
    } catch (e) {
      this.state = 'error';
      return this.error = `Could not load the session solution for ${level.get('name')}: ` + e.toString() + "\n" + e.stack;
    }
  }

  grabLevelLoaderData() {
    this.world = this.levelLoader.world;
    this.level = this.levelLoader.level;
    this.session = this.levelLoader.session;
    return this.solution != null ? this.solution : (this.solution = this.levelLoader.session.solution);
  }

  setupGod() {
    this.god.setLevel(this.level.serialize({supermodel: this.supermodel, session: this.session, otherSession: null, headless: true, sessionless: false}));
    this.god.setLevelSessionIDs([this.session.id]);
    this.god.setWorldClassMap(this.world.classMap);
    this.god.lastFlagHistory = this.session.get('state').flagHistory;
    this.god.lastDifficulty = this.session.get('state').difficulty;
    this.god.lastFixedSeed = this.session.solution.seed;
    return this.god.lastSubmissionCount = 0;
  }

  initGoalManager() {
    this.goalManager = new GoalManager(this.world, this.level.get('goals'), this.team);
    return this.god.setGoalManager(this.goalManager);
  }

  register(tokenSource) {
    this.listenToOnce(this.god, 'infinite-loop', this.fail);
    this.listenToOnce(this.god, 'user-code-problem', this.onUserCodeProblem);
    this.listenToOnce(this.god, 'goals-calculated', this.processSingleGameResults);
    this.god.createWorld({spells: aetherUtils.generateSpellsObject({levelSession: this.session, token: tokenSource})});
    this.state = 'running';
    return this.reportResults();
  }

  extractTestLogs() {
    this.testLogs = [];
    for (var log of Array.from(__guard__(__guard__(__guard__(this.god != null ? this.god.angelsShare : undefined, x2 => x2.busyAngels), x1 => x1[0]), x => x.allLogs) != null ? __guard__(__guard__(__guard__(this.god != null ? this.god.angelsShare : undefined, x2 => x2.busyAngels), x1 => x1[0]), x => x.allLogs) : [])) {
      if (log.indexOf('[TEST]') === -1) { continue; }
      this.testLogs.push(log.replace(/\|.*?\| \[TEST\] /, ''));
    }
    return this.testLogs;
  }

  reportResults() {
    return (typeof this.updateCallback === 'function' ? this.updateCallback({test: this, state: this.state, testLogs: this.extractTestLogs()}) : undefined);
  }

  processSingleGameResults(e) {
    this.goals = e.goalStates;
    this.frames = e.totalFrames;
    this.lastFrameHash = e.lastFrameHash;
    this.simulationFrameRate = e.simulationFrameRate;
    this.state = 'complete';
    this.reportResults();
    return this.scheduleCleanup();
  }

  isSuccessful(careAboutFrames) {
    if (careAboutFrames == null) { careAboutFrames = true; }
    if (this.solution == null) { return false; }
    if ((this.frames !== this.solution.frameCount) && !!careAboutFrames) { return false; }
    if (this.simulationFrameRate < 30) { return false; }
    if (this.goals && this.solution.goals) {
      for (var k in this.goals) {
        if (!this.solution.goals[k]) { continue; }
        if (this.solution.goals[k] !== this.goals[k].status) { return false; }
      }
    }
    return true;
  }

  onUserCodeProblem(e) {
    console.warn("Found user code problem:", e);
    this.userCodeProblems.push(e.problem);
    return this.reportResults();
  }

  onNonUserCodeProblem(e) {
    console.error("Found non-user-code problem:", e);
    this.error = `Failed due to non-user-code problem: ${JSON.stringify(e)}`;
    this.state = 'error';
    this.reportResults();
    return this.scheduleCleanup();
  }

  fail(e) {
    this.error = 'Failed due to infinite loop.';
    this.state = 'error';
    this.reportResults();
    return this.scheduleCleanup();
  }

  scheduleCleanup() {
    return setTimeout(this.cleanup, 100);
  }

  cleanup() {
    if (this.levelLoader) {
      this.stopListening(this.levelLoader);
      this.levelLoader.destroy();
    }
    if (this.god) {
      this.stopListening(this.god);
      this.god.destroy();
    }
    return this.world = null;
  }
});

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}