CocoModel = require './CocoModel'
schema = require 'schemas/models/clan.schema'

module.exports = class Clan extends CocoModel
  @className: 'Clan'
  @schema: schema
  urlRoot: '/db/clan'
