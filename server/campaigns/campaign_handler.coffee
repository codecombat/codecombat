Campaign = require('./Campaign')
Handler = require('../commons/Handler')

CampaignHandler = class CampaignHandler extends Handler
  modelClass: Campaign
  editableProperties: ['name', 'description', 'levels']



module.exports = new CampaignHandler()