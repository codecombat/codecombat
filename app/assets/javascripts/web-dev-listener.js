// TODO: don't serve this script from codecombat.com; serve it from a harmless extra domain we don't have yet.

window.addEventListener('message', receiveMessage, false);

var concreteDOM;
var virtualDOM;
var goalStates;

var allowedOrigins = [
    'https://codecombat.com',
    'http://localhost:3000',
    'http://direct.codecombat.com',
    'http://staging.codecombat.com'
];

function receiveMessage(event) {
    var origin = event.origin || event.originalEvent.origin; // For Chrome, the origin property is in the event.originalEvent object.
    if (allowedOrigins.indexOf(origin) == -1) {
        console.log('Ignoring message from bad origin:', origin);
        return;
    }
    //console.log(event);
    switch (event.data.type) {
    case 'create':
        create(event.data.dom);
        checkGoals(event.data.goals, event.source);
        break;
    case 'update':
        if (virtualDOM)
            update(event.data.dom);
        else
            create(event.data.dom);
        checkGoals(event.data.goals, event.source);
        break;
    case 'log':
        console.log(event.data.text);
        break;
    default:
        console.log('Unknown message type:', event.data.type);
    }
}

function create(dom) {
    concreteDOM = deku.dom.create(event.data.dom);
    virtualDOM = event.data.dom;
    // TODO: target the actual HTML tag and combine our initial structure for styles/scripts/tags with theirs
    $('body').empty().append(concreteDOM);
}

function update(dom) {
    function dispatch() {}  // Might want to do something here in the future
    var context = {};  // Might want to use this to send shared state to every component
    var changes = deku.diff.diffNode(virtualDOM, event.data.dom);
    changes.reduce(deku.dom.update(dispatch, context), concreteDOM);  // Rerender
    virtualDOM = event.data.dom;
}

function checkGoals(goals) {
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
	event.source.postMessage({type: 'goals-updated', goalStates: goalStates, overallStatus: overallStatus}, event.origin);
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
};

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
