utils = require '../lib/utils'
errors = require '../commons/errors'
wrap = require 'co-express'
Promise = require 'bluebird'
database = require '../commons/database'
mongoose = require 'mongoose'
Campaign = require '../models/Campaign'
parse = require '../commons/parse'
LevelSession = require '../models/LevelSession'

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
