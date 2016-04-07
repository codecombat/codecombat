UserPollsRecord = require './../models/UserPollsRecord'
Handler = require '../commons/Handler'
async = require 'async'
mongoose = require 'mongoose'

UserPollsRecordHandler = class UserPollsRecordHandler extends Handler
  modelClass: UserPollsRecord
  jsonSchema: require '../../app/schemas/models/user-polls-record.schema'

  hasAccess: (req) ->
    req.user and (req.method in ['GET', 'POST', 'PUT'] or req.user?.isAdmin())

  hasAccessToDocument: (req, document, method=null) ->
    req.user?.isAdmin() or req.user?._id.equals document.get('user')

  getByRelationship: (req, res, args...) ->
    relationship = args[1]
    return @getUserPollsRecord(req, res, args[2]) if relationship is 'user'
    super arguments...

  getUserPollsRecord: (req, res, userID) ->
    UserPollsRecord.findOne(user: userID).exec (err, doc) =>
      return @sendDatabaseError(res, err) if err
      return @sendSuccess(res, doc) if doc?
      @createAndSaveNewUserPollsRecord userID, req, res

  createAndSaveNewUserPollsRecord: (userID, req, res) =>
    return @sendForbiddenError(res) unless req.user
    initVals = user: userID, polls: {}, level: req.user.level()
    userPollsRecord = new UserPollsRecord initVals
    userPollsRecord.save (err) =>
      return @sendDatabaseError(res, err) if err
      @sendSuccess(res, @formatEntity(req, userPollsRecord))

  saveChangesToDocument: (req, document, done) ->
    document.set 'level', req.user.level()
    super req, document, done


module.exports = new UserPollsRecordHandler()
