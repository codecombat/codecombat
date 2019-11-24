// TODO: don't serve this script from codecombat.com; serve it from a harmless extra domain we don't have yet.

var lastSource = null;
var lastOrigin = null;
window.onerror = function(message, url, line, column, error){
  console.log("User script error on line " + line + ", column " + column + ": ", error);
  lastSource.postMessage({
    type: 'error',
    message: message,
    url: url,
    line: line || 0,
    column: column || 0,
  }, lastOrigin);
}
window.addEventListener('message', receiveMessage, false);

var concreteDom;
var concreteStyles;
var concreteScripts;
var virtualDom;
var virtualStyles;
var virtualScripts;
var goalStates;
var createFailed;

var allowedOrigins = [
    /^https?:\/\/(.*\.)?codecombat\.com$/,
    /^https?:\/\/localhost:[\d]+$/, // For local development
    /^https?:\/\/10.0.2.2:[\d]+$/, // For local virtual machines
    /^https?:\/\/coco\.code\.ninja$/,
    /^https?:\/\/.*codecombat-staging-codecombat\.runnableapp\.com$/,
    /^https?:\/\/(.*\.)?koudashijie\.com$/ // For china infrastructure
];

function receiveMessage(event) {
    var origin = event.origin || event.originalEvent.origin; // For Chrome, the origin property is in the event.originalEvent object.
    var allowed = false;
    allowedOrigins.forEach(function(pattern) {
        allowed = allowed || pattern.test(origin);
    });
    if (!allowed) {
        console.log('Ignoring message from bad origin:', origin);
        return;
    }
    lastOrigin = origin;
    var data = event.data;
    var source = lastSource = event.source;
    switch (data.type) {
    case 'create':
        create(_.pick(data, 'dom', 'styles', 'scripts'));
        checkGoals(data.goals, source, origin);
        $('body').first().off('click', checkRememberedGoals);
        $('body').first().on('click', checkRememberedGoals);
        break;
    case 'update':
        if (virtualDom && !createFailed)
            update(_.pick(data, 'dom', 'styles', 'scripts'));
        else
            create(_.pick(data, 'dom', 'styles', 'scripts'));
        checkGoals(data.goals, source, origin);
        break;
    case 'highlight-css-selector':
        $('*').css('box-shadow', '');
        $(data.selector).css('box-shadow', 'inset 0 0 2px 2px rgba(255, 255, 0, 1.0), 0 0 2px 2px rgba(255, 255, 0, 1.0)');
        break;
    case 'log':
        console.log(data.text);
        break;
    default:
        console.log('Unknown message type:', data.type);
    }
}

function create(options) {
    try {
        virtualDom = options.dom;
        virtualStyles = options.styles;
        virtualScripts = options.scripts;
        concreteDom = deku.dom.create(virtualDom);
        concreteStyles = deku.dom.create(virtualStyles);
        concreteScripts = deku.dom.create(virtualScripts);
        // TODO: :after elements don't seem to work? (:before do)
        $('body').first().empty().append(concreteDom);
        replaceNodes('[for="player-styles"]', unwrapConcreteNodes(concreteStyles));
        replaceNodes('[for="player-scripts"]', unwrapConcreteNodes(concreteScripts));
        createFailed = false;
    } catch(e) {
        createFailed = true;
        $('.loading-message').addClass('hidden')
        $('.loading-error').removeClass('hidden')
        const errPos = parseStackTrace(e.stack);
        lastSource.postMessage({
          type: 'error',
          message: e.name+": "+e.message,
          line: errPos.line,
          column: errPos.column,
        }, lastOrigin);
    }
}

function parseStackTrace(trace) {
    const lines = trace.split('\n')
    const regexes = [
      /.*?at .*? \(eval at globalEval.*?\).*?,.*?(\d+):(\d+)\)$/, // Chrome stacktrace formatting
      /@.*eval:(\d+):(\d+)$/, // Firefox stacktrace formatting
      /at eval code \(eval code:(\d+):(\d+)\)$/, // Internet Explorer stacktrace formatting
      // Safari doesn't include line numbers for eval in stack trace
    ]
    var matchedLine;
    for (var i = 0; i < regexes.length; i++) {
        var regex = regexes[i];
        matchedLine = _.find(lines, function(line) {
            return regex.test(line)
        })
        if (!matchedLine) continue;
        const match = matchedLine.match(regex);
        return {
            line: Number(match[1]),
            column: Number(match[2]),
        }
    }
    if (!matchedLine) return { line: 0, column: 0 };
}

function unwrapConcreteNodes(wrappedNodes) {
    return wrappedNodes.children;
}

function replaceNodes(selector, newNodes){
    var $newNodes = $(newNodes).clone();
    $(selector + ':not(:first)').remove();
    
    var firstNode = $(selector).first();
    $newNodes.attr('for', firstNode.attr('for'))
    
    // Workaround for an IE bug where style nodes created by Deku aren't read
    // Resetting innerText strips the newlines from it
    var recreatedNodes = $newNodes.toArray();
    recreatedNodes.forEach(function(node){
      node.innerHTML = node.innerHTML.trim();
    })

    var newFirstNode = recreatedNodes[0];
    firstNode.replaceWith(newFirstNode);
    
    $(newFirstNode).after(_.tail(recreatedNodes));
}

function update(options) {
    var dom = options.dom;
    var styles = options.styles;
    var scripts = options.scripts;
    function dispatch() {}  // Might want to do something here in the future
    var context = {};  // Might want to use this to send shared state to every component

    var domChanges = deku.diff.diffNode(virtualDom, dom);
    domChanges.reduce(deku.dom.update(dispatch, context), concreteDom);  // Rerender

    // var scriptChanges = deku.diff.diffNode(virtualScripts, scripts);
    // scriptChanges.reduce(deku.dom.update(dispatch, context), concreteScripts);  // Rerender
    // replaceNodes('[for="player-scripts"]', unwrapConcreteNodes(concreteScripts));

    var styleChanges = deku.diff.diffNode(virtualStyles, styles);
    styleChanges.reduce(deku.dom.update(dispatch, context), concreteStyles);  // Rerender
    replaceNodes('[for="player-styles"]', unwrapConcreteNodes(concreteStyles));

    virtualDom = dom;
    virtualStyles = styles;
    virtualScripts = scripts;
}

var lastGoalArgs = [];
function checkRememberedGoals() {
    checkGoals.apply(this, lastGoalArgs);
}

function checkGoals(goals, source, origin) {
    lastGoalArgs = [goals, source, origin]; // Memoize for checkRememberedGoals
    // Check right now and also in one second, since our 1-second CSS transition might be affecting things until it is done.
    doCheckGoals(goals, source, origin);
    _.delay(function() { doCheckGoals(goals, source, origin); }, 1001);
}

function doCheckGoals(goals, source, origin) {
    var newGoalStates = {};
    var overallSuccess = true;
    goals.forEach(function(goal) {
        var $result = $(goal.html.selector);
        //console.log('ran selector', goal.html.selector, 'to find element(s)', $result);
        var success = true;
        goal.html.valueChecks.forEach(function(check) {
            //console.log(' ... and should make sure that the value of', check.eventProps, 'is', _.omit(check, 'eventProps'), '?', matchesCheck($result, check))
            success = success && matchesCheck($result, check);
        });
        overallSuccess = overallSuccess && success;
        newGoalStates[goal.id] = {status: success ? 'success' : 'incomplete'};  // No 'failure' state
    });
    if (!_.isEqual(newGoalStates, goalStates)) {
        goalStates = newGoalStates;
        var overallStatus = overallSuccess ? 'success' : null;  // Can't really get to 'failure', just 'incomplete', which is represented by null here
        source.postMessage({type: 'goals-updated', goalStates: goalStates, overallStatus: overallStatus}, origin);
    }
}

function downTheChain(obj, keyChain) {
    if (!obj)
        return null;
    if (!_.isArray(keyChain))
        return obj[keyChain];
    var value = obj;
    while (keyChain.length && value) {
        if (keyChain[0].match(/\(.*\)$/)) {
            var args, argsString = keyChain[0].match(/\((.*)\)$/)[1];
            if (argsString)
                args = eval(argsString).split(/, ?/g).filter(function(x) { return x !== ''; });  // TODO: can/should we avoid eval here?
            else
                args = [];
            value = value[keyChain[0].split('(')[0]].apply(value, args);  // value.text(), value.css('background-color'), etc.
        }
        else
            value = value[keyChain[0]];
        keyChain = keyChain.slice(1);
    }
    return value;
}

function matchesCheck(value, check) {
    var v = downTheChain(value, check.eventProps);
    if ((check.equalTo != null) && v !== check.equalTo) {
        return false;
    }
    if ((check.notEqualTo != null) && v === check.notEqualTo) {
        return false;
    }
    if ((check.greaterThan != null) && !(v > check.greaterThan)) {
        return false;
    }
    if ((check.greaterThanOrEqualTo != null) && !(v >= check.greaterThanOrEqualTo)) {
        return false;
    }
    if ((check.lessThan != null) && !(v < check.lessThan)) {
        return false;
    }
    if ((check.lessThanOrEqualTo != null) && !(v <= check.lessThanOrEqualTo)) {
        return false;
    }
    if ((check.containingString != null) && (!v || v.search(check.containingString) === -1)) {
        return false;
    }
    if ((check.notContainingString != null) && (v != null ? v.search(check.notContainingString) : void 0) !== -1) {
        return false;
    }
    if ((check.containingRegexp != null) && (!v || v.search(new RegExp(check.containingRegexp)) === -1)) {
        return false;
    }
    if ((check.notContainingRegexp != null) && (v != null ? v.search(new RegExp(check.notContainingRegexp)) : void 0) !== -1) {
        return false;
    }
    return true;
}
