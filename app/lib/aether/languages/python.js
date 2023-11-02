_ = window?._ ? self?._ ? global?._ ? require 'lodash'  # rely on lodash existing, since it busts CodeCombat to browserify it--TODO

Language = require './language'

module.exports = class Python extends Language
  name: 'Python'
  id: 'python'
  parserID: 'filbert'
  thisValue: 'self'
  thisValueAccess: 'self.'
  heroValueAccess: 'hero.'
  wrappedCodeIndentLen: 4

  constructor: ->
    super arguments...

  # Called to check if the ast has changed enough.
  # All of this code has been broken by the new esper changes.
  hasChangedASTs: (a, b) -> true

  usesFunctionWrapping: () -> false

  # Sets up middleware for the python execution context.
  setupInterpreter: (esper) ->
    realm = esper.realm
    ###
      Register this function to be called whenever something from the outside world
      returns an array. We intercept the array and make it behave more like a Python
      list.
    ###
    realm.options.linkValueCallReturnValueWrapper = (value) ->
      ArrayPrototype = realm.ArrayPrototype

      return value unless value.jsTypeName is 'object'

      if value.clazz is 'Array'
        defineProperties = realm.Object.getImmediate('defineProperties')
        # listPropertyDescriptor has already been set up in the engine.
        # Reference: https://github.com/codecombat/skulpty/blob/master/lib/stdlib.js#L79
        listPropertyDescriptor = realm.globalScope.get('__pythonRuntime').getImmediate('utils').getImmediate('listPropertyDescriptor')

        gen = defineProperties.call realm.Object, [value, listPropertyDescriptor], realm.globalScope
        # All execution requests return a generator, thus we must consume the generator
        # to make execution happen.
        it = gen.next()
        while not it.done
          it = gen.next()

      return value
