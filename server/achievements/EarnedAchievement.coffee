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

# Maybe consider indexing on changed: -1 as well?
EarnedAchievementSchema.index({user: 1, achievement: 1}, {unique: true, name: 'earned achievement index'})

module.exports = EarnedAchievement = mongoose.model('EarnedAchievement', EarnedAchievementSchema)