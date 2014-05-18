mongoose = require 'mongoose'
jsonschema = require '../../app/schemas/models/earned_achievement'

EarnedAchievementSchema = new mongoose.Schema({
  created:
    type: Date
    default: Date.now
  notified:
    type: Boolean
    default: false
  user:
    type: mongoose.Schema.Types.ObjectId
    ref: 'User'
  achievement:
    type: mongoose.Schema.Types.ObjectId
    ref: 'Achievement'
}, {strict:false})

module.exports = EarnedAchievement = mongoose.model('EarnedAchievement', EarnedAchievementSchema)