mongoose = require 'mongoose'
plugins = require '../plugins/plugins'

CampaignSchema = new mongoose.Schema(body: String, {strict:false, minimize: false})

CampaignSchema.plugin(plugins.NamedPlugin)
CampaignSchema.plugin(plugins.TranslationCoveragePlugin)

module.exports = mongoose.model('campaign', CampaignSchema)
