Level = require './Level'
Session = require './sessions/LevelSession'
User = require '../users/User'
SessionHandler = require './sessions/level_session_handler'
Feedback = require './feedbacks/LevelFeedback'
Handler = require '../commons/Handler'
mongoose = require 'mongoose'
async = require 'async'

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
  ]

  postEditableProperties: ['name']

  getByRelationship: (req, res, args...) ->
    return @getSession(req, res, args[0]) if args[1] is 'session'
    return @getLeaderboard(req, res, args[0]) if args[1] is 'leaderboard'
    return @getMyLeaderboardRank(req, res, args[0]) if args[1] is 'leaderboard_rank'
    return @getMySessions(req, res, args[0]) if args[1] is 'my_sessions'
    return @getFeedback(req, res, args[0]) if args[1] is 'feedback'
    return @getRandomSessionPair(req, res, args[0]) if args[1] is 'random_session_pair'
    return @getLeaderboardFacebookFriends(req, res, args[0]) if args[1] is 'leaderboard_facebook_friends'
    return @getLeaderboardGPlusFriends(req, res, args[0]) if args[1] is 'leaderboard_gplus_friends'
    return @getHistogramData(req, res, args[0]) if args[1] is 'histogram_data'
    return @checkExistence(req, res, args[0]) if args[1] is 'exists'
    super(arguments...)

  fetchLevelByIDAndHandleErrors: (id, req, res, callback) ->
    @getDocumentForIdOrSlug id, (err, level) =>
      return @sendDatabaseError(res, err) if err
      return @sendNotFoundError(res) unless level?
      return @sendUnauthorizedError(res) unless @hasAccessToDocument(req, level, 'get')
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

      # TODO: generalize this for levels based on their teams
      else if level.get('type') is 'ladder'
        sessionQuery.team = 'humans'

      Session.findOne(sessionQuery).exec (err, doc) =>
        return @sendDatabaseError(res, err) if err
        return @sendSuccess(res, doc) if doc?
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
    initVals.codeLanguage = req.user.get('aceConfig')?.language ? 'javascript'
    session = new Session(initVals)

    session.save (err) =>
      return @sendDatabaseError(res, err) if err
      @sendSuccess(res, @formatEntity(req, session))
      # TODO: tying things like @formatEntity and saveChangesToDocument don't make sense
      # associated with the handler, because the handler might return a different type
      # of model, like in this case. Refactor to move that logic to the model instead.

  getMySessions: (req, res, slugOrID) ->
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
    selectProperties = ['totalScore', 'creatorName', 'creator']

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

  getFeedback: (req, res, id) ->
    return @sendNotFoundError(res) unless req.user
    @fetchLevelByIDAndHandleErrors id, req, res, (err, level) =>
      feedbackQuery =
        creator: mongoose.Types.ObjectId(req.user.id.toString())
        'level.original': level.original.toString()
        'level.majorVersion': level.version.major

      Feedback.findOne(feedbackQuery).exec (err, doc) =>
        return @sendDatabaseError(res, err) if err
        return @sendNotFoundError(res) unless doc?
        @sendSuccess(res, doc)

module.exports = new LevelHandler()
