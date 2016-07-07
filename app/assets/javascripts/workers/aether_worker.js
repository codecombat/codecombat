var window = self;
var Global = self;

importScripts("/javascripts/lodash.js", "/javascripts/aether.js");

try {
  //Detect very modern javascript support.
  (0,eval("'use strict'; let test = WeakMap && (class Test { *gen(a=7) { yield yield * () => true ; } });"));
  console.log("Modern javascript detected, aw yeah!");
  self.importScripts('/javascripts/esper.modern.js');  
} catch (e) {
  console.log("Legacy javascript detected, falling back...", e.message);
  self.importScripts('/javascripts/esper.js');  
}

//console.log("Aether Tome worker has finished importing scripts.");
var aethers = {};
var languagesImported = {};

var ensureLanguageImported = function(language) {
  if (languagesImported[language]) return;
  importScripts("/javascripts/app/vendor/aether-" + language + ".js");
  languagesImported[language] = true;
};

var createAether = function (spellKey, options) {
    ensureLanguageImported(options.language);
    aethers[spellKey] = new Aether(options);
    return JSON.stringify({
        "message": "Created aether for " + spellKey,
        "function": "createAether"
    });
};

var hasChangedSignificantly = function(spellKey, a,b,careAboutLineNumbers,careAboutLint) {
    var hasChanged = aethers[spellKey].hasChangedSignificantly(a,b,careAboutLineNumbers,careAboutLint);
    var functionName = "hasChangedSignificantly";
    var returnObject = {
        "function":functionName,
        "hasChanged": hasChanged,
        "spellKey": spellKey
    };
    return JSON.stringify(returnObject);
};

var updateLanguageAether = function(newLanguage) {
    ensureLanguageImported(newLanguage);
    for (var spellKey in aethers)
    {
        if (aethers.hasOwnProperty(spellKey))
        {
            aethers[spellKey].setLanguage(newLanguage);
        }
        
    }
};

var lint = function(spellKey, source) {
    var currentAether = aethers[spellKey];
    var lintMessages = currentAether.lint(source);
    var functionName = "lint";
    var returnObject = {
        "lintMessages": lintMessages,
        "function": functionName
    };
    return JSON.stringify(returnObject);
};

var transpile = function(spellKey, source) {
    var currentAether = aethers[spellKey];
    currentAether.transpile(source);
    var functionName = "transpile";
    var returnObject = {
        "problems": currentAether.problems,
        "function": functionName,
        "spellKey": spellKey
    };
    return JSON.stringify(returnObject);
};

self.addEventListener('message', function(e) {
    var data = JSON.parse(e.data);
    if (data.function == "createAether")
    {
        self.postMessage(createAether(data.spellKey, data.options));
    }
    else if (data.function == "updateLanguageAether")
    {
        updateLanguageAether(data.newLanguage);
    }
    else if (data.function == "hasChangedSignificantly")
    {
        self.postMessage(hasChangedSignificantly(
            data.spellKey,
            data.a,
            data.b,
            data.careAboutLineNumbers,
            data.careAboutLint
        ));
    }
    else if (data.function == "lint")
    {
        self.postMessage(lint(data.spellKey, data.source));
    }
    else if (data.function == "transpile")
    {
        self.postMessage(transpile(data.spellKey, data.source));
    }
    else
    {
        var message = "Didn't execute any function...";
        var returnObject = {"message":message, "function":"none"};
        self.postMessage(JSON.stringify(returnObject));
    }
}, false); 
