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
self.workerID = "DebugWorker";

self.logLimit = 2000;
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
importScripts('/javascripts/world.js');

var World = self.require('lib/world/world');
var GoalManager = self.require('lib/world/GoalManager');
serializedClasses = {
    "Thang": self.require('lib/world/thang'),
    "Vector": self.require('lib/world/vector'),
    "Rectangle": self.require('lib/world/rectangle')
}

self.getCurrentFrame = function getCurrentFrame(args) { return self.world.frames.length; };

//optimize this later
self.currentUserCodeMapCopy = {};
self.currentWorldFrame = 0;

self.maxSerializationDepth = 3;

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

var cache = {};

self.invalidateCache = function () {
    cache = {};
};

self.retrieveValueFromCache = function (thangID, spellID, variableChain, frame) {
    var frameCache, thangCache, spellCache;
    if ((frameCache = cache[frame]) && (thangCache = frameCache[thangID]) && (spellCache = thangCache[spellID]))
        return spellCache[variableChain.join()];
    return undefined;
};


self.updateCache = function (thangID, spellID, variableChain, frame, value) {
    var key, keys, currentObject;
    keys = [frame,thangID, spellID, variableChain.join()];
    currentObject = cache;
    
    for (var i = 0, len = keys.length - 1; i < len; i++)
    {
        key = keys[i];
        if (!(key in currentObject))
            currentObject[key] = {};
        currentObject = currentObject[key];
    }
    currentObject[keys[keys.length - 1]] = value;
};

self.retrieveValueFromFrame = function retrieveValueFromFrame(args) {
    var cacheValue;
    if (args.frame === self.currentWorldFrame && (cacheValue = self.retrieveValueFromCache(args.currentThangID, args.currentSpellID, args.variableChain, args.frame)))
        return self.postMessage({type: 'debug-value-return', serialized: {"key": args.variableChain.join(), "value": cacheValue}});
        
    
    var retrieveProperty = function retrieveProperty(currentThangID, currentSpellID, variableChain)
    {
        var prop;
        var value;
        var keys = [];
        for (var i = 0, len = variableChain.length; i < len; i++) {
                prop = variableChain[i];
                if (prop === "this")
                {
                    value = self.world.thangMap[currentThangID];

                }
                else if (i === 0)
                {
                    try
                    {
                        value = _.last(_.last(self.world.userCodeMap[currentThangID][currentSpellID].flow.states).statements).variables[prop];
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
                        var thang = self.world.thangMap[value.id];
                        value = thang || "<Thang " + value.id + " (non-existent)>"
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
        self.updateCache(currentThangID,currentSpellID,variableChain, args.frame, serializedProperty.value);
        self.postMessage({type: 'debug-value-return', serialized: serializedProperty});
    };
    self.enableFlowOnThangSpell(args.currentThangID, args.currentSpellID, args.userCodeMap);
    self.setupWorldToRunUntilFrame(args);
    self.world.loadFramesUntilFrame(
        args.frame, 
        retrieveProperty.bind({},args.currentThangID, args.currentSpellID, args.variableChain), 
        self.onWorldError, 
        self.onWorldLoadProgress
    );
};

self.enableFlowOnThangSpell = function enableFlowOnThang(thangID, spellID, userCodeMap) {
    try {
        if (userCodeMap[thangID][spellID].originalOptions.includeFlow === true && 
            userCodeMap[thangID][spellID].originalOptions.noSerializationInFlow === true)
            return;
        else
        {
            userCodeMap[thangID][spellID].originalOptions.includeFlow = true;
            userCodeMap[thangID][spellID].originalOptions.noSerializationInFlow = true;
            var temporaryAether = Aether.deserialize(userCodeMap[thangID][spellID]);
            temporaryAether.transpile(temporaryAether.raw);
            userCodeMap[thangID][spellID] = temporaryAether.serialize();
        }
        
    }
    catch (e) {
        console.log("there was an error enabling flow on thang spell:" + e)
    }
};

self.setupWorldToRunUntilFrame = function setupWorldToRunUntilFrame(args) {
    self.postedErrors = {};
    self.t0 = new Date();
    self.firstWorld = args.firstWorld;
    self.postedErrors = false;
    self.logsLogged = 0;

    var stringifiedUserCodeMap = JSON.stringify(args.userCodeMap);
    var userCodeMapHasChanged = ! _.isEqual(self.currentUserCodeMapCopy, stringifiedUserCodeMap);
    self.currentUserCodeMapCopy = stringifiedUserCodeMap;
    if (!self.world || userCodeMapHasChanged || args.frame != self.currentWorldFrame) {
        self.invalidateCache();
        try {
            self.world = new World(args.worldName, args.userCodeMap);
            if (args.level)
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

        self.world.totalFrames = args.frame; //hack to work around error checking
        self.currentWorldFrame = args.frame;
    }
};
self.runWorldUntilFrame = function runWorldUntilFrame(args) {
    self.setupWorldToRunUntilFrame(args);
    
    self.world.loadFramesUntilFrame(args.frame, self.onWorldLoaded, self.onWorldError, self.onWorldLoadProgress);
    
};

self.onWorldLoaded = function onWorldLoaded() {
    console.log("World loaded!");
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
