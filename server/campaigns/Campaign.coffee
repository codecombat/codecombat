mongoose = require 'mongoose'
plugins = require '../plugins/plugins'

CampaignSchema = new mongoose.Schema(body: String, {strict: false})

CampaignSchema.index({i18nCoverage: 1}, {name: 'translation coverage index', sparse: true})
CampaignSchema.index({slug: 1}, {name: 'slug index', sparse: true, unique: true})

CampaignSchema.plugin(plugins.NamedPlugin)
CampaignSchema.plugin(plugins.TranslationCoveragePlugin)

module.exports = mongoose.model('campaign', CampaignSchema)
