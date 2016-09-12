(function e(t,n,r){function s(o,u){if(!n[o]){if(!t[o]){var a=typeof require=="function"&&require;if(!u&&a)return a(o,!0);if(i)return i(o,!0);var f=new Error("Cannot find module '"+o+"'");throw f.code="MODULE_NOT_FOUND",f}var l=n[o]={exports:{}};t[o][0].call(l.exports,function(e){var n=t[o][1][e];return s(n?n:e)},l,l.exports,e,t,n,r)}return n[o].exports}var i=typeof require=="function"&&require;for(var o=0;o<r.length;o++)s(r[o]);return s})({1:[function(require,module,exports){
window.deku = require('deku')

},{"deku":12}],2:[function(require,module,exports){
'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});
/**
 * Use typed arrays if we can
 */

var FastArray = typeof Uint32Array === 'undefined' ? Array : Uint32Array;

/**
 * Bit vector
 */

function createBv(sizeInBits) {
  return new FastArray(Math.ceil(sizeInBits / 32));
}

function setBit(v, idx) {
  var r = idx % 32;
  var pos = (idx - r) / 32;

  v[pos] |= 1 << r;
}

function clearBit(v, idx) {
  var r = idx % 32;
  var pos = (idx - r) / 32;

  v[pos] &= ~(1 << r);
}

function getBit(v, idx) {
  var r = idx % 32;
  var pos = (idx - r) / 32;

  return !!(v[pos] & 1 << r);
}

/**
 * Exports
 */

exports.createBv = createBv;
exports.setBit = setBit;
exports.clearBit = clearBit;
exports.getBit = getBit;
},{}],3:[function(require,module,exports){
'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.create = create;

var _dom = require('../dom');

var dom = _interopRequireWildcard(_dom);

var _diff = require('../diff');

function _interopRequireWildcard(obj) { if (obj && obj.__esModule) { return obj; } else { var newObj = {}; if (obj != null) { for (var key in obj) { if (Object.prototype.hasOwnProperty.call(obj, key)) newObj[key] = obj[key]; } } newObj.default = obj; return newObj; } }

/**
 * Create a DOM renderer using a container element. Everything will be rendered
 * inside of that container. Returns a function that accepts new state that can
 * replace what is currently rendered.
 */

function create(container, dispatch) {
  var options = arguments.length <= 2 || arguments[2] === undefined ? {} : arguments[2];

  var oldVnode = null;
  var node = null;
  var rootId = options.id || '0';

  if (container && container.childNodes.length > 0) {
    container.innerHTML = '';
  }

  var update = function update(newVnode, context) {
    var changes = (0, _diff.diffNode)(oldVnode, newVnode, rootId);
    node = changes.reduce(dom.update(dispatch, context), node);
    oldVnode = newVnode;
    return node;
  };

  var create = function create(vnode, context) {
    node = dom.create(vnode, rootId, dispatch, context);
    if (container) container.appendChild(node);
    oldVnode = vnode;
    return node;
  };

  return function (vnode) {
    var context = arguments.length <= 1 || arguments[1] === undefined ? {} : arguments[1];

    return node !== null ? update(vnode, context) : create(vnode, context);
  };
}
},{"../diff":4,"../dom":7}],4:[function(require,module,exports){
'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.Actions = undefined;
exports.diffAttributes = diffAttributes;
exports.diffChildren = diffChildren;
exports.diffNode = diffNode;

var _element = require('../element');

var _dift = require('dift');

var diffActions = _interopRequireWildcard(_dift);

var _unionType = require('union-type');

var _unionType2 = _interopRequireDefault(_unionType);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _interopRequireWildcard(obj) { if (obj && obj.__esModule) { return obj; } else { var newObj = {}; if (obj != null) { for (var key in obj) { if (Object.prototype.hasOwnProperty.call(obj, key)) newObj[key] = obj[key]; } } newObj.default = obj; return newObj; } }

var Any = function Any() {
  return true;
};
var Path = function Path() {
  return String;
};

/**
 * Patch actions
 */

var Actions = exports.Actions = (0, _unionType2.default)({
  setAttribute: [String, Any, Any],
  removeAttribute: [String, Any],
  insertChild: [Any, Number, Path],
  removeChild: [Number],
  updateChild: [Number, Array],
  updateChildren: [Array],
  insertBefore: [Number],
  replaceNode: [Any, Any, Path],
  removeNode: [Any],
  sameNode: [],
  updateThunk: [Any, Any, Path]
});

/**
 * Diff two attribute objects and return an array of actions that represent
 * changes to transform the old object into the new one.
 */

function diffAttributes(previous, next) {
  var setAttribute = Actions.setAttribute;
  var removeAttribute = Actions.removeAttribute;

  var changes = [];
  var pAttrs = previous.attributes;
  var nAttrs = next.attributes;

  for (var name in nAttrs) {
    if (nAttrs[name] !== pAttrs[name]) {
      changes.push(setAttribute(name, nAttrs[name], pAttrs[name]));
    }
  }

  for (var name in pAttrs) {
    if (!(name in nAttrs)) {
      changes.push(removeAttribute(name, pAttrs[name]));
    }
  }

  return changes;
}

/**
 * Compare two arrays of virtual nodes and return an array of actions
 * to transform the left into the right. A starting path is supplied that use
 * recursively to build up unique paths for each node.
 */

function diffChildren(previous, next, parentPath) {
  var insertChild = Actions.insertChild;
  var updateChild = Actions.updateChild;
  var removeChild = Actions.removeChild;
  var insertBefore = Actions.insertBefore;
  var updateChildren = Actions.updateChildren;
  var CREATE = diffActions.CREATE;
  var UPDATE = diffActions.UPDATE;
  var MOVE = diffActions.MOVE;
  var REMOVE = diffActions.REMOVE;

  var previousChildren = (0, _element.groupByKey)(previous.children);
  var nextChildren = (0, _element.groupByKey)(next.children);
  var key = function key(a) {
    return a.key;
  };
  var changes = [];

  function effect(type, prev, next, pos) {
    var nextPath = next ? (0, _element.createPath)(parentPath, next.key == null ? next.index : next.key) : null;
    switch (type) {
      case CREATE:
        {
          changes.push(insertChild(next.item, pos, nextPath));
          break;
        }
      case UPDATE:
        {
          var actions = diffNode(prev.item, next.item, nextPath);
          if (actions.length > 0) {
            changes.push(updateChild(prev.index, actions));
          }
          break;
        }
      case MOVE:
        {
          var actions = diffNode(prev.item, next.item, nextPath);
          actions.push(insertBefore(pos));
          changes.push(updateChild(prev.index, actions));
          break;
        }
      case REMOVE:
        {
          changes.push(removeChild(prev.index));
          break;
        }
    }
  }

  (0, diffActions.default)(previousChildren, nextChildren, effect, key);

  return updateChildren(changes);
}

/**
 * Compare two virtual nodes and return an array of changes to turn the left
 * into the right.
 */

function diffNode(prev, next, path) {
  var changes = [];
  var replaceNode = Actions.replaceNode;
  var setAttribute = Actions.setAttribute;
  var sameNode = Actions.sameNode;
  var removeNode = Actions.removeNode;
  var updateThunk = Actions.updateThunk;

  // No left node to compare it to
  // TODO: This should just return a createNode action

  if (prev === null || prev === undefined) {
    throw new Error('Left node must not be null or undefined');
  }

  // Bail out and skip updating this whole sub-tree
  if (prev === next) {
    changes.push(sameNode());
    return changes;
  }

  // Remove
  if (prev != null && next == null) {
    changes.push(removeNode(prev));
    return changes;
  }

  // Replace
  if (prev.type !== next.type) {
    changes.push(replaceNode(prev, next, path));
    return changes;
  }

  // Text
  if ((0, _element.isText)(next)) {
    if (prev.nodeValue !== next.nodeValue) {
      changes.push(setAttribute('nodeValue', next.nodeValue, prev.nodeValue));
    }
    return changes;
  }

  // Thunk
  if ((0, _element.isThunk)(next)) {
    if ((0, _element.isSameThunk)(prev, next)) {
      changes.push(updateThunk(prev, next, path));
    } else {
      changes.push(replaceNode(prev, next, path));
    }
    return changes;
  }

  // Empty
  if ((0, _element.isEmpty)(next)) {
    return changes;
  }

  changes = diffAttributes(prev, next);
  changes.push(diffChildren(prev, next, path));

  return changes;
}
},{"../element":11,"dift":15,"union-type":26}],5:[function(require,module,exports){
'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.default = createElement;

var _element = require('../element');

var _setAttribute = require('./setAttribute');

var _svg = require('./svg');

var _svg2 = _interopRequireDefault(_svg);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var cache = {};

/**
 * Create a real DOM element from a virtual element, recursively looping down.
 * When it finds custom elements it will render them, cache them, and keep going,
 * so they are treated like any other native element.
 */

function createElement(vnode, path, dispatch, context) {
  if ((0, _element.isText)(vnode)) {
    var value = typeof vnode.nodeValue === 'string' || typeof vnode.nodeValue === 'number' ? vnode.nodeValue : '';
    return document.createTextNode(value);
  }

  if ((0, _element.isEmpty)(vnode)) {
    return document.createElement('noscript');
  }

  if ((0, _element.isThunk)(vnode)) {
    var props = vnode.props;
    var component = vnode.component;
    var children = vnode.children;
    var onCreate = component.onCreate;

    var render = typeof component === 'function' ? component : component.render;
    var model = {
      children: children,
      props: props,
      path: path,
      dispatch: dispatch,
      context: context
    };
    var output = render(model);
    var _DOMElement = createElement(output, (0, _element.createPath)(path, output.key || '0'), dispatch, context);
    if (onCreate) onCreate(model);
    vnode.state = {
      vnode: output,
      model: model
    };
    return _DOMElement;
  }

  var cached = cache[vnode.type];

  if (typeof cached === 'undefined') {
    cached = cache[vnode.type] = _svg2.default.isElement(vnode.type) ? document.createElementNS(_svg2.default.namespace, vnode.type) : document.createElement(vnode.type);
  }

  var DOMElement = cached.cloneNode(false);

  for (var name in vnode.attributes) {
    (0, _setAttribute.setAttribute)(DOMElement, name, vnode.attributes[name]);
  }

  vnode.children.forEach(function (node, index) {
    if (node === null || node === undefined) {
      return;
    }
    var child = createElement(node, (0, _element.createPath)(path, node.key || index), dispatch, context);
    DOMElement.appendChild(child);
  });

  return DOMElement;
}
},{"../element":11,"./setAttribute":8,"./svg":9}],6:[function(require,module,exports){
'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});
/**
 * Special attributes that map to DOM events.
 */

exports.default = {
  onAbort: 'abort',
  onAnimationStart: 'animationstart',
  onAnimationIteration: 'animationiteration',
  onAnimationEnd: 'animationend',
  onBlur: 'blur',
  onCanPlay: 'canplay',
  onCanPlayThrough: 'canplaythrough',
  onChange: 'change',
  onClick: 'click',
  onContextMenu: 'contextmenu',
  onCopy: 'copy',
  onCut: 'cut',
  onDoubleClick: 'dblclick',
  onDrag: 'drag',
  onDragEnd: 'dragend',
  onDragEnter: 'dragenter',
  onDragExit: 'dragexit',
  onDragLeave: 'dragleave',
  onDragOver: 'dragover',
  onDragStart: 'dragstart',
  onDrop: 'drop',
  onDurationChange: 'durationchange',
  onEmptied: 'emptied',
  onEncrypted: 'encrypted',
  onEnded: 'ended',
  onError: 'error',
  onFocus: 'focus',
  onInput: 'input',
  onInvalid: 'invalid',
  onKeyDown: 'keydown',
  onKeyPress: 'keypress',
  onKeyUp: 'keyup',
  onLoad: 'load',
  onLoadedData: 'loadeddata',
  onLoadedMetadata: 'loadedmetadata',
  onLoadStart: 'loadstart',
  onPause: 'pause',
  onPlay: 'play',
  onPlaying: 'playing',
  onProgress: 'progress',
  onMouseDown: 'mousedown',
  onMouseEnter: 'mouseenter',
  onMouseLeave: 'mouseleave',
  onMouseMove: 'mousemove',
  onMouseOut: 'mouseout',
  onMouseOver: 'mouseover',
  onMouseUp: 'mouseup',
  onPaste: 'paste',
  onRateChange: 'ratechange',
  onReset: 'reset',
  onScroll: 'scroll',
  onSeeked: 'seeked',
  onSeeking: 'seeking',
  onSubmit: 'submit',
  onStalled: 'stalled',
  onSuspend: 'suspend',
  onTimeUpdate: 'timeupdate',
  onTransitionEnd: 'transitionend',
  onTouchCancel: 'touchcancel',
  onTouchEnd: 'touchend',
  onTouchMove: 'touchmove',
  onTouchStart: 'touchstart',
  onVolumeChange: 'volumechange',
  onWaiting: 'waiting',
  onWheel: 'wheel'
};
},{}],7:[function(require,module,exports){
'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.update = exports.create = undefined;

var _create = require('./create');

var _create2 = _interopRequireDefault(_create);

var _update = require('./update');

var _update2 = _interopRequireDefault(_update);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

exports.create = _create2.default;
exports.update = _update2.default;
},{"./create":5,"./update":10}],8:[function(require,module,exports){
'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.removeAttribute = removeAttribute;
exports.setAttribute = setAttribute;

var _svgAttributeNamespace = require('svg-attribute-namespace');

var _svgAttributeNamespace2 = _interopRequireDefault(_svgAttributeNamespace);

var _element = require('../element');

var _indexOf = require('index-of');

var _indexOf2 = _interopRequireDefault(_indexOf);

var _setify = require('setify');

var _setify2 = _interopRequireDefault(_setify);

var _events = require('./events');

var _events2 = _interopRequireDefault(_events);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function removeAttribute(DOMElement, name, previousValue) {
  var eventType = _events2.default[name];
  if (eventType) {
    if (typeof previousValue === 'function') {
      DOMElement.removeEventListener(eventType, previousValue);
    }
    return;
  }
  switch (name) {
    case 'checked':
    case 'disabled':
    case 'selected':
      DOMElement[name] = false;
      break;
    case 'innerHTML':
    case 'nodeValue':
      DOMElement.innerHTML = '';
      break;
    case 'value':
      DOMElement.value = '';
      break;
    default:
      DOMElement.removeAttribute(name);
      break;
  }
}

function setAttribute(DOMElement, name, value, previousValue) {
  var eventType = _events2.default[name];
  if (value === previousValue) {
    return;
  }
  if (eventType) {
    if (typeof previousValue === 'function') {
      DOMElement.removeEventListener(eventType, previousValue);
    }
    DOMElement.addEventListener(eventType, value);
    return;
  }
  if (!(0, _element.isValidAttribute)(value)) {
    removeAttribute(DOMElement, name, previousValue);
    return;
  }
  switch (name) {
    case 'checked':
    case 'disabled':
    case 'innerHTML':
    case 'nodeValue':
      DOMElement[name] = value;
      break;
    case 'selected':
      DOMElement.selected = value;
      // Fix for IE/Safari where select is not correctly selected on change
      if (DOMElement.tagName === 'OPTION' && DOMElement.parentNode) {
        var select = DOMElement.parentNode;
        select.selectedIndex = (0, _indexOf2.default)(select.options, DOMElement);
      }
      break;
    case 'value':
      (0, _setify2.default)(DOMElement, value);
      break;
    default:
      DOMElement.setAttributeNS((0, _svgAttributeNamespace2.default)(name), name, value);
      break;
  }
}
},{"../element":11,"./events":6,"index-of":16,"setify":24,"svg-attribute-namespace":25}],9:[function(require,module,exports){
'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});

var _isSvgElement = require('is-svg-element');

var namespace = 'http://www.w3.org/2000/svg';

exports.default = {
  isElement: _isSvgElement.isElement,
  namespace: namespace
};
},{"is-svg-element":17}],10:[function(require,module,exports){
'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.insertAtIndex = undefined;
exports.default = patch;

var _setAttribute2 = require('./setAttribute');

var _element = require('../element');

var _create = require('./create');

var _create2 = _interopRequireDefault(_create);

var _diff = require('../diff');

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

/**
 * Modify a DOM element given an array of actions. A context can be set
 * that will be used to render any custom elements.
 */

function patch(dispatch, context) {
  return function (DOMElement, action) {
    _diff.Actions.case({
      setAttribute: function setAttribute(name, value, previousValue) {
        (0, _setAttribute2.setAttribute)(DOMElement, name, value, previousValue);
      },
      removeAttribute: function removeAttribute(name, previousValue) {
        (0, _setAttribute2.removeAttribute)(DOMElement, name, previousValue);
      },
      insertBefore: function insertBefore(index) {
        insertAtIndex(DOMElement.parentNode, index, DOMElement);
      },
      sameNode: function sameNode() {},
      updateChildren: function updateChildren(changes) {
        // Create a clone of the children so we can reference them later
        // using their original position even if they move around
        var childNodes = Array.prototype.slice.apply(DOMElement.childNodes);

        changes.forEach(function (change) {
          _diff.Actions.case({
            insertChild: function insertChild(vnode, index, path) {
              insertAtIndex(DOMElement, index, (0, _create2.default)(vnode, path, dispatch, context));
            },
            removeChild: function removeChild(index) {
              DOMElement.removeChild(childNodes[index]);
            },
            updateChild: function updateChild(index, actions) {
              var update = patch(dispatch, context);
              actions.forEach(function (action) {
                return update(childNodes[index], action);
              });
            }
          }, change);
        });
      },
      updateThunk: function updateThunk(prev, next, path) {
        var props = next.props;
        var children = next.children;
        var component = next.component;
        var onUpdate = component.onUpdate;

        var render = typeof component === 'function' ? component : component.render;
        var prevNode = prev.state.vnode;
        var model = {
          children: children,
          props: props,
          path: path,
          dispatch: dispatch,
          context: context
        };
        var nextNode = render(model);
        var changes = (0, _diff.diffNode)(prevNode, nextNode, (0, _element.createPath)(path, '0'));
        DOMElement = changes.reduce(patch(dispatch, context), DOMElement);
        if (onUpdate) onUpdate(model);
        next.state = {
          vnode: nextNode,
          model: model
        };
      },
      replaceNode: function replaceNode(prev, next, path) {
        var newEl = (0, _create2.default)(next, path, dispatch, context);
        var parentEl = DOMElement.parentNode;
        if (parentEl) parentEl.replaceChild(newEl, DOMElement);
        DOMElement = newEl;
        removeThunks(prev);
      },
      removeNode: function removeNode(prev) {
        removeThunks(prev);
        DOMElement.parentNode.removeChild(DOMElement);
        DOMElement = null;
      }
    }, action);

    return DOMElement;
  };
}

/**
 * Recursively remove all thunks
 */

function removeThunks(vnode) {
  while ((0, _element.isThunk)(vnode)) {
    var _vnode = vnode;
    var component = _vnode.component;
    var state = _vnode.state;
    var onRemove = component.onRemove;
    var model = state.model;

    if (onRemove) onRemove(model);
    vnode = state.vnode;
  }

  if (vnode.children) {
    for (var i = 0; i < vnode.children.length; i++) {
      removeThunks(vnode.children[i]);
    }
  }
}

/**
 * Slightly nicer insertBefore
 */

var insertAtIndex = exports.insertAtIndex = function insertAtIndex(parent, index, el) {
  var target = parent.childNodes[index];
  if (target) {
    parent.insertBefore(el, target);
  } else {
    parent.appendChild(el);
  }
};
},{"../diff":4,"../element":11,"./create":5,"./setAttribute":8}],11:[function(require,module,exports){
'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.create = create;
exports.createTextElement = createTextElement;
exports.createEmptyElement = createEmptyElement;
exports.createThunkElement = createThunkElement;
exports.isValidAttribute = isValidAttribute;

function _toConsumableArray(arr) { if (Array.isArray(arr)) { for (var i = 0, arr2 = Array(arr.length); i < arr.length; i++) { arr2[i] = arr[i]; } return arr2; } else { return Array.from(arr); } }

function _typeof(obj) { return obj && typeof Symbol !== "undefined" && obj.constructor === Symbol ? "symbol" : typeof obj; }

/**
 * This function lets us create virtual nodes using a simple
 * syntax. It is compatible with JSX transforms so you can use
 * JSX to write nodes that will compile to this function.
 *
 * let node = element('div', { id: 'foo' }, [
 *   element('a', { href: 'http://google.com' },
 *     element('span', {}, 'Google'),
 *     element('b', {}, 'Link')
 *   )
 * ])
 */

function create(type, attributes) {
  for (var _len = arguments.length, children = Array(_len > 2 ? _len - 2 : 0), _key = 2; _key < _len; _key++) {
    children[_key - 2] = arguments[_key];
  }

  if (!type) throw new TypeError('element() needs a type.');

  attributes = attributes || {};
  children = (children || []).reduce(reduceChildren, []);

  var key = typeof attributes.key === 'string' || typeof attributes.key === 'number' ? attributes.key : undefined;

  delete attributes.key;

  if ((typeof type === 'undefined' ? 'undefined' : _typeof(type)) === 'object' || typeof type === 'function') {
    return createThunkElement(type, key, attributes, children);
  }

  return {
    attributes: attributes,
    children: children,
    type: type,
    key: key
  };
}

/**
 * Cleans up the array of child elements.
 * - Flattens nested arrays
 * - Converts raw strings and numbers into vnodes
 * - Filters out undefined elements
 */

function reduceChildren(children, vnode) {
  if (typeof vnode === 'string' || typeof vnode === 'number') {
    children.push(createTextElement(vnode));
  } else if (vnode === null) {
    children.push(createEmptyElement());
  } else if (Array.isArray(vnode)) {
    children = [].concat(_toConsumableArray(children), _toConsumableArray(vnode.reduce(reduceChildren, [])));
  } else if (typeof vnode === 'undefined') {
    throw new Error('vnode can\'t be undefined. Did you mean to use null?');
  } else {
    children.push(vnode);
  }
  return children;
}

/**
 * Text nodes are stored as objects to keep things simple
 */

function createTextElement(text) {
  return {
    type: '#text',
    nodeValue: text
  };
}

/**
 * Text nodes are stored as objects to keep things simple
 */

function createEmptyElement() {
  return {
    type: '#empty'
  };
}

/**
 * Lazily-rendered virtual nodes
 */

function createThunkElement(component, key, props, children) {
  return {
    type: '#thunk',
    children: children,
    props: props,
    component: component,
    key: key
  };
}

/**
 * Is a vnode a thunk?
 */

var isThunk = exports.isThunk = function isThunk(node) {
  return node.type === '#thunk';
};

/**
 * Is a vnode a text node?
 */

var isText = exports.isText = function isText(node) {
  return node.type === '#text';
};

/**
 * Is a vnode an empty placeholder?
 */

var isEmpty = exports.isEmpty = function isEmpty(node) {
  return node.type === '#empty';
};

/**
 * Determine if two virtual nodes are the same type
 */

var isSameThunk = exports.isSameThunk = function isSameThunk(left, right) {
  return isThunk(left) && isThunk(right) && left.component === right.component;
};

/**
 * Group an array of virtual elements by their key, using index as a fallback.
 */

var groupByKey = exports.groupByKey = function groupByKey(children) {
  return children.reduce(function (acc, child, i) {
    if (child != null && child !== false) {
      acc.push({
        key: String(child.key || i),
        item: child,
        index: i
      });
    }
    return acc;
  }, []);
};

/**
 * Check if an attribute should be rendered into the DOM.
 */

function isValidAttribute(value) {
  if (typeof value === 'boolean') return value;
  if (typeof value === 'function') return false;
  if (value === '') return true;
  if (value === undefined) return false;
  if (value === null) return false;
  return true;
}

/**
 * Create a node path, eg. (23,5,2,4) => '23.5.2.4'
 */

var createPath = exports.createPath = function createPath() {
  for (var _len2 = arguments.length, args = Array(_len2), _key2 = 0; _key2 < _len2; _key2++) {
    args[_key2] = arguments[_key2];
  }

  return args.join('.');
};
},{}],12:[function(require,module,exports){
'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.h = exports.dom = exports.diff = exports.vnode = exports.string = exports.element = exports.createApp = undefined;

var _diff = require('./diff');

var diff = _interopRequireWildcard(_diff);

var _element = require('./element');

var vnode = _interopRequireWildcard(_element);

var _string = require('./string');

var string = _interopRequireWildcard(_string);

var _dom = require('./dom');

var dom = _interopRequireWildcard(_dom);

var _app = require('./app');

var app = _interopRequireWildcard(_app);

function _interopRequireWildcard(obj) { if (obj && obj.__esModule) { return obj; } else { var newObj = {}; if (obj != null) { for (var key in obj) { if (Object.prototype.hasOwnProperty.call(obj, key)) newObj[key] = obj[key]; } } newObj.default = obj; return newObj; } }

var element = vnode.create;
var h = vnode.create;
var createApp = app.create;

exports.createApp = createApp;
exports.element = element;
exports.string = string;
exports.vnode = vnode;
exports.diff = diff;
exports.dom = dom;
exports.h = h;
},{"./app":3,"./diff":4,"./dom":7,"./element":11,"./string":13}],13:[function(require,module,exports){
'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.render = undefined;

var _renderString = require('./renderString');

var render = _renderString.renderString;

exports.render = render;
},{"./renderString":14}],14:[function(require,module,exports){
'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.renderString = renderString;

var _element = require('../element');

/**
 * Turn an object of key/value pairs into a HTML attribute string. This
 * function is responsible for what attributes are allowed to be rendered and
 * should handle any other special cases specific to deku.
 */

function attributesToString(attributes) {
  var str = '';
  for (var name in attributes) {
    var value = attributes[name];
    if (name === 'innerHTML') continue;
    if ((0, _element.isValidAttribute)(value)) str += ' ' + name + '="' + attributes[name] + '"';
  }
  return str;
}

/**
 * Render a virtual element to a string. You can pass in an option state context
 * object that will be given to all components.
 */

function renderString(element, context) {
  var path = arguments.length <= 2 || arguments[2] === undefined ? '0' : arguments[2];

  if ((0, _element.isText)(element)) {
    return element.nodeValue;
  }

  if ((0, _element.isEmpty)(element)) {
    return '<noscript></noscript>';
  }

  if ((0, _element.isThunk)(element)) {
    var props = element.props;
    var component = element.component;
    var _children = element.children;
    var render = component.render;

    var output = render({
      children: _children,
      props: props,
      path: path,
      context: context
    });
    return renderString(output, context, path);
  }

  var attributes = element.attributes;
  var type = element.type;
  var children = element.children;

  var innerHTML = attributes.innerHTML;
  var str = '<' + type + attributesToString(attributes) + '>';

  if (innerHTML) {
    str += innerHTML;
  } else {
    str += children.map(function (child, i) {
      return renderString(child, context, path + '.' + (child.key == null ? i : child.key));
    }).join('');
  }

  str += '</' + type + '>';
  return str;
}
},{"../element":11}],15:[function(require,module,exports){
'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.REMOVE = exports.MOVE = exports.UPDATE = exports.CREATE = undefined;

var _bitVector = require('bit-vector');

/**
 * Actions
 */

var CREATE = 0; /**
                 * Imports
                 */

var UPDATE = 1;
var MOVE = 2;
var REMOVE = 3;

/**
 * dift
 */

function dift(prev, next, effect, key) {
  var pStartIdx = 0;
  var nStartIdx = 0;
  var pEndIdx = prev.length - 1;
  var nEndIdx = next.length - 1;
  var pStartItem = prev[pStartIdx];
  var nStartItem = next[nStartIdx];

  // List head is the same
  while (pStartIdx <= pEndIdx && nStartIdx <= nEndIdx && equal(pStartItem, nStartItem)) {
    effect(UPDATE, pStartItem, nStartItem, nStartIdx);
    pStartItem = prev[++pStartIdx];
    nStartItem = next[++nStartIdx];
  }

  // The above case is orders of magnitude more common than the others, so fast-path it
  if (nStartIdx > nEndIdx && pStartIdx > pEndIdx) {
    return;
  }

  var pEndItem = prev[pEndIdx];
  var nEndItem = next[nEndIdx];
  var movedFromFront = 0;

  // Reversed
  while (pStartIdx <= pEndIdx && nStartIdx <= nEndIdx && equal(pStartItem, nEndItem)) {
    effect(MOVE, pStartItem, nEndItem, pEndIdx - movedFromFront + 1);
    pStartItem = prev[++pStartIdx];
    nEndItem = next[--nEndIdx];
    ++movedFromFront;
  }

  // Reversed the other way (in case of e.g. reverse and append)
  while (pEndIdx >= pStartIdx && nStartIdx <= nEndIdx && equal(nStartItem, pEndItem)) {
    effect(MOVE, pEndItem, nStartItem, nStartIdx);
    pEndItem = prev[--pEndIdx];
    nStartItem = next[++nStartIdx];
    --movedFromFront;
  }

  // List tail is the same
  while (pEndIdx >= pStartIdx && nEndIdx >= nStartIdx && equal(pEndItem, nEndItem)) {
    effect(UPDATE, pEndItem, nEndItem, nEndIdx);
    pEndItem = prev[--pEndIdx];
    nEndItem = next[--nEndIdx];
  }

  if (pStartIdx > pEndIdx) {
    while (nStartIdx <= nEndIdx) {
      effect(CREATE, null, nStartItem, nStartIdx);
      nStartItem = next[++nStartIdx];
    }

    return;
  }

  if (nStartIdx > nEndIdx) {
    while (pStartIdx <= pEndIdx) {
      effect(REMOVE, pStartItem);
      pStartItem = prev[++pStartIdx];
    }

    return;
  }

  var created = 0;
  var pivotDest = null;
  var pivotIdx = pStartIdx - movedFromFront;
  var keepBase = pStartIdx;
  var keep = (0, _bitVector.createBv)(pEndIdx - pStartIdx);

  var prevMap = keyMap(prev, pStartIdx, pEndIdx + 1, key);

  for (; nStartIdx <= nEndIdx; nStartItem = next[++nStartIdx]) {
    var oldIdx = prevMap[key(nStartItem)];

    if (isUndefined(oldIdx)) {
      effect(CREATE, null, nStartItem, pivotIdx++);
      ++created;
    } else if (pStartIdx !== oldIdx) {
      (0, _bitVector.setBit)(keep, oldIdx - keepBase);
      effect(MOVE, prev[oldIdx], nStartItem, pivotIdx++);
    } else {
      pivotDest = nStartIdx;
    }
  }

  if (pivotDest !== null) {
    (0, _bitVector.setBit)(keep, 0);
    effect(MOVE, prev[pStartIdx], next[pivotDest], pivotDest);
  }

  // If there are no creations, then you have to
  // remove exactly max(prevLen - nextLen, 0) elements in this
  // diff. You have to remove one more for each element
  // that was created. This means once we have
  // removed that many, we can stop.
  var necessaryRemovals = prev.length - next.length + created;
  for (var removals = 0; removals < necessaryRemovals; pStartItem = prev[++pStartIdx]) {
    if (!(0, _bitVector.getBit)(keep, pStartIdx - keepBase)) {
      effect(REMOVE, pStartItem);
      ++removals;
    }
  }

  function equal(a, b) {
    return key(a) === key(b);
  }
}

function isUndefined(val) {
  return typeof val === 'undefined';
}

function keyMap(items, start, end, key) {
  var map = {};

  for (var i = start; i < end; ++i) {
    map[key(items[i])] = i;
  }

  return map;
}

/**
 * Exports
 */

exports.default = dift;
exports.CREATE = CREATE;
exports.UPDATE = UPDATE;
exports.MOVE = MOVE;
exports.REMOVE = REMOVE;
},{"bit-vector":2}],16:[function(require,module,exports){
/*!
 * index-of <https://github.com/jonschlinkert/index-of>
 *
 * Copyright (c) 2014-2015 Jon Schlinkert.
 * Licensed under the MIT license.
 */

'use strict';

module.exports = function indexOf(arr, ele, start) {
  start = start || 0;
  var idx = -1;

  if (arr == null) return idx;
  var len = arr.length;
  var i = start < 0
    ? (len + start)
    : start;

  if (i >= arr.length) {
    return -1;
  }

  while (i < len) {
    if (arr[i] === ele) {
      return i;
    }
    i++;
  }

  return -1;
};

},{}],17:[function(require,module,exports){
/**
 * Supported SVG elements
 *
 * @type {Array}
 */

exports.elements = {
  'animate': true,
  'circle': true,
  'defs': true,
  'ellipse': true,
  'g': true,
  'line': true,
  'linearGradient': true,
  'mask': true,
  'path': true,
  'pattern': true,
  'polygon': true,
  'polyline': true,
  'radialGradient': true,
  'rect': true,
  'stop': true,
  'svg': true,
  'text': true,
  'tspan': true
}

/**
 * Is element's namespace SVG?
 *
 * @param {String} name
 */

exports.isElement = function (name) {
  return name in exports.elements
}

},{}],18:[function(require,module,exports){
var supportedTypes = ['text', 'search', 'tel', 'url', 'password'];

module.exports = function(element){
    return !!(element.setSelectionRange && ~supportedTypes.indexOf(element.type));
};

},{}],19:[function(require,module,exports){
var _curry2 = require('./internal/_curry2');


/**
 * Wraps a function of any arity (including nullary) in a function that accepts exactly `n`
 * parameters. Unlike `nAry`, which passes only `n` arguments to the wrapped function,
 * functions produced by `arity` will pass all provided arguments to the wrapped function.
 *
 * @func
 * @memberOf R
 * @sig (Number, (* -> *)) -> (* -> *)
 * @category Function
 * @param {Number} n The desired arity of the returned function.
 * @param {Function} fn The function to wrap.
 * @return {Function} A new function wrapping `fn`. The new function is
 *         guaranteed to be of arity `n`.
 * @deprecated since v0.15.0
 * @example
 *
 *      var takesTwoArgs = function(a, b) {
 *        return [a, b];
 *      };
 *      takesTwoArgs.length; //=> 2
 *      takesTwoArgs(1, 2); //=> [1, 2]
 *
 *      var takesOneArg = R.arity(1, takesTwoArgs);
 *      takesOneArg.length; //=> 1
 *      // All arguments are passed through to the wrapped function
 *      takesOneArg(1, 2); //=> [1, 2]
 */
module.exports = _curry2(function(n, fn) {
  // jshint unused:vars
  switch (n) {
    case 0: return function() {return fn.apply(this, arguments);};
    case 1: return function(a0) {return fn.apply(this, arguments);};
    case 2: return function(a0, a1) {return fn.apply(this, arguments);};
    case 3: return function(a0, a1, a2) {return fn.apply(this, arguments);};
    case 4: return function(a0, a1, a2, a3) {return fn.apply(this, arguments);};
    case 5: return function(a0, a1, a2, a3, a4) {return fn.apply(this, arguments);};
    case 6: return function(a0, a1, a2, a3, a4, a5) {return fn.apply(this, arguments);};
    case 7: return function(a0, a1, a2, a3, a4, a5, a6) {return fn.apply(this, arguments);};
    case 8: return function(a0, a1, a2, a3, a4, a5, a6, a7) {return fn.apply(this, arguments);};
    case 9: return function(a0, a1, a2, a3, a4, a5, a6, a7, a8) {return fn.apply(this, arguments);};
    case 10: return function(a0, a1, a2, a3, a4, a5, a6, a7, a8, a9) {return fn.apply(this, arguments);};
    default: throw new Error('First argument to arity must be a non-negative integer no greater than ten');
  }
});

},{"./internal/_curry2":22}],20:[function(require,module,exports){
var _curry2 = require('./internal/_curry2');
var _curryN = require('./internal/_curryN');
var arity = require('./arity');


/**
 * Returns a curried equivalent of the provided function, with the
 * specified arity. The curried function has two unusual capabilities.
 * First, its arguments needn't be provided one at a time. If `g` is
 * `R.curryN(3, f)`, the following are equivalent:
 *
 *   - `g(1)(2)(3)`
 *   - `g(1)(2, 3)`
 *   - `g(1, 2)(3)`
 *   - `g(1, 2, 3)`
 *
 * Secondly, the special placeholder value `R.__` may be used to specify
 * "gaps", allowing partial application of any combination of arguments,
 * regardless of their positions. If `g` is as above and `_` is `R.__`,
 * the following are equivalent:
 *
 *   - `g(1, 2, 3)`
 *   - `g(_, 2, 3)(1)`
 *   - `g(_, _, 3)(1)(2)`
 *   - `g(_, _, 3)(1, 2)`
 *   - `g(_, 2)(1)(3)`
 *   - `g(_, 2)(1, 3)`
 *   - `g(_, 2)(_, 3)(1)`
 *
 * @func
 * @memberOf R
 * @category Function
 * @sig Number -> (* -> a) -> (* -> a)
 * @param {Number} length The arity for the returned function.
 * @param {Function} fn The function to curry.
 * @return {Function} A new, curried function.
 * @see R.curry
 * @example
 *
 *      var addFourNumbers = function() {
 *        return R.sum([].slice.call(arguments, 0, 4));
 *      };
 *
 *      var curriedAddFourNumbers = R.curryN(4, addFourNumbers);
 *      var f = curriedAddFourNumbers(1, 2);
 *      var g = f(3);
 *      g(4); //=> 10
 */
module.exports = _curry2(function curryN(length, fn) {
  return arity(length, _curryN(length, [], fn));
});

},{"./arity":19,"./internal/_curry2":22,"./internal/_curryN":23}],21:[function(require,module,exports){
/**
 * Optimized internal two-arity curry function.
 *
 * @private
 * @category Function
 * @param {Function} fn The function to curry.
 * @return {Function} The curried function.
 */
module.exports = function _curry1(fn) {
  return function f1(a) {
    if (arguments.length === 0) {
      return f1;
    } else if (a != null && a['@@functional/placeholder'] === true) {
      return f1;
    } else {
      return fn(a);
    }
  };
};

},{}],22:[function(require,module,exports){
var _curry1 = require('./_curry1');


/**
 * Optimized internal two-arity curry function.
 *
 * @private
 * @category Function
 * @param {Function} fn The function to curry.
 * @return {Function} The curried function.
 */
module.exports = function _curry2(fn) {
  return function f2(a, b) {
    var n = arguments.length;
    if (n === 0) {
      return f2;
    } else if (n === 1 && a != null && a['@@functional/placeholder'] === true) {
      return f2;
    } else if (n === 1) {
      return _curry1(function(b) { return fn(a, b); });
    } else if (n === 2 && a != null && a['@@functional/placeholder'] === true &&
                          b != null && b['@@functional/placeholder'] === true) {
      return f2;
    } else if (n === 2 && a != null && a['@@functional/placeholder'] === true) {
      return _curry1(function(a) { return fn(a, b); });
    } else if (n === 2 && b != null && b['@@functional/placeholder'] === true) {
      return _curry1(function(b) { return fn(a, b); });
    } else {
      return fn(a, b);
    }
  };
};

},{"./_curry1":21}],23:[function(require,module,exports){
var arity = require('../arity');


/**
 * Internal curryN function.
 *
 * @private
 * @category Function
 * @param {Number} length The arity of the curried function.
 * @return {array} An array of arguments received thus far.
 * @param {Function} fn The function to curry.
 */
module.exports = function _curryN(length, received, fn) {
  return function() {
    var combined = [];
    var argsIdx = 0;
    var left = length;
    var combinedIdx = 0;
    while (combinedIdx < received.length || argsIdx < arguments.length) {
      var result;
      if (combinedIdx < received.length &&
          (received[combinedIdx] == null ||
           received[combinedIdx]['@@functional/placeholder'] !== true ||
           argsIdx >= arguments.length)) {
        result = received[combinedIdx];
      } else {
        result = arguments[argsIdx];
        argsIdx += 1;
      }
      combined[combinedIdx] = result;
      if (result == null || result['@@functional/placeholder'] !== true) {
        left -= 1;
      }
      combinedIdx += 1;
    }
    return left <= 0 ? fn.apply(this, combined) : arity(left, _curryN(length, combined, fn));
  };
};

},{"../arity":19}],24:[function(require,module,exports){
var naturalSelection = require('natural-selection');

module.exports = function(element, value){
    var canSet = naturalSelection(element) && element === document.activeElement;

    if (canSet) {
        var start = element.selectionStart,
            end = element.selectionEnd;

        element.value = value;
        element.setSelectionRange(start, end);
    } else {
        element.value = value;
    }
};

},{"natural-selection":18}],25:[function(require,module,exports){
'use strict';

module.exports = module.exports['default'] = SvgAttributeNamespace

/*
 * Supported SVG attribute namespaces by prefix.
 *
 * References:
 * - http://www.w3.org/TR/SVGTiny12/attributeTable.html
 * - http://www.w3.org/TR/SVG/attindex.html
 * - http://www.w3.org/TR/DOM-Level-2-Core/core.html#ID-ElSetAttrNS
 */

var namespaces = module.exports.namespaces = {
  ev: 'http://www.w3.org/2001/xml-events',
  xlink: 'http://www.w3.org/1999/xlink',
  xml: 'http://www.w3.org/XML/1998/namespace',
  xmlns: 'http://www.w3.org/2000/xmlns/'
}

/**
 * Get namespace of svg attribute
 *
 * @param {String} attributeName
 * @return {String} namespace
 */

function SvgAttributeNamespace (attributeName) {
  // if no prefix separator in attributeName, then no namespace
  if (attributeName.indexOf(':') === -1) return null

  // get prefix from attributeName
  var prefix = attributeName.split(':', 1)[0]

  // if prefix in supported prefixes
  if (namespaces.hasOwnProperty(prefix)) {
    // then namespace of prefix
    return namespaces[prefix]
  } else {
    // else unsupported prefix
    throw new Error('svg-attribute-namespace: prefix "' + prefix + '" is not supported by SVG.')
  }
}

},{}],26:[function(require,module,exports){
var curryN = require('ramda/src/curryN');

function isString(s) { return typeof s === 'string'; }
function isNumber(n) { return typeof n === 'number'; }
function isObject(value) {
  var type = typeof value;
  return !!value && (type == 'object' || type == 'function');
}
function isFunction(f) { return typeof f === 'function'; }
var isArray = Array.isArray || function(a) { return 'length' in a; };

var mapConstrToFn = curryN(2, function(group, constr) {
  return constr === String    ? isString
       : constr === Number    ? isNumber
       : constr === Object    ? isObject
       : constr === Array     ? isArray
       : constr === Function  ? isFunction
       : constr === undefined ? group
                              : constr;
});

function Constructor(group, name, validators) {
  validators = validators.map(mapConstrToFn(group));
  var constructor = curryN(validators.length, function() {
    var val = [], v, validator;
    for (var i = 0; i < arguments.length; ++i) {
      v = arguments[i];
      validator = validators[i];
      if ((typeof validator === 'function' && validator(v)) ||
          (v !== undefined && v !== null && v.of === validator)) {
        val[i] = arguments[i];
      } else {
        throw new TypeError('wrong value ' + v + ' passed to location ' + i + ' in ' + name);
      }
    }
    val.of = group;
    val.name = name;
    return val;
  });
  return constructor;
}

function rawCase(type, cases, action, arg) {
  if (type !== action.of) throw new TypeError('wrong type passed to case');
  var name = action.name in cases ? action.name
           : '_' in cases         ? '_'
                                  : undefined;
  if (name === undefined) {
    throw new Error('unhandled value passed to case');
  } else {
    return cases[name].apply(undefined, arg !== undefined ? action.concat([arg]) : action);
  }
}

var typeCase = curryN(3, rawCase);
var caseOn = curryN(4, rawCase);

function Type(desc) {
  var obj = {};
  for (var key in desc) {
    obj[key] = Constructor(obj, key, desc[key]);
  }
  obj.case = typeCase(obj);
  obj.caseOn = caseOn(obj);
  return obj;
}

module.exports = Type;

},{"ramda/src/curryN":20}]},{},[1]);
