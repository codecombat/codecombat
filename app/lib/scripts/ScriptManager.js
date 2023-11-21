// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS002: Fix invalid constructor
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__, or convert again using --optional-chaining
 * DS104: Avoid inline assignments
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let ScriptManager;
const CocoClass = require('core/CocoClass');
const CocoView = require('views/core/CocoView');
const {scriptMatchesEventPrereqs} = require('./../world/script_event_prereqs');
const utils = require('core/utils');

const allScriptModules = [];
allScriptModules.push(require('./SpriteScriptModule'));
allScriptModules.push(require('./DOMScriptModule'));
allScriptModules.push(require('./SurfaceScriptModule'));
allScriptModules.push(require('./PlaybackScriptModule'));
allScriptModules.push(require('./SoundScriptModule'));

const store = require('app/core/store');

const DEFAULT_BOT_MOVE_DURATION = 500;
const DEFAULT_SCRUB_DURATION = 1000;

module.exports = (ScriptManager = (ScriptManager = (function() {
  ScriptManager = class ScriptManager extends CocoClass {
    static initClass() {
      this.prototype.scriptInProgress = false;
      this.prototype.currentNoteGroup = null;
      this.prototype.currentTimeouts = [];
      this.prototype.worldLoading = true;
      this.prototype.ignoreEvents = false;
      this.prototype.quiet = false;

      this.prototype.triggered = [];
      this.prototype.ended = [];
      this.prototype.noteGroupQueue = [];
      this.prototype.originalScripts = []; // use these later when you want to revert to an original state

      this.prototype.subscriptions = {
        'script:end-current-script': 'onEndNoteGroup',
        'level:loading-view-unveiling'() { return this.setWorldLoading(false); },
        'level:restarted': 'onLevelRestarted',
        'level:shift-space-pressed': 'onEndNoteGroup',
        'level:escape-pressed': 'onEndAll'
      };

      this.prototype.shortcuts = {
        '⇧+space, space, enter'() { return Backbone.Mediator.publish('level:shift-space-pressed', {}); },
        'escape'() { return Backbone.Mediator.publish('level:escape-pressed', {}); }
      };
    }

    static extractSayEvents(script) {
      const sayEvents = [];
      __guard__(script != null ? script.noteChain : undefined, x => x.forEach(note => __guard__(note != null ? note.sprites : undefined, x1 => x1.forEach(function(sprites) {
        if (__guard__(sprites != null ? sprites.say : undefined, x2 => x2.text)) {
          return sayEvents.push(sprites);
        }
      }))));
      return sayEvents;
    }

    // SETUP / TEARDOWN

    constructor(options) {
      super(options);
      this.tick = this.tick.bind(this);
      this.originalScripts = _.clone(options.scripts);
      this.session = options.session;
      this.levelID = options.levelID;
      this.debugScripts = application.isIPadApp || utils.getQueryVariable('dev');
      this.initProperties();
      if (utils.isOzaria) {
        this.saveSayEventsToStore();
      }
      this.addScriptSubscriptions();
      this.beginTicking();
    }

    setScripts(newScripts) {
      this.originalScripts(_.clone(newScripts));
      this.quiet = true;
      this.initProperties();
      this.loadFromSession();
      this.quiet = false;
      this.addScriptSubscriptions();
      this.run();
      if (utils.isOzaria) {
        return this.saveSayEventsToStore();
      }
    }

    initProperties() {
      if (this.scriptInProgress) { this.endAll({force:true}); }
      this.triggered = [];
      this.ended = [];
      this.noteGroupQueue = [];
      return this.scripts = $.extend(true, [], this.originalScripts);
    }

    addScriptSubscriptions() {
      let idNum = 0;
      const makeCallback = channel => event => this.onNote(channel, event);
      return (() => {
        const result = [];
        for (var script of Array.from(this.scripts)) {
          if (!script.id) { script.id = (idNum++).toString(); }
          var callback = makeCallback(script.channel); // curry in the channel argument
          result.push(this.addNewSubscription(script.channel, callback));
        }
        return result;
      })();
    }

    // All say events that are valid need to be added to the tutorial as the
    // script manager starts up. Future say events will be added to the tutorial
    // as they become valid and are published.
    saveSayEventsToStore() {
      let sayEvents = [];

      this.scripts.forEach(script => {
        if (!this.scriptPrereqsSatisfied(script)) {
          return;
        }
        if (script.eventPrereqs) {
          return;
        }

        return sayEvents = sayEvents.concat(ScriptManager.extractSayEvents(script));
      });

      if (sayEvents.length) {
        return store.dispatch('game/addTutorialStepsFromSayEvents', sayEvents);
      }
    }

    beginTicking() {
      return this.tickInterval = setInterval(this.tick, 5000);
    }

    tick() {
      const scriptStates = {};
      const now = new Date();
      for (var script of Array.from(this.scripts)) {
        scriptStates[script.id] = {
          timeSinceLastEnded: (script.lastEnded ? now - script.lastEnded : 0) / 1000,
          timeSinceLastTriggered: (script.lastTriggered ? now - script.lastTriggered : 0) / 1000
        };
      }

      const stateEvent = {
        scriptRunning: (this.currentNoteGroup != null ? this.currentNoteGroup.scriptID : undefined) || '',
        noteGroupRunning: (this.currentNoteGroup != null ? this.currentNoteGroup.name : undefined) || '',
        scriptStates,
        timeSinceLastScriptEnded: (this.lastScriptEnded ? now - this.lastScriptEnded : 0) / 1000
      };

      return Backbone.Mediator.publish('script:tick', stateEvent);  // Used to trigger level scripts.
    }

    loadFromSession() {
      // load the queue with note groups to skip through
      this.addEndedScriptsFromSession();
      this.addPartiallyEndedScriptFromSession();
      return Array.from(this.noteGroupQueue).map((noteGroup) =>
        this.processNoteGroup(noteGroup));
    }

    addPartiallyEndedScriptFromSession() {
      const {
        scripts
      } = this.session.get('state');
      if (!(scripts != null ? scripts.currentScript : undefined)) { return; }
      const script = _.find(this.scripts, {id: scripts.currentScript});
      if (!script) { return; }
      const canSkipScript = utils.isCodeCombat || (ScriptManager.extractSayEvents(script).length === 0); // say events are reset each new run
      if (canSkipScript) {
        this.triggered.push(script.id);
      }
      const noteChain = this.processScript(script);
      if (!noteChain) { return; }
      if (scripts.currentScriptOffset && canSkipScript) {
        for (var noteGroup of Array.from(noteChain.slice(0, +(scripts.currentScriptOffset-1) + 1 || undefined))) { noteGroup.skipMe = true; }
      }
      return this.addNoteChain(noteChain, false);
    }

    addEndedScriptsFromSession() {
      const {
        scripts
      } = this.session.get('state');
      if (!scripts) { return; }
      const endedObj = scripts['ended'] || {};
      const sortedPairs = _.sortBy(_.pairs(endedObj), pair => pair[1]);
      const scriptsToSkip = (Array.from(sortedPairs).map((p) => p[0]));
      for (var scriptID of Array.from(scriptsToSkip)) {
        var script = _.find(this.scripts, {id: scriptID});
        if (!script) {
          console.warn('Couldn\'t find script for', scriptID, 'from scripts', this.scripts, 'when restoring session scripts.');
          continue;
        }
        if (script.repeats) { continue; } // repeating scripts are not 'rerun'
        var canSkipScript = utils.isCodeCombat || (ScriptManager.extractSayEvents(script).length === 0); // say events are reset each new run
        if (canSkipScript) {
          this.triggered.push(scriptID);
          this.ended.push(scriptID);
        }
        var noteChain = this.processScript(script);
        if (!noteChain) { return; }
        if (canSkipScript) {
          for (var noteGroup of Array.from(noteChain)) { noteGroup.skipMe = true; }
        }
        this.addNoteChain(noteChain, false);
      }
    }

    setWorldLoading(worldLoading) {
      this.worldLoading = worldLoading;
      if (!this.worldLoading) { return this.run(); }
    }

    initializeCamera() {
      // Fire off the first bounds-setting script now, before we're actually running any other ones.
      for (var script of Array.from(this.scripts)) {
        for (var note of Array.from(script.noteChain || [])) {
          if ((note.surface != null ? note.surface.focus : undefined) != null) {
            var surfaceModule = _.find(note.modules || [], module => module.surfaceCameraNote);
            if (surfaceModule) {
              var cameraNote = surfaceModule.surfaceCameraNote(true);
              this.publishNote(cameraNote);
              return;
            }
          }
        }
      }
    }

    destroy() {
      this.onEndAll();
      clearInterval(this.tickInterval);
      return super.destroy();
    }

    // TRIGGERERING NOTES

    onNote(channel, event) {
      if (this.ignoreEvents) { return; }
      for (var script of Array.from(this.scripts)) {
        var alreadyTriggered = Array.from(this.triggered).includes(script.id);
        if (script.channel !== channel) { continue; }
        if (alreadyTriggered && !script.repeats) { continue; }
        if ((script.lastTriggered != null) && (script.repeats === 'session')) { continue; }
        if ((script.lastTriggered != null) && ((new Date().getTime() - script.lastTriggered) < 1)) { continue; }
        if (script.neverRun) { continue; }

        if (script.notAfter) {
          for (var scriptID of Array.from(script.notAfter)) {
            if (Array.from(this.triggered).includes(scriptID)) {
              script.neverRun = true;
              break;
            }
          }
          if (script.neverRun) { continue; }
        }

        if (!this.scriptPrereqsSatisfied(script)) { continue; }
        // This allows the content team to filter scripts by language.
        if (event.codeLanguage == null) { var left;
        event.codeLanguage = (left = this.session.get('codeLanguage')) != null ? left : 'python'; }
        if (!scriptMatchesEventPrereqs(script, event)) { continue; }
        // everything passed!
        if (this.debugScripts) { console.debug(`SCRIPT: Running script '${script.id}'`); }
        script.lastTriggered = new Date().getTime();
        if (!alreadyTriggered) { this.triggered.push(script.id); }
        var noteChain = this.processScript(script);

        if (utils.isOzaria) {
          // There may have been new conditions that are met so we are now in a
          // position to add new say events to the tutorial. Duplicates are ignored.
          var sayEvents = ScriptManager.extractSayEvents(script);
          if (sayEvents.length) {
            store.dispatch('game/addTutorialStepsFromSayEvents', sayEvents);
          }
        }

        if (!noteChain) { return this.trackScriptCompletions((script.id)); }
        this.addNoteChain(noteChain);
        this.run();
      }
    }

    scriptPrereqsSatisfied(script) {
      return _.every(script.scriptPrereqs || [], prereq => Array.from(this.triggered).includes(prereq));
    }

    processScript(script) {
      const {
        noteChain
      } = script;
      if (!(noteChain != null ? noteChain.length : undefined)) { return null; }
      for (var noteGroup of Array.from(noteChain)) { noteGroup.scriptID = script.id; }
      const lastNoteGroup = noteChain[noteChain.length - 1];
      lastNoteGroup.isLast = true;
      return noteChain;
    }

    addNoteChain(noteChain, clearYields) {
      let noteGroup;
      if (clearYields == null) { clearYields = true; }
      for (noteGroup of Array.from(noteChain)) { this.processNoteGroup(noteGroup); }
      for (let i = 0; i < noteChain.length; i++) { noteGroup = noteChain[i]; noteGroup.index = i; }
      if (clearYields) {
        for (noteGroup of Array.from(this.noteGroupQueue)) { if (noteGroup.script.yields) { noteGroup.skipMe = true; } }
      }
      for (noteGroup of Array.from(noteChain)) { this.noteGroupQueue.push(noteGroup); }
      return this.endYieldingNote();
    }

    processNoteGroup(noteGroup) {
      if (noteGroup.modules != null) { return; }
      if ((noteGroup.playback != null ? noteGroup.playback.scrub : undefined) != null) {
        if (noteGroup.playback.scrub.duration == null) { noteGroup.playback.scrub.duration = DEFAULT_SCRUB_DURATION; }
      }
      if (noteGroup.sprites == null) { noteGroup.sprites = []; }
      for (var sprite of Array.from(noteGroup.sprites)) {
        if (sprite.move != null) {
          if (sprite.move.duration == null) { sprite.move.duration = DEFAULT_BOT_MOVE_DURATION; }
        }
        if (sprite.id == null) { sprite.id = 'Hero Placeholder'; }
      }
      if (noteGroup.script == null) { noteGroup.script = {}; }
      if (noteGroup.script.yields == null) { noteGroup.script.yields = true; }
      if (noteGroup.script.skippable == null) { noteGroup.script.skippable = true; }
      return noteGroup.modules = ((() => {
        const result = [];
        for (var Module of Array.from(allScriptModules)) {           if (Module.neededFor(noteGroup)) {
            result.push(new Module(noteGroup));
          }
        }
        return result;
      })());
    }

    endYieldingNote() {
      if (this.scriptInProgress && (this.currentNoteGroup != null ? this.currentNoteGroup.script.yields : undefined)) {
        this.endNoteGroup();
        return true;
      }
    }

    // STARTING NOTES

    run() {
      // catch all for analyzing the current state and doing whatever needs to happen next
      if (this.scriptInProgress) { return; }
      this.skipAhead();
      if (!this.noteGroupQueue.length) { return; }
      const nextNoteGroup = this.noteGroupQueue[0];
      if (this.worldLoading && nextNoteGroup.skipMe) { return; }
      if (this.worldLoading && !(nextNoteGroup.script != null ? nextNoteGroup.script.beforeLoad : undefined)) { return; }
      this.noteGroupQueue = this.noteGroupQueue.slice(1);
      this.currentNoteGroup = nextNoteGroup;
      this.notifyScriptStateChanged();
      this.scriptInProgress = true;
      this.currentTimeouts = [];
      const scriptLabel = `${nextNoteGroup.scriptID} - ${nextNoteGroup.name}`;
      if (this.debugScripts) { console.debug(`SCRIPT: Starting note group '${nextNoteGroup.name}'`); }
      for (var module of Array.from(nextNoteGroup.modules)) {
        for (var note of Array.from(module.startNotes())) { this.processNote(note, nextNoteGroup); }
      }
      if (nextNoteGroup.script.duration) {
        const f = () => (typeof this.onNoteGroupTimeout === 'function' ? this.onNoteGroupTimeout(nextNoteGroup) : undefined);
        setTimeout(f, nextNoteGroup.script.duration);
      }
      return Backbone.Mediator.publish('script:note-group-started', {});
    }

    skipAhead() {
      let i;
      if (this.worldLoading) { return; }
      if (!(this.noteGroupQueue[0] != null ? this.noteGroupQueue[0].skipMe : undefined)) { return; }
      this.ignoreEvents = true;
      for (i = 0; i < this.noteGroupQueue.length; i++) {
        var noteGroup = this.noteGroupQueue[i];
        if (!noteGroup.skipMe) { break; }
        if (this.debugScripts) { console.debug(`SCRIPT: Skipping note group '${noteGroup.name}'`); }
        this.processNoteGroup(noteGroup);
        for (var module of Array.from(noteGroup.modules)) {
          var notes = module.skipNotes();
          for (var note of Array.from(notes)) { this.processNote(note, noteGroup); }
        }
        this.trackScriptCompletionsFromNoteGroup(noteGroup);
      }
      this.noteGroupQueue = this.noteGroupQueue.slice(i);
      return this.ignoreEvents = false;
    }

    processNote(note, noteGroup) {
      if (note.event == null) { note.event = {}; }
      if (note.delay) {
        const f = () => this.sendDelayedNote(noteGroup, note);
        return this.currentTimeouts.push(setTimeout(f, note.delay));
      } else {
        return this.publishNote(note);
      }
    }

    sendDelayedNote(noteGroup, note) {
      // some events should only happen after the bot has moved into position
      if (noteGroup !== this.currentNoteGroup) { return; }
      return this.publishNote(note);
    }

    publishNote(note) {
      if (note.vuex) {
        return store.dispatch(
          note.channel,
          note.event != null ? note.event : {}
        );
      } else {
        return Backbone.Mediator.publish(note.channel, note.event != null ? note.event : {});
      }
    }

    // ENDING NOTES

    onLevelRestarted() {
      this.quiet = true;
      this.endAll({force:true});
      this.initProperties();
      this.resetThings();
      Backbone.Mediator.publish('script:reset', {});
      this.quiet = false;
      return this.run();
    }

    onEndNoteGroup(e) {
      // press enter
      if (!(this.currentNoteGroup != null ? this.currentNoteGroup.script.skippable : undefined)) { return; }
      this.endNoteGroup();
      return this.run();
    }

    endNoteGroup() {
      if (this.ending) { return; } // kill infinite loops right here
      this.ending = true;
      if (this.currentNoteGroup == null) { return; }
      const scriptLabel = `${this.currentNoteGroup.scriptID} - ${this.currentNoteGroup.name}`;
      if (this.debugScripts) { console.debug(`SCRIPT: Ending note group '${this.currentNoteGroup.name}'`); }
      for (var timeout of Array.from(this.currentTimeouts)) { clearTimeout(timeout); }
      for (var module of Array.from(this.currentNoteGroup.modules)) {
        for (var note of Array.from(module.endNotes())) { this.processNote(note, this.currentNoteGroup); }
      }
      if (!this.quiet) { Backbone.Mediator.publish('script:note-group-ended', {}); }
      this.scriptInProgress = false;
      this.trackScriptCompletionsFromNoteGroup(this.currentNoteGroup);
      this.currentNoteGroup = null;
      if (!this.noteGroupQueue.length) {
        this.notifyScriptStateChanged();
        this.resetThings();
      }
      return this.ending = false;
    }

    onEndAll(e) {
      // Escape was pressed.
      return this.endAll();
    }

    endAll(options) {
      if (options == null) { options = {}; }
      if (this.scriptInProgress) {
        if ((!this.currentNoteGroup.script.skippable) && (!options.force)) { return; }
        this.endNoteGroup();
      }

      for (let i = 0; i < this.noteGroupQueue.length; i++) {
        var noteGroup = this.noteGroupQueue[i];
        if (((noteGroup.script != null ? noteGroup.script.skippable : undefined) === false) && !options.force) {
          this.noteGroupQueue = this.noteGroupQueue.slice(i);
          this.run();
          this.notifyScriptStateChanged();
          return;
        }

        this.processNoteGroup(noteGroup);
        for (var module of Array.from(noteGroup.modules)) {
          var notes = module.skipNotes();
          if (!this.quiet) { for (var note of Array.from(notes)) { this.processNote(note, noteGroup); } }
        }
        if (!this.quiet) { this.trackScriptCompletionsFromNoteGroup(noteGroup); }
      }

      this.noteGroupQueue = [];

      this.resetThings();
      return this.notifyScriptStateChanged();
    }

    onNoteGroupTimeout(noteGroup) {
      if (noteGroup !== this.currentNoteGroup) { return; }
      this.endNoteGroup();
      return this.run();
    }

    resetThings() {
      Backbone.Mediator.publish('level:enable-controls', {});
      return Backbone.Mediator.publish('level:set-letterbox', { on: false });
    }

    trackScriptCompletionsFromNoteGroup(noteGroup) {
      if (!noteGroup.isLast) { return; }
      return this.trackScriptCompletions(noteGroup.scriptID);
    }

    trackScriptCompletions(scriptID) {
      if (this.quiet) { return; }
      if (!Array.from(this.ended).includes(scriptID)) { this.ended.push(scriptID); }
      for (var script of Array.from(this.scripts)) {
        if (script.id === scriptID) {
          script.lastEnded = new Date();
        }
      }
      this.lastScriptEnded = new Date();
      return Backbone.Mediator.publish('script:ended', {scriptID});
    }

    notifyScriptStateChanged() {
      if (this.quiet) { return; }
      const event = {
        currentScript: (this.currentNoteGroup != null ? this.currentNoteGroup.scriptID : undefined) || null,
        currentScriptOffset: (this.currentNoteGroup != null ? this.currentNoteGroup.index : undefined) || 0
      };
      return Backbone.Mediator.publish('script:state-changed', event);
    }
  };
  ScriptManager.initClass();
  return ScriptManager;
})()));

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}