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
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let LevelBus;
const Bus = require('./Bus');
const {me} = require('core/auth');
const LevelSession = require('models/LevelSession');
const utils = require('core/utils');
const tagger = require('lib/SolutionConceptTagger');
const store = require('core/store');
const Concepts = require('collections/Concepts');
const globalVar = require('core/globalVar');

module.exports = (LevelBus = (function() {
  LevelBus = class LevelBus extends Bus {
    static initClass() {

      this.prototype.subscriptions = {
        'tome:editing-began': 'onEditingBegan',
        'tome:editing-ended': 'onEditingEnded',
        'script:state-changed': 'onScriptStateChanged',
        'script:ended': 'onScriptEnded',
        'script:reset': 'onScriptReset',
        'surface:sprite-selected': 'onSpriteSelected',
        'level:show-victory': 'onVictory',
        'tome:spell-changed': 'onSpellChanged',
        'tome:spell-created': 'onSpellCreated',
        'tome:cast-spells': 'onCastSpells',
        'tome:winnability-updated': 'onWinnabilityUpdated',
        'application:idle-changed': 'onIdleChanged',
        'goal-manager:new-goal-states': 'onNewGoalStates',
        'god:new-world-created': 'onNewWorldCreated'
      };
    }

    static get(levelID, sessionID) {
      const docName = `play/level/${levelID}/${sessionID}`;
      return Bus.getFromCache(docName) || new LevelBus(docName);
    }

    constructor() {
      super(...arguments);
      this.incrementSessionPlaytime = this.incrementSessionPlaytime.bind(this);
      this.onMeSynced = this.onMeSynced.bind(this);
      this.onPlayerJoined = this.onPlayerJoined.bind(this);
      this.onChatAdded = this.onChatAdded.bind(this);
      this.changedSessionProperties = {};
      const saveDelay = window.serverConfig != null ? window.serverConfig.sessionSaveDelay : undefined;
      const [wait, maxWait] = Array.from((() => { switch (false) {
        case !!application.isProduction && !!saveDelay: return [1, 5];  // Save quickly in development.
        case !me.isAnonymous(): return [saveDelay.anonymous.min, saveDelay.anonymous.max];
        default: return [saveDelay.registered.min, saveDelay.registered.max];
      } })());
      this.saveSession = _.debounce(this.reallySaveSession, wait * 1000, {maxWait: maxWait * 1000});
      this.playerIsIdle = false;
      this.vuexDestroyFunctions = [];
      this.vuexDestroyFunctions.push(store.watch(
        state => state.game.timesCodeRun,
        timesCodeRun => {
          this.session.set({timesCodeRun});
          return this.changedSessionProperties.timesCodeRun = true;
      })
      );
      this.vuexDestroyFunctions.push(store.watch(
        state => state.game.timesAutocompleteUsed,
        timesAutocompleteUsed => {
          this.session.set({timesAutocompleteUsed});
          return this.changedSessionProperties.timesAutocompleteUsed = true;
      })
      );
      if (utils.useWebsocket) {
        this.wsBus = globalVar.application.wsBus;
      }
    }

    init() {
      super.init();
      return this.fireScriptsRef = this.fireRef != null ? this.fireRef.child('scripts') : undefined;
    }

    setSession(session) {
      this.session = session;
      return this.timerIntervalID = setInterval(this.incrementSessionPlaytime, 1000);
    }

    onIdleChanged(e) {
      return this.playerIsIdle = e.idle;
    }

    incrementSessionPlaytime() {
      let left;
      if (this.playerIsIdle) { return; }
      this.changedSessionProperties.playtime = true;
      this.session.set('playtime', ((left = this.session.get('playtime')) != null ? left : 0) + 1);
      if (store.state.game.hintsVisible) {
        let left1;
        this.session.set('hintTime', ((left1 = this.session.get('hintTime')) != null ? left1 : 0) + 1);
        return this.changedSessionProperties.hintTime = true;
      }
    }

    onPoint() {
      return true;
    }

    onMeSynced() {
      return super.onMeSynced();
    }

    join() {
      return super.join();
    }

    disconnect() {
      if (this.fireScriptsRef != null) {
        this.fireScriptsRef.off();
      }
      this.fireScriptsRef = null;
      return super.disconnect();
    }

    removeFirebaseData(callback) {
      if (!this.myConnection) { return (typeof callback === 'function' ? callback() : undefined); }
      this.myConnection.child('connected');
      this.fireRef.remove();
      return this.onDisconnect.cancel(() => typeof callback === 'function' ? callback() : undefined);
    }

    // UPDATING FIREBASE AND SESSION

    onEditingBegan() {} //@wizardRef?.child('editing').set(true)  # no more wizards
    onEditingEnded() {} //@wizardRef?.child('editing').set(false)  # no more wizards

    // HACK: Backbone does not work with nested documents, but we want to
    //   patch only those props that have changed. Look into plugins to
    //   give Backbone support for nested docs and update the code here.

    // TODO: The LevelBus doesn't need to be in charge of updating the
    //   LevelSession object. Either break this off into a separate class
    //   or have the LevelSession object listen for all these events itself.

    setSpells(spells) {
      return (() => {
        const result = [];
        for (var spellKey in spells) {
          var spell = spells[spellKey];
          result.push(this.onSpellCreated({spell}));
        }
        return result;
      })();
    }

    onSpellChanged(e) {
      if (!this.onPoint()) { return; }
      let code = this.session.get('code');
      if (code == null) { code = {}; }
      const parts = e.spell.spellKey.split('/');

      if (code[parts[0]] == null) { code[parts[0]] = {}; }
      code[parts[0]][parts[1]] = e.spell.getSource();

      this.changedSessionProperties.code = true;
      this.changedSessionProperties.heroCode = undefined;
      if (e.spell.level.isType('ladder')) {
        // lets always set heroCode for ladder so that we don't save hero-placeholder-1 anyway
        this.changedSessionProperties.heroCode = e.spell.getSource();
      }
      this.session.set({'code': code});
      return this.saveSession();
    }

    onSpellCreated(e) {
      if (!this.onPoint()) { return; }
      this.changedSessionProperties.teamSpells = true;
      this.session.set({'teamSpells': utils.teamSpells});
      this.saveSession();
      if ((e.spell.team === me.team) || (e.spell.otherSession && (e.spell.team !== e.spell.otherSession.get('team')))) {
        // https://github.com/codecombat/codecombat/issues/81
        return this.onSpellChanged(e);  // Save the new spell to the session, too.
      }
    }

    onCastSpells(e) {
      if (!this.onPoint() || !e.realTime) { return; }
      // We have incremented state.submissionCount and reset state.flagHistory.
      this.changedSessionProperties.state = true;
      return this.saveSession();
    }

    onWinnabilityUpdated(e) {
      if (!this.onPoint() || !e.winnable) { return; }
      if (!e.level.get('mirrorMatch')) { return; }  // Mirror matches don't otherwise show victory, so we win here.
      if (__guard__(this.session.get('state'), x => x.complete)) { return; }
      return this.onVictory();
    }

    onNewWorldCreated(e) {
      if (!this.onPoint()) { return; }
      // Record the flag history.
      const state = this.session.get('state');
      const flagHistory = (Array.from(e.world.flagHistory).filter((flag) => flag.source !== 'code'));
      if (_.isEqual(state.flagHistory, flagHistory)) { return; }
      state.flagHistory = flagHistory;
      this.changedSessionProperties.state = true;
      this.session.set('state', state);
      return this.saveSession();
    }

    onScriptStateChanged(e) {
      if (!this.onPoint()) { return; }
      if (this.fireScriptsRef != null) {
        this.fireScriptsRef.update(e);
      }
      const state = this.session.get('state');
      const scripts = state.scripts != null ? state.scripts : {};
      scripts.currentScript = e.currentScript;
      scripts.currentScriptOffset = e.currentScriptOffset;
      this.changedSessionProperties.state = true;
      this.session.set('state', state);
      return this.saveSession();
    }

    onScriptEnded(e) {
      let scripts;
      if (!this.onPoint()) { return; }
      const state = this.session.get('state');
      if (!(scripts = state.scripts)) { return; }
      if (scripts.ended == null) { scripts.ended = {}; }
      if (scripts.ended[e.scriptID] != null) { return; }
      const index = _.keys(scripts.ended).length + 1;
      if (this.fireScriptsRef != null) {
        this.fireScriptsRef.child('ended').child(e.scriptID).set(index);
      }
      scripts.ended[e.scriptID] = index;
      this.session.set('state', state);
      this.changedSessionProperties.state = true;
      return this.saveSession();
    }

    onScriptReset() {
      if (!this.onPoint()) { return; }
      if (this.fireScriptsRef != null) {
        this.fireScriptsRef.set({});
      }
      const state = this.session.get('state');
      state.scripts = {};
      //state.complete = false  # Keep it complete once ever completed.
      this.session.set('state', state);
      this.changedSessionProperties.state = true;
      return this.saveSession();
    }

    onSpriteSelected(e) {
      if (!this.onPoint()) { return; }
      const state = this.session.get('state');
      state.selected = (e.thang != null ? e.thang.id : undefined) || null;
      this.session.set('state', state);
      this.changedSessionProperties.state = true;
      return this.saveSession();
    }

    onVictory(e) {
      if (!this.onPoint()) { return; }
      if (utils.isOzaria && e && e.capstoneInProgress) { return; }
      const state = this.session.get('state');
      if (utils.isCodeCombat) {
        if (state.complete) { return; }
        state.complete = true;
        this.session.set('state', state);
        this.changedSessionProperties.state = true;
        return this.reallySaveSession();  // Make sure it saves right away; don't debounce it.
      } else {
        let needsImmediateSave = false;
        if (!state.complete) {
          state.complete = true;
          this.session.set('state', state);
          this.changedSessionProperties.state = true;
          needsImmediateSave = true;
        }
        if (e.isCapstone && !this.session.get('published')) {
          // Publish the capstone level if it is completed
          this.session.set('published', true);
          this.changedSessionProperties.published = true;
          needsImmediateSave = true;
        }
        if (needsImmediateSave) {
          return this.reallySaveSession();  // Make sure it saves right away; don't debounce it.
        }
      }
    }

    onNewGoalStates(e) {
      // TODO: this log doesn't capture when null-status goals are being set during world streaming. Where can they be coming from?
      const {
        goalStates
      } = e;
      if (_.find(newGoalStates, gs => !gs.status)) { return console.error("Somehow trying to save null goal states!", newGoalStates); }

      if (e.overallStatus !== 'success') { return; }
      var newGoalStates = goalStates;
      const state = this.session.get('state');
      const oldGoalStates = state.goalStates || {};

      let changed = false;
      for (var goalKey in newGoalStates) {
        var goalState = newGoalStates[goalKey];
        if (!me.isStudent()) {
          // don't undo success, this property is for keying off achievements for home users
          // do undo for students, though, so this property can be used in teacher assessment tabs
          if (((oldGoalStates[goalKey] != null ? oldGoalStates[goalKey].status : undefined) === 'success') && (goalState.status !== 'success')) { continue; }
        }
        if (utils.kindaEqual(state.goalStates != null ? state.goalStates[goalKey] : undefined, goalState)) { continue; } // Only save when goals really change
        changed = true;
        oldGoalStates[goalKey] = _.cloneDeep(newGoalStates[goalKey]);
      }

      if (changed) {
        state.goalStates = oldGoalStates;
        this.session.set('state', state);
        this.changedSessionProperties.state = true;
        return this.saveSession();
      }
    }

    onPlayerJoined(snapshot) {
      super.onPlayerJoined(...arguments);
      if (!this.onPoint()) { return; }
      let players = this.session.get('players');
      if (players == null) { players = {}; }
      const player = snapshot.val();
      if (players[player.id] != null) { return; }
      players[player.id] = {};
      this.session.set('players', players);
      this.changedSessionProperties.players = true;
      return this.saveSession();
    }

    onChatAdded(snapshot) {
      super.onChatAdded(...arguments);
      let chat = this.session.get('chat');
      if (chat == null) { chat = []; }
      const message = snapshot.val();
      if (message.system) { return; }
      chat.push(message);
      if (chat.length > 50) { chat = chat.slice(chat.length-50); }
      this.session.set('chat', chat);
      this.changedSessionProperties.chat = true;
      return this.saveSession();
    }

    // Debounced as saveSession
    reallySaveSession() {
      let heroCode;
      if (_.isEmpty(this.changedSessionProperties)) { return; }
      // don't let peeking admins mess with the session accidentally
      if (this.session.get('creator') !== me.id) { return; }
      if (this.session.fake) { return; }
      if (this.changedSessionProperties.code) {
        this.updateSessionConcepts();
        ({
          heroCode
        } = this.changedSessionProperties);
        delete this.changedSessionProperties.heroCode;
      }
      Backbone.Mediator.publish('level:session-will-save', {session: this.session});
      const patch = {};
      for (var prop in this.changedSessionProperties) { patch[prop] = this.session.get(prop); }
      if (heroCode) { // let's only update trueSpell of session(hero-placeholder for all ladders)
        patch.code = { 'hero-placeholder': { plan: heroCode }, 'hero-placeholder-1': { plan: '' } };
      }
      if (_.isEmpty(patch.code)) { delete patch.code; } // don't update empty code
      this.changedSessionProperties = {};

      // since updates are coming fast and loose for session objects
      // don't let what the server returns overwrite changes since the save began
      const tempSession = new LevelSession({_id: this.session.id});
      return tempSession.save(patch, {patch: true, type: 'PUT'});
    }

    updateSessionConcepts() {
      let needle;
      if ((needle = this.session.get('codeLanguage'), !['javascript', 'python'].includes(needle))) { return; }
      return this.loadConcepts(concepts => {
        try {
          let tags = tagger({ast: this.session.lastAST, language: this.session.get('codeLanguage')}, concepts);
          tags = _.without(tags, 'basic_syntax');
          this.session.set('codeConcepts', tags);
          return this.changedSessionProperties.codeConcepts = true;
        } catch (e) {
          // Just in case the concept tagger system breaks. Esper needed fixing to handle
          // the Python skulpt AST, the concept tagger is not fully tested, and this is a
          // critical piece of code, so want to make sure this can fail gracefully.
          console.warn('Unable to parse concepts from this AST.');
          return console.warn(e);
        }
      });
    }

    loadConcepts(onConceptsLoaded) {
      const concepts = new Concepts([]);
      this.listenTo(concepts, 'sync', onConceptsLoaded);
      return concepts.fetch({data: { skip: 0, limit: 1000 }});
    }

    subscribeTeacher(teacherId) {
      if (!this.wsBus) { return; }
      const topic = `user-${teacherId.toString()}`;
      this.wsBus.ws.subscribe(topic);
      return me.fetchOnlineTeachers([teacherId.toString()]).then(onlineTeacher => {
        return this.wsBus.updateOnlineFriends(onlineTeacher);
      });
    }

    destroy() {
      clearInterval(this.timerIntervalID);
      for (var destroyFunction of Array.from(this.vuexDestroyFunctions)) {
        destroyFunction();
      }
      return super.destroy();
    }
  };
  LevelBus.initClass();
  return LevelBus;
})());

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}