// There's no reason that this file is in JavaScript instead of CoffeeScript.
// We should convert it and update the brunch config.

// If we wanted to be more robust, we could use this: https://github.com/padolsey/operative/blob/master/src/operative.js
if(typeof window !== 'undefined' || !self.importScripts)
  throw "Attempt to load worker_world into main window instead of web worker.";

// Taken from https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Function/bind
// This is here for running simuations in enviroments lacking function.bind (PhantomJS mostly)
if (!Function.prototype.bind) {
  Function.prototype.bind = function (oThis) {
    if (typeof this !== "function") {
      // closest thing possible to the ECMAScript 5 internal IsCallable function
      throw new TypeError("Function.prototype.bind (Shim) - target is not callable");
    }

    var aArgs = Array.prototype.slice.call(arguments, 1), 
        fToBind = this, 
        fNOP = function () {},
        fBound = function () {
          return fToBind.apply(this instanceof fNOP && oThis
                                 ? this
                                 : oThis,
                               aArgs.concat(Array.prototype.slice.call(arguments)));
        };

    fNOP.prototype = this.prototype;
    fBound.prototype = new fNOP();

    return fBound;
  };
}

// assign global window so that Brunch's require (in world.js) can go into it
self.window = self;
self.workerID = "Worker";

self.logLimit = 200;
self.logsLogged = 0;
var console = {
  log: function() {
    if(self.logsLogged++ == self.logLimit)
      self.postMessage({type: 'console-log', args: ["Log limit " + self.logLimit + " reached; shutting up."], id: self.workerID});
    else if(self.logsLogged < self.logLimit) {
      args = [].slice.call(arguments);
      for(var i = 0; i < args.length; ++i) {
        if(args[i] && args[i].constructor) {
          if(args[i].constructor.className === "Thang" || args[i].isComponent)
            args[i] = args[i].toString();
        }
      }
      try {
        self.postMessage({type: 'console-log', args: args, id: self.workerID});
      }
      catch(error) {
        self.postMessage({type: 'console-log', args: ["Could not post log: " + args, error.toString(), error.stack, error.stackTrace], id: self.workerID});
      }
    }
  }};  // so that we don't crash when debugging statements happen
console.error = console.info = console.log;
self.console = console;

importScripts('/javascripts/world.js');

// We could do way more from this: http://stackoverflow.com/questions/10653809/making-webworkers-a-safe-environment
Object.defineProperty(self, "XMLHttpRequest", {
  get: function() { throw new Error("Access to XMLHttpRequest is forbidden."); },
  configurable: false
});

self.transferableSupported = function transferableSupported() {
  // Not in IE, even in IE 11
  try {
    var ab = new ArrayBuffer(1);
    worker.postMessage(ab, [ab]);
    return ab.byteLength == 0;
  } catch(error) {
    return false;
  }
  return false;
}

var World = self.require('lib/world/world');
var GoalManager = self.require('lib/world/GoalManager');

self.runWorld = function runWorld(args) {
  self.postedErrors = {};
  self.t0 = new Date();
  self.firstWorld = args.firstWorld;
  self.postedErrors = false;
  self.logsLogged = 0;
  
  try {
    self.world = new World(args.worldName, args.userCodeMap);
    if(args.level)
      self.world.loadFromLevel(args.level, true);
    self.goalManager = new GoalManager(self.world);
    self.goalManager.setGoals(args.goals);
    self.goalManager.setCode(args.userCodeMap);
    self.goalManager.worldGenerationWillBegin();
    self.world.setGoalManager(self.goalManager);
  }
  catch (error) {
    self.onWorldError(error);
    return;
  }
  Math.random = self.world.rand.randf;  // so user code is predictable
  self.world.loadFrames(self.onWorldLoaded, self.onWorldError, self.onWorldLoadProgress);
};

self.onWorldLoaded = function onWorldLoaded() {
  self.goalManager.worldGenerationEnded();
  var t1 = new Date();
  var diff = t1 - self.t0;
  var transferableSupported = self.transferableSupported();
  try {
    var serialized = self.world.serialize();
  }
  catch(error) {
    console.log("World serialization error:", error.toString() + "\n" + error.stack || error.stackTrace);
  }
  var t2 = new Date();
  //console.log("About to transfer", serialized.serializedWorld.trackedPropertiesPerThangValues, serialized.transferableObjects);
  try {
    if(transferableSupported)
      self.postMessage({type: 'new-world', serialized: serialized.serializedWorld, goalStates: self.goalManager.getGoalStates()}, serialized.transferableObjects);
    else
      self.postMessage({type: 'new-world', serialized: serialized.serializedWorld, goalStates: self.goalManager.getGoalStates()});
  }
  catch(error) {
    console.log("World delivery error:", error.toString() + "\n" + error.stack || error.stackTrace);
  }
  var t3 = new Date();
  console.log("And it was so: (" + (diff / self.world.totalFrames).toFixed(3) + "ms per frame,", self.world.totalFrames, "frames)\nSimulation   :", diff + "ms \nSerialization:", (t2 - t1) + "ms\nDelivery     :", (t3 - t2) + "ms");
  self.world = null;
};

self.onWorldError = function onWorldError(error) {
  if(error instanceof Aether.problems.UserCodeProblem) {
    if(!self.postedErrors[error.key]) {
      var problem = error.serialize();
      self.postMessage({type: 'user-code-problem', problem: problem});
      self.postedErrors[error.key] = problem;
    }
  }
  else {
    console.log("Non-UserCodeError:", error.toString() + "\n" + error.stack || error.stackTrace);
  }
  /*  We don't actually have the recoverable property any more; hmm
  if(!self.firstWorld && !error.recoverable) {
    self.abort();
    return false;
  }
  */
  return true;
};

self.onWorldLoadProgress = function onWorldLoadProgress(progress) {
  self.postMessage({type: 'world-load-progress-changed', progress: progress});
};

self.abort = function abort() {
  if(self.world && self.world.name) {
    console.log("About to abort:", self.world.name, typeof self.world.abort);
    if(typeof self.world !== "undefined")
      self.world.abort();
    self.world = null;
  }
  self.postMessage({type: 'abort'});
};

self.reportIn = function reportIn() {
  self.postMessage({type: 'reportIn'});
}

self.addEventListener('message', function(event) {
  self[event.data.func](event.data.args);
});

self.postMessage({type: 'worker-initialized'});
