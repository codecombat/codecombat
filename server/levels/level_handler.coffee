Level = require('./Level')
Session = require('./sessions/LevelSession')
SessionHandler = require('./sessions/level_session_handler')
Feedback = require('./feedbacks/LevelFeedback')
Handler = require('../commons/Handler')
mongoose = require('mongoose')

LevelHandler = class LevelHandler extends Handler
  modelClass: Level
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
    return @getMySessions(req, res, args[0]) if args[1] is 'my_sessions'
    return @getFeedback(req, res, args[0]) if args[1] is 'feedback'
    return @sendNotFoundError(res)

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
      complete:false
      scripts:
        currentScript:null # will not save empty objects

    initVals.permissions = [
      {
        target:req.user.id
        access:'owner'
      }
      {
        target:'public'
        access:'write'
      }
    ]
    session = new Session(initVals)

    session.save (err) =>
      return @sendDatabaseError(res, err) if err
      @sendSuccess(res, @formatEntity(req, session))
      # TODO: tying things like @formatEntity and saveChangesToDocument don't make sense
      # associated with the handler, because the handler might return a different type
      # of model, like in this case. Refactor to move that logic to the model instead.

  getMySessions: (req, res, id) ->
    @fetchLevelByIDAndHandleErrors id, req, res, (err, level) =>
      sessionQuery =
        level:
          original: level.original.toString()
          majorVersion: level.version.major
        creator: req.user._id+''

      query = Session.find(sessionQuery)
      query.exec (err, results) =>
        if err then @sendDatabaseError(res, err) else @sendSuccess res, results

  getLeaderboard: (req, res, id) ->
    @validateLeaderboardRequestParameters req
    [original, version] = id.split '.'
    version = parseInt(version) ? 0
    scoreQuery = {}
    scoreQuery[if req.query.order is 1 then "$gte" else "$lte"] = req.query.scoreOffset

    sessionsQueryParameters =
      level:
        original: original
        majorVersion: version
      team: req.query.team
      totalScore: scoreQuery
      submitted: true

    sortParameters =
      "totalScore": req.query.order

    selectProperties = [
      'totalScore'
      'creatorName'
      'creator'
    ]

    query = Session
      .find(sessionsQueryParameters)
      .limit(req.query.limit)
      .sort(sortParameters)
      .select(selectProperties.join ' ')

    query.exec (err, resultSessions) =>
      return @sendDatabaseError(res, err) if err
      resultSessions ?= []
      @sendSuccess res, resultSessions

  validateLeaderboardRequestParameters: (req) ->
    req.query.order = parseInt(req.query.order) ? -1
    req.query.scoreOffset = parseFloat(req.query.scoreOffset) ? 100000
    req.query.team ?= 'humans'
    req.query.limit = parseInt(req.query.limit) ? 20

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
