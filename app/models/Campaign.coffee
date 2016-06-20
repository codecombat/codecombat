CocoModel = require './CocoModel'
schema = require 'schemas/models/campaign.schema'
Level = require 'models/Level'
Levels = require 'collections/Levels'
CocoCollection = require 'collections/CocoCollection'

module.exports = class Campaign extends CocoModel
  @className: 'Campaign'
  @schema: schema
  urlRoot: '/db/campaign'
  @denormalizedLevelProperties: _.keys(_.omit(schema.properties.levels.additionalProperties.properties, ['unlocks', 'position', 'rewards']))
  @denormalizedCampaignProperties: ['name', 'i18n', 'slug']
  
  getLevels: ->
    levels = new Levels(_.values(@get('levels')))
    levels.comparator = 'campaignIndex'
    levels.sort()
    return levels
    
  getNonLadderLevels: ->
    levels = new Levels(_.values(@get('levels')))
    levels.reset(levels.reject (level) -> level.isLadder())
    levels.comparator = 'campaignIndex'
    levels.sort()
    return levels
