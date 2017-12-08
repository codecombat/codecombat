CocoModel = require './CocoModel'
schema = require 'schemas/models/campaign.schema'
Level = require 'models/Level'
Levels = require 'collections/Levels'
CocoCollection = require 'collections/CocoCollection'
utils = require '../core/utils'

module.exports = class Campaign extends CocoModel
  @className: 'Campaign'
  @schema: schema
  urlRoot: '/db/campaign'
  @denormalizedLevelProperties: _.keys(_.omit(schema.properties.levels.additionalProperties.properties, ['position', 'rewards']))
  @denormalizedCampaignProperties: ['name', 'i18n', 'slug']

  initialize: (options = {}) ->
    @forceCourseNumbering = options.forceCourseNumbering
    super(arguments...)

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

  getLevelNumber: (levelID, defaultNumber) ->
    unless @levelNumberMap
      levels = []
      for level in @getLevels().models when level.get('original')
        practice = @levelIsPractice level
        assessment = @levelIsAssessment level
        levels.push({key: level.get('original'), practice, assessment})
      @levelNumberMap = utils.createLevelNumberMap(levels)
    @levelNumberMap[levelID] ? defaultNumber

  levelIsPractice: (level) ->
    # Migration: in home version, only treat levels explicitly labeled as "Level Name A", "Level Name B", etc. as practice levels
    level = level.attributes if level.attributes
    if @get('type') is 'course' or @forceCourseNumbering
      return level.practice
    else
      return level.practice and / [ABCD]$/.test level.name
  
  levelIsAssessment: (level) ->
    level = level.attributes if level.attributes
    return level.assessment

  updateI18NCoverage: -> super(_.omit(@attributes, 'levels'))
