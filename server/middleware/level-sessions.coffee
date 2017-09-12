errors = require '../commons/errors'
wrap = require 'co-express'
LevelSession = require '../models/LevelSession'
Level = require '../models/Level'
CourseInstance = require('../models/CourseInstance')
mongoose = require 'mongoose'
database = require '../commons/database'


submitToLadder = wrap (req, res) ->
  requestSessionID = req.body.session
  courseInstanceId = req.body.courseInstanceId

  if (not req.user) or req.user.isAnonymous()
    throw new errors.Unauthorized()

  session = yield LevelSession.findOne({_id: requestSessionID}).select('code leagues codeLanguage creator level')
  if not session
    throw new errors.NotFound('Session not found.')

  unless req.user?.isAdmin()
    userHasPermissionToSubmitCode = session.get('creator') is req.user?.id
    unless userHasPermissionToSubmitCode
      throw new errors.Forbidden()

  levelOriginal = session.get('level.original')
  levelWithType = yield Level.findCurrentVersion(levelOriginal).select('type').lean()
  if not levelWithType.type or not (levelWithType.type in ['ladder', 'hero-ladder', 'course-ladder'])
    throw new errors.Forbidden('Level isn\'t of type "ladder"')

  sessionUpdateObject =
    submitted: true
    submittedCode: session.get('code')
    submittedCodeLanguage: session.get('codeLanguage') or 'python'
    submitDate: new Date()
    standardDeviation: 25 / 3
    numberOfWinsAndTies: 0
    numberOfLosses: 0
    isRanking: true
    randomSimulationIndex: Math.random()

  # Reset all league stats, enter the session into any leagues the user is currently part of (not retroactive when joining new leagues)
  leagueIDs = req.user.get('clans') or []
  leagueIDs = leagueIDs.concat req.user.get('courseInstances') or []
  leagueIDs = (leagueID + '' for leagueID in leagueIDs)  # Make sure to save them as strings.
  currentLeagueIds = (session.get('leagues') or []).map((l) -> l.leagueID)
  leagueIDs = _.unique(leagueIDs.concat(currentLeagueIds))

  if courseInstanceId and not _.contains(leagueIDs, courseInstanceId)
    courseInstance = yield CourseInstance.findById(courseInstanceId)
    if not courseInstance
      throw new errors.NotFound('Course Instance not found')
    if not courseInstance.isMember(req.user._id)
      throw new errors.Forbidden('Not assigned this course in this classroom')
    leagueIDs.push(courseInstance.id)

  newLeagues = []
  for leagueID in leagueIDs
    league = _.clone(_.find(session.get('leagues'), leagueID: leagueID) ? leagueID: leagueID)
    league.stats ?= {}
    league.stats.standardDeviation = 25 / 3
    league.stats.numberOfWinsAndTies = 0
    league.stats.numberOfLosses = 0
    league.stats.meanStrength ?= 25
    league.stats.totalScore ?= 10
    delete league.lastOpponentSubmitDate
    newLeagues.push(league)
  unless _.isEqual newLeagues, session.get('leagues')
    sessionUpdateObject.leagues = newLeagues
  yield LevelSession.update {_id: session._id}, sessionUpdateObject
  session.set(sessionUpdateObject)
  res.send(session.toObject({req}))


unsetScores = wrap (req, res) ->
  sessionID = req.body.session
  unless sessionID
    throw new errors.UnprocessableEntity('No session provided.')
  yield LevelSession.update {_id: mongoose.Types.ObjectId(sessionID)}, {$unset: {'state.topScores': 1}}
  res.send 200
  
  
putKeyValueDb = wrap (req, res) ->
  if (not req.user) or (req.user.isAnonymous() and not req.user.get('hourOfCode'))
    throw new errors.Unauthorized('You must be logged in.')
  
  key = req.params.key
    
  session = yield database.getDocFromHandle(req, LevelSession)
  if not session
    throw new errors.NotFound('Session not found.')
    
  sessionDb = session.get('keyValueDb')
  if not sessionDb
    level = yield Level.findCurrentVersion(session.get('level.original'), 'type')
    if level.get('type') isnt 'game-dev'
      throw new errors.UnprocessableEntity('Only game dev levels can have dbs')
  else if _.size(sessionDb) >= 100 and not _.has(sessionDb, key) 
    throw new errors.UnprocessableEntity('Only game dev levels can have dbs')
    
  value = req.body
  unless _.any([_.isString(value), _.isNumber(value), _.isNull(value), _.isBoolean(value)])
    throw new errors.UnprocessableEntity('Values may only be strings, numbers, booleans, or null')
    
  if _.isString(value) and value.length > 1024
    throw new errors.UnprocessableEntity('Strings may not be over one kilobyte')
    
  yield session.update({ $set: { "keyValueDb.#{key}": value }})
  res.status(200).json(value)
  
incrementKeyValueDb = wrap (req, res) ->
  if (not req.user) or (req.user.isAnonymous() and not req.user.get('hourOfCode'))
    throw new errors.Unauthorized('You must be logged in.')
    
  key = req.params.key

  session = yield database.getDocFromHandle(req, LevelSession)
  if not session
    throw new errors.NotFound('Session not found.')

  sessionDb = session.get('keyValueDb')
  if not sessionDb
    level = yield Level.findCurrentVersion(session.get('level.original'), 'type')
    if level.get('type') isnt 'game-dev'
      throw new errors.UnprocessableEntity('Only game dev levels can have dbs')
  else if _.size(sessionDb) >= 100 and not _.has(sessionDb, key) 
    throw new errors.UnprocessableEntity('Only game dev levels can have dbs')

  value = req.body
  unless _.isNumber(value)
    throw new errors.UnprocessableEntity('Value must be a number')

  currentValue = sessionDb?[key]
  if _.isNumber(currentValue)
    update = { $inc: { }}
    update.$inc['keyValueDb.'+key] = value
    yield session.update(update)
    res.status(200).json(value+currentValue)
  else
    update = { $set: {}}
    update.$set['keyValueDb.'+key] = value
    yield session.update(update)
    res.status(200).json(value)


module.exports = {
  incrementKeyValueDb
  putKeyValueDb
  submitToLadder
  unsetScores
}
