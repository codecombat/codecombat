CampaignStatus = require('./CampaignStatus')
Handler = require('../commons/Handler')

CampaignStatusHandler = class CampaignStatusHandler extends Handler
  modelClass: CampaignStatus
  editableProperties: ['levelStatuses']
  postEditableProperties: ['campaign', 'user']
  
  post: (req, res) ->
    req.body.user = req.user._id
    super(req, res)

module.exports = new CampaignStatusHandler()
