// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let Campaign
const CocoModel = require('./CocoModel')
const schema = require('schemas/models/campaign.schema')
const Levels = require('collections/Levels')
const utils = require('../core/utils')
const api = require('core/api')
const levelUtils = require('../core/levelUtils')

module.exports = (Campaign = (function () {
  Campaign = class Campaign extends CocoModel {
    static initClass () {
      this.className = 'Campaign'
      this.schema = schema
      this.prototype.urlRoot = '/db/campaign'
      this.denormalizedLevelProperties = _.keys(_.omit(schema.properties.levels.additionalProperties.properties, ['position', 'rewards', 'first', 'nextLevels', 'campaignPage', 'releasePhase', 'moduleNum']))
      this.denormalizedCampaignProperties = ['name', 'i18n', 'slug']
      this.nextLevelProperties = ['original', 'name', 'slug', 'type', 'permissions']
    }

    initialize (options) {
      if (options == null) { options = {} }
      this.forceCourseNumbering = options.forceCourseNumbering
      return super.initialize(...arguments)
    }

    static getLevels (campaign) {
      let {
        levels
      } = campaign
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
      this.getLevels().models.forEach(l => { levelNameMap[l.get('original')] = utils.i18n(l.attributes, 'name') })
      return levelNameMap
    }

    getLevelNumber (levelID, defaultNumber) {
      if (this.levelNumberMap == null) { this.levelNumberMap = Campaign.getLevelNumberMap(this.attributes) }
      return this.levelNumberMap[levelID] != null ? this.levelNumberMap[levelID] : defaultNumber
    }

    static levelIsPractice (level, forceCourseNumbering) {
      // Migration: in home version, only treat levels explicitly labeled as "Level Name A", "Level Name B", etc. as practice levels
      // See: https://github.com/codecombat/codecombat/commit/296d2c940d8ecd729d098e45e203e2b1182ff86a
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

    updateI18NCoverage () { return super.updateI18NCoverage(_.omit(this.attributes, 'levels')) }
  }
  Campaign.initClass()
  return Campaign
})())
