Language = require './language'
parserHolder = {}

module.exports = class Java extends Language
  name: 'Java'
  id: 'java'

  constructor: ->
    super arguments...
    @runtimeGlobals = ___JavaRuntime: parserHolder.cashew.___JavaRuntime, _Object: parserHolder.cashew._Object, Integer: parserHolder.cashew.Integer, Double: parserHolder.cashew.Double, _NotInitialized: parserHolder.cashew._NotInitialized, _ArrayList: parserHolder.cashew._ArrayList


  obviouslyCannotTranspile: (rawCode) ->
    false

