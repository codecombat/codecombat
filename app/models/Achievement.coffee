CocoModel = require './CocoModel'
utils = require '../lib/utils'

module.exports = class Achievement extends CocoModel
  @className: 'Achievement'
  @schema: require 'schemas/models/achievement'
  urlRoot: '/db/achievement'

  isRepeatable: ->
    @get('proportionalTo')?

  # TODO logic is duplicated in Mongoose Achievement schema
  getExpFunction: ->
    kind = @get('function')?.kind or jsonschema.properties.function.default.kind
    parameters = @get('function')?.parameters or jsonschema.properties.function.default.parameters
    return utils.functionCreators[kind](parameters) if kind of utils.functionCreators

  @styleMapping:
    1: 'achievement-wood'
    2: 'achievement-stone'
    3: 'achievement-silver'
    4: 'achievement-gold'
    5: 'achievement-diamond'

  getNotifyStyle: -> Achievement.styleMapping[@get 'difficulty']

  getImageURL: ->
    if @get 'icon' then '/file/' + @get('icon') else '/images/achievements/default.png'
