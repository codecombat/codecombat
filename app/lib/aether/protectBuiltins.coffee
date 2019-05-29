_ = window?._ ? self?._ ? global?._ ? require 'lodash'  # rely on lodash existing, since it busts CodeCombat to browserify it--TODO

problems = require './problems'

# These builtins, being objects, will have to be cloned and restored.
module.exports.builtinObjectNames = builtinObjectNames = [
  # Built-in Objects
  'Object', 'Function', 'Array', 'String', 'Boolean', 'Number', 'Date', 'RegExp', 'Math', 'JSON',

  # Error Objects
  'Error', 'EvalError', 'RangeError', 'ReferenceError', 'SyntaxError', 'TypeError', 'URIError'
]

# These builtins aren't objects, so it's easy.
module.exports.builtinNames = builtinNames = builtinObjectNames.concat [
  # Math-related
  'NaN', 'Infinity', 'undefined', 'parseInt', 'parseFloat', 'isNaN', 'isFinite',

  # URI-related
  'decodeURI', 'decodeURIComponent', 'encodeURI', 'encodeURIComponent',

  # Nope!
  # 'eval'
]

getOwnPropertyNames = Object.getOwnPropertyNames  # Grab all properties, including non-enumerable ones.
getOwnPropertyDescriptor = Object.getOwnPropertyDescriptor
defineProperty = Object.defineProperty.bind Object

globalScope = (-> @)()
builtinClones = []  # We make pristine copies of our builtins so that we can copy them overtop the real ones later.
builtinReal = []  # These are the globals that the player will actually get to mess with, which we'll clean up after.
module.exports.addedGlobals = addedGlobals = {}

module.exports.addGlobal = addGlobal = (name, value) ->
  # Ex.: Aether.addGlobal('Vector', require('lib/world/vector')), before the Aether instance is constructed.
  return if addedGlobals[name]?
  value ?= globalScope[name]
  addedGlobals[name] = value

addGlobal name for name in builtinObjectNames  # Protect our initial builtin objects as globals.

module.exports.replaceBuiltin = replaceBuiltin = (name, value) ->
  #NOOP
