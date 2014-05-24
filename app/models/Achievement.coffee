CocoModel = require './CocoModel'

module.exports = class Achievement extends CocoModel
  @className: 'Achievement'
  @schema: require 'schemas/models/achievement'
  urlRoot: '/db/achievement'

  initialize: (id) ->
    super()
    @set('_id', id) if id?