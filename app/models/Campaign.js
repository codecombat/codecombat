const CocoModel = require('./CocoModel')
const schema = require('schemas/models/campaign.schema')
const _ = require('lodash')
const utils = require('core/utils')
const Levels = require('collections/Levels')
const levelUtils = require('core/levelUtils')
const api = require('core/api')

class Campaign extends CocoModel {
  constructor (options = {}) {
    super()
    this.forceCourseNumbering = options.forceCourseNumbering
  }

  static getLevels (campaign) {
    let { levels } = campaign
    levels = _.sortBy(levels, 'campaignIndex')
    if (utils.isOzaria) {
      if (!me.isAdmin() && me.isInternal()) {
        // remove beta levels
        levels = levels.filter(l => l.releasePhase !== 'beta')
      } else if (!me.isAdmin() && !me.isInternal() && !utils.internalCampaignIds.includes(campaign._id)) {
        // remove beta+internal levels
        levels = levels.filter(l => (l.releasePhase !== 'beta') && (l.releasePhase !== 'internalRelease'))
      }
    }
    return levels
  }

  getLevels () {
    return new Levels(Campaign.getLevels(this.toJSON()))
  }

  getLevelsByModules () {
    const campaignId = this.get('_id')
    const isCh1 = utils.freeCampaignIds.includes(campaignId)
    const levels = this.getLevels().models
    const campaignLevels = {}
    campaignLevels[campaignId] = {
      modules: levelUtils.buildLevelsListByModule(levels, isCh1)
    }
    return campaignLevels
  }

  static fetchIntroContentDataForLevels (campaignLevelsModuleMap) {
    let levels
    let introLevels = []
    for (const campaignId in campaignLevelsModuleMap) {
      const campaignModules = campaignLevelsModuleMap[campaignId]
      for (const moduleNum in campaignModules.modules) {
        levels = campaignModules.modules[moduleNum]
        introLevels = introLevels.concat(levels.filter(l => l.get('introContent')))
      }
    }
    return api.levels.fetchIntroContent(introLevels)
      .then(introLevelContentMap => {
        return introLevels.forEach(l => {
          return utils.addIntroLevelContent(l, introLevelContentMap)
        })
      })
  }

  getNonLadderLevels () {
    const levels = new Levels(_.values(this.get('levels')))
    levels.reset(levels.reject(level => level.isLadder()))
    levels.comparator = 'campaignIndex'
    levels.sort()
    return levels
  }

  static getLevelNumberMap (campaign, forceCourseNumbering) {
    const levels = []
    for (const level of Array.from(this.getLevels(campaign))) {
      if (!level.original) { continue }
      const practice = this.levelIsPractice(level, (campaign.type === 'course') || forceCourseNumbering)
      const assessment = this.levelIsAssessment(level)
      levels.push({ key: level.original, practice, assessment })
    }
    return utils.createLevelNumberMap(levels)
  }

  getLevelNameMap () {
    const levelNameMap = {}
    this.getLevels().models.map(l => {
      levelNameMap[l.get('original')] = utils.i18n(l.attributes, 'name')
      return levelNameMap[l.get('original')]
    })
    return levelNameMap
  }

  getLevelNumber (levelID, defaultNumber) {
    if (this.levelNumberMap == null) { this.levelNumberMap = Campaign.getLevelNumberMap(this.attributes) }
    return this.levelNumberMap[levelID] != null ? this.levelNumberMap[levelID] : defaultNumber
  }

  static levelIsPractice (level, forceCourseNumbering) {
    if (forceCourseNumbering) {
      return level.practice
    } else {
      return level.practice && / [ABCD]$/.test(level.name)
    }
  }

  levelIsPractice (level) {
    if (level.attributes) { level = level.attributes }
    return Campaign.levelIsPractice(level, (this.get('type') === 'course') || this.forceCourseNumbering)
  }

  levelIsAssessment (level) {
    if (level.attributes) { level = level.attributes }
    return Campaign.levelIsAssessment(level)
  }

  static levelIsAssessment (level) { return level.assessment }

  updateI18NCoverage () {
    return super.updateI18NCoverage(_.omit(this.attributes, 'levels'))
  }
}

Campaign.className = 'Campaign'
Campaign.schema = schema
Campaign.denormalizedLevelProperties = _.keys(_.omit(schema.properties.levels.additionalProperties.properties, ['position', 'rewards', 'first', 'nextLevels', 'campaignPage', 'releasePhase', 'moduleNum']))
Campaign.denormalizedCampaignProperties = ['name', 'i18n', 'slug']
Campaign.nextLevelProperties = ['original', 'name', 'slug', 'type', 'permissions']
Campaign.prototype.urlRoot = '/db/campaign'

module.exports = Campaign
