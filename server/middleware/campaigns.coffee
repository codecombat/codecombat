utils = require '../lib/utils'
errors = require '../commons/errors'
wrap = require 'co-express'
Promise = require 'bluebird'
database = require '../commons/database'
mongoose = require 'mongoose'
Campaign = require '../models/Campaign'
parse = require '../commons/parse'
LevelSession = require '../models/LevelSession'
slack = require '../slack'

module.exports =
  fetchByType: wrap (req, res, next) ->
    type = req.query.type
    return next() unless type
    unless _.contains(Campaign.jsonSchema.properties.type.enum, type)
      throw new errors.UnprocessableEntity('Bad campaign type')
    dbq = Campaign.find { type: type }
    dbq.select(parse.getProjectFromReq(req))
    campaigns = yield dbq.exec()
    campaigns = (campaign.toObject({req: req}) for campaign in campaigns)
    res.status(200).send(campaigns)

  put: wrap (req, res) ->
    campaign = yield database.getDocFromHandle(req, Campaign)
    if not campaign
      throw new errors.NotFound('Campaign not found.')
    levelsBefore = _.keys(campaign.get('levels'))
    hasPermission = req.user.isAdmin()
    unless hasPermission or database.isJustFillingTranslations(req, campaign)
      throw new errors.Forbidden('Must be an admin or submitting translations to edit a campaign')

    database.assignBody(req, campaign)
    database.validateDoc(campaign)
    levelsAfter = _.keys(campaign.get('levels'))
    if not _.isEqual(levelsBefore, levelsAfter)
      campaign.set('levelsUpdated', new Date())
    campaign = yield campaign.save()
    res.status(200).send(campaign.toObject())
    docLink = "http://codecombat.com#{req.headers['x-current-path']}"
    slack.sendChangedSlackMessage creator: req.user, target: campaign, docLink: docLink
