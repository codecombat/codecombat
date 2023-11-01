// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS002: Fix invalid constructor
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__, or convert again using --optional-chaining
 * DS201: Simplify complex destructure assignments
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
// Every Angel has one web worker attached to it. It will call methods inside the worker and kill it if it times out.
// God is the public API; Angels are an implementation detail. Each God can have one or more Angels.

let Angel;
const {now} = require('lib/world/world_utils');
const World = require('lib/world/world');
const CocoClass = require('core/CocoClass');
const GoalManager = require('lib/world/GoalManager');
const {sendSlackMessage, sendContactMessage} = require('core/contact');
const errors = require('core/errors');
const utils = require('core/utils');
const store = require('core/store');

let reportedLoadErrorAlready = false;

module.exports = (Angel = (function() {
  Angel = class Angel extends CocoClass {
    static initClass() {
      this.nicks = ['Archer', 'Lana', 'Cyril', 'Pam', 'Cheryl', 'Woodhouse', 'Ray', 'Krieger'];

      this.prototype.infiniteLoopIntervalDuration = 10000;  // check this often; must be longer than other two combined
      this.prototype.infiniteLoopTimeoutDuration = 7500;  // wait this long for a response when checking
      this.prototype.abortTimeoutDuration = 500;  // give in-process or dying workers this long to give up

      this.prototype.subscriptions = {
        'level:flag-updated': 'onFlagEvent',
        'playback:stop-real-time-playback': 'onStopRealTimePlayback',
        'level:escape-pressed': 'onEscapePressed'
      };
    }

    constructor(shared) {
      super();
      this.testWorker = this.testWorker.bind(this);
      this.onWorkerMessage = this.onWorkerMessage.bind(this);
      this.infinitelyLooped = this.infinitelyLooped.bind(this);
      this.fireWorker = this.fireWorker.bind(this);
      this.simulateSync = this.simulateSync.bind(this);
      this.shared = shared;
      this.say('Got my wings.');
      const isIE = window.navigator && ((window.navigator.userAgent.search('MSIE') !== -1) || (window.navigator.appName === 'Microsoft Internet Explorer'));
      const slowerSimulations = isIE;  //or @shared.headless
      // Since IE is so slow to serialize without transferable objects, we can't trust it.
      // We also noticed the headless_client simulator needing more time. (This does both Simulators, though.) If we need to use lots of headless clients, enable this.
      if (slowerSimulations) {
        this.infiniteLoopIntervalDuration *= 10;
        this.infiniteLoopTimeoutDuration *= 10;
        this.abortTimeoutDuration *= 10;
      }

      if (utils.getQueryVariable('dev')) {
        // Set a very long timeout so that debugging can be done without infinite loop detection
        // breaking the debugger.
        this.infiniteLoopIntervalDuration *= 100000;
        this.infiniteLoopTimeoutDuration *= 100000;
        this.abortTimeoutDuration *= 100000;
      }

      this.initialized = false;
      this.running = false;
      this.allLogs = [];
      this.hireWorker();
      this.shared.angels.push(this);
      this.listenTo(this.shared.gameUIState.get('realTimeInputEvents'), 'add', this.onAddRealTimeInputEvent);
    }

    destroy() {
      this.fireWorker(false);
      _.remove(this.shared.angels, this);
      return super.destroy();
    }

    workIfIdle() {
      if (!this.running) { return this.doWork(); }
    }

    // say: debugging stuff, usually off; log: important performance indicators, keep on
    say(...args) {} //@log args...
    log() {
      // console.info.apply is undefined in IE9, CoffeeScript splats invocation won't work.
      // http://stackoverflow.com/questions/5472938/does-ie9-support-console-log-and-is-it-a-real-function
      let message = `|${this.shared.godNick}'s ${this.nick}|`;
      for (var arg of Array.from(arguments)) { message += ` ${arg}`; }
      console.info(message);
      return this.allLogs.push(message);
    }

    testWorker() {
      if (this.destroyed) { return; }
      clearTimeout(this.condemnTimeout);
      this.condemnTimeout = _.delay((() => this.infinitelyLooped({timedOut: true})), this.infiniteLoopTimeoutDuration);
      this.say('Let\'s give it', this.infiniteLoopTimeoutDuration, 'to not loop.');
      return this.worker.postMessage({func: 'reportIn'});
    }

    onWorkerMessage(event) {
      if (this.aborting && (event.data.type !== 'abort')) { return this.say('Currently aborting old work.'); }

      switch (event.data.type) {
        // First step: worker has to load the scripts.
        case 'worker-initialized':
          if (!this.initialized) {
            this.log(`Worker initialized after ${(new Date()) - this.worker.creationTime}ms`);
            this.initialized = true;
            return this.doWork();
          }
          break;

        // We watch over the worker as it loads the world frames to make sure it doesn't infinitely loop.
        case 'start-load-frames':
          return clearTimeout(this.condemnTimeout);
        case 'report-in':
          this.say('Worker reported in.');
          return clearTimeout(this.condemnTimeout);
        case 'end-load-frames':
          clearTimeout(this.condemnTimeout);
          return this.beholdGoalStates({goalStates: event.data.goalStates, overallStatus: event.data.overallStatus, preload: false, totalFrames: event.data.totalFrames, lastFrameHash: event.data.lastFrameHash, simulationFrameRate: event.data.simulationFrameRate});  // Work ends here if we're headless.
        case 'end-preload-frames':
          clearTimeout(this.condemnTimeout);
          return this.beholdGoalStates({goalStates: event.data.goalStates, overallStatus: event.data.overallStatus, preload: true, simulationFrameRate: event.data.simulationFrameRate});

        // We have to abort like an infinite loop if we see one of these; they're not really recoverable
        case 'non-user-code-problem':
          this.publishGodEvent('non-user-code-problem', {problem: event.data.problem});
          if (this.shared.firstWorld) {
            return this.infinitelyLooped({escaped: false, nonUserCodeProblem: true, problem: event.data.problem});  // For now, this should do roughly the right thing if it happens during load.
          } else {
            return this.fireWorker();
          }

        // If it didn't finish simulating successfully, or we abort the worker.
        case 'abort':
          this.say('Aborted.', event.data);
          clearTimeout(this.abortTimeout);
          this.aborting = false;
          this.running = false;
          _.remove(this.shared.busyAngels, this);
          return this.doWork();

        // We pay attention to certain progress indicators as the world loads.
        case 'console-log':
          return this.log(...Array.from(event.data.args || []));
        case 'user-code-problem':
          return this.publishGodEvent('user-code-problem', {problem: event.data.problem});
        case 'world-load-progress-changed':
          var {
            progress
          } = event.data;
          if (this.work.indefiniteLength) { progress = Math.min(progress, 0.9); }
          this.publishGodEvent('world-load-progress-changed', { progress });
          if ((event.data.progress !== 1) && !this.work.preload && !this.work.headless && !this.work.synchronous && !this.deserializationQueue.length && (!this.shared.firstWorld || !!this.shared.spectate)) {
            return this.worker.postMessage({func: 'serializeFramesSoFar'});  // Stream it!
          }
          break;

        // We have some or all of the frames serialized, so let's send the (partially?) simulated world to the Surface.
        case 'some-frames-serialized': case 'new-world':
          var deserializationArgs = [event.data.serialized, event.data.goalStates, event.data.startFrame, event.data.endFrame, this.streamingWorld];
          this.deserializationQueue.push(deserializationArgs);
          if (this.deserializationQueue.length === 1) {
            return this.beholdWorld(...Array.from(deserializationArgs || []));
          }
          break;

        default:
          return this.log('Received unsupported message:', event.data);
      }
    }

    beholdGoalStates({goalStates, overallStatus, preload, totalFrames, lastFrameHash, simulationFrameRate}) {
      if (this.aborting) { return; }
      const event = {goalStates, preload: preload != null ? preload : false, overallStatus};
      if (totalFrames != null) { event.totalFrames = totalFrames; }
      if (lastFrameHash != null) { event.lastFrameHash = lastFrameHash; }
      if (simulationFrameRate != null) { event.simulationFrameRate = simulationFrameRate; }
      this.publishGodEvent('goals-calculated', event);
      if (this.shared.headless) { return this.finishWork(); }
    }

    beholdWorld(serialized, goalStates, startFrame, endFrame, streamingWorld) {
      if (this.aborting) { return; }
      // Toggle BOX2D_ENABLED during deserialization so that if we have box2d in the namespace, the Collides Components still don't try to create bodies for deserialized Thangs upon attachment.
      window.BOX2D_ENABLED = false;
      if (streamingWorld != null) {
        streamingWorld.indefiniteLength = this.work.indefiniteLength;
      }
      this.streamingWorld = World.deserialize(serialized, this.shared.worldClassMap, this.shared.lastSerializedWorldFrames, this.finishBeholdingWorld(goalStates), startFrame, endFrame, this.work.level, streamingWorld);
      window.BOX2D_ENABLED = true;
      return this.shared.lastSerializedWorldFrames = serialized.frames;
    }

    finishBeholdingWorld(goalStates) { return world => {
      if (this.aborting || this.destroyed) { return; }
      let finished = world.frames.length === world.totalFrames;
      if (world.indefiniteLength && (world.victory != null)) {
        finished = true;
        world.totalFrames = world.frames.length;
      }
      const firstChangedFrame = (this.work != null ? this.work.indefiniteLength : undefined) ? 0 : world.findFirstChangedFrame(this.shared.world);
      const eventType = finished ? 'new-world-created' : 'streaming-world-updated';
      if (finished) {
        this.shared.world = world;
      }
      this.publishGodEvent(eventType, {world, firstWorld: this.shared.firstWorld, goalStates, team: me.team, firstChangedFrame, finished, keyValueDb: world.keyValueDb != null ? world.keyValueDb : {}});
      if (finished) {
        for (var scriptNote of Array.from(this.shared.world.scriptNotes)) {
          Backbone.Mediator.publish(scriptNote.channel, scriptNote.event);
        }
        if (this.shared.goalManager != null) {
          this.shared.goalManager.world = world;
        }
        return this.finishWork();
      } else {
        let deserializationArgs;
        if (this.deserializationQueue != null) {
          this.deserializationQueue.shift();
        }  // Finished with this deserialization.
        if (deserializationArgs = this.deserializationQueue != null ? this.deserializationQueue[0] : undefined) {  // Start another?
          return this.beholdWorld(...Array.from(deserializationArgs || []));
        }
      }
    }; }

    finishWork() {
      this.streamingWorld = null;
      this.shared.firstWorld = false;
      this.deserializationQueue = [];
      this.running = false;
      _.remove(this.shared.busyAngels, this);
      clearTimeout(this.condemnTimeout);
      clearInterval(this.purgatoryTimer);
      this.condemnTimeout = (this.purgatoryTimer = null);
      return this.doWork();
    }

    finalizePreload() {
      this.say('Finalize preload.');
      this.worker.postMessage({func: 'finalizePreload'});
      return this.work.preload = false;
    }

    infinitelyLooped(...args) {
      let obj = args[0], val = obj.escaped, escaped = val != null ? val : false, val1 = obj.nonUserCodeProblem, nonUserCodeProblem = val1 != null ? val1 : false, val2 = obj.problem, problem = val2 != null ? val2 : null, val3 = obj.timedOut, timedOut = val3 != null ? val3 : false;
      console.log('Infinitely looped.', escaped, nonUserCodeProblem, problem, timedOut);
      this.say('On infinitely looped! Aborting?', this.aborting);
      if (this.aborting) { return; }
      if (problem == null) { problem = {}; }
      if (problem.type == null) { problem.type = 'runtime'; }
      if (problem.level == null) { problem.level = 'error'; }
      if (problem.id == null) { problem.id = 'runtime_InfiniteLoop'; }  // TODO: use some other ID for non-user-code problems?
      if (escaped) { if (problem.message == null) { problem.message = 'Escape pressed; code aborted.'; } }
      if (timedOut) { if (problem.message == null) { problem.message = 'Code never finished. It\'s either really slow or has an infinite loop.'; } }
      if (problem.message == null) { problem.message = 'Unknown error.'; }
      this.publishGodEvent('user-code-problem', {problem});
      this.publishGodEvent('infinite-loop', {firstWorld: this.shared.firstWorld, nonUserCodeProblem, problem, timedOut});
      if (nonUserCodeProblem) { this.reportLoadError(); }
      if (timedOut) {
        // If they try again, give them more time next time
        this.infiniteLoopIntervalDuration *= 2;
        this.infiniteLoopTimeoutDuration *= 2;
      }
      return this.fireWorker();
    }

    publishGodEvent(channel, e) {
      // For Simulator. TODO: refactor all the god:* Mediator events to be local events.
      this.shared.god.trigger(channel, e);
      e.god = this.shared.god;
      return Backbone.Mediator.publish('god:' + channel, e);
    }

    reportLoadError() {
      if (me.isAdmin() || /dev=true/.test((window.location != null ? window.location.href : undefined) != null ? (window.location != null ? window.location.href : undefined) : '') || reportedLoadErrorAlready) { return; }
      reportedLoadErrorAlready = true;
      const context = {email: me.get('email')};
      context.message = "Automatic Report - Unable to Load Level\nLogs:\n" + this.allLogs.join('\n');
      if (/Error: Out of memory/.test(context.message) && /Legacy javascript detected/.test(context.message)) {
        return;  // If the computer is so old it doesn't have modern JS, it's probably more their problem than ours
      }
      if ($.browser) {
        context.browser = `${$.browser.platform} ${$.browser.name} ${$.browser.versionNumber}`;
      }
      context.screenSize = `${(typeof screen !== 'undefined' && screen !== null ? screen.width : undefined) != null ? (typeof screen !== 'undefined' && screen !== null ? screen.width : undefined) : $(window).width()} x ${(typeof screen !== 'undefined' && screen !== null ? screen.height : undefined) != null ? (typeof screen !== 'undefined' && screen !== null ? screen.height : undefined) : $(window).height()}`;
      context.subject = `Level Load Error: ${__guard__(this.work != null ? this.work.level : undefined, x => x.name) || 'Unknown Level'}`;
      context.levelSlug = __guard__(this.work != null ? this.work.level : undefined, x1 => x1.slug);
      context.message = `*${context.subject}*
${context.message}

Screen: ${context.screenSize}
Browser: ${context.browser || 'Unknown'}\
`;
      context.event = 'level-load-error';
      context.channel = 'level-load-errors';
      //sendContactMessage context  # We didn't really do anything with it in email form
      return sendSlackMessage(context);
    }

    doWork() {
      if (this.aborting) { return; }
      if (!this.initialized) { return this.say('Not initialized for work yet.'); }
      if (this.shared.workQueue.length) {
        this.work = this.shared.workQueue.shift();
        this.say('Running world...');
        this.running = true;
        this.shared.busyAngels.push(this);
        this.deserializationQueue = [];
        if (this.work.synchronous) { return _.defer(this.simulateSync, this.work); }
        this.worker.postMessage({func: 'runWorld', args: this.work});
        clearTimeout(this.purgatoryTimer);
        this.say('Infinite loop timer started at interval of', this.infiniteLoopIntervalDuration);
        return this.purgatoryTimer = setInterval(this.testWorker, this.infiniteLoopIntervalDuration);
      } else {
        this.say('No work to do.');
        return this.hireWorker();
      }
    }

    abort() {
      if (!this.running) { return; }
      this.say('Aborting...');
      this.running = false;
      __guard__(__guard__(this.work != null ? this.work.world : undefined, x1 => x1.goalManager), x => x.destroy());
      if (this.work != null) {
        this.work.aborted = true;
      }
      this.work = null;
      this.streamingWorld = null;
      this.deserializationQueue = [];
      _.remove(this.shared.busyAngels, this);
      if (this.worker) {
        this.abortTimeout = _.delay(this.fireWorker, this.abortTimeoutDuration);
        this.aborting = true;
        return this.worker.postMessage({func: 'abort'});
      }
    }

    fireWorker(rehire) {
      if (rehire == null) { rehire = true; }
      if (this.destroyed) { return; }
      this.aborting = false;
      this.running = false;
      _.remove(this.shared.busyAngels, this);
      if (this.worker != null) {
        this.worker.removeEventListener('message', this.onWorkerMessage);
      }
      if (this.worker != null) {
        this.worker.terminate();
      }
      this.worker = null;
      clearTimeout(this.condemnTimeout);
      clearInterval(this.purgatoryTimer);
      this.say('Fired worker.');
      this.initialized = false;
      __guardMethod__(this.work != null ? this.work.world : undefined, 'destroy', o => o.destroy());
      this.work = null;
      this.streamingWorld = null;
      this.deserializationQueue = [];
      if (rehire) { return this.hireWorker(); }
    }

    hireWorker() {
      if (typeof Worker === 'undefined' || Worker === null) {
        if (!this.initialized) {
          this.initialized = true;
          this.doWork();
        }
        return null;
      }
      if (this.worker) { return; }
      this.say('Hiring worker.');
      this.worker = new Worker(this.shared.workerCode);
      this.worker.addEventListener('error', errors.onWorkerError);
      this.worker.addEventListener('message', this.onWorkerMessage);
      return this.worker.creationTime = new Date();
    }

    onFlagEvent(flagEvent) {
      if (!this.running || !this.work.realTime) { return; }
      if (this.work.synchronous) {
        return this.work.world.addFlagEvent(flagEvent);
      } else {
        return this.worker.postMessage({func: 'addFlagEvent', args: flagEvent});
      }
    }

    onAddRealTimeInputEvent(realTimeInputEvent) {
      if (!this.running || !this.work.realTime) { return; }
      if (this.work.synchronous) {
        return this.work.world.addRealTimeInputEvent(realTimeInputEvent.toJSON());
      } else {
        return this.worker.postMessage({func: 'addRealTimeInputEvent', args: realTimeInputEvent.toJSON()});
      }
    }

    onStopRealTimePlayback(e) {
      // TODO Improve later with GoalManger reworking
      if (utils.isOzaria && store.getters['game/clickedUpdateCapstoneCode'] && __guard__(__guard__(__guard__(this.work != null ? this.work.world : undefined, x2 => x2.goalManager), x1 => x1.goalStates), x => x["has-stopped-playing-game"])) {
        // The update button goal is a simple way to ensure that the student presses update to test their code.
        // After the first time the update button has been pressed, it is in a 'success' state until the page reloads.
        this.work.world.goalManager.setGoalState("has-clicked-update-button", "success");
      }

      if (utils.isOzaria && store.getters['game/hasPlayedGame'] && __guard__(__guard__(__guard__(this.work != null ? this.work.world : undefined, x5 => x5.goalManager), x4 => x4.goalStates), x3 => x3["has-stopped-playing-game"])) {
        // Mark the goal completed and prevent the goalmanager being destroying
        this.work.world.goalManager.setGoalState("has-stopped-playing-game", "success");
        this.work.world.endWorld(true, 0);
        return;
      }
      if (!this.running || !this.work.realTime) { return; }
      if (this.work.synchronous) {
        return this.abort();
      }
      this.work.realTime = false;
      this.lastRealTimeWork = new Date();
      return this.worker.postMessage({func: 'stopRealTimePlayback'});
    }


    onEscapePressed(e) {
      if (!this.running || !!this.work.realTime) { return; }
      if ((new Date() - this.lastRealTimeWork) < 1000) { return; }  // Fires right after onStopRealTimePlayback
      return this.infinitelyLooped({escaped: true});
    }

    //### Synchronous code for running worlds on main thread (profiling / IE9) ####
    simulateSync(work) {
      if (typeof imitateIE9 !== 'undefined' && imitateIE9 !== null) { __guardMethod__(console, 'profile', o => o.profile(`World Generation ${(Math.random() * 1000).toFixed(0)}`)); }
      work.t0 = now();
      work.world = new World(work.userCodeMap);
      work.world.synchronous = true;
      work.world.levelSessionIDs = work.levelSessionIDs;
      work.world.submissionCount = work.submissionCount;
      work.world.fixedSeed = work.fixedSeed;
      work.world.flagHistory = work.flagHistory != null ? work.flagHistory : [];
      work.world.realTimeInputEvents = work.realTimeInputEvents != null ? work.realTimeInputEvents : [];
      work.world.difficulty = work.difficulty != null ? work.difficulty : 0;
      work.world.capstoneStage = work.capstoneStage != null ? work.capstoneStage : 1;
      work.world.language = me.get('preferredLanguage', true);
      work.world.loadFromLevel(work.level, true);
      work.world.preloading = work.preload;
      work.world.headless = work.headless;
      work.world.realTime = work.realTime;
      work.world.indefiniteLength = work.indefiniteLength;
      work.world.justBegin = work.justBegin;
      work.world.keyValueDb = work.keyValueDb;
      if (this.shared.goalManager) {
        const goalManager = new GoalManager(work.world, this.shared.goalManager.initialGoals, null, this.shared.goalManager.options);
        goalManager.setGoals(work.goals);
        goalManager.setCode(work.userCodeMap);
        goalManager.worldGenerationWillBegin();
        work.world.setGoalManager(goalManager);
      }
      return this.beginSimulationSync(work);
    }

    beginSimulationSync(work) {
      work.t1 = now();
      work.world.worldLoadStartTime = work.t1;
      work.world.lastRealTimeUpdate = 0;
      work.world.realTimeSpeedFactor = 1;
      return this.simulateFramesSync(work, 0);
    }

    simulateFramesSync(work, i) {
      if (this.destroyed || work.aborted) { return; }
      const {
        world
      } = work;
      if (i == null) { i = world.frames.length; }
      const simulationLoopStartTime = now();
      while (i < world.totalFrames) {
        var error;
        if (work.realTime) {
          this.streamFrameSync(work);
          if (world.indefiniteLength && (world.victory != null)) {
            world.indefiniteLength = false;
          }
          var continuing = world.shouldContinueLoading(simulationLoopStartTime, (function() {}), false, (() => { if (!this.destroyed) { return this.simulateFramesSync(work); } }));
          if (!continuing) { return; }
        }
        if (world.indefiniteLength && (i === (world.totalFrames - 1))) {
          ++world.totalFrames;
        }
        try {
          var frame = world.getFrame(i++);
        } catch (error1) {
          error = error1;
          this.handleWorldError(world, error);
          this.reportLoadError();
          break;
        }
        if (error = (world.unhandledRuntimeErrors != null ? world.unhandledRuntimeErrors : [])[0]) {
          this.handleWorldError(world, error);
          break;  // We quit on the first one
        }
      }
      return this.finishSimulationSync(work);
    }

    handleWorldError(world, error) {
      if (error.isUserCodeProblem) {
        this.publishGodEvent('user-code-problem', {problem: error});
      } else {
        console.error('Non-UserCodeError:', (error.toString() + '\n' + error.stack) || error.stackTrace);
        const problem = {type: 'runtime', level: 'error', message: error.toString()};
        this.publishGodEvent('non-user-code-problem', {problem});
      }
      // End the world immediately
      world.indefiniteLength = false;
      return world.totalFrames = world.frames.length;
    }

    streamFrameSync(work) {
      const goalStates = work.world.goalManager.getGoalStates();
      return this.finishBeholdingWorld(goalStates)(work.world);
    }

    finishSimulationSync(work) {
      this.publishGodEvent('world-load-progress-changed', {progress: 1});
      work.world.ended = true;
      for (var system of Array.from(work.world.systems)) { system.finish(work.world.thangs); }
      work.t2 = now();
      if (typeof imitateIE9 !== 'undefined' && imitateIE9 !== null) { __guardMethod__(console, 'profileEnd', o => o.profileEnd()); }
      console.log('Construction:', (work.t1 - work.t0).toFixed(0), 'ms. Simulation:', (work.t2 - work.t1).toFixed(0), 'ms --', ((work.t2 - work.t1) / work.world.frames.length).toFixed(3), 'ms per frame, profiled.');

      if (work.world.ended) {
        work.world.goalManager.worldGenerationEnded();
        work.world.goalManager.notifyGoalChanges();
      }
      const goalStates = work.world.goalManager.getGoalStates();

      this.running = false;

      if (work.headless) {
        const simulationFrameRate = ((work.world.frames.length / (work.t2 - work.t1)) * 1000 * 30) / work.world.frameRate;
        this.beholdGoalStates({goalStates, overallStatus: work.world.goalManager.checkOverallStatus(), preload: false, totalFrames: work.world.totalFrames, lastFrameHash: __guard__(work.world.frames[work.world.totalFrames - 2], x => x.hash), simulationFrameRate});
        return;
      }

      return this.shared.lastSerializedWorldFrames = work.world.frames;
    }
  };
  Angel.initClass();
  return Angel;
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