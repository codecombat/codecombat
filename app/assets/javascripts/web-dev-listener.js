// TODO: don't serve this script from codecombat.com; serve it from a harmless extra domain we don't have yet.

window.addEventListener('message', receiveMessage, false);

var concreteDom;
var concreteStyles;
var concreteScripts;
var virtualDom;
var virtualStyles;
var virtualScripts;
var goalStates;

var allowedOrigins = [
    /https:\/\/codecombat\.com/,
    /http:\/\/localhost:3000/,
    /http:\/\/direct\.codecombat\.com/,
    /http:\/\/staging\.codecombat\.com/,
    /http:\/\/next\.codecombat\.com/,
    /http:\/\/.*codecombat-staging-codecombat\.runnableapp\.com/,
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
    var data = event.data;
    var source = event.source;
    switch (data.type) {
    case 'create':
        create(_.pick(data, 'dom', 'styles', 'scripts'));
        checkGoals(data.goals, source, origin);
        break;
    case 'update':
        if (virtualDom)
            update(_.pick(data, 'dom', 'styles', 'scripts'));
        else
            create(_.pick(data, 'dom', 'styles', 'scripts'));
        checkGoals(data.goals, source, origin);
        break;
    case 'log':
        console.log(data.text);
        break;
    default:
        console.log('Unknown message type:', data.type);
    }
}

function create({ dom, styles, scripts }) {
    virtualDom = dom;
    virtualStyles = styles;
    virtualScripts = scripts;
    concreteDom = deku.dom.create(dom);
    concreteStyles = deku.dom.create(styles);
    concreteScripts = deku.dom.create(scripts);
    // TODO: :after elements don't seem to work? (:before do)
    $('body').first().empty().append(concreteDom);
    replaceNodes('[for="player-styles"]', unwrapConcreteNodes(concreteStyles));
    replaceNodes('[for="player-scripts"]', unwrapConcreteNodes(concreteScripts));
}

function unwrapConcreteNodes(wrappedNodes) {
    return wrappedNodes.children;
}

function replaceNodes(selector, newNodes){
    $newNodes = $(newNodes).clone()
    $(selector + ':not(:first)').remove();
    
    firstNode = $(selector).first();
    $newNodes.attr('for', firstNode.attr('for'));
    
    newFirstNode = $newNodes[0];
    try {
      firstNode.replaceWith(newFirstNode); // Removes newFirstNode from its array (!!)
    } catch (e) {
      console.log('Failed to update some nodes:', e);
    }
    
    $(newFirstNode).after($newNodes);
}

function update({ dom, styles, scripts }) {
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

function checkGoals(goals, source, origin) {
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
