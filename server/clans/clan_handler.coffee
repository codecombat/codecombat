async = require 'async'
mongoose = require 'mongoose'
Handler = require '../commons/Handler'
Clan = require './Clan'

ClanHandler = class ClanHandler extends Handler
  modelClass: Clan
  jsonSchema: require '../../app/schemas/models/Clan.schema'
  allowedMethods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE']

  hasAccess: (req) ->
    return true if req.method in ['GET']
    return true if req.user? and not req.user.isAnonymous()
    false

  hasAccessToDocument: (req, document, method=null) ->
    method = (method or req.method).toLowerCase()
    return true if req.user?.isAdmin()
    return true if method is 'get'
    false

  makeNewInstance: (req) ->
    instance = super(req)
    instance.set 'ownerID', req.user._id
    instance.set 'ownerName', req.user.name
    instance.set 'members', [
      {id: req.user._id, name: req.user.name, level: req.user.level()}
    ]
    instance

module.exports = new ClanHandler()
