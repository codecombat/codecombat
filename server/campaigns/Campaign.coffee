mongoose = require('mongoose')
plugins = require('../plugins/plugins')

NestedLevelSchema = new mongoose.Schema(
  name: String
  description: String
  thumbnail: Buffer
  original: {type: mongoose.Schema.ObjectId, ref: 'level'}
  majorVersion: Number
)

CampaignSchema = new mongoose.Schema(
  description: String
  levels: [NestedLevelSchema]
)

CampaignSchema.plugin(plugins.NamedPlugin)
CampaignSchema.plugin(plugins.PermissionsPlugin)
CampaignSchema.plugin(plugins.SearchablePlugin, {searchable: ['name', 'description']})

module.exports = Campaign = mongoose.model('campaign', CampaignSchema)

