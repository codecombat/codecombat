mongoose = require 'mongoose'
jsonschema = require '../../app/schemas/models/earned_achievement'

EarnedAchievementSchema = new mongoose.Schema({
  created:
    type: Date
    default: Date.now
  notified:
    type: Boolean
    default: false
}, {strict:false})

module.exports = EarnedAchievement = mongoose.model('earned_achievement', EarnedAchievementSchema)