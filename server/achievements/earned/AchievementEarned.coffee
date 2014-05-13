mongoose = require 'mongoose'
jsonschema = require '../../../app/schemas/models/achievement_earned'

AchievementEarnedSchema = new mongoose.Schema({
  user: Object
}, {strict:false})

module.exports = AchievementEarned = mongoose.model('achievements.earned', AchievementEarnedSchema)