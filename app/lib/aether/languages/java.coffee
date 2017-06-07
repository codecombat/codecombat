Language = require './language'
parserHolder = {}

module.exports = class Java extends Language
  name: 'Java'
  id: 'java'
  parserID: 'cashew'

  constructor: ->
    super arguments...
    parserHolder.cashew ?= self?.aetherCashew ? require 'cashew-js'
    @runtimeGlobals = ___JavaRuntime: parserHolder.cashew.___JavaRuntime, _Object: parserHolder.cashew._Object, Integer: parserHolder.cashew.Integer, Double: parserHolder.cashew.Double, _NotInitialized: parserHolder.cashew._NotInitialized, _ArrayList: parserHolder.cashew._ArrayList


  obviouslyCannotTranspile: (rawCode) ->
    false

