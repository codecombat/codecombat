// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS104: Avoid inline assignments
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let addedGlobals, addGlobal, builtinNames, builtinObjectNames, left, left1, replaceBuiltin;
const _ = (left = (left1 = (typeof window !== 'undefined' && window !== null ? window._ : undefined) != null ? (typeof window !== 'undefined' && window !== null ? window._ : undefined) : (typeof self !== 'undefined' && self !== null ? self._ : undefined)) != null ? left1 : (typeof global !== 'undefined' && global !== null ? global._ : undefined)) != null ? left : require('lodash');  // rely on lodash existing, since it busts CodeCombat to browserify it--TODO

const problems = require('./problems');

// These builtins, being objects, will have to be cloned and restored.
module.exports.builtinObjectNames = (builtinObjectNames = [
  // Built-in Objects
  'Object', 'Function', 'Array', 'String', 'Boolean', 'Number', 'Date', 'RegExp', 'Math', 'JSON',

  // Error Objects
  'Error', 'EvalError', 'RangeError', 'ReferenceError', 'SyntaxError', 'TypeError', 'URIError'
]);

// These builtins aren't objects, so it's easy.
module.exports.builtinNames = (builtinNames = builtinObjectNames.concat([
  // Math-related
  'NaN', 'Infinity', 'undefined', 'parseInt', 'parseFloat', 'isNaN', 'isFinite',

  // URI-related
  'decodeURI', 'decodeURIComponent', 'encodeURI', 'encodeURIComponent',

  // Nope!
  // 'eval'
]));

const {
  getOwnPropertyNames
} = Object;  // Grab all properties, including non-enumerable ones.
const {
  getOwnPropertyDescriptor
} = Object;
const defineProperty = Object.defineProperty.bind(Object);

const globalScope = (function() { return this; })();
const builtinClones = [];  // We make pristine copies of our builtins so that we can copy them overtop the real ones later.
const builtinReal = [];  // These are the globals that the player will actually get to mess with, which we'll clean up after.
module.exports.addedGlobals = (addedGlobals = {});

module.exports.addGlobal = (addGlobal = function(name, value) {
  // Ex.: Aether.addGlobal('Vector', require('lib/world/vector')), before the Aether instance is constructed.
  if (addedGlobals[name] != null) { return; }
  if (value == null && globalScope) { value = globalScope[name]; }
  return addedGlobals[name] = value;
});

for (var name of Array.from(builtinObjectNames)) { addGlobal(name); }  // Protect our initial builtin objects as globals.

module.exports.replaceBuiltin = (replaceBuiltin = function(name, value) {});
  //NOOP
