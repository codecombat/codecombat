async = require 'async'
mongoose = require 'mongoose'
Handler = require '../commons/Handler'
Clan = require './Clan'
EarnedAchievement = require '../achievements/EarnedAchievement'
User = require '../users/User'
UserHandler = require '../users/user_handler'

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
    return true if document.get('ownerID')?.equals req.user._id
    false

  makeNewInstance: (req) ->
    userName = req.user.get('name') ? 'Anoner'
    instance = super(req)
    instance.set 'ownerID', req.user._id
    instance.set 'members', [req.user._id]
    instance

  delete: (req, res, clanID) ->
    @getDocumentForIdOrSlug clanID, (err, clan) =>
      return @sendDatabaseError res, err if err
      return @sendNotFoundError res unless clan
      return @sendForbiddenError res unless @hasAccessToDocument(req, clan)
      memberIDs = clan.get('members')
      Clan.remove {_id: clan.get('_id')}, (err) =>
        return @sendDatabaseError res, err if err
        User.update {_id: {$in: memberIDs}}, {$pull: {clans: clan.get('_id')}}, {multi: true}, (err) =>
          return @sendDatabaseError(res, err) if err
          @sendNoContent(res)

  getByRelationship: (req, res, args...) ->
    return @joinClan(req, res, args[0]) if args[1] is 'join'
    return @leaveClan(req, res, args[0]) if args[1] is 'leave'
    return @getMemberAchievements(req, res, args[0]) if args[1] is 'member_achievements'
    return @getMembers(req, res, args[0]) if args[1] is 'members'
    return @getPublicClans(req, res) if args[1] is 'public'
    return @removeMember(req, res, args[0], args[2]) if args.length is 3 and args[1] is 'remove'
    super(arguments...)

  joinClan: (req, res, clanID) ->
    return @sendForbiddenError(res) unless req.user? and not req.user.isAnonymous()
    try
      clanID = mongoose.Types.ObjectId(clanID)
    catch err
      return @sendNotFoundError(res, err)
    Clan.findById clanID, (err, clan) =>
      return @sendDatabaseError(res, err) if err
      Clan.update {_id: clanID}, {$addToSet: {members: req.user._id}}, (err) =>
        return @sendDatabaseError(res, err) if err
        User.update {_id: req.user._id}, {$addToSet: {clans: clanID}}, (err) =>
          return @sendDatabaseError(res, err) if err
          @sendSuccess(res)

  leaveClan: (req, res, clanID) ->
    return @sendForbiddenError(res) unless req.user? and not req.user.isAnonymous()
    try
      clanID = mongoose.Types.ObjectId(clanID)
    catch err
      return @sendNotFoundError(res, err)
    Clan.findById clanID, (err, clan) =>
      return @sendDatabaseError(res, err) if err
      return @sendForbiddenError(res) if clan.get('ownerID')?.equals req.user._id
      Clan.update {_id: clanID}, {$pull: {members: req.user._id}}, (err) =>
        return @sendDatabaseError(res, err) if err
        User.update {_id: req.user._id}, {$pull: {clans: clanID}}, (err) =>
          return @sendDatabaseError(res, err) if err
          @sendSuccess(res)

  getMemberAchievements: (req, res, clanID) ->
    # TODO: add tests
    Clan.findById clanID, (err, clans) =>
      return @sendDatabaseError(res, err) if err
      memberIDs = _.map clans.get('members') ? [], (memberID) -> memberID.toHexString()
      EarnedAchievement.find {user: {$in: memberIDs}}, (err, documents) =>
        return @sendDatabaseError(res, err) if err?
        cleandocs = (@formatEntity(req, doc) for doc in documents)
        @sendSuccess(res, cleandocs)

  getMembers: (req, res, clanID) ->
    # TODO: add tests
    return @sendForbiddenError(res) unless req.user? and not req.user.isAnonymous()
    clanIDs = req.user.get('clans') ? []
    Clan.findById clanID, (err, clans) =>
      return @sendDatabaseError(res, err) if err
      memberIDs = clans.get('members') ? []
      User.find {_id: {$in: memberIDs}}, (err, users) =>
        return @sendDatabaseError(res, err) if err
        cleandocs = (UserHandler.formatEntity(req, doc) for doc in users)
        @sendSuccess(res, cleandocs)

  getPublicClans: (req, res) ->
    # Return 100 public clans, sorted by member count, created date
    query = [{ $match : {type : 'public'} }]
    query.push {$project : {_id: 1, name: 1, slug: 1, type: 1, members: 1, memberCount: {$size: "$members"}, ownerID: 1}}
    query.push {$sort: { memberCount: -1, _id: -1 }}
    query.push {$limit: 100}
    Clan.aggregate(query).exec (err, documents) =>
      return @sendDatabaseError(res, err) if err
      @sendSuccess(res, documents)

  removeMember: (req, res, clanID, memberID) ->
    return @sendForbiddenError(res) unless req.user? and not req.user.isAnonymous()
    try
      clanID = mongoose.Types.ObjectId(clanID)
      memberID = mongoose.Types.ObjectId(memberID)
    catch err
      return @sendNotFoundError(res, err)
    Clan.findById clanID, (err, clan) =>
      return @sendDatabaseError(res, err) if err
      return @sendForbiddenError res unless @hasAccessToDocument(req, clan)
      return @sendForbiddenError(res) if clan.get('ownerID').equals memberID
      Clan.update {_id: clanID}, {$pull: {members: memberID}}, (err) =>
        return @sendDatabaseError(res, err) if err
        User.update {_id: memberID}, {$pull: {clans: clanID}}, (err) =>
          return @sendDatabaseError(res, err) if err
          @sendSuccess(res)

module.exports = new ClanHandler()
