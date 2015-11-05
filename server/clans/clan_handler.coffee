async = require 'async'
mongoose = require 'mongoose'
Handler = require '../commons/Handler'
AnalyticsLogEvent = require '../analytics/AnalyticsLogEvent'
Clan = require './Clan'
EarnedAchievement = require '../achievements/EarnedAchievement'
EarnedAchievementHandler = require '../achievements/earned_achievement_handler'
LevelSession = require '../levels/sessions/LevelSession'
LevelSessionHandler = require '../levels/sessions/level_session_handler'
User = require '../users/User'
UserHandler = require '../users/user_handler'

memberLimit = 200

ClanHandler = class ClanHandler extends Handler
  modelClass: Clan
  jsonSchema: require '../../app/schemas/models/clan.schema'
  allowedMethods: ['GET', 'POST', 'PUT', 'DELETE']

  hasAccess: (req) ->
    return true if req.method is 'GET'
    return false if req.method is 'POST' and req.body?.type is 'private' and not req.user?.isPremium()
    req.method in @allowedMethods or req.user?.isAdmin()

  hasAccessToDocument: (req, document, method=null) ->
    return false unless document?
    return true if req.user?.isAdmin()
    return true if (method or req.method).toLowerCase() is 'get'
    return true if document.get('ownerID')?.equals req.user?._id
    false

  makeNewInstance: (req) ->
    instance = super(req)
    instance.set 'ownerID', req.user._id
    instance.set 'members', [req.user._id]
    instance.set 'dashboardType', 'premium' if req.body?.type is 'private'
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
          AnalyticsLogEvent.logEvent req.user, 'Clan deleted', clanID: clanID, type: clan.get('type')

  getByRelationship: (req, res, args...) ->
    return @joinClan(req, res, args[0]) if args[1] is 'join'
    return @leaveClan(req, res, args[0]) if args[1] is 'leave'
    return @getMemberAchievements(req, res, args[0]) if args[1] is 'member_achievements'
    return @getMembers(req, res, args[0]) if args[1] is 'members'
    return @getMemberSessions(req, res, args[0]) if args[1] is 'member_sessions'
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
      return @sendNotFoundError(res) unless clan
      return @sendDatabaseError(res, err) unless clanType = clan.get('type')
      return @sendForbiddenError(res) unless clanType is 'public' or req.user.isPremium()
      Clan.update {_id: clanID}, {$addToSet: {members: req.user._id}}, (err) =>
        return @sendDatabaseError(res, err) if err
        User.update {_id: req.user._id}, {$addToSet: {clans: clanID}}, (err) =>
          return @sendDatabaseError(res, err) if err
          @sendSuccess(res)
          AnalyticsLogEvent.logEvent req.user, 'Clan joined', clanID: clanID, type: clanType

  leaveClan: (req, res, clanID) ->
    return @sendForbiddenError(res) unless req.user? and not req.user.isAnonymous()
    try
      clanID = mongoose.Types.ObjectId(clanID)
    catch err
      return @sendNotFoundError(res, err)
    Clan.findById clanID, (err, clan) =>
      return @sendDatabaseError(res, err) if err
      return @sendNotFoundError(res) unless clan
      return @sendForbiddenError(res) if clan.get('ownerID')?.equals req.user._id
      Clan.update {_id: clanID}, {$pull: {members: req.user._id}}, (err) =>
        return @sendDatabaseError(res, err) if err
        User.update {_id: req.user._id}, {$pull: {clans: clanID}}, (err) =>
          return @sendDatabaseError(res, err) if err
          @sendSuccess(res)
          AnalyticsLogEvent.logEvent req.user, 'Clan left', clanID: clanID, type: clan.get('type')

  getMemberAchievements: (req, res, clanID) ->
    # TODO: add tests
    Clan.findById clanID, (err, clan) =>
      return @sendDatabaseError(res, err) if err
      return @sendNotFoundError(res) unless clan
      memberIDs = _.map clan.get('members') ? [], (memberID) -> memberID.toHexString?() or memberID
      User.find {_id: {$in: memberIDs}}, 'nameLower', {limit: memberLimit}, (err, users) =>
        return @sendDatabaseError(res, err) if err
        memberIDs = []
        for user in users
          memberIDs.push user.id
        EarnedAchievement.find {user: {$in: memberIDs}}, 'achievementName user', (err, documents) =>
          return @sendDatabaseError(res, err) if err?
          cleandocs = (EarnedAchievementHandler.formatEntity(req, doc) for doc in documents)
          @sendSuccess(res, cleandocs)

  getMembers: (req, res, clanID) ->
    # TODO: add tests
    Clan.findById clanID, (err, clan) =>
      return @sendDatabaseError(res, err) if err
      return @sendNotFoundError(res) unless clan
      memberIDs = _.map clan.get('members') ? [], (memberID) -> memberID.toHexString?() or memberID
      User.find {_id: {$in: memberIDs}}, 'name nameLower points heroConfig.thangType', {}, (err, users) =>
        return @sendDatabaseError(res, err) if err
        cleandocs = (UserHandler.formatEntity(req, doc) for doc in users)
        @sendSuccess(res, cleandocs)

  getMemberSessions: (req, res, clanID) ->
    # TODO: add tests
    # TODO: restrict information returned based on clan type
    Clan.findById clanID, (err, clan) =>
      return @sendDatabaseError(res, err) if err
      return @sendNotFoundError(res) unless clan
      return @sendForbiddenError(res) unless clan.get('dashboardType') is 'premium'
      memberIDs = _.map clan.get('members') ? [], (memberID) -> memberID.toHexString?() or memberID
      User.find {_id: {$in: memberIDs}}, 'name', {limit: memberLimit}, (err, users) =>
        return @sendDatabaseError(res, err) if err
        memberIDs = []
        for user in users
          memberIDs.push user.id
          break unless memberIDs.length < memberLimit
        LevelSession.find {creator: {$in: memberIDs}}, 'changed codeLanguage creator creatorName levelID levelName playtime state submittedCodeLanguage', (err, documents) =>
          return @sendDatabaseError(res, err) if err?
          cleandocs = (LevelSessionHandler.formatEntity(req, doc) for doc in documents)
          @sendSuccess(res, cleandocs)

  getPublicClans: (req, res) ->
    # Return 100 public clans, sorted by member count, created date
    query = [{ $match : {type : 'public'} }]
    query.push {$project : {_id: 1, name: 1, slug: 1, type: 1, description: 1, memberCount: {$size: "$members"}, ownerID: 1}}
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
      return @sendNotFoundError(res) unless clan
      return @sendForbiddenError res unless @hasAccessToDocument(req, clan)
      return @sendForbiddenError(res) if clan.get('ownerID').equals memberID
      Clan.update {_id: clanID}, {$pull: {members: memberID}}, (err) =>
        return @sendDatabaseError(res, err) if err
        User.update {_id: memberID}, {$pull: {clans: clanID}}, (err) =>
          return @sendDatabaseError(res, err) if err
          @sendSuccess(res)
          AnalyticsLogEvent.logEvent req.user, 'Clan member removed', clanID: clanID, type: clan.get('type'), memberID: memberID

module.exports = new ClanHandler()
