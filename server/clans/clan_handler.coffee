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
    userName = req.user.get('name') ? 'Anoner'
    instance = super(req)
    instance.set 'ownerID', req.user._id
    instance.set 'ownerName', userName
    instance.set 'members', [
      {id: req.user._id, name: userName, level: req.user.level()}
    ]
    instance

  getByRelationship: (req, res, args...) ->
    return @joinClan(req, res, args[0]) if args[1] is 'join'
    super(arguments...)

  joinClan: (req, res, clanID) ->
    return @sendForbiddenError(res) unless req.user? and not req.user.isAnonymous()
    Clan.findById clanID, (err, clan) =>
      return @sendSuccess(res, clan) if _.find clan.get('members'), (m) -> m.id.equals req.user.id
      member =
        id: req.user._id
        name: req.user.get('name') ? 'Anoner'
        level: req.user.level()
      Clan.update {_id: clanID}, {$push: {members: member}}, (err) =>
        return @sendDatabaseError(res, err) if err
        @sendSuccess(res)

module.exports = new ClanHandler()
