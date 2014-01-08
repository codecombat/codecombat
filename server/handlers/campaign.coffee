winston = require('winston')
request = require('request')
Campaign = require('../models/Campaign')
Handler = require('./Handler')

CampaignHandler = class CampaignHandler extends Handler
  modelClass: Campaign
  editableProperties: ['name', 'description', 'levels']



module.exports = new CampaignHandler()