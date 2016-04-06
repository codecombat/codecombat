UserCodeProblem = require './../models/UserCodeProblem'
Handler = require '../commons/Handler'
utils = require '../lib/utils'

class UserCodeProblemHandler extends Handler
  modelClass: UserCodeProblem
  jsonSchema: require '../../app/schemas/models/user_code_problem'
  editableProperties: [
    'code'
    'codeSnippet'
    'errHint'
    'errId'
    'errLevel'
    'errMessage'
    'errMessageNoLineInfo'
    'errRange'
    'errType'
    'language'
    'levelID'
  ]

  makeNewInstance: (req) ->
    ucp = super(req)
    ucp.set('creator', req.user._id)
    ucp

  hasAccess: (req) ->
    return true if req.user?.isAdmin()
    return true if req.method.toLowerCase() is 'post'
    false

  getByRelationship: (req, res, args...) ->
    return @sendForbiddenError res unless @hasAccess req
    return @getCommonLevelProblemsBySlug(req, res) if args[1] is 'common_problems'
    super(arguments...)

  getCommonLevelProblemsBySlug: (req, res) ->
    # Returns an ordered array of common user code problems with: language, message, hint, count
    # Parameters:
    # slug - level slug
    # startDay - Inclusive, optional, e.g. '2014-12-14'
    # endDay - Exclusive, optional, e.g. '2014-12-16'

    levelSlug = req.query.slug or req.body.slug
    startDay = req.query.startDay or req.body.startDay
    endDay = req.query.endDay or req.body.endDay

    return @sendSuccess res, [] unless levelSlug?

    # Build query
    match = if startDay? or endDay? then {$match: {$and: [levelID: levelSlug]}} else {$match: {levelID: levelSlug}}
    match["$match"]["$and"].push _id: {$gte: utils.objectIdFromTimestamp(startDay + "T00:00:00.000Z")} if startDay?
    match["$match"]["$and"].push _id: {$lt: utils.objectIdFromTimestamp(endDay + "T00:00:00.000Z")} if endDay?
    limit = {$limit: 100000}
    group = {"$group": {"_id": {"errMessage": "$errMessageNoLineInfo", "errHint": "$errHint", "language": "$language", "levelID": "$levelID"}, "count": {"$sum": 1}}}
    sort = { $sort : { "_id.levelID": 1, count : -1, "_id.language": 1 } }
    query = UserCodeProblem.aggregate match, limit, group, sort
    query.cache(30 * 60 * 1000)

    query.exec (err, data) =>
      if err? then return @sendDatabaseError res, err
      formatted = ({language: item._id.language, message: item._id.errMessage, hint: item._id.errHint, count: item.count} for item in data)
      @sendSuccess res, formatted

module.exports = new UserCodeProblemHandler()
