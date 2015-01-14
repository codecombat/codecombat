Level = require './Level'
Session = require './sessions/LevelSession'
User = require '../users/User'
SessionHandler = require './sessions/level_session_handler'
Feedback = require './feedbacks/LevelFeedback'
Handler = require '../commons/Handler'
mongoose = require 'mongoose'
async = require 'async'
utils = require '../lib/utils'

LevelHandler = class LevelHandler extends Handler
  modelClass: Level
  jsonSchema: require '../../app/schemas/models/level'
  editableProperties: [
    'description'
    'documentation'
    'background'
    'nextLevel'
    'scripts'
    'thangs'
    'systems'
    'victory'
    'name'
    'i18n'
    'icon'
    'goals'
    'type'
    'showsGuide'
    'banner'
    'employerDescription'
    'terrain'
    'i18nCoverage'
    'loadingTip'
    'requiresSubscription'
    'adventurer'
    'practice'
    'adminOnly'
    'disableSpaces'
    'hidesSubmitUntilRun'
    'hidesPlayButton'
    'hidesRunShortcut'
    'hidesHUD'
    'hidesSay'
    'hidesCodeToolbar'
    'hidesRealTimePlayback'
    'backspaceThrottle'
    'lockDefaultCode'
    'moveRightLoopSnippet'
    'realTimeSpeedFactor'
    'autocompleteFontSizePx'
    'requiredCode'
    'suspectCode'
    'requiredGear'
    'restrictedGear'
    'allowedHeroes'
    'tasks'
    'helpVideos'
    'campaign'
    'replayable'
    'buildTime'
  ]

  postEditableProperties: ['name']

  getByRelationship: (req, res, args...) ->
    return @getSession(req, res, args[0]) if args[1] is 'session'
    return @getLeaderboard(req, res, args[0]) if args[1] is 'leaderboard'
    return @getMyLeaderboardRank(req, res, args[0]) if args[1] is 'leaderboard_rank'
    return @getMySessions(req, res, args[0]) if args[1] is 'my_sessions'
    return @getFeedback(req, res, args[0]) if args[1] is 'feedback'
    return @getAllFeedback(req, res, args[0]) if args[1] is 'all_feedback'
    return @getRandomSessionPair(req, res, args[0]) if args[1] is 'random_session_pair'
    return @getLeaderboardFacebookFriends(req, res, args[0]) if args[1] is 'leaderboard_facebook_friends'
    return @getLeaderboardGPlusFriends(req, res, args[0]) if args[1] is 'leaderboard_gplus_friends'
    return @getHistogramData(req, res, args[0]) if args[1] is 'histogram_data'
    return @checkExistence(req, res, args[0]) if args[1] is 'exists'
    return @getPlayCountsBySlugs(req, res) if args[1] is 'play_counts'
    return @getLevelPlaytimesBySlugs(req, res) if args[1] is 'playtime_averages'
    super(arguments...)

  fetchLevelByIDAndHandleErrors: (id, req, res, callback) ->
    @getDocumentForIdOrSlug id, (err, level) =>
      return @sendDatabaseError(res, err) if err
      return @sendNotFoundError(res) unless level?
      return @sendForbiddenError(res) unless @hasAccessToDocument(req, level, 'get')
      callback err, level

  getSession: (req, res, id) ->
    return @sendNotFoundError(res) unless req.user
    @fetchLevelByIDAndHandleErrors id, req, res, (err, level) =>
      sessionQuery =
        level:
          original: level.original.toString()
          majorVersion: level.version.major
        creator: req.user.id

      if req.query.team?
        sessionQuery.team = req.query.team

      Session.findOne(sessionQuery).exec (err, doc) =>
        return @sendDatabaseError(res, err) if err
        return @sendSuccess(res, doc) if doc?
        return @sendPaymentRequiredError(res, err) if (not req.user.isPremium()) and level.get('requiresSubscription') and not level.get('adventurer')
        @createAndSaveNewSession sessionQuery, req, res

  createAndSaveNewSession: (sessionQuery, req, res) =>
    initVals = sessionQuery

    initVals.state =
      complete: false
      scripts:
        currentScript: null # will not save empty objects

    initVals.permissions = [
      {
        target: req.user.id
        access: 'owner'
      }
      {
        target: 'public'
        access: 'write'
      }
    ]
    initVals.codeLanguage = req.user.get('aceConfig')?.language ? 'python'
    session = new Session(initVals)

    session.save (err) =>
      return @sendDatabaseError(res, err) if err
      @sendSuccess(res, @formatEntity(req, session))
      # TODO: tying things like @formatEntity and saveChangesToDocument don't make sense
      # associated with the handler, because the handler might return a different type
      # of model, like in this case. Refactor to move that logic to the model instead.

  getMySessions: (req, res, slugOrID) ->
    return @sendForbiddenError(res) if not req.user
    findParameters = {}
    if Handler.isID slugOrID
      findParameters['_id'] = slugOrID
    else
      findParameters['slug'] = slugOrID
    selectString = 'original version.major permissions'
    query = Level.findOne(findParameters)
      .select(selectString)
      .lean()

    query.exec (err, level) =>
      return @sendDatabaseError(res, err) if err
      return @sendNotFoundError(res) unless level?
      sessionQuery =
        level:
          original: level.original.toString()
          majorVersion: level.version.major
        creator: req.user._id+''

      query = Session.find(sessionQuery).select('-screenshot')
      query.exec (err, results) =>
        if err then @sendDatabaseError(res, err) else @sendSuccess res, results

  getHistogramData: (req, res, slug) ->
    query = Session.aggregate [
      {$match: {'levelID': slug, 'submitted': true, 'team': req.query.team}}
      {$project: {totalScore: 1, _id: 0}}
    ]

    query.exec (err, data) =>
      if err? then return @sendDatabaseError res, err
      valueArray = _.pluck data, 'totalScore'
      @sendSuccess res, valueArray

  checkExistence: (req, res, slugOrID) ->
    findParameters = {}
    if Handler.isID slugOrID
      findParameters['_id'] = slugOrID
    else
      findParameters['slug'] = slugOrID
    selectString = 'original version.major permissions'
    query = Level.findOne(findParameters)
    .select(selectString)
    .lean()

    query.exec (err, level) =>
      return @sendDatabaseError(res, err) if err
      return @sendNotFoundError(res) unless level?
      res.send({'exists': true})
      res.end()

  getLeaderboard: (req, res, id) ->
    sessionsQueryParameters = @makeLeaderboardQueryParameters(req, id)

    sortParameters =
      'totalScore': req.query.order
    selectProperties = ['totalScore', 'creatorName', 'creator', 'submittedCodeLanguage']

    query = Session
      .find(sessionsQueryParameters)
      .limit(req.query.limit)
      .sort(sortParameters)
      .select(selectProperties.join ' ')

    query.exec (err, resultSessions) =>
      return @sendDatabaseError(res, err) if err
      resultSessions ?= []
      @sendSuccess res, resultSessions

  getMyLeaderboardRank: (req, res, id) ->
    req.query.order = 1
    sessionsQueryParameters = @makeLeaderboardQueryParameters(req, id)
    Session.count sessionsQueryParameters, (err, count) =>
      return @sendDatabaseError(res, err) if err
      res.send JSON.stringify(count + 1)

  makeLeaderboardQueryParameters: (req, id) ->
    @validateLeaderboardRequestParameters req
    [original, version] = id.split '.'
    version = parseInt(version) ? 0
    scoreQuery = {}
    scoreQuery[if req.query.order is 1 then '$gt' else '$lt'] = req.query.scoreOffset
    query =
      level:
        original: original
        majorVersion: version
      team: req.query.team
      totalScore: scoreQuery
      submitted: true
    query

  validateLeaderboardRequestParameters: (req) ->
    req.query.order = parseInt(req.query.order) ? -1
    req.query.scoreOffset = parseFloat(req.query.scoreOffset) ? 100000
    req.query.team ?= 'humans'
    req.query.limit = parseInt(req.query.limit) ? 20

  getLeaderboardFacebookFriends: (req, res, id) -> @getLeaderboardFriends(req, res, id, 'facebookID')
  getLeaderboardGPlusFriends: (req, res, id) -> @getLeaderboardFriends(req, res, id, 'gplusID')
  getLeaderboardFriends: (req, res, id, serviceProperty) ->
    friendIDs = req.body.friendIDs or []
    return res.send([]) unless friendIDs.length

    q = {}
    q[serviceProperty] = {$in: friendIDs}
    query = User.find(q).select("#{serviceProperty} name").lean()

    query.exec (err, userResults) ->
      return res.send([]) unless userResults.length
      [id, version] = id.split('.')
      userIDs = (r._id+'' for r in userResults)
      q = {'level.original': id, 'level.majorVersion': parseInt(version), creator: {$in: userIDs}, totalScore: {$exists: true}}
      query = Session.find(q)
      .select('creator creatorName totalScore team')
      .lean()

      query.exec (err, sessionResults) ->
        return res.send([]) unless sessionResults.length
        userMap = {}
        userMap[u._id] = u[serviceProperty] for u in userResults
        session[serviceProperty] = userMap[session.creator] for session in sessionResults
        res.send(sessionResults)

  getRandomSessionPair: (req, res, slugOrID) ->
    findParameters = {}
    if Handler.isID slugOrID
      findParameters['_id'] = slugOrID
    else
      findParameters['slug'] = slugOrID
    selectString = 'original version'
    query = Level.findOne(findParameters)
    .select(selectString)
    .lean()

    query.exec (err, level) =>
      return @sendDatabaseError(res, err) if err
      return @sendNotFoundError(res) unless level?

      sessionsQueryParameters =
        level:
          original: level.original.toString()
          majorVersion: level.version.major
        submitted: true

      query = Session.find(sessionsQueryParameters).distinct('team')
      query.exec (err, teams) =>
        return @sendDatabaseError res, err if err? or not teams
        findTop20Players = (sessionQueryParams, team, cb) ->
          sessionQueryParams['team'] = team
          Session.aggregate [
            {$match: sessionQueryParams}
            {$project: {'totalScore': 1}}
            {$sort: {'totalScore': -1}}
            {$limit: 20}
          ], cb

        async.map teams, findTop20Players.bind(@, sessionsQueryParameters), (err, map) =>
          if err? then return @sendDatabaseError(res, err)
          sessions = []
          for mapItem in map
            sessions.push _.sample(mapItem)
          if map.length != 2 then return @sendDatabaseError res, 'There aren\'t sessions of 2 teams, so cannot choose random opponents!'
          @sendSuccess res, sessions

  getFeedback: (req, res, levelID) ->
    return @sendNotFoundError(res) unless req.user
    @doGetFeedback req, res, levelID, false

  getAllFeedback: (req, res, levelID) ->
    return @sendNotFoundError(res) unless req.user
    @doGetFeedback req, res, levelID, true

  doGetFeedback: (req, res, levelID, multiple) ->
    @fetchLevelByIDAndHandleErrors levelID, req, res, (err, level) =>
      feedbackQuery =
        'level.original': level.original.toString()
        'level.majorVersion': level.version.major
      feedbackQuery.creator = mongoose.Types.ObjectId(req.user.id.toString()) unless multiple
      fn = if multiple then 'find' else 'findOne'
      Feedback[fn](feedbackQuery).exec (err, result) =>
        return @sendDatabaseError(res, err) if err
        return @sendNotFoundError(res) unless result?
        @sendSuccess(res, result)

  getPlayCountsBySlugs: (req, res) ->
    # This is hella slow (4s on my box), so relying on some dumb caching for it.
    # If we can't make this faster with indexing or something, we might want to maintain the counts another way.
    levelIDs = req.query.ids or req.body.ids
    return @sendSuccess res, [] unless levelIDs?

    @playCountCache ?= {}
    @playCountCachedSince ?= new Date()
    if (new Date()) - @playCountCachedSince > 86400 * 1000  # Dumb cache expiration
      @playCountCache = {}
      @playCountCachedSince = new Date()
    cacheKey = levelIDs.join ','
    if playCounts = @playCountCache[cacheKey]
      return @sendSuccess res, playCounts
    query = Session.aggregate [
      {$match: {levelID: {$in: levelIDs}}}
      {$group: {_id: "$levelID", playtime: {$sum: "$playtime"}, sessions: {$sum: 1}}}
      {$sort: {sessions: -1}}
    ]
    query.exec (err, data) =>
      if err? then return @sendDatabaseError res, err
      @playCountCache[cacheKey] = data
      @sendSuccess res, data

  hasAccessToDocument: (req, document, method=null) ->
    method ?= req.method
    return true if method is null or method is 'get'
    super(req, document, method)


  getLevelPlaytimesBySlugs: (req, res) ->
    # Returns an array of per-day level average playtimes
    # Parameters:
    # slugs - array of level slugs
    # startDay - Inclusive, optional, e.g. '2014-12-14'
    # endDay - Exclusive, optional, e.g. '2014-12-16'

    # TODO: An uncached call takes about 5s for dungeons-of-kithgard locally
    # TODO: This is very similar to getLevelCompletionsBySlugs(), time to generalize analytics APIs?

    levelSlugs = req.query.slugs or req.body.slugs
    startDay = req.query.startDay or req.body.startDay
    endDay = req.query.endDay or req.body.endDay

    return @sendSuccess res, [] unless levelSlugs?

    # Cache results for 1 day
    @levelPlaytimesCache ?= {}
    @levelPlaytimesCachedSince ?= new Date()
    if (new Date()) - @levelPlaytimesCachedSince > 86400 * 1000  # Dumb cache expiration
      @levelPlaytimesCache = {}
      @levelPlaytimesCachedSince = new Date()
    cacheKey = levelSlugs.join(',')
    cacheKey += 's' + startDay if startDay?
    cacheKey += 'e' + endDay if endDay?
    return @sendSuccess res, levelPlaytimes if levelPlaytimes = @levelPlaytimesCache[cacheKey]

    # Build query
    match = {$match: {$and: [{"state.complete": true}, {"playtime": {$gt: 0}}, {levelID: {$in: levelSlugs}}]}}
    match["$match"]["$and"].push _id: {$gte: utils.objectIdFromTimestamp(startDay + "T00:00:00.000Z")} if startDay?
    match["$match"]["$and"].push _id: {$lt: utils.objectIdFromTimestamp(endDay + "T00:00:00.000Z")} if endDay?
    project = {"$project": {"_id": 0, "levelID": 1, "playtime": 1, "created": {"$concat": [{"$substr":  ["$created", 0, 10]}]}}}
    group = {"$group": {"_id": {"created": "$created", "level": "$levelID"}, "average": {"$avg": "$playtime"}}}
    query = Session.aggregate match, project, group

    query.exec (err, data) =>
      if err? then return @sendDatabaseError res, err

      # Build list of level average playtimes
      playtimes = []
      for item in data
        playtimes.push
          level: item._id.level
          created: item._id.created
          average: item.average
      @levelPlaytimesCache[cacheKey] = playtimes
      @sendSuccess res, playtimes

module.exports = new LevelHandler()
