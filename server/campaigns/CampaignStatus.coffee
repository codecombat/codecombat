mongoose = require('mongoose')

LevelStatusSchema = new mongoose.Schema(
  lastPlayed: Date
  victorious: Boolean
  original: {type: mongoose.Schema.ObjectId, ref: 'level'}
  majorVersion: Number
)

CampaignStatusSchema = new mongoose.Schema(
  user: {type: mongoose.Schema.ObjectId, ref: 'User'}
  campaign: {type: mongoose.Schema.ObjectId, ref: 'campaign'}
  levelStatuses: [LevelStatusSchema]
)
CampaignStatusSchema.index {user: 1, campaign: 1}, {unique: true}

module.exports = CampaignStatus = mongoose.model('campaign.status', CampaignStatusSchema)