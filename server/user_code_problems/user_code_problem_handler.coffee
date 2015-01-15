UserCodeProblem = require './UserCodeProblem'
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

  getByRelationship: (req, res, args...) ->
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

    # Cache results for 1 day
    @commonLevelProblemsCache ?= {}
    @commonLevelProblemsCachedSince ?= new Date()
    if (new Date()) - @commonLevelProblemsCachedSince > 86400 * 1000  # Dumb cache expiration
      @commonLevelProblemsCache = {}
      @commonLevelProblemsCachedSince = new Date()
    cacheKey = levelSlug
    cacheKey += 's' + startDay if startDay?
    cacheKey += 'e' + endDay if endDay?
    return @sendSuccess res, commonProblems if commonProblems = @commonLevelProblemsCache[cacheKey]

    # Build query
    match = if startDay? or endDay? then {$match: {$and: []}} else {$match: {}}
    match["$match"]["$and"].push _id: {$gte: utils.objectIdFromTimestamp(startDay + "T00:00:00.000Z")} if startDay?
    match["$match"]["$and"].push _id: {$lt: utils.objectIdFromTimestamp(endDay + "T00:00:00.000Z")} if endDay?
    group = {"$group": {"_id": {"errMessage": "$errMessageNoLineInfo", "errHint": "$errHint", "language": "$language", "levelID": "$levelID"}, "count": {"$sum": 1}}}
    sort = { $sort : { "_id.levelID": 1, count : -1, "_id.language": 1 } }
    query = UserCodeProblem.aggregate match, group, sort

    query.exec (err, data) =>
      if err? then return @sendDatabaseError res, err

      # Build per-level common problem lists
      commonProblems = {}
      for item in data
        levelID = item._id.levelID
        commonProblems[levelID] ?= []
        commonProblems[levelID].push
          language: item._id.language
          message: item._id.errMessage
          hint: item._id.errHint
          count: item.count

      # Cache all the levels
      for levelID of commonProblems
        cacheKey = levelID
        cacheKey += 's' + startDay if startDay?
        cacheKey += 'e' + endDay if endDay?
        @commonLevelProblemsCache[cacheKey] = commonProblems[levelID]
      @sendSuccess res, commonProblems[levelSlug]

module.exports = new UserCodeProblemHandler()
