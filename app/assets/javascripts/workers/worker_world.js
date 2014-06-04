// This file is in JavaScript because we can't figure out how to get brunch to compile it bare.

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

// Assign global window so that Brunch's require (in world.js) can go into it
self.window = self;
self.workerID = "Worker";

self.logLimit = 200;
self.logsLogged = 0;
var console = {
  log: function() {
    if(self.logsLogged++ == self.logLimit)
      self.postMessage({type: 'console-log', args: ["Log limit " + self.logLimit + " reached; shutting up."], id: self.workerID});
    else if(self.logsLogged < self.logLimit) {
      var args = [].slice.call(arguments);
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
console.error = console.warn = console.info = console.debug = console.log;
self.console = console;

self.importScripts('/javascripts/world.js', '/javascripts/lodash.js', '/javascripts/aether.js');

var restricted = ["XMLHttpRequest", "importScripts", "Worker"];
for(var i = 0; i < restricted.length; ++i) {
  // We could do way more from this: http://stackoverflow.com/questions/10653809/making-webworkers-a-safe-environment
  Object.defineProperty(self, restricted[i], {
    get: function() { throw new Error("Access to that global property is forbidden."); },
    configurable: false
  });
}

self.transferableSupported = function transferableSupported() {
  if (typeof self._transferableSupported !== 'undefined') return self._transferableSupported;
  // Not in IE, even in IE 11
  try {
    var ab = new ArrayBuffer(1);
    worker.postMessage(ab, [ab]);
    return self._transferableSupported = ab.byteLength == 0;
  } catch(error) {
    return self._transferableSupported = false;
  }
  return self._transferableSupported = false;
};

var World = self.require('lib/world/world');
var GoalManager = self.require('lib/world/GoalManager');

Aether.addGlobal('Vector', require('lib/world/vector'));
Aether.addGlobal('_', _);

var serializedClasses = {
    "Thang": self.require('lib/world/thang'),
    "Vector": self.require('lib/world/vector'),
    "Rectangle": self.require('lib/world/rectangle')
};
self.currentUserCodeMapCopy = "";
self.currentDebugWorldFrame = 0;

self.stringifyValue = function(value, depth) {
    var brackets, i, isArray, isObject, key, prefix, s, sep, size, v, values, _i, _j, _len, _len1, _ref, _ref1, _ref2, _ref3;
    if (!value || _.isString(value)) {
        return value;
    }
    if (_.isFunction(value)) {
        if (depth === 2) {
            return void 0;
        } else {
            return "<Function>";
        }
    }
    if (value === this.thang && depth) {
        return "<this " + value.id + ">";
    }
    if (depth === 2) {
        if (((_ref = value.constructor) != null ? _ref.className : void 0) === "Thang") {
            value = "<" + (value.type || value.spriteName) + " - " + value.id + ", " + (value.pos ? value.pos.toString() : 'non-physical') + ">";
        } else {
            value = value.toString();
        }
        return value;
    }
    isArray = _.isArray(value);
    isObject = _.isObject(value);
    if (!(isArray || isObject)) {
        return value.toString();
    }
    brackets = isArray ? ["[", "]"] : ["{", "}"];
    size = _.size(value);
    if (!size) {
        return brackets.join("");
    }
    values = [];
    if (isArray) {
        for (_i = 0, _len = value.length; _i < _len; _i++) {
            v = value[_i];
            s = this.stringifyValue(v, depth + 1);
            if (s !== void 0) {
                values.push("" + s);
            }
        }
    } else {
        _ref2 = (_ref1 = value.apiProperties) != null ? _ref1 : _.keys(value);
        for (_j = 0, _len1 = _ref2.length; _j < _len1; _j++) {
            key = _ref2[_j];
            if (key[0] === "_") continue;
            s = this.stringifyValue(value[key], depth + 1);
            if (s !== void 0) {
                values.push(key + ": " + s);
            }
        }
    }
    sep = '\n' + ((function() {
        var _k, _results;
        _results = [];
        for (i = _k = 0; 0 <= depth ? _k < depth : _k > depth; i = 0 <= depth ? ++_k : --_k) {
            _results.push("  ");
        }
        return _results;
    })()).join('');
    prefix = (_ref3 = value.constructor) != null ? _ref3.className : void 0;
    if (isArray) {
        if (prefix == null) {
            prefix = "Array";
        }
    }
    if (isObject) {
        if (prefix == null) {
            prefix = "Object";
        }
    }
    prefix = prefix ? prefix + " " : "";
    return "" + prefix + brackets[0] + sep + "  " + (values.join(sep + '  ')) + sep + brackets[1];
};


self.retrieveValueFromFrame = function retrieveValueFromFrame(args) {

    var retrieveProperty = function retrieveProperty(currentThangID, currentSpellID, variableChain)
    {
        var prop;
        var value;
        var keys = [];
        for (var i = 0, len = variableChain.length; i < len; i++) {
            prop = variableChain[i];
            if (prop === "this")
            {
                value = self.debugWorld.thangMap[currentThangID];

            }
            else if (i === 0)
            {
                try
                {
                    if (Aether.globals[prop])
                    {
                        value = Aether.globals[prop];
                    }
                    else
                    {
                        var flowStates = self.debugWorld.userCodeMap[currentThangID][currentSpellID].flow.states;
                        //we have to go to the second last flowState as we run the world for one additional frame
                        //to collect the flow
                        value = _.last(flowStates[flowStates.length - 1].statements).variables[prop];
                    }
                }
                catch (e)
                {
                    value = undefined;
                }

            }
            else
            {
                value = value[prop];
            }
            keys.push(prop);
            if (!value) break;
            var classOfValue;
            if (classOfValue = serializedClasses[value.CN])
            {
                if (value.CN === "Thang")
                {
                    var thang = self.debugWorld.thangMap[value.id];
                    value = thang || "<Thang " + value.id + " (non-existent)>";
                }
                else
                {
                    value = classOfValue.deserializeFromAether(value);
                }
            }
        }
        var serializedProperty = {
            "key": keys.join("."),
            "value": self.stringifyValue(value,0)
        };
        self.postMessage({type: 'debug-value-return', serialized: serializedProperty});
    };
    self.enableFlowOnThangSpell(args.currentThangID, args.currentSpellID, args.userCodeMap);
    self.setupDebugWorldToRunUntilFrame(args);
    self.debugWorld.loadFrames(
        retrieveProperty.bind({}, args.currentThangID, args.currentSpellID, args.variableChain),
        self.onDebugWorldError,
        self.onDebugWorldProgress,
        false,
        args.frame
    );
};

self.enableFlowOnThangSpell = function (thangID, spellID, userCodeMap) {
    try {
        var options = userCodeMap[thangID][spellID].originalOptions;
        if (options.includeFlow === true && options.noSerializationInFlow === true)
            return;
        else
        {
            options.includeFlow = true;
            options.noSerializationInFlow = true;
            var temporaryAether = Aether.deserialize(userCodeMap[thangID][spellID]);
            temporaryAether.transpile(temporaryAether.raw);
            userCodeMap[thangID][spellID] = temporaryAether.serialize();
        }

    }
    catch (error) {
        console.log("Debug error enabling flow on", thangID, spellID + ":", error.toString() + "\n" + error.stack || error.stackTrace);
    }
};

self.setupDebugWorldToRunUntilFrame = function (args) {
    self.debugPostedErrors = {};
    self.debugt0 = new Date();
    self.logsLogged = 0;

    var stringifiedUserCodeMap = JSON.stringify(args.userCodeMap);
    var userCodeMapHasChanged = ! _.isEqual(self.currentUserCodeMapCopy, stringifiedUserCodeMap);
    self.currentUserCodeMapCopy = stringifiedUserCodeMap;
    if (!self.debugWorld || userCodeMapHasChanged || args.frame < self.currentDebugWorldFrame) {
        try {
            self.debugWorld = new World(args.userCodeMap);
            self.debugWorld.levelSessionIDs = args.levelSessionIDs;
            if (args.level)
                self.debugWorld.loadFromLevel(args.level, true);
            self.debugWorld.debugging = true;
            self.debugGoalManager = new GoalManager(self.debugWorld);
            self.debugGoalManager.setGoals(args.goals);
            self.debugGoalManager.setCode(args.userCodeMap);
            self.debugGoalManager.worldGenerationWillBegin();
            self.debugWorld.setGoalManager(self.debugGoalManager);
        }
        catch (error) {
            self.onDebugWorldError(error);
            return;
        }
        Math.random = self.debugWorld.rand.randf;  // so user code is predictable
        Aether.replaceBuiltin("Math", Math);
    }
    self.debugWorld.totalFrames = args.frame; //hack to work around error checking
    self.currentDebugWorldFrame = args.frame;
};


self.onDebugWorldLoaded = function onDebugWorldLoaded() {
    self.postMessage({type: 'debug-world-loaded'});
};

self.onDebugWorldError = function onDebugWorldError(error) {

    if(!error.isUserCodeProblem) {
        console.log("Debug Non-UserCodeError:", error.toString() + "\n" + error.stack || error.stackTrace);
    }
    return true;
};

self.onDebugWorldProgress = function onDebugWorldProgress(progress) {
    self.postMessage({type: 'debug-world-load-progress-changed', progress: progress});
};

self.debugAbort = function () {
    if(self.debugWorld) {
        self.debugWorld.abort();
        self.debugWorld.destroy();
        self.debugWorld = null;
    }
    self.postMessage({type: 'debug-abort'});
};

self.runWorld = function runWorld(args) {
  self.postedErrors = {};
  self.t0 = new Date();
  self.logsLogged = 0;

  try {
    self.world = new World(args.userCodeMap);
    self.world.levelSessionIDs = args.levelSessionIDs;
    if(args.level)
      self.world.loadFromLevel(args.level, true);
    self.world.preloading = args.preload;
    self.world.headless = args.headless;
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
  Aether.replaceBuiltin("Math", Math);
  self.postMessage({type: 'start-load-frames'});
  self.world.loadFrames(self.onWorldLoaded, self.onWorldError, self.onWorldLoadProgress);
};

self.onWorldLoaded = function onWorldLoaded() {
  self.goalManager.worldGenerationEnded();
  var goalStates = self.goalManager.getGoalStates();
  self.postMessage({type: 'end-load-frames', goalStates: goalStates});
  var t1 = new Date();
  var diff = t1 - self.t0;
  if (self.world.headless)
    return console.log('Headless simulation completed in ' + diff + 'ms.');

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
    var message = {type: 'new-world', serialized: serialized.serializedWorld, goalStates: goalStates};
    if(transferableSupported)
      self.postMessage(message, serialized.transferableObjects);
    else
      self.postMessage(message);
  }
  catch(error) {
    console.log("World delivery error:", error.toString() + "\n" + error.stack || error.stackTrace);
  }
  var t3 = new Date();
  console.log("And it was so: (" + (diff / self.world.totalFrames).toFixed(3) + "ms per frame,", self.world.totalFrames, "frames)\nSimulation   :", diff + "ms \nSerialization:", (t2 - t1) + "ms\nDelivery     :", (t3 - t2) + "ms");
  self.world.goalManager.destroy();
  self.world.destroy();
  self.world = null;
};

self.onWorldError = function onWorldError(error) {
  if(error.isUserCodeProblem) {
    var errorKey = error.userInfo.key;
    if(!errorKey || !self.postedErrors[errorKey]) {
      self.postMessage({type: 'user-code-problem', problem: error});
      self.postedErrors[errorKey] = error;
    }
  }
  else {
    console.log("Non-UserCodeError:", error.toString() + "\n" + error.stack || error.stackTrace);
    self.postMessage({type: 'non-user-code-problem', problem: {message: error.toString()}});
  }
  /*  We don't actually have the recoverable property any more; hmm
  if(!error.recoverable) {
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
  if(self.world) {
    self.world.abort();
    self.world.goalManager.destroy();
    self.world.destroy();
    self.world = null;
  }
  self.postMessage({type: 'abort'});
};

self.reportIn = function reportIn() {
  self.postMessage({type: 'report-in'});
};

self.finalizePreload = function finalizePreload() {
  self.world.finalizePreload(self.onWorldLoaded);
};

self.addEventListener('message', function(event) {
  self[event.data.func](event.data.args);
});

self.postMessage({type: 'worker-initialized'});
