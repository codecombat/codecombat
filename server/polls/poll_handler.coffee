Poll = require './Poll'
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

  getNextPoll: (req, res, lastPollID) ->
    @findPollPriority lastPollID, (err, lastPriority) =>
      return @sendDatabaseError(res, err) if err
      @getNextPollAfterPriority lastPriority, (err, poll) =>
        return @sendDatabaseError(res, err) if err
        return @sendNotFoundError(res) unless poll
        @sendSuccess res, @formatEntity(req, poll)

  findPollPriority: (lastPollID, callback) ->
    return callback null, -9001 #unless lastPollID
    Poll.findById mongoose.Types.ObjectId(lastPollID), 'priority', {lean: true}, (err, poll) ->
      callback err, poll?.priority

  getNextPollAfterPriority: (priority, callback) ->
    Poll.findOne({priority: {$gt: priority}}).sort('priority').exec callback

  delete: (req, res, slugOrID) ->
    return @sendForbiddenError res unless req.user?.isAdmin()
    @getDocumentForIdOrSlug slugOrID, (err, document) =>
      return @sendDatabaseError(res, err) if err
      return @sendNotFoundError(res) unless document?
      document.remove (err, document) =>
        return @sendDatabaseError(res, err) if err
        @sendNoContent res

module.exports = new PollHandler()
