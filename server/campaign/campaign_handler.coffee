Campaign = require './Campaign'
Handler = require '../commons/Handler'

CampaignHandler = class CampaignHandler extends Handler
  modelClass: Campaign
  editableProperties: [
    'name'
    'i18n'
    'i18nCoverage'
    'ambientSound'
    'backgroundImage'
    'backgroundColor'
    'backgroundColorTransparent'
    'adjacentCampaigns'
    'levels'
  ]
  jsonSchema: require '../../app/schemas/models/campaign.schema'

  hasAccess: (req) ->
    req.method is 'GET' or req.user?.isAdmin()

module.exports = new CampaignHandler()
