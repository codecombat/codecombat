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

  setupInterpreter: (esper) ->
    realm = esper.realm
    realm.options.linkValueCallReturnValueWrapper = (value) ->
      ArrayPrototype = realm.ArrayPrototype

      return value unless value.jsTypeName is 'object'

      if value.clazz is 'Array'
        defineProperties = realm.Object.getImmediate('defineProperties')
        listPropertyDescriptor = realm.globalScope.get('__pythonRuntime').getImmediate('utils').getImmediate('listPropertyDescriptor')

        gen = defineProperties.call realm.Object, [value, listPropertyDescriptor], realm.globalScope
        it = gen.next()
        while not it.done
          it = gen.next()

      return value
