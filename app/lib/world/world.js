// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__, or convert again using --optional-chaining
 * DS104: Avoid inline assignments
 * DS202: Simplify dynamic range loops
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let World;
const _ = require('lodash'); // TODO webpack: Get these two loading from lodash entry, probably
_.string = require('underscore.string');
const Vector = require('./vector');
const Rectangle = require('./rectangle');
const Ellipse = require('./ellipse');
const LineSegment = require('./line_segment');
const WorldFrame = require('./world_frame');
const Thang = require('./thang');
const ThangState = require('./thang_state');
const Rand = require('./rand');
const WorldScriptNote = require('./world_script_note');
const {now, consolidateThangs, typedArraySupport} = require('./world_utils');
const Component = require('lib/world/component');
const System = require('lib/world/system');
const PROGRESS_UPDATE_INTERVAL = 100;
const DESERIALIZATION_INTERVAL = 10;
const REAL_TIME_BUFFER_MIN = 2 * PROGRESS_UPDATE_INTERVAL;
const REAL_TIME_BUFFER_MAX = 3 * PROGRESS_UPDATE_INTERVAL;
const REAL_TIME_BUFFERED_WAIT_INTERVAL = 0.5 * PROGRESS_UPDATE_INTERVAL;
const REAL_TIME_COUNTDOWN_DELAY = 3000;  // match CountdownScreen
const ITEM_ORIGINAL = '53e12043b82921000051cdf9';
const EXISTS_ORIGINAL = '524b4150ff92f1f4f8000024';
const COUNTDOWN_LEVELS = ['sky-span'];
window.string_score = require('vendor/scripts/string_score.js'); // Used as a global in DB code
require('vendor/scripts/coffeescript'); // Install the global CoffeeScript compiler #TODO Performance: Load this only when necessary
require('lib/worldLoader'); // Install custom hack to dynamically require library files

module.exports = (World = (function() {
  World = class World {
    static initClass() {
      this.className = 'World';
      this.prototype.age = 0;
      this.prototype.ended = false;
      this.prototype.preloading = false;  // Whether we are just preloading a world in case we soon cast it
      this.prototype.debugging = false;  // Whether we are just rerunning to debug a world we've already cast
      this.prototype.headless = false;  // Whether we are just simulating for goal states instead of all serialized results
      this.prototype.synchronous = false;  // Whether we are simulating the game on the main thread and don't need to serialize/deserialize
      this.prototype.framesSerializedSoFar = 0;
      this.prototype.framesClearedSoFar = 0;
      this.prototype.apiProperties = ['age', 'dt'];
      this.prototype.realTimeBufferMax = REAL_TIME_BUFFER_MAX / 1000;  // Return in-progress deserializing world

      // Spread deserialization out across multiple calls so the interface stays responsive
      this.deserializeSomeFrames = (o, w, finishedWorldCallback, perf, startFrame, endFrame) => {
        let elapsed;
        ++perf.batches;
        const startTime = now();
        for (let frameIndex = w.frames.length, end = endFrame, asc = w.frames.length <= end; asc ? frameIndex < end : frameIndex > end; asc ? frameIndex++ : frameIndex--) {
          w.frames.push(WorldFrame.deserialize(w, frameIndex - startFrame, o.trackedPropertiesThangIDs, o.trackedPropertiesThangs, o.trackedPropertiesPerThangKeys, o.trackedPropertiesPerThangTypes, o.trackedPropertiesPerThangValues, o.specialKeysToValues, o.scoresStorage, o.frameHashes[frameIndex - startFrame], w.dt * frameIndex));
          elapsed = now() - startTime;
          if ((elapsed > DESERIALIZATION_INTERVAL) && (frameIndex < (endFrame - 1))) {
            //console.log "  Deserialization not finished, let's do it again soon. Have:", w.frames.length, ", wanted from", startFrame, "to", endFrame
            perf.framesCPUTime += elapsed;
            this.deserializationTimeout = _.delay(this.deserializeSomeFrames, 1, o, w, finishedWorldCallback, perf, startFrame, endFrame);
            return;
          }
        }
        this.deserializationTimeout = null;
        perf.framesCPUTime += elapsed;
        return this.finishDeserializing(w, finishedWorldCallback, perf, startFrame, endFrame);  // Pick at random for good distribution
      };

      this.prototype.scoreTypes = ['time', 'damage-taken', 'damage-dealt', 'gold-collected', 'difficulty', 'survival-time', 'defeated'];
    }
    constructor(userCodeMap, classMap) {
      // classMap is needed for deserializing Worlds, Thangs, and other classes
      this.userCodeMap = userCodeMap;
      this.classMap = classMap != null ? classMap : {Vector, Rectangle, Thang, Ellipse, LineSegment};
      Thang.resetThangIDs();

      if (this.userCodeMap == null) { this.userCodeMap = {}; }
      this.thangs = [];
      this.thangMap = {};
      this.systems = [];
      this.systemMap = {};
      this.scriptNotes = [];
      this.rand = new Rand(0);  // Existence System may change this seed
      this.frames = [new WorldFrame(this, 0)];
    }

    destroy() {
      if (this.goalManager != null) {
        this.goalManager.destroy();
      }
      for (var thang of Array.from(this.thangs)) { thang.destroy(); }
      for (var key in this) { this[key] = undefined; }
      this.destroyed = true;
      return this.destroy = function() {};
    }

    getFrame(frameIndex) {
      // Optimize it a bit--assume we have all if @ended and are at the previous frame otherwise
      let frame;
      const {
        frames
      } = this;
      if (this.ended) {
        frame = frames[frameIndex];
      } else if (frameIndex) {
        frame = frames[frameIndex - 1].getNextFrame();
        frames.push(frame);
      } else {
        frame = frames[0];
      }
      this.age = frameIndex * this.dt;
      return frame;
    }

    getThangByID(id) {
      return this.thangMap[id];
    }

    setThang(thang) {
      thang.stateChanged = true;
      for (let i = 0; i < this.thangs.length; i++) {
        var old = this.thangs[i];
        if (old.id === thang.id) {
          this.thangs[i] = thang;
          break;
        }
      }
      return this.thangMap[thang.id] = thang;
    }

    thangDialogueSounds(startFrame) {
      if (startFrame == null) { startFrame = 0; }
      if (!(startFrame < this.frames.length)) { return []; }
      const [sounds, seen] = Array.from([[], {}]);
      for (let frameIndex = startFrame, end = this.frames.length, asc = startFrame <= end; asc ? frameIndex < end : frameIndex > end; asc ? frameIndex++ : frameIndex--) {
        var frame = this.frames[frameIndex];
        for (var thangID in frame.thangStateMap) {
          var sayMessage;
          var state = frame.thangStateMap[thangID];
          if (!state.thang.say || !(sayMessage = state.getStateForProp('sayMessage'))) { continue; }
          var soundKey = state.thang.spriteName + ':' + sayMessage;
          if (!seen[soundKey]) {
            sounds.push([state.thang.spriteName, sayMessage]);
            seen[soundKey] = true;
          }
        }
      }
      return sounds;
    }

    setGoalManager(goalManager) {
      this.goalManager = goalManager;
    }

    addError(error) {
      (this.runtimeErrors != null ? this.runtimeErrors : (this.runtimeErrors = [])).push(error);
      return (this.unhandledRuntimeErrors != null ? this.unhandledRuntimeErrors : (this.unhandledRuntimeErrors = [])).push(error);
    }

    loadFrames(loadedCallback, errorCallback, loadProgressCallback, preloadedCallback, skipDeferredLoading, loadUntilFrame) {
      if (this.aborted) { return; }
      if (this.justBegin) { this.totalFrames = 2; }
      if (!this.thangs.length) { console.log('Warning: loadFrames called on empty World (no thangs).'); }
      const continueLaterFn = () => {
        if (!this.destroyed) { return this.loadFrames(loadedCallback, errorCallback, loadProgressCallback, preloadedCallback, skipDeferredLoading, loadUntilFrame); }
      };
      if (this.realTime && !this.countdownFinished) {
        this.realTimeSpeedFactor = 1;
        if (!this.showsCountdown) {
          if (['woodland-cleaver', 'village-guard', 'shield-rush'].includes(this.levelID)) {
            this.realTimeSpeedFactor = 2;
          } else if (['thornbush-farm', 'back-to-back', 'ogre-encampment', 'peasant-protection', 'munchkin-swarm', 'munchkin-harvest', 'swift-dagger', 'shrapnel', 'arcane-ally', 'touch-of-death', 'bonemender'].includes(this.levelID)) {
            this.realTimeSpeedFactor = 3;
          }
        }
        if (this.showsCountdown) {
          return setTimeout(this.finishCountdown(continueLaterFn), REAL_TIME_COUNTDOWN_DELAY);
        } else {
          this.finishCountdown(continueLaterFn);
        }
      }
      const t1 = now();
      if (this.t0 == null) { this.t0 = t1; }
      if (this.worldLoadStartTime == null) { this.worldLoadStartTime = t1; }
      if (this.lastRealTimeUpdate == null) { this.lastRealTimeUpdate = 0; }
      const frameToLoadUntil = loadUntilFrame ? loadUntilFrame + 1 : this.totalFrames;  // Might stop early if debugging.
      let i = this.frames.length;
      while (true) {
        var error;
        if (this.indefiniteLength) {
          if (!this.realTime) { break; } // realtime has been stopped
          if (this.victory != null) { break; } // game won or lost  # TODO: give a couple seconds of buffer after victory is set instead of ending instantly
        } else {
          if (i >= frameToLoadUntil) { break; }
          if (i >= this.totalFrames) { break; }
        }
        if (!this.shouldContinueLoading(t1, loadProgressCallback, skipDeferredLoading, continueLaterFn)) { return; }
        if (this.debugging) { this.adjustFlowSettings(loadUntilFrame); }
        try {
          this.getFrame(i);
          ++i;  // Increment this after we have succeeded in getting the frame, otherwise we'll have to do that frame again
        } catch (error1) {
          error = error1;
          this.addError(error);  // Not an Aether.errors.UserCodeError; maybe we can't recover
        }
        if (!this.preloading && !this.debugging) {
          for (error of Array.from((this.unhandledRuntimeErrors != null ? this.unhandledRuntimeErrors : []))) {
            if (!errorCallback(error)) { return; }
          }  // errorCallback tells us whether the error is recoverable
          this.unhandledRuntimeErrors = [];
        }
      }
      return this.finishLoadingFrames(loadProgressCallback, loadedCallback, preloadedCallback);
    }

    finishLoadingFrames(loadProgressCallback, loadedCallback, preloadedCallback) {
      if (!this.debugging) {
        this.ended = true;
        for (var system of Array.from(this.systems)) { system.finish(this.thangs); }
      }
      if (this.preloading) {
        return preloadedCallback();
      } else {
        if (typeof loadProgressCallback === 'function') {
          loadProgressCallback(1);
        }
        return loadedCallback();
      }
    }

    finishCountdown(continueLaterFn) { return () => {
      if (this.destroyed) { return; }
      this.countdownFinished = true;
      return continueLaterFn();
    }; }

    shouldDelayRealTimeSimulation(t) {
      if (!this.realTime) { return false; }
      const timeSinceStart = (t - this.worldLoadStartTime) * this.realTimeSpeedFactor;
      const timeLoaded = this.frames.length * this.dt * 1000;
      const timeBuffered = timeLoaded - timeSinceStart;
      if (this.indefiniteLength) {
        return timeBuffered > 0;
      } else {
        return timeBuffered > (REAL_TIME_BUFFER_MAX * this.realTimeSpeedFactor);
      }
    }

    shouldUpdateRealTimePlayback(t) {
      if (!this.realTime) { return false; }
      if ((this.frames.length * this.dt) === this.lastRealTimeUpdate) { return false; }
      const timeLoaded = this.frames.length * this.dt * 1000;
      const timeSinceStart = (t - this.worldLoadStartTime) * this.realTimeSpeedFactor;
      const remainingBuffer = (this.lastRealTimeUpdate * 1000) - timeSinceStart;
      if (this.indefiniteLength) {
        return remainingBuffer <= 0;
      } else {
        return remainingBuffer < (REAL_TIME_BUFFER_MIN * this.realTimeSpeedFactor);
      }
    }

    shouldContinueLoading(t1, loadProgressCallback, skipDeferredLoading, continueLaterFn) {
      let shouldDelayRealTimeSimulation, shouldUpdateProgress;
      const t2 = now();
      const chunkSize = this.frames.length - this.framesSerializedSoFar;
      const simedTime = this.frames.length / this.frameRate;

      const chunkTime = (() => { switch (false) {
        case !(simedTime > 15): return 7;
        case !(simedTime > 10): return 5;
        case !(simedTime > 5): return 3;
        case !(simedTime > 2): return 1;
        default: return 0.5;
      } })();

      const bailoutTime = Math.max(2000*chunkTime, 10000);

      const dt = t2 - t1;

      if (this.realTime) {
        shouldUpdateProgress = this.shouldUpdateRealTimePlayback(t2);
        shouldDelayRealTimeSimulation = !shouldUpdateProgress && this.shouldDelayRealTimeSimulation(t2);
      } else {
        shouldUpdateProgress = (((dt > PROGRESS_UPDATE_INTERVAL) && ((chunkSize / this.frameRate) >= chunkTime)) || (dt > bailoutTime));
        shouldDelayRealTimeSimulation = false;
      }
      if (!shouldUpdateProgress && !shouldDelayRealTimeSimulation) { return true; }
      // Stop loading frames for now; continue in a moment.
      if (shouldUpdateProgress) {
        if (this.realTime) { this.lastRealTimeUpdate = this.frames.length * this.dt; }
        //console.log 'we think it is now', (t2 - @worldLoadStartTime) / 1000, 'so delivering', @lastRealTimeUpdate
        if (!this.preloading) { if (typeof loadProgressCallback === 'function') {
          loadProgressCallback(this.frames.length / this.totalFrames);
        } }
      }
      t1 = t2;
      if ((t2 - this.t0) > 1000) {
        if (!this.realTime) { console.log('  Loaded', this.frames.length, 'of', this.totalFrames, '(+' + (t2 - this.t0).toFixed(0) + 'ms)'); }
        this.t0 = t2;
      }
      if (skipDeferredLoading) {
        continueLaterFn();
      } else {
        let delay = 0;
        if (shouldDelayRealTimeSimulation) {
          if (this.indefiniteLength) {
            delay = 1000 / 30;
          } else {
            delay = REAL_TIME_BUFFERED_WAIT_INTERVAL;
          }
        }
        setTimeout(continueLaterFn, delay);
      }
      return false;
    }

    adjustFlowSettings(loadUntilFrame) {
      return (() => {
        const result = [];
        for (var thang of Array.from(this.thangs)) {
          if (thang.isProgrammable) {
            var userCode = this.userCodeMap[thang.id] != null ? this.userCodeMap[thang.id] : {};
            result.push((() => {
              const result1 = [];
              for (var methodName in userCode) {
                var aether = userCode[methodName];
                var framesToLoadFlowBefore = (methodName === 'plan') || (methodName === 'makeBid') ? 200 : 1;  // Adjust if plan() is taking even longer
                result1.push(aether._shouldSkipFlow = this.frames.length < (loadUntilFrame - framesToLoadFlowBefore));
              }
              return result1;
            })());
          }
        }
        return result;
      })();
    }

    finalizePreload(loadedCallback) {
      this.preloading = false;
      if (this.ended) { return loadedCallback(); }
    }

    abort() {
      return this.aborted = true;
    }

    addFlagEvent(flagEvent) {
      return this.flagHistory.push(flagEvent);
    }

    addRealTimeInputEvent(realTimeInputEvent) {
      return this.realTimeInputEvents.push(realTimeInputEvent);
    }

    loadFromLevel(level, willSimulate) {
      if (willSimulate == null) { willSimulate = true; }
      this.levelID = level.slug;
      this.levelComponents = level.levelComponents;
      this.thangTypes = level.thangTypes;
      this.loadScriptsFromLevel(level);
      this.loadSystemsFromLevel(level);
      this.loadThangsFromLevel(level, willSimulate);
      this.showsCountdown = Array.from(COUNTDOWN_LEVELS).includes(this.levelID) || _.any(this.thangs, t => (t.programmableProperties && Array.from(t.programmableProperties).includes('findFlags')) || (t.inventory != null ? t.inventory.flag : undefined));
      if (level.picoCTFProblem) { this.picoCTFProblem = level.picoCTFProblem; }
      if ((this.picoCTFProblem != null ? this.picoCTFProblem.instances : undefined) && !this.picoCTFProblem.flag_sha1) {
        this.picoCTFProblem = _.merge(this.picoCTFProblem, this.picoCTFProblem.instances[0]);
      }
      for (var system of Array.from(this.systems)) {
        try {
          system.start(this.thangs);
        } catch (err) {
          console.error("Error starting system!", system, err);
        }
      }
      return this.constrainHeroHealth(level);
    }

    loadSystemsFromLevel(level) {
      // Remove old Systems
      this.systems = [];
      this.systemMap = {};

      // Load new Systems
      for (var levelSystem of Array.from(level.systems)) {
        var systemModel = levelSystem.model;
        var {
          config
        } = levelSystem;
        var systemClass = this.loadClassFromCode(systemModel.js, systemModel.name, 'system');
        //console.log "using db system class ---\n", systemClass, "\n--- from code ---n", systemModel.js, "\n---"
        var system = new systemClass(this, config);
        this.addSystems(system);
      }
      return null;
    }

    loadThangsFromLevel(level, willSimulate) {
      // Remove old Thangs
      this.thangs = [];
      this.thangMap = {};

      // Load new Thangs
      const toAdd = (Array.from(level.thangs != null ? level.thangs : []).map((thangConfig) => this.loadThangFromLevel(thangConfig, level.levelComponents, level.thangTypes)));
      if (willSimulate && !this.synchronous) { this.extraneousThangs = consolidateThangs(toAdd); }  // Combine walls, for example; serialize the leftovers later
      for (var thang of Array.from(toAdd)) { this.addThang(thang); }
      return null;
    }

    loadThangFromLevel(thangConfig, levelComponents, thangTypes, equipBy=null) {
      let existsConfigIndex, isItem;
      const components = [];
      for (let componentIndex = 0; componentIndex < thangConfig.components.length; componentIndex++) {
        var component = thangConfig.components[componentIndex];
        var componentModel = _.find(levelComponents, c => (c.original === component.original) && (c.version.major === (component.majorVersion != null ? component.majorVersion : 0)));
        var componentClass = this.loadClassFromCode(componentModel.js, componentModel.name, 'component');
        components.push([componentClass, component.config]);
        if (component.original === ITEM_ORIGINAL) {
          isItem = true;
          if (equipBy) { component.config.ownerID = equipBy; }
        } else if (component.original === EXISTS_ORIGINAL) {
          existsConfigIndex = componentIndex;
        }
      }
      if (isItem && (existsConfigIndex != null)) {
        // For memory usage performance, make sure these don't get any tracked properties assigned.
        components[existsConfigIndex][1] = {exists: false, stateless: true};
      }
      const thangTypeOriginal = thangConfig.thangType;
      const thangTypeModel = _.find(thangTypes, t => t.original === thangTypeOriginal);
      if (!thangTypeModel) { return console.error(thangConfig.id != null ? thangConfig.id : equipBy, 'could not find ThangType for', thangTypeOriginal); }
      const thangTypeName = thangTypeModel.name;
      const thang = new Thang(this, thangTypeName, thangConfig.id);
      try {
        thang.addComponents(...Array.from(components || []));
      } catch (e) {
        console.error('couldn\'t load components for', thangTypeOriginal, thangConfig.id, 'because', e.toString(), e.stack);
      }
      return thang;
    }

    addThang(thang) {
      this.thangs.unshift(thang);  // Interactions happen in reverse order of specification/drawing
      this.setThang(thang);
      this.updateThangState(thang);
      thang.updateRegistration();
      return thang;
    }

    loadScriptsFromLevel(level) {
      this.scriptNotes = [];
      this.scripts = [];
      return this.addScripts(...Array.from(level.scripts || []));
    }

    loadClassFromCode(js, name, kind) {
      // Cache them based on source code so we don't have to worry about extra compilations
      if (kind == null) { kind = 'component'; }
      if (this.componentCodeClassMap == null) { this.componentCodeClassMap = {}; }
      if (this.systemCodeClassMap == null) { this.systemCodeClassMap = {}; }
      const map = kind === 'component' ? this.componentCodeClassMap : this.systemCodeClassMap;
      let c = map[js];
      if (c) { return c; }
      try {
        window.require = window.libWorldRequire;
        c = (map[js] = eval(js));
      } catch (err) {
        console.error(`Couldn't compile ${kind} code:`, err, "\n", js);
        c = (map[js] = {});
      }
      window.require = null
      c.className = name;
      return c;
    }

    updateThangState(thang) {
      return this.frames[this.frames.length-1].thangStateMap[thang.id] = thang.getState();
    }

    size() {
      if ((this.width == null) || (this.height == null)) { this.calculateBounds(); }
      if ((this.width != null) && (this.height != null)) { return [this.width, this.height]; }
    }

    getBounds() {
      if (this.bounds == null) { this.calculateBounds(); }
      return this.bounds;
    }

    calculateBounds() {
      const bounds = {left: 0, top: 0, right: 0, bottom: 0};
      const hasLand = _.some(this.thangs, 'isLand');
      for (var thang of Array.from(this.thangs)) {  // Look at Lands only
        if (thang.isLand || (!hasLand && thang.rectangle)) {
          var rect = thang.rectangle().axisAlignedBoundingBox();
          bounds.left = Math.min(bounds.left, rect.x - (rect.width / 2));
          bounds.right = Math.max(bounds.right, rect.x + (rect.width / 2));
          bounds.bottom = Math.min(bounds.bottom, rect.y - (rect.height / 2));
          bounds.top = Math.max(bounds.top, rect.y + (rect.height / 2));
        }
      }
      this.width = bounds.right - bounds.left;
      this.height = bounds.top - bounds.bottom;
      this.bounds = bounds;
      return [this.width, this.height];
    }

    calculateSimpleMovementBounds(thangs){
      // Figure out corners based solely on where simple movement dots are
      // This could also calculate automatically from GridMovement2 System, but that's not used in all levels
      if (thangs == null) { ({
        thangs
      } = this); }
      const bounds = {left: 9001, top: -9001, right: -9001, bottom: 9001};
      for (var thang of Array.from(thangs)) {  // Dot Stateless, Dot Underwater, etc.
        if (/^Dot/.test(thang.spriteName)) {
          bounds.left = Math.min(bounds.left, thang.pos.x);
          bounds.right = Math.max(bounds.right, thang.pos.x);
          bounds.bottom = Math.min(bounds.bottom, thang.pos.y);
          bounds.top = Math.max(bounds.top, thang.pos.y);
        }
      }
      return bounds;
    }

    publishNote(channel, event) {
      if (event == null) { event = {}; }
      channel = 'world:' + channel;
      for (var script of Array.from(this.scripts != null ? this.scripts : [])) {
        if (script.channel !== channel) { continue; }
        var scriptNote = new WorldScriptNote(script, event);
        if (scriptNote.invalid) { continue; }
        this.scriptNotes.push(scriptNote);
      }
      if (!this.goalManager) { return; }
      return this.goalManager.submitWorldGenerationEvent(channel, event, this.frames.length);
    }

    // This can be used for arbitrary Backbone Mediator events tied to world frames.
    // Example: publishWorldEvent('update-key-value-db', {})
    // For new event types, add a subscription schema in app/schemas/subscriptions/world
    publishWorldEvent(channel, event) {
      if (event == null) { event = {}; }
      channel = 'world:' + channel;
      const scriptNote = new WorldScriptNote({ channel }, event);
      return this.scriptNotes.push(scriptNote);
    }

    publishCameraEvent(eventName, event) {
      if (!(typeof Backbone !== 'undefined' && Backbone !== null ? Backbone.Mediator : undefined)) { return; } // headless mode don't have this
      if (event == null) { event = {}; }
      eventName = 'camera:' + eventName;
      return Backbone.Mediator.publish(eventName, event);
    }

    getGoalState(goalID) {
      return this.goalManager.getGoalState(goalID);
    }

    setGoalState(goalID, status) {
      return this.goalManager.setGoalState(goalID, status);
    }

    endWorld(victory, delay, tentative) {
      if (victory == null) { victory = false; }
      if (delay == null) { delay = 3; }
      if (tentative == null) { tentative = false; }
      const maximumFrame = this.indefiniteLength ? Infinity : this.totalFrames;
      this.totalFrames = Math.min(maximumFrame, this.frames.length + Math.floor(delay / this.dt));  // end a few seconds later
      this.victory = victory;  // TODO: should just make this signify the winning superteam
      this.victoryIsTentative = tentative;
      const status = this.victory ? 'won' : 'lost';
      this.publishNote(status);
      return console.log(`The world ended in ${status} on frame ${this.totalFrames}`);
    }

    addSystems(...systems) {
      this.systems = this.systems.concat(systems);
      return Array.from(systems).map((system) =>
        (this.systemMap[system.constructor.className] = system));
    }
    getSystem(systemClassName) {
      return (this.systemMap != null ? this.systemMap[systemClassName] : undefined);
    }

    addScripts(...scripts) {
      return this.scripts = (this.scripts != null ? this.scripts : []).concat(scripts);
    }

    addTrackedProperties(...props) {
      return this.trackedProperties = (this.trackedProperties != null ? this.trackedProperties : []).concat(props);
    }

    serialize() {
      // Code hotspot; optimize it
      let i, propIndex, scoresBytesStored, storage, type;
      if (this.ended) { this.freeMemoryBeforeFinalSerialization(); }
      const startFrame = this.framesSerializedSoFar;
      const endFrame = this.frames.length;
      if (this.indefiniteLength) {
        const toClear = Math.max(this.framesSerializedSoFar-10, 0);
        for (i of Array.from(_.range(this.framesClearedSoFar, toClear))) {
          this.frames[i] = null;
        }
        this.framesClearedSoFar = this.framesSerializedSoFar;
      }
      //console.log "... world serializing frames from", startFrame, "to", endFrame, "of", @totalFrames
      let [transferableObjects, nontransferableObjects] = Array.from([0, 0]);
      const serializedFlagHistory = (Array.from(this.flagHistory).map((flag) => _.omit(_.clone(flag), 'processed')));
      const o = {totalFrames: this.totalFrames, maxTotalFrames: this.maxTotalFrames, frameRate: this.frameRate, dt: this.dt, victory: this.victory, userCodeMap: {}, trackedProperties: {}, flagHistory: serializedFlagHistory, difficulty: this.difficulty, scores: this.getScores(), randomSeed: this.randomSeed, picoCTFFlag: this.picoCTFFlag, keyValueDb: this.keyValueDb};
      for (var prop of Array.from(this.trackedProperties || [])) { o.trackedProperties[prop] = this[prop]; }

      for (var thangID in this.userCodeMap) {
        var methods = this.userCodeMap[thangID];
        var serializedMethods = (o.userCodeMap[thangID] = {});
        for (var methodName in methods) {
          var left;
          var method = methods[methodName];
          serializedMethods[methodName] = (left = (typeof method.serialize === 'function' ? method.serialize() : undefined)) != null ? left : method;
        }
      } // serialize the method again if it has been deserialized

      const t0 = now();
      o.trackedPropertiesThangIDs = [];
      o.trackedPropertiesPerThangIndices = [];
      o.trackedPropertiesPerThangKeys = [];
      o.trackedPropertiesPerThangTypes = [];
      const trackedPropertiesPerThangValues = [];  // We won't send these, just the offsets and the storage buffer
      o.trackedPropertiesPerThangValuesOffsets = [];  // Needed to reconstruct ArrayBufferViews on other end, since Firefox has bugs transfering those: https://bugzilla.mozilla.org/show_bug.cgi?id=841904 and https://bugzilla.mozilla.org/show_bug.cgi?id=861925  # Actually, as of January 2014, it should be fixed. So we could try to undo the workaround.
      let transferableStorageBytesNeeded = 0;
      const nFrames = endFrame - startFrame;
      for (var thang of Array.from(this.thangs)) {
        // Don't serialize empty trackedProperties for stateless Thangs which haven't changed (like obstacles).
        // Check both, since sometimes people mark stateless Thangs but then change them, and those should still be tracked, and the inverse doesn't work on the other end (we'll just think it doesn't exist then).
        // If streaming the world, a thang marked stateless that actually change will get messed up. I think.
        if (thang.stateless && !_.some(thang.trackedPropertiesUsed, Boolean)) { continue; }
        o.trackedPropertiesThangIDs.push(thang.id);
        var trackedPropertiesIndices = [];
        var trackedPropertiesKeys = [];
        var trackedPropertiesTypes = [];
        for (propIndex = 0; propIndex < thang.trackedPropertiesUsed.length; propIndex++) {
          var used = thang.trackedPropertiesUsed[propIndex];
          if (!used) { continue; }
          trackedPropertiesIndices.push(propIndex);
          trackedPropertiesKeys.push(thang.trackedPropertiesKeys[propIndex]);
          trackedPropertiesTypes.push(thang.trackedPropertiesTypes[propIndex]);
        }
        o.trackedPropertiesPerThangIndices.push(trackedPropertiesIndices);
        o.trackedPropertiesPerThangKeys.push(trackedPropertiesKeys);
        o.trackedPropertiesPerThangTypes.push(trackedPropertiesTypes);
        trackedPropertiesPerThangValues.push([]);
        o.trackedPropertiesPerThangValuesOffsets.push([]);
        for (type of Array.from(trackedPropertiesTypes)) {
          transferableStorageBytesNeeded += ThangState.transferableBytesNeededForType(type, nFrames);
        }
      }
      transferableStorageBytesNeeded += ThangState.transferableBytesNeededForType('number', this.scoreTypes.length * nFrames);
      if (typedArraySupport) {
        o.storageBuffer = new ArrayBuffer(transferableStorageBytesNeeded);
      } else {
        o.storageBuffer = [];
      }
      let storageBufferOffset = 0;
      for (let thangIndex = 0; thangIndex < trackedPropertiesPerThangValues.length; thangIndex++) {
        var trackedPropertiesValues = trackedPropertiesPerThangValues[thangIndex];
        var trackedPropertiesValuesOffsets = o.trackedPropertiesPerThangValuesOffsets[thangIndex];
        for (propIndex = 0; propIndex < o.trackedPropertiesPerThangTypes[thangIndex].length; propIndex++) {
          var bytesStored;
          type = o.trackedPropertiesPerThangTypes[thangIndex][propIndex];
          [storage, bytesStored] = Array.from(ThangState.createArrayForType(type, nFrames, o.storageBuffer, storageBufferOffset));
          trackedPropertiesValues.push(storage);
          trackedPropertiesValuesOffsets.push(storageBufferOffset);
          if (bytesStored) { ++transferableObjects; }
          if (!bytesStored) { ++nontransferableObjects; }
          if (typedArraySupport) {
            storageBufferOffset += bytesStored;
          } else {
            // Instead of one big array with each storage as a view into it, they're all separate, so let's keep 'em around for flattening.
            storageBufferOffset += storage.length;
            o.storageBuffer.push(storage);
          }
        }
      }
      [o.scoresStorage, scoresBytesStored] = Array.from(ThangState.createArrayForType('number', nFrames * this.scoreTypes.length, o.storageBuffer, storageBufferOffset));

      o.specialKeysToValues = [null, Infinity, NaN];
      // Whatever is in specialKeysToValues index 0 will be default for anything missing, so let's make sure it's null.
      // Don't think we can include undefined or it'll be treated as a sparse array; haven't tested performance.
      o.specialValuesToKeys = {};
      for (i = 0; i < o.specialKeysToValues.length; i++) {
        var specialValue = o.specialKeysToValues[i];
        o.specialValuesToKeys[specialValue] = i;
      }

      const t1 = now();
      o.frameHashes = [];
      for (let frameIndex = startFrame, end = endFrame, asc = startFrame <= end; asc ? frameIndex < end : frameIndex > end; asc ? frameIndex++ : frameIndex--) {
        o.frameHashes.push(this.frames[frameIndex].serialize(frameIndex - startFrame, o.trackedPropertiesThangIDs, o.trackedPropertiesPerThangIndices, o.trackedPropertiesPerThangTypes, trackedPropertiesPerThangValues, o.specialValuesToKeys, o.specialKeysToValues, o.scoresStorage));
      }
      const t2 = now();

      if (!typedArraySupport) {
        const flattened = [];
        for (storage of Array.from(o.storageBuffer)) {
          for (var value of Array.from(storage)) {
            flattened.push(value);
          }
        }
        o.storageBuffer = flattened;
      }

      //console.log 'Allocating memory:', (t1 - t0).toFixed(0), 'ms; assigning values:', (t2 - t1).toFixed(0), 'ms, so', ((t2 - t1) / nFrames).toFixed(3), 'ms per frame for', nFrames, 'frames'
      //console.log 'Got', transferableObjects, 'transferable objects and', nontransferableObjects, 'nontransferable; stored', transferableStorageBytesNeeded, 'bytes transferably'

      o.thangs = (Array.from(this.thangs.concat(this.extraneousThangs != null ? this.extraneousThangs : [])).map((t) => t.serialize()));
      o.scriptNotes = (Array.from(this.scriptNotes).map((sn) => sn.serialize()));
      if (o.scriptNotes.length > 200) {
        console.log('Whoa, serializing a lot of WorldScriptNotes here:', o.scriptNotes.length);
      }
      if (!this.ended) { this.freeMemoryAfterEachSerialization(); }
      return {serializedWorld: o, transferableObjects: [o.storageBuffer], startFrame, endFrame};
    }

    static deserialize(o, classMap, oldSerializedWorldFrames, finishedWorldCallback, startFrame, endFrame, level, streamingWorld) {
      // Code hotspot; optimize it
      //console.log 'Deserializing', o, 'length', JSON.stringify(o).length
      //console.log JSON.stringify(o)
      //console.log 'Got special keys and values:', o.specialValuesToKeys, o.specialKeysToValues
      let i, prop, val, w;
      let thang, thangID;
      const perf = {};
      perf.t0 = now();
      const nFrames = endFrame - startFrame;
      if (streamingWorld) {
        w = streamingWorld;
        // Make sure we get any Aether updates from the new frames into the already-deserialized streaming world Aethers.
        for (thangID in o.userCodeMap) {
          var methods = o.userCodeMap[thangID];
          for (var methodName in methods) {
            var serializedAether = methods[methodName];
            for (var aetherStateKey of ['flow', 'metrics', 'style', 'problems']) {
              if (w.userCodeMap[thangID] == null) { w.userCodeMap[thangID] = {}; }
              if (w.userCodeMap[thangID][methodName] == null) { w.userCodeMap[thangID][methodName] = {}; }
              w.userCodeMap[thangID][methodName][aetherStateKey] = serializedAether[aetherStateKey];
            }
          }
        }
      } else {
        w = new World(o.userCodeMap, classMap);
      }
      [w.totalFrames, w.maxTotalFrames, w.frameRate, w.dt, w.scriptNotes, w.victory, w.flagHistory, w.difficulty, w.scores, w.randomSeed, w.picoCTFFlag, w.keyValueDb] = Array.from([o.totalFrames, o.maxTotalFrames, o.frameRate, o.dt, o.scriptNotes != null ? o.scriptNotes : [], o.victory, o.flagHistory, o.difficulty, o.scores, o.randomSeed, o.picoCTFFlag, o.keyValueDb]);
      for (prop in o.trackedProperties) { val = o.trackedProperties[prop]; w[prop] = val; }

      perf.t1 = now();
      if (w.thangs.length) {
        for (var thangConfig of Array.from(o.thangs)) {
          if (thang = w.thangMap[thangConfig.id]) {
            for (prop in thangConfig.finalState) {
              val = thangConfig.finalState[prop];
              thang[prop] = val;
            }
          } else {
            w.thangs.push(thang = Thang.deserialize(thangConfig, w, classMap, level.levelComponents));
            w.setThang(thang);
          }
        }
      } else {
        w.thangs = ((() => {
          const result = [];
          for (thang of Array.from(o.thangs)) {             result.push(Thang.deserialize(thang, w, classMap, level.levelComponents));
          }
          return result;
        })());
        for (thang of Array.from(w.thangs)) { w.setThang(thang); }
      }
      w.scriptNotes = (Array.from(o.scriptNotes).map((sn) => WorldScriptNote.deserialize(sn, w, classMap)));
      perf.t2 = now();

      o.trackedPropertiesThangs = ((() => {
        const result1 = [];
        for (thangID of Array.from(o.trackedPropertiesThangIDs)) {           result1.push(w.getThangByID(thangID));
        }
        return result1;
      })());
      o.trackedPropertiesPerThangValues = [];
      for (let thangIndex = 0; thangIndex < o.trackedPropertiesPerThangTypes.length; thangIndex++) {
        var trackedPropertiesValues;
        var trackedPropertyTypes = o.trackedPropertiesPerThangTypes[thangIndex];
        o.trackedPropertiesPerThangValues.push((trackedPropertiesValues = []));
        var trackedPropertiesValuesOffsets = o.trackedPropertiesPerThangValuesOffsets[thangIndex];
        for (var propIndex = 0; propIndex < trackedPropertyTypes.length; propIndex++) {
          var type = trackedPropertyTypes[propIndex];
          var storage = ThangState.createArrayForType(type, nFrames, o.storageBuffer, trackedPropertiesValuesOffsets[propIndex])[0];
          if (!typedArraySupport) {
            // This could be more efficient
            i = trackedPropertiesValuesOffsets[propIndex];
            storage = o.storageBuffer.slice(i, i + storage.length);
          }
          trackedPropertiesValues.push(storage);
        }
      }
      perf.t3 = now();

      perf.batches = 0;
      perf.framesCPUTime = 0;
      if (!streamingWorld) { w.frames = []; }
      if (this.deserializationTimeout) { clearTimeout(this.deserializationTimeout); }

      if (w.indefiniteLength) {
        const clearTo = Math.max(w.frames.length - 100, 0);
        if (clearTo > w.framesClearedSoFar) {
          for (i of Array.from(_.range(w.framesClearedSoFar, clearTo))) {
            w.frames[i] = null;
          }
        }
        w.framesClearedSoFar = clearTo;
      }

      this.deserializationTimeout = _.delay(this.deserializeSomeFrames, 1, o, w, finishedWorldCallback, perf, startFrame, endFrame);
      return w;
    }

    static finishDeserializing(w, finishedWorldCallback, perf, startFrame, endFrame) {
      perf.t4 = now();
      w.ended = true;
      const nFrames = endFrame - startFrame;
      const totalCPUTime = (perf.t3 - perf.t0) + perf.framesCPUTime;
      //console.log 'Deserialization:', totalCPUTime.toFixed(0) + 'ms (' + (totalCPUTime / nFrames).toFixed(3) + 'ms per frame).', perf.batches, 'batches. Did', startFrame, 'to', endFrame, 'in', (perf.t4 - perf.t0).toFixed(0) + 'ms wall clock time.'
      if (false) {
        console.log('  Deserializing--constructing new World:', (perf.t1 - perf.t0).toFixed(2) + 'ms');
        console.log('  Deserializing--Thangs and ScriptNotes:', (perf.t2 - perf.t1).toFixed(2) + 'ms');
        console.log('  Deserializing--reallocating memory:', (perf.t3 - perf.t2).toFixed(2) + 'ms');
        console.log('  Deserializing--WorldFrames:', (perf.t4 - perf.t3).toFixed(2) + 'ms wall clock time,', (perf.framesCPUTime).toFixed(2) + 'ms CPU time');
      }
      return finishedWorldCallback(w);
    }

    findFirstChangedFrame(oldWorld) {
      let i;
      if (!oldWorld) { return 0; }
      for (i = 0; i < this.frames.length; i++) {
        var newFrame = this.frames[i];
        var oldFrame = oldWorld.frames[i];
        if (!oldFrame || ((newFrame.hash !== oldFrame.hash) && !(newFrame.hash == null) && !(oldFrame.hash == null))) { break; }
      }  // undefined gets in there when streaming at the last frame of each batch for some reason
      const firstChangedFrame = i;
      if (this.frames.length === this.totalFrames) {
        if (this.frames[i]) {
          console.log('First changed frame is', firstChangedFrame, 'with hash', this.frames[i].hash, 'compared to', oldWorld.frames[i] != null ? oldWorld.frames[i].hash : undefined);
        } else {
          console.log('No frames were changed out of all', this.frames.length);
        }
      }
      return firstChangedFrame;
    }

    freeMemoryBeforeFinalSerialization() {
      this.levelComponents = null;
      return this.thangTypes = null;
    }

    freeMemoryAfterEachSerialization() {
      return (() => {
        const result = [];
        for (let i = 0; i < this.frames.length; i++) {
          var frame = this.frames[i];
          if (i < (this.frames.length - 1)) {
            result.push(this.frames[i] = null);
          }
        }
        return result;
      })();
    }

    pointsForThang(thangID, camera=null) {
      // Optimized
      if (this.pointsForThangCache == null) { this.pointsForThangCache = {}; }
      const cacheKey = thangID;
      let allPoints = this.pointsForThangCache[cacheKey];
      if (!allPoints) {
        allPoints = [];
        const lastFrameIndex = this.frames.length - 1;
        let lastPos = {x: null, y: null};
        for (let frameIndex = lastFrameIndex; frameIndex >= 0; frameIndex--) {
          var pos;
          var frame = this.frames[frameIndex];
          if (!frame) { continue; } // may have been evicted for game dev levels
          if (pos = frame.thangStateMap[thangID] != null ? frame.thangStateMap[thangID].getStateForProp('pos') : undefined) {
            if (camera) { pos = camera.worldToSurface({x: pos.x, y: pos.y}); }  // without z
            if ((lastPos.x == null) || ((Math.abs(lastPos.x - pos.x) + Math.abs(lastPos.y - pos.y)) > 1)) {
              lastPos = pos;
            }
          }
          if ((lastPos.y !== 0) || (lastPos.x !== 0)) { allPoints.push(lastPos.y, lastPos.x); }
        }
        allPoints.reverse();
        this.pointsForThangCache[cacheKey] = allPoints;
      }

      return allPoints;
    }

    actionsForThang(thangID, keepIdle) {
      // Optimized
      if (keepIdle == null) { keepIdle = false; }
      if (this.actionsForThangCache == null) { this.actionsForThangCache = {}; }
      const cacheKey = thangID + '_' + Boolean(keepIdle);
      const cached = this.actionsForThangCache[cacheKey];
      if (cached) { return cached; }
      const states = (Array.from(this.frames).map((frame) => frame.thangStateMap[thangID]));
      const actions = [];
      let lastAction = '';
      for (let i = 0; i < states.length; i++) {
        var state = states[i];
        var action = state != null ? state.getStateForProp('action') : undefined;
        if (!action || ((action === lastAction) && !state.actionActivated)) { continue; }
        if ((state.action === 'idle') && !keepIdle) { continue; }
        actions.push({frame: i, pos: state.pos, name: action});
        lastAction = action;
      }
      this.actionsForThangCache[cacheKey] = actions;
      return actions;
    }

    getTeamColors() {
      const teamConfigs = this.teamConfigs || {};
      const colorConfigs = {};
      for (var teamName in teamConfigs) { var config = teamConfigs[teamName]; colorConfigs[teamName] = config.color; }
      return colorConfigs;
    }

    teamForPlayer(n) {
      let playableTeams = this.playableTeams != null ? this.playableTeams : ['humans'];
      if ((playableTeams[0] === 'ogres') && (playableTeams[1] === 'humans')) {
        playableTeams = ['humans', 'ogres'];  // Make sure they're in the right order, since our other code is frail to the ordering
      }
      if (n != null) {
        return playableTeams[n % playableTeams.length];
      } else {
        return _.sample(playableTeams);
      }
    }
    // Not 'code-length', that doesn't need to be stored per each frame

    getScores() {
      return {
        time: this.age,
        'damage-taken': __guard__(this.getSystem('Combat'), x => x.damageTakenForTeam('humans')),
        'damage-dealt': __guard__(this.getSystem('Combat'), x1 => x1.damageDealtForTeam('humans')),
        'gold-collected': __guard__(__guard__(this.getSystem('Inventory'), x3 => x3.teamGold.humans), x2 => x2.collected),
        'difficulty': this.difficulty,
        'code-length': __guard__(this.getThangByID('Hero Placeholder'), x4 => x4.linesOfCodeUsed),
        'survival-time': this.age,
        'defeated': __guard__(this.getSystem('Combat'), x5 => x5.defeatedByTeam('humans'))
      };
    }

    constrainHeroHealth(level) {
      if (!level.constrainHeroHealth) { return; }
      const hero = _.find(this.thangs, {id: 'Hero Placeholder'});
      if (hero != null) {
        let max, min;
        const object = level.clampedProperties != null ? level.clampedProperties : {};
        for (var prop in object) {
          ({min, max} = object[prop]);
          if (max != null) { hero[prop] = Math.min(hero[prop], max); }
          if (min != null) { hero[prop] = Math.max(hero[prop], min); }
          hero.keepTrackedProperty(prop);
        }
        if (level.recommendedHealth != null) {
          hero.maxHealth = Math.max(hero.maxHealth, level.recommendedHealth);
          hero.keepTrackedProperty('maxHealth');
        }
        if (level.maximumHealth != null) {
          hero.maxHealth = Math.min(hero.maxHealth, level.maximumHealth);
          hero.keepTrackedProperty('maxHealth');
        }
        hero.health = hero.maxHealth;
        return hero.keepTrackedProperty('health');
      }
    }
  };
  World.initClass();
  return World;
})());

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}