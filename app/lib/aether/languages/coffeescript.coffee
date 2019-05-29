_ = window?._ ? self?._ ? global?._ ? require 'lodash'  # rely on lodash existing, since it busts CodeCombat to browserify it--TODO

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

  usesFunctionWrapping: () -> false
