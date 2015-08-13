log = require 'winston'
async = require 'async'
bayes = new (require 'bayesian-battle')()
LevelSession = require '../../levels/sessions/LevelSession'
User = require '../../users/User'

SIMULATOR_VERSION = 3

module.exports.scoringTaskTimeoutInSeconds = 600

module.exports.scoringTaskQueue = null

module.exports.simulatorIsTooOld = (req, res) ->
  clientSimulator = req.body.simulator
  return false if clientSimulator?.version >= SIMULATOR_VERSION
  message = "Old simulator version #{clientSimulator?.version}, need to clear cache and get version #{SIMULATOR_VERSION}."
  log.debug "400: #{message}"
  res.send 400, message
  res.end()
  true


module.exports.sendResponseObject = (req, res, object) ->
  res.setHeader('Content-Type', 'application/json')
  res.send(object)
  res.end()


module.exports.formatSessionInformation = (session) ->
  sessionID: session._id
  team: session.team ? 'No team'
  transpiledCode: session.transpiledCode
  submittedCodeLanguage: session.submittedCodeLanguage
  teamSpells: session.teamSpells ? {}
  levelID: session.levelID
  creatorName: session.creatorName
  creator: session.creator
  totalScore: session.totalScore


module.exports.calculateSessionScores = (callback) ->
  sessionIDs = _.pluck @clientResponseObject.sessions, 'sessionID'
  async.map sessionIDs, retrieveOldSessionData, (err, oldScores) =>
    if err? then callback err, {error: 'There was an error retrieving the old scores'}
    try
      oldScoreArray = _.toArray putRankingFromMetricsIntoScoreObject @clientResponseObject, oldScores
      newScoreArray = bayes.updatePlayerSkills oldScoreArray
      createSessionScoreUpdate.call @, scoreObject for scoreObject in newScoreArray
      callback err, newScoreArray
    catch e
      callback e

retrieveOldSessionData = (sessionID, callback) ->
  formatOldScoreObject = (session) ->
    standardDeviation: session.standardDeviation ? 25/3
    meanStrength: session.meanStrength ? 25
    totalScore: session.totalScore ? (25 - 1.8*(25/3))
    id: sessionID
    submittedCodeLanguage: session.submittedCodeLanguage

  return formatOldScoreObject @levelSession if sessionID is @levelSession?._id  # No need to fetch again

  query = _id: sessionID
  selection = 'standardDeviation meanStrength totalScore submittedCodeLanguage'
  LevelSession.findOne(query).select(selection).lean().exec (err, session) ->
    return callback err, {'error': 'There was an error retrieving the session.'} if err?
    callback err, formatOldScoreObject session

putRankingFromMetricsIntoScoreObject = (taskObject, scoreObject) ->
  scoreObject = _.indexBy scoreObject, 'id'
  scoreObject[session.sessionID].gameRanking = session.metrics.rank for session in taskObject.sessions
  return scoreObject

createSessionScoreUpdate = (scoreObject) ->
  newTotalScore = scoreObject.meanStrength - 1.8 * scoreObject.standardDeviation
  scoreHistoryAddition = [Date.now(), newTotalScore]
  @levelSessionUpdates ?= {}
  @levelSessionUpdates[scoreObject.id] =
    meanStrength: scoreObject.meanStrength
    standardDeviation: scoreObject.standardDeviation
    totalScore: newTotalScore
    $push: {scoreHistory: {$each: [scoreHistoryAddition], $slice: -1000}}
    randomSimulationIndex: Math.random()


module.exports.indexNewScoreArray = (newScoreArray, callback) ->
  newScoresObject = _.indexBy newScoreArray, 'id'
  @newScoresObject = newScoresObject
  callback null, newScoresObject


module.exports.addMatchToSessionsAndUpdate = (newScoreObject, callback) ->
  matchObject = {}
  matchObject.date = new Date()
  matchObject.opponents = {}
  for session in @clientResponseObject.sessions
    sessionID = session.sessionID
    matchObject.opponents[sessionID] = match = {}
    match.sessionID = sessionID
    match.userID = session.creator
    match.name = session.name
    match.totalScore = session.totalScore
    match.metrics = {}
    match.metrics.rank = Number(newScoreObject[sessionID]?.gameRanking ? 0)
    match.codeLanguage = newScoreObject[sessionID].submittedCodeLanguage

  #log.info "Match object computed, result: #{JSON.stringify(matchObject, null, 2)}"
  #log.info 'Writing match object to database...'
  #use bind with async to do the writes
  sessionIDs = _.pluck @clientResponseObject.sessions, 'sessionID'
  async.each sessionIDs, updateMatchesInSession.bind(@, matchObject), (err) ->
    callback err

updateMatchesInSession = (matchObject, sessionID, callback) ->
  currentMatchObject = {}
  currentMatchObject.date = matchObject.date
  currentMatchObject.metrics = matchObject.opponents[sessionID].metrics
  opponentsClone = _.cloneDeep matchObject.opponents
  opponentsClone = _.omit opponentsClone, sessionID
  opponentsArray = _.toArray opponentsClone
  currentMatchObject.opponents = opponentsArray
  currentMatchObject.codeLanguage = matchObject.opponents[opponentsArray[0].sessionID].codeLanguage
  #currentMatchObject.simulator = @clientResponseObject.simulator  # Uncomment when actively debugging simulation mismatches
  #currentMatchObject.randomSeed = parseInt(@clientResponseObject.randomSeed or 0, 10)  # Uncomment when actively debugging simulation mismatches
  sessionUpdateObject = @levelSessionUpdates[sessionID]
  sessionUpdateObject.$push.matches = {$each: [currentMatchObject], $slice: -200}
  #log.info "Update is #{JSON.stringify(sessionUpdateObject, null, 2)}"
  LevelSession.update {_id: sessionID}, sessionUpdateObject, callback


module.exports.updateUserSimulationCounts = (reqUserID, callback) ->
  incrementUserSimulationCount reqUserID, 'simulatedBy', (err) =>
    if err? then return callback err
    #console.log 'Incremented user simulation count!'
    unless @isRandomMatch
      incrementUserSimulationCount @levelSession.creator, 'simulatedFor', callback
    else
      callback null

incrementUserSimulationCount = (userID, type, callback) =>
  return callback null unless userID
  inc = {}
  inc[type] = 1
  User.update {_id: userID}, {$inc: inc}, (err, affected) ->
    log.error "Error incrementing #{type} for #{userID}: #{err}" if err
    callback err


module.exports.calculateOpposingTeam = (sessionTeam) ->
  teams = ['ogres', 'humans']
  opposingTeams = _.pull teams, sessionTeam
  return opposingTeams[0]


module.exports.sendEachTaskPairToTheQueue = (taskPairs, callback) ->
  async.each taskPairs, sendTaskPairToQueue, callback

sendTaskPairToQueue = (taskPair, callback) ->
  module.exports.scoringTaskQueue.sendMessage {sessions: taskPair}, 5, (err, data) -> callback? err, data


module.exports.generateTaskPairs = (submittedSessions, sessionToScore) ->
  taskPairs = []
  for session in submittedSessions
    if session.toObject?
      session = session.toObject()
    teams = ['ogres', 'humans']
    opposingTeams = _.pull teams, sessionToScore.team
    if String(session._id) isnt String(sessionToScore._id) and session.team in opposingTeams
      #console.log 'Adding game to taskPairs!'
      taskPairs.push [sessionToScore._id, String session._id]
  return taskPairs


module.exports.addPairwiseTaskToQueue = (taskPair, cb) ->
  LevelSession.findOne(_id: taskPair[0]).lean().exec (err, firstSession) =>
    if err? then return cb err
    LevelSession.find(_id: taskPair[1]).exec (err, secondSession) =>
      if err? then return cb err
      try
        taskPairs = module.exports.generateTaskPairs(secondSession, firstSession)
      catch e
        if e then return cb e

      module.exports.sendEachTaskPairToTheQueue taskPairs, (taskPairError) ->
        if taskPairError? then return cb taskPairError
        cb null
