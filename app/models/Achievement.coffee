CocoModel = require './CocoModel'
utils = require '../lib/utils'

module.exports = class Achievement extends CocoModel
  @className: 'Achievement'
  @schema: require 'schemas/models/achievement'
  urlRoot: '/db/achievement'

  isRepeatable: ->
    @get('proportionalTo')?a

  # TODO logic is duplicated in Mongoose Achievement schema
  getExpFunction: ->
    kind = @get('function')?.kind or jsonschema.properties.function.default.kind
    parameters = @get('function')?.parameters or jsonschema.properties.function.default.parameters
    return utils.functionCreators[kind](parameters) if kind of utils.functionCreators
