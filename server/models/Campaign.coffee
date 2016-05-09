mongoose = require 'mongoose'
plugins = require '../plugins/plugins'
log = require 'winston'
config = require '../../server_config'
jsonSchema = require '../../app/schemas/models/campaign.schema.coffee'

CampaignSchema = new mongoose.Schema(body: String, {strict: false,read:config.mongo.readpref})

CampaignSchema.index({i18nCoverage: 1}, {name: 'translation coverage index', sparse: true})
CampaignSchema.index({slug: 1}, {name: 'slug index', sparse: true, unique: true})
CampaignSchema.index({type: 1}, {name: 'type index', sparse: true})

CampaignSchema.plugin(plugins.NamedPlugin)
CampaignSchema.plugin(plugins.TranslationCoveragePlugin)
CampaignSchema.plugin plugins.PatchablePlugin

CampaignSchema.statics.updateAdjacentCampaigns = (savedCampaign) ->
  Campaign = require './Campaign'
  query = {}
  query["adjacentCampaigns.#{savedCampaign.get '_id'}"] = {$exists: true}
  Campaign.find(query).exec (err, campaigns) ->
    return log.error "Couldn't search for adjacent campaigns to update because of #{err}" if err
    for campaign in campaigns
      acs = campaign.get 'adjacentCampaigns'
      ac = acs[savedCampaign.get '_id']
      # Let's make sure that we're adding translations, otherwise let's not update yet.
      # We could possibly remove this; not sure it's worth having.
      [oldI18NCount, newI18NCount] = [0, 0]
      oldI18NCount += _.size(translations) for lang, translations of ac.i18n ? {}
      newI18NCount += _.size(translations) for lang, translations of savedCampaign.get('i18n') ? {}
      continue unless newI18NCount > oldI18NCount
      ac.i18n = savedCampaign.get('i18n')
      # Save without using middleware so that we don't get into a post-save loop.
      Campaign.findByIdAndUpdate campaign._id, {$set: {adjacentCampaigns: acs}}, (err, doc) ->
        return log.error "Couldn't save updated adjacent campaign because of #{err}" if err

CampaignSchema.pre 'save', (done) ->
  if not @get('levelsUpdated')
    @set('levelsUpdated', @_id.getTimestamp())
  done()
  
CampaignSchema.post 'save', -> @constructor.updateAdjacentCampaigns @

CampaignSchema.statics.jsonSchema = jsonSchema
CampaignSchema.statics.editableProperties = [
  'name'
  'fullName'
  'description'
  'type'
  'i18n'
  'i18nCoverage'
  'ambientSound'
  'backgroundImage'
  'backgroundColor'
  'backgroundColorTransparent'
  'adjacentCampaigns'
  'levels'
]

module.exports = mongoose.model('campaign', CampaignSchema)
