const CocoModel = require('./CocoModel')
const schema = require('schemas/models/earned_achievement')

class EarnedAchievement extends CocoModel {
  constructor () {
    super()
    this.className = 'EarnedAchievement'
    this.schema = schema
    this.urlRoot = '/db/earned_achievement'
  }

  save () {
    if (this.get('earnedRewards') === null) {
      this.unset('earnedRewards')
    }
    return super.save(...arguments)
  }
}

module.exports = EarnedAchievement
