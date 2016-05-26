log = require 'winston'
async = require 'async'
bayes = new (require 'bayesian-battle')()
LevelSession = require '../../models/LevelSession'
User = require '../../models/User'
perfmon = require '../../commons/perfmon'
LZString = require 'lz-string'

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


module.exports.sendResponseObject = (res, object) ->
  res.setHeader('Content-Type', 'application/json')
  res.send(object)
  res.end()

module.exports.formatSessionInformation = (session) ->
  heroID = if session.team is 'ogres' then 'hero-placeholder-1' else 'hero-placeholder'
  submittedCode = {}
  submittedCode[heroID] = plan: LZString.compressToUTF16(session.submittedCode?[heroID]?.plan ? '')

  _id: session._id
  sessionID: session._id
  team: session.team ? 'No team'
  submittedCode: submittedCode
  submittedCodeLanguage: session.submittedCodeLanguage
  teamSpells: session.teamSpells ? {}
  levelID: session.levelID
  creatorName: session.creatorName
  creator: session.creator
  totalScore: session.totalScore
  submitDate: session.submitDate
  shouldUpdateLastOpponentSubmitDateForLeague: session.shouldUpdateLastOpponentSubmitDateForLeague

module.exports.calculateSessionScores = (callback) ->
  sessionIDs = _.map @clientResponseObject.sessions, 'sessionID'
  async.map sessionIDs, retrieveOldSessionData.bind(@), (err, oldScores) =>
    if err? then return callback err, {error: 'There was an error retrieving the old scores'}
    oldScoreArray = _.toArray putRankingFromMetricsIntoScoreObject @clientResponseObject, oldScores
    newScoreArray = updatePlayerSkills oldScoreArray
    createSessionScoreUpdate.call @, scoreObject for scoreObject in newScoreArray
    callback null, newScoreArray

retrieveOldSessionData = (sessionID, callback) ->
  formatOldScoreObject = (session) =>
    oldScoreObject =
      standardDeviation: session.standardDeviation ? 25/3
      meanStrength: session.meanStrength ? 25
      totalScore: session.totalScore ? (25 - 1.8*(25/3))
      id: sessionID
      submittedCodeLanguage: session.submittedCodeLanguage
      ladderAchievementDifficulty: session.ladderAchievementDifficulty
      submitDate: session.submitDate
    if session.leagues?.length
      _.find(@clientResponseObject.sessions, sessionID: sessionID).leagues = session.leagues
      oldScoreObject.leagues = []
      for league in session.leagues
        oldScoreObject.leagues.push
          leagueID: league.leagueID
          stats:
            id: sessionID
            standardDeviation: league.stats.standardDeviation ? 25/3
            meanStrength: league.stats.meanStrength ? 25
            totalScore: league.stats.totalScore ? (25 - 1.8*(25/3))
    oldScoreObject

  return formatOldScoreObject @levelSession if sessionID is @levelSession?._id  # No need to fetch again

  query = _id: sessionID
  selection = 'standardDeviation meanStrength totalScore submittedCodeLanguage leagues ladderAchievementDifficulty submitDate'
  LevelSession.findOne(query).select(selection).lean().exec (err, session) ->
    return callback err, {'error': 'There was an error retrieving the session.'} if err?
    callback err, formatOldScoreObject session

putRankingFromMetricsIntoScoreObject = (taskObject, scoreObject) ->
  scoreObject = _.indexBy scoreObject, 'id'
  sharedLeagueIDs = (league.leagueID for league in (taskObject.sessions[0].leagues ? []) when _.find(taskObject.sessions[1].leagues, leagueID: league.leagueID))
  for session in taskObject.sessions
    scoreObject[session.sessionID].gameRanking = session.metrics.rank
    for league in (session.leagues ? []) when league.leagueID in sharedLeagueIDs
      # We will also score any shared leagues, and we indicate that by assigning a non-null gameRanking to them.
      _.find(scoreObject[session.sessionID].leagues, leagueID: league.leagueID).stats.gameRanking = session.metrics.rank
  return scoreObject

updatePlayerSkills = (oldScoreArray) ->
  newScoreArray = bayes.updatePlayerSkills oldScoreArray
  scoreObjectA = newScoreArray[0]
  scoreObjectB = newScoreArray[1]
  for leagueA in (scoreObjectA.leagues ? []) when leagueA.stats.gameRanking?
    leagueB = _.find scoreObjectB.leagues, leagueID: leagueA.leagueID
    [leagueA.stats, leagueB.stats] = bayes.updatePlayerSkills [leagueA.stats, leagueB.stats]
    leagueA.stats.updated = leagueB.stats.updated = true
  newScoreArray

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
  for league, leagueIndex in (scoreObject.leagues ? [])
    continue unless league.stats.updated
    newTotalScore = league.stats.meanStrength - 1.8 * league.stats.standardDeviation
    scoreHistoryAddition = [scoreHistoryAddition[0], newTotalScore]
    leagueSetPrefix = "leagues.#{leagueIndex}.stats."
    sessionUpdateObject = @levelSessionUpdates[scoreObject.id]
    sessionUpdateObject.$set ?= {}
    sessionUpdateObject.$push ?= {}
    sessionUpdateObject.$set[leagueSetPrefix + 'meanStrength'] = league.stats.meanStrength
    sessionUpdateObject.$set[leagueSetPrefix + 'standardDeviation'] = league.stats.standardDeviation
    sessionUpdateObject.$set[leagueSetPrefix + 'totalScore'] = newTotalScore
    sessionUpdateObject.$push[leagueSetPrefix + 'scoreHistory'] = {$each: [scoreHistoryAddition], $slice: -1000}


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
  sessionIDs = _.map @clientResponseObject.sessions, 'sessionID'
  async.each sessionIDs, updateMatchesInSession.bind(@, matchObject), (err) ->
    callback err

ladderBenchmarkAIs =
  '564ba6cea33967be1312ae59': 0
  '564ba830a33967be1312ae61': 1
  '564ba91aa33967be1312ae65': 2
  '564ba95ca33967be1312ae69': 3
  '564ba9b7a33967be1312ae6d': 4

updateMatchesInSession = (matchObject, sessionID, callback) ->
  currentMatchObject = {}
  currentMatchObject.date = matchObject.date
  currentMatchObject.metrics = matchObject.opponents[sessionID].metrics
  opponentsClone = _.cloneDeep matchObject.opponents
  opponentsClone = _.omit opponentsClone, sessionID
  opponentsArray = _.toArray opponentsClone
  currentMatchObject.opponents = opponentsArray
  currentMatchObject.codeLanguage = matchObject.opponents[opponentsArray[0].sessionID].codeLanguage  # TODO: we have our opponent code language in twice, do we maybe want our own code language instead?
  #currentMatchObject.simulator = @clientResponseObject.simulator  # Uncomment when actively debugging simulation mismatches
  #currentMatchObject.randomSeed = parseInt(@clientResponseObject.randomSeed or 0, 10)  # Uncomment when actively debugging simulation mismatches
  sessionUpdateObject = @levelSessionUpdates[sessionID]
  sessionUpdateObject.$push.matches = {$each: [currentMatchObject], $slice: -200}
  if currentMatchObject.metrics.rank is 0 and defeatedAI = ladderBenchmarkAIs[currentMatchObject.opponents[0].userID]
    mySession = _.find @clientResponseObject.sessions, sessionID: sessionID
    newLadderAchievementDifficulty = Math.max defeatedAI, mySession.ladderAchievementDifficulty || 0
    if newLadderAchievementDifficulty isnt mySession.ladderAchievementDifficulty
      sessionUpdateObject.ladderAchievementDifficulty = newLadderAchievementDifficulty

  myScoreObject = @newScoresObject[sessionID]
  opponentSession = _.find @clientResponseObject.sessions, (session) -> session.sessionID isnt sessionID
  for league, leagueIndex in myScoreObject.leagues ? []
    continue unless league.stats.updated
    opponentLeagueTotalScore = _.find(opponentSession.leagues, leagueID: league.leagueID).stats.totalScore ? (25 - 1.8*(25/3))
    leagueMatch = _.cloneDeep currentMatchObject
    leagueMatch.opponents[0].totalScore = opponentLeagueTotalScore
    sessionUpdateObject.$push["leagues.#{leagueIndex}.stats.matches"] = {$each: [leagueMatch], $slice: -200}
    if _.find(@clientResponseObject.sessions, sessionID: sessionID).shouldUpdateLastOpponentSubmitDateForLeague is league.leagueID
      sessionUpdateObject.$set["leagues.#{leagueIndex}.lastOpponentSubmitDate"] = new Date(opponentSession.submitDate)  # TODO: somewhere, if these are already the same, don't record the match, since we likely just recorded the same match?

  #log.info "Update for #{sessionID} is #{JSON.stringify(sessionUpdateObject, null, 2)}"
  LevelSession.update {_id: sessionID}, sessionUpdateObject, callback


module.exports.updateUserSimulationCounts = (reqUserID, callback) ->
  incrementUserSimulationCount reqUserID, 'simulatedBy', (err) =>
    if err? then return callback err
    #console.log 'Incremented user simulation count!'
    perfmon.client.increment 'simulations'
    unless @isRandomMatch
      incrementUserSimulationCount @levelSession.creator, 'simulatedFor', callback
    else
      callback null

incrementUserSimulationCount = (userID, type, callback) =>
  return callback null unless userID
  inc = {}
  inc[type] = 1
  User.update {_id: userID}, {$inc: inc}, (err, result) ->
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
