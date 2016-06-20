log = require 'winston'
async = require 'async'
errors = require '../../commons/errors'
scoringUtils = require './scoringUtils'
LevelSession = require '../../models/LevelSession'
Level = require '../../models/Level'

module.exports = createNewTask = (req, res) ->
  requestSessionID = req.body.session
  originalLevelID = req.body.originalLevelID
  currentLevelID = req.body.levelID
  requestLevelMajorVersion = parseInt(req.body.levelMajorVersion)

  yetiGuru = {}
  async.waterfall [
    validatePermissions.bind(yetiGuru, req, requestSessionID)
    fetchAndVerifyLevelType.bind(yetiGuru, currentLevelID)
    fetchSessionObjectToSubmit.bind(yetiGuru, requestSessionID)
    updateSessionToSubmit.bind(yetiGuru, req.user)
    # Because there's some bug where the chained rankings don't work, and this is super slow, let's just not do this until we fix it.
    #fetchInitialSessionsToRankAgainst.bind(yetiGuru, requestLevelMajorVersion, originalLevelID)
    #generateAndSendTaskPairsToTheQueue
  ], (err, successMessageObject) ->
    if err? then return errors.serverError res, "There was an error submitting the game to the queue: #{err}"
    scoringUtils.sendResponseObject res, successMessageObject


validatePermissions = (req, sessionID, callback) ->
  return callback 'You are unauthorized to submit that game to the simulator.' unless req.user?.get('email')
  return callback null if req.user?.isAdmin()

  findParameters = _id: sessionID
  selectString = 'creator submittedCode code'
  LevelSession.findOne(findParameters).select(selectString).lean().exec (err, retrievedSession) =>
    if err? then return callback err
    userHasPermissionToSubmitCode = retrievedSession.creator is req.user?.id
    unless userHasPermissionToSubmitCode then return callback 'You are unauthorized to submit that game to the simulator.'
    # Disabling this for now, since mirror matches submit different transpiled code for the same source code.
    #alreadySubmitted = _.isEqual(retrievedSession.code, retrievedSession.submittedCode)
    #unless alreadySubmitted then return callback 'You have already submitted that exact code for simulation.'
    callback null


fetchAndVerifyLevelType = (levelID, cb) ->
  Level.findOne(_id: levelID).select('type').lean().exec (err, levelWithType) ->
    if err? then return cb err
    if not levelWithType.type or not (levelWithType.type in ['ladder', 'hero-ladder', 'course-ladder']) then return cb 'Level isn\'t of type "ladder"'
    cb null

fetchSessionObjectToSubmit = (sessionID, callback) ->
  LevelSession.findOne({_id: sessionID}).select('team code leagues codeLanguage').exec (err, session) ->
    callback err, session?.toObject()

updateSessionToSubmit = (user, sessionToUpdate, callback) ->
  sessionUpdateObject =
    submitted: true
    submittedCode: sessionToUpdate.code
    submittedCodeLanguage: sessionToUpdate.codeLanguage or 'python'
    submitDate: new Date()
    #meanStrength: 25  # Let's try not resetting the score on resubmission
    standardDeviation: 25 / 3
    #totalScore: 10  # Let's try not resetting the score on resubmission
    numberOfWinsAndTies: 0
    numberOfLosses: 0
    isRanking: true
    randomSimulationIndex: Math.random()

  # Reset all league stats as well, and enter the session into any leagues the user is currently part of (not retroactive when joining new leagues)
  leagueIDs = user.get('clans') or []
  leagueIDs = leagueIDs.concat user.get('courseInstances') or []
  leagueIDs = (leagueID + '' for leagueID in leagueIDs)  # Make sure to save them as strings.
  newLeagues = []
  for leagueID in leagueIDs
    league = _.clone(_.find(sessionToUpdate.leagues, leagueID: leagueID) ? leagueID: leagueID)
    league.stats ?= {}
    league.stats.standardDeviation = 25 / 3
    league.stats.numberOfWinsAndTies = 0
    league.stats.numberOfLosses = 0
    league.stats.meanStrength ?= 25
    league.stats.totalScore ?= 10
    delete league.lastOpponentSubmitDate
    newLeagues.push(league)
  unless _.isEqual newLeagues, sessionToUpdate.leagues
    sessionUpdateObject.leagues = sessionToUpdate.leagues = newLeagues
  LevelSession.update {_id: sessionToUpdate._id}, sessionUpdateObject, (err, result) ->
    callback err, sessionToUpdate

fetchInitialSessionsToRankAgainst = (levelMajorVersion, levelID, submittedSession, callback) ->
  opposingTeam = scoringUtils.calculateOpposingTeam(submittedSession.team)
  findParameters =
    'level.original': levelID
    'level.majorVersion': levelMajorVersion
    submitted: true
    team: opposingTeam
  sortParameters = totalScore: 1
  limitNumber = 1
  query = LevelSession.aggregate [
    {$match: findParameters}
    {$sort: sortParameters}
    {$limit: limitNumber}
  ]

  query.exec (err, sessionToRankAgainst) ->
    callback err, sessionToRankAgainst, submittedSession

generateAndSendTaskPairsToTheQueue = (sessionToRankAgainst, submittedSession, callback) ->
  taskPairs = scoringUtils.generateTaskPairs(sessionToRankAgainst, submittedSession)
  scoringUtils.sendEachTaskPairToTheQueue taskPairs, (taskPairError) ->
    if taskPairError? then return callback taskPairError
    #console.log 'Sent task pairs to the queue!'
    #console.log taskPairs
    callback null, {message: 'All task pairs were succesfully sent to the queue'}
