CocoModel = require './CocoModel'
schema = require 'schemas/models/campaign.schema'
Level = require 'models/Level'
Levels = require 'collections/Levels'
CocoCollection = require 'collections/CocoCollection'
utils = require '../core/utils'
api = require 'core/api'

module.exports = class Campaign extends CocoModel
  @className: 'Campaign'
  @schema: schema
  urlRoot: '/db/campaign'
  @denormalizedLevelProperties: _.keys(_.omit(schema.properties.levels.additionalProperties.properties, ['position', 'rewards', 'first', 'nextLevels', 'campaignPage', 'releasePhase', 'moduleNum']))
  @denormalizedCampaignProperties: ['name', 'i18n', 'slug']
  @nextLevelProperties: ['original', 'name', 'slug', 'type']

  initialize: (options = {}) ->
    @forceCourseNumbering = options.forceCourseNumbering
    super(arguments...)

  @getLevels: (campaign) ->
    levels = campaign.levels
    levels = _.sortBy(levels, 'campaignIndex')
    if not me.isAdmin() and me.isInternal()
      # remove beta levels
      levels = levels.filter((l) => l.releasePhase != 'beta')
    else if not me.isAdmin() and not me.isInternal() and not utils.internalCampaignIds.includes(campaign._id)
      # remove beta+internal levels
      levels = levels.filter((l) => l.releasePhase != 'beta' && l.releasePhase != 'internalRelease')
    return levels

  getLevels: ->
    return new Levels(Campaign.getLevels(@toJSON()))

  getLevelsByModules: ->
    campaignId = @get('_id')
    isCh1 = utils.freeCampaignIds.includes(campaignId)
    levels = @getLevels().models
    campaignLevels = {}
    campaignLevels[campaignId] = {
      modules: utils.buildLevelsListByModule(levels, isCh1)
    }
    return campaignLevels

  @fetchIntroContentDataForLevels: (campaignLevelsModuleMap) ->
    introLevels = []
    for campaignId, campaignModules of campaignLevelsModuleMap
      for moduleNum, levels of campaignModules.modules
        introLevels = introLevels.concat(levels.filter((l) => l.get('introContent')))
    api.levels.fetchIntroContent(introLevels)
    .then (introLevelContentMap) =>
      introLevels.forEach((l) =>
        utils.addIntroLevelContent(l, introLevelContentMap)
      )

  getNonLadderLevels: ->
    levels = new Levels(_.values(@get('levels')))
    levels.reset(levels.reject (level) -> level.isLadder())
    levels.comparator = 'campaignIndex'
    levels.sort()
    return levels

  @getLevelNumberMap: (campaign, forceCourseNumbering) ->
    levels = []
    for level in @getLevels(campaign)
      continue unless level.original
      practice = @levelIsPractice(level, (campaign.type is 'course') or forceCourseNumbering)
      assessment = @levelIsAssessment level
      levels.push({key: level.original, practice, assessment})
    return utils.createLevelNumberMap(levels)

  getLevelNameMap: () ->
    levelNameMap = {}
    @getLevels().models.map((l) => levelNameMap[l.get('original')] = utils.i18n(l.attributes, 'name'))
    return levelNameMap

  getLevelNumber: (levelID, defaultNumber) ->
    @levelNumberMap ?= Campaign.getLevelNumberMap(@attributes)
    @levelNumberMap[levelID] ? defaultNumber

  @levelIsPractice: (level, forceCourseNumbering) ->
    # Migration: in home version, only treat levels explicitly labeled as "Level Name A", "Level Name B", etc. as practice levels
    # See: https://github.com/codecombat/codecombat/commit/296d2c940d8ecd729d098e45e203e2b1182ff86a
    if forceCourseNumbering
      return level.practice
    else
      return level.practice and / [ABCD]$/.test level.name

  levelIsPractice: (level) ->
    level = level.attributes if level.attributes
    return Campaign.levelIsPractice(level, @get('type') is 'course' or @forceCourseNumbering)

  levelIsAssessment: (level) ->
    level = level.attributes if level.attributes
    return Campaign.levelIsAssessment(level)

  @levelIsAssessment: (level) -> level.assessment


  updateI18NCoverage: -> super(_.omit(@attributes, 'levels'))
