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

self.getCurrentFrame = function getCurrentFrame(args) { return self.world.frames.length; };

//optimize this later
self.currentUserCodeMapCopy = {};
self.currentWorldFrame = 0;

self.maxSerializationDepth = 3;
self.serializeProperty = function serializeProperty(prop, depth) {
    var typeOfProperty = typeof(prop);
    if (["undefined","boolean","number","string","xml"].indexOf(typeOfProperty) > -1 || prop === null || prop instanceof Date || prop instanceof String)
        return prop;
    else if (typeOfProperty === "function") return "<function>";
    else if (prop instanceof Array)
    {
        if (depth >= self.maxSerializationDepth) return Object.keys(prop);
        else
        {
            var newProps = [];
            for(var i= 0, arrayLength=prop.length; i < arrayLength; i++)
                newProps[i] = self.serializeProperty(prop[i],depth + 1);
            return newProps;
        }
    }
    else if (prop.hasOwnProperty("id"))
    {
        return prop.id;
    }
    else if (prop.hasOwnProperty('serialize'))
    {
        return prop.serialize();
    }
    else
    {
        newObject = {};
        for (var key in prop)
        {
            if (prop.hasOwnProperty(key))
            {
                if (depth >= self.maxSerializationDepth)
                {
                    newObject[key] = "DEPTH EXCEEDED";
                }
                else
                {
                    newObject[key] = self.serializeProperty(prop[key], depth + 1);
                }
            }
        }
        return newObject;
    }
};

self.retrieveThangPropertyFromFrame = function retrieveThangPropertyFromFrame(args) {
    var thangID = args.thangID;
    var prop = args.prop;
    var retrieveProperty = function retrieveProperty()
    {
        var unserializedProperty = self.world.thangMap[thangID][prop];
        self.postMessage({type: 'debug-value-return', serialized: self.serializeProperty(unserializedProperty,0)});
    };
    self.setupWorldToRunUntilFrame(args);
    self.world.loadFramesUntilFrame(args.frame, retrieveProperty, self.onWorldError, self.onWorldLoadProgress);
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
    if (!self.world || userCodeMapHasChanged || args.frame < self.currentWorldFrame)
    {
        
        
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
    }

    self.world.totalFrames = args.frame; //hack to work around error checking
    self.currentWorldFrame = args.frame;
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
    console.log("received message!")
    self[event.data.func](event.data.args);
});

self.postMessage({type: 'worker-initialized'});
