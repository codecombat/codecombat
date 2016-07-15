// TODO: don't serve this script from codecombat.com; serve it from a harmless extra domain we don't have yet.

window.addEventListener("message", receiveMessage, false);

var concreteDOM;
var virtualDOM;

function receiveMessage(event) {
    var origin = event.origin || event.originalEvent.origin; // For Chrome, the origin property is in the event.originalEvent object.
    if (origin != 'https://codecombat.com' && origin != 'http://localhost:3000') {
        console.log("Bad origin:", origin);
    }
    //console.log(event);
    switch (event.data.type) {
    case 'create':
    case 'update':
        if (virtualDOM)
            update(event.data.dom);
        else
	    create(event.data.dom);
        break;
    case 'log':
        console.log(event.data.text);
        break;
    default:
	console.log('Unknown message type:', event.data.type);
    }

    //event.source.postMessage("hi there yourself!  the secret response is: rheeeeet!", event.origin);
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
    changes.reduce(deku.dom.update(dispatch, context), concreteDOM)  // Rerender
    virtualDOM = event.data.dom;
}
