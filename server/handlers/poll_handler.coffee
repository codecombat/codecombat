Poll = require './../models/Poll'
UserPollsRecord = require './../models/UserPollsRecord'
Handler = require '../commons/Handler'
async = require 'async'
mongoose = require 'mongoose'

PollHandler = class PollHandler extends Handler
  modelClass: Poll
  jsonSchema: require '../../app/schemas/models/poll.schema'
  allowedMethods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE']

  hasAccess: (req) ->
    req.method in ['GET', 'PUT'] or req.user?.isAdmin()

  hasAccessToDocument: (req, document, method=null) ->
    method = (method or req.method).toLowerCase()
    return true if req.user?.isAdmin()
    return true if method is 'get'
    return true if method in ['post', 'put'] and @isJustFillingTranslations req, document
    false

  getByRelationship: (req, res, args...) ->
    relationship = args[1]
    return @getNextPoll(req, res, args[0]) if relationship is 'next'
    super arguments...

  getNextPoll: (req, res, userPollsRecordID) ->
    if userPollsRecordID and userPollsRecordID isnt '-'
      UserPollsRecord.findOne(_id: mongoose.Types.ObjectId(userPollsRecordID)).lean().exec (err, userPollsRecord) =>
        return @sendDatabaseError(res, err) if err
        answeredPolls = _.keys(userPollsRecord?.polls ? {})
        @getNextUnansweredPoll req, res, answeredPolls
    else
      @getNextUnansweredPoll req, res, []

  getNextUnansweredPoll: (req, res, answeredPolls) ->
    if answeredPolls.length
      query = {_id: {$nin: (mongoose.Types.ObjectId(pollID) for pollID in answeredPolls)}}
    else
      query = {}
    Poll.findOne(query).sort('priority').exec (err, poll) =>
      return @sendDatabaseError(res, err) if err
      return @sendNotFoundError(res) unless poll
      @sendSuccess res, @formatEntity(req, poll)

  delete: (req, res, slugOrID) ->
    return @sendForbiddenError res unless req.user?.isAdmin()
    @getDocumentForIdOrSlug slugOrID, (err, document) =>
      return @sendDatabaseError(res, err) if err
      return @sendNotFoundError(res) unless document?
      document.remove (err, document) =>
        return @sendDatabaseError(res, err) if err
        @sendNoContent res

  getNamesByIDs: (req, res) -> @getNamesByOriginals req, res, true

module.exports = new PollHandler()
