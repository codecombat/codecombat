CocoModel = require './CocoModel'
util = require '../lib/utils'

module.exports = class Achievement extends CocoModel
  @className: 'Achievement'
  @schema: require 'schemas/models/achievement'
  urlRoot: '/db/achievement'

  isRepeatable: ->
    @get('proportionalTo')?

  # TODO logic is duplicated in Mongoose Achievement schema
  getExpFunction: ->
    kind = @get('function')?.kind or @schema.function.default.kind
    parameters = @get('function')?.parameters or @schema.function.default.parameters
    funcCreator = if kind is 'linear' then util.createLinearFunc else if kind is 'logarithmic' then utils.createLogFunc
    return funcCreator(parameters) if funcCreator?
