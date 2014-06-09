mongoose = require 'mongoose'
jsonschema = require '../../app/schemas/models/earned_achievement'

EarnedAchievementSchema = new mongoose.Schema({
  created:
    type: Date
    default: Date.now
  changed:
    type: Date
    default: Date.now
  notified:
    type: Boolean
    default: false
}, {strict:false})

EarnedAchievementSchema.pre 'save', (next) ->
  @set('changed', Date.now())
  next()

EarnedAchievementSchema.index({user: 1, achievement: 1}, {unique: true, name: 'earned achievement index'})
EarnedAchievementSchema.index({user: 1, changed: -1}, {name: 'latest '})


module.exports = EarnedAchievement = mongoose.model('EarnedAchievement', EarnedAchievementSchema)



