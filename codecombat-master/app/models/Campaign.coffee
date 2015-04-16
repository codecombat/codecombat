CocoModel = require './CocoModel'
schema = require 'schemas/models/campaign.schema'

module.exports = class Campaign extends CocoModel
  @className: 'Campaign'
  @schema: schema
  urlRoot: '/db/campaign'
  saveBackups: true
  @denormalizedLevelProperties: _.keys(_.omit(schema.properties.levels.additionalProperties.properties, ['unlocks', 'position', 'rewards']))
  @denormalizedCampaignProperties: ['name', 'i18n', 'slug']
