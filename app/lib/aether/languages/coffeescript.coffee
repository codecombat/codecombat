parserHolder = {}
estraverse = require 'estraverse'

Language = require './language'

module.exports = class CoffeeScript extends Language
  name: 'CoffeeScript'
  id: 'coffeescript'
  parserID: 'csredux'
  thisValue:'@'
  thisValueAccess:'@'
  heroValueAccess:'hero.'
  wrappedCodeIndentLen: 4

  constructor: ->
    super arguments...
    @indent = Array(@wrappedCodeIndentLen + 1).join ' '
    parserHolder.csredux ?= self?.aetherCoffeeScriptRedux ? {}

  usesFunctionWrapping: () -> false


