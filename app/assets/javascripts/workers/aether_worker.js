var window = self;
var Global = self;

importScripts("/javascripts/tome_aether.js");
console.log("imported scripts!");
var aethers = {};

var createAether = function (spellKey, options) 
{
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

var updateLanguageAether = function(newLanguage) 
{
    for (var spellKey in aethers)
    {
        if (aethers.hasOwnProperty(spellKey))
        {
            aethers[spellKey].setLanguage(newLanguage);
        }
        
    }
};

var lint = function(spellKey, source)
{
    var currentAether = aethers[spellKey];
    var lintMessages = currentAether.lint(source);
    var functionName = "lint";
    var returnObject = {
        "lintMessages": lintMessages,
        "function": functionName
    };
    return JSON.stringify(returnObject);
};

var transpile = function(spellKey, source)
{
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
        updateLanguageAether(data.newLanguage)
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