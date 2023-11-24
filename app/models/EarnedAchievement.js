// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let EarnedAchievement
const CocoModel = require('./CocoModel')

module.exports = (EarnedAchievement = (function () {
  EarnedAchievement = class EarnedAchievement extends CocoModel {
    static initClass () {
      this.className = 'EarnedAchievement'
      this.schema = require('schemas/models/earned_achievement')
      this.prototype.urlRoot = '/db/earned_achievement'
    }

    save () {
      if (this.get('earnedRewards') === null) { this.unset('earnedRewards') }
      return super.save(...arguments)
    }
  }
  EarnedAchievement.initClass()
  return EarnedAchievement
})())
