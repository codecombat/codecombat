CocoModel = require './CocoModel'

module.exports = class Campaign extends CocoModel
  @className: 'Campaign'
  @schema: require 'schemas/models/campaign.schema'
  urlRoot: '/db/campaign'
  saveBackups: true
