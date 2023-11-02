const CocoModel = require('./CocoModel')
const schema = require('schemas/models/earned_achievement')

class EarnedAchievement extends CocoModel {
  constructor () {
    super()
  }

  save () {
    if (this.get('earnedRewards') === null) {
      this.unset('earnedRewards')
    }
    return super.save(...arguments)
  }
}

EarnedAchievement.className = 'EarnedAchievement'
EarnedAchievement.schema = schema
EarnedAchievement.prototype.urlRoot = '/db/earned_achievement'

module.exports = EarnedAchievement
