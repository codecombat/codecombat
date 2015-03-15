config = require '../../server_config'
log = require 'winston'
mongoose = require 'mongoose'
async = require 'async'
errors = require '../commons/errors'
aws = require 'aws-sdk'
db = require './../routes/db'
queues = require '../commons/queue'
LevelSession = require '../levels/sessions/LevelSession'
Level = require '../levels/Level'
User = require '../users/User'
TaskLog = require './task/ScoringTask'
bayes = new (require 'bayesian-battle')()

scoringTaskQueue = undefined
scoringTaskTimeoutInSeconds = 600

SIMULATOR_VERSION = 3

module.exports.setup = (app) -> connectToScoringQueue()

connectToScoringQueue = ->
  queues.initializeQueueClient ->
    queues.queueClient.registerQueue 'scoring', {}, (error, data) ->
      if error? then throw new Error "There was an error registering the scoring queue: #{error}"
      scoringTaskQueue = data
      #log.info 'Connected to scoring task queue!'

module.exports.messagesInQueueCount = (req, res) ->
  scoringTaskQueue.totalMessagesInQueue (err, count) ->
    if err? then return errors.serverError res, "There was an issue finding the Mongoose count:#{err}"
    response = String(count)
    res.send(response)
    res.end()

module.exports.addPairwiseTaskToQueueFromRequest = (req, res) ->
  taskPair = req.body.sessions
  addPairwiseTaskToQueue req.body.sessions, (err, success) ->
    if err? then return errors.serverError res, "There was an error adding pairwise tasks: #{err}"
    sendResponseObject req, res, {'message': 'All task pairs were succesfully sent to the queue'}

addPairwiseTaskToQueue = (taskPair, cb) ->
  LevelSession.findOne(_id: taskPair[0]).lean().exec (err, firstSession) =>
    if err? then return cb err
    LevelSession.find(_id: taskPair[1]).exec (err, secondSession) =>
      if err? then return cb err
      try
        taskPairs = generateTaskPairs(secondSession, firstSession)
      catch e
        if e then return cb e

      sendEachTaskPairToTheQueue taskPairs, (taskPairError) ->
        if taskPairError? then return cb taskPairError
        cb null

# We should rip these out, probably
module.exports.resimulateAllSessions = (req, res) ->
  unless isUserAdmin req then return errors.unauthorized res, 'Unauthorized. Even if you are authorized, you shouldn\'t do this'

  originalLevelID = req.body.originalLevelID
  levelMajorVersion = parseInt(req.body.levelMajorVersion)

  findParameters =
    submitted: true
    level:
      original: originalLevelID
      majorVersion: levelMajorVersion

  query = LevelSession
  .find(findParameters)
  .lean()

  query.exec (err, result) ->
    if err? then return errors.serverError res, err
    result = _.sample result, 10
    async.each result, resimulateSession.bind(@, originalLevelID, levelMajorVersion), (err) ->
      if err? then return errors.serverError res, err
      sendResponseObject req, res, {'message': 'All task pairs were succesfully sent to the queue'}

resimulateSession = (originalLevelID, levelMajorVersion, session, cb) =>
  sessionUpdateObject =
    submitted: true
    submitDate: new Date()
    meanStrength: 25
    standardDeviation: 25/3
    totalScore: 10
    numberOfWinsAndTies: 0
    numberOfLosses: 0
    isRanking: true
  LevelSession.update {_id: session._id}, sessionUpdateObject, (err, updatedSession) ->
    if err? then return cb err, null
    opposingTeam = calculateOpposingTeam(session.team)
    fetchInitialSessionsToRankAgainst levelMajorVersion, originalLevelID, opposingTeam, (err, sessionsToRankAgainst) ->
      if err? then return cb err, null

      taskPairs = generateTaskPairs(sessionsToRankAgainst, session)
      sendEachTaskPairToTheQueue taskPairs, (taskPairError) ->
        if taskPairError? then return cb taskPairError, null
        cb null

earliestSubmissionCache = {}
findEarliestSubmission = (queryParams, callback) ->
  cacheKey = JSON.stringify queryParams
  return callback null, cached if cached = earliestSubmissionCache[cacheKey]
  LevelSession.findOne(queryParams).sort(submitDate: 1).lean().exec (err, earliest) ->
    return callback err if err
    result = earliestSubmissionCache[cacheKey] = earliest?.submitDate
    callback null, result

findRandomSession = (queryParams, callback) ->
  # We pick a random submitDate between the first submit date for the level and now, then do a $lt fetch to find a session to simulate.
  # We bias it towards recently submitted sessions.
  queryParams.submitted = true
  findEarliestSubmission queryParams, (err, startDate) ->
    return callback err, null unless startDate
    now = new Date()
    interval = now - startDate
    cutoff = new Date now - Math.pow(Math.random(), 2) * interval
    queryParams.submitDate = $gte: startDate, $lt: cutoff
    selection = 'team totalScore transpiledCode submittedCodeLanguage teamSpells levelID creatorName creator submitDate'
    LevelSession.findOne(queryParams).sort(submitDate: -1).select(selection).lean().exec (err, session) ->
      return callback err if err
      callback null, session

formatSessionInformation = (session) ->
  sessionID: session._id
  team: session.team ? 'No team'
  transpiledCode: session.transpiledCode
  submittedCodeLanguage: session.submittedCodeLanguage
  teamSpells: session.teamSpells ? {}
  levelID: session.levelID
  creatorName: session.creatorName
  creator: session.creator
  totalScore: session.totalScore

module.exports.getTwoGames = (req, res) ->
  #if isUserAnonymous req then return errors.unauthorized(res, 'You need to be logged in to get games.')
  humansGameID = req.body.humansGameID
  ogresGameID = req.body.ogresGameID
  return if simulatorIsTooOld req, res
  #ladderGameIDs = ['greed', 'criss-cross', 'brawlwood', 'dungeon-arena', 'gold-rush', 'sky-span']  # Let's not give any extra simulations to old ladders.
  ladderGameIDs = ['dueling-grounds', 'cavern-survival', 'multiplayer-treasure-grove', 'harrowland']  #, 'zero-sum']
  levelID = _.sample ladderGameIDs
  unless ogresGameID and humansGameID
    async.map [{levelID: levelID, team: 'humans'}, {levelID: levelID, team: 'ogres'}], findRandomSession, (err, sessions) ->
      if err then return errors.serverError(res, "Couldn't get two games to simulate for #{levelID}.")
      unless sessions.length is 2
        res.send(204, 'No games to score.')
        return res.end()
      taskObject = messageGenerated: Date.now(), sessions: (formatSessionInformation session for session in sessions)
      #console.log 'Dispatching random game between', taskObject.sessions[0].creatorName, 'and', taskObject.sessions[1].creatorName
      sendResponseObject req, res, taskObject
  else
    #console.log "Directly simulating #{humansGameID} vs. #{ogresGameID}."
    LevelSession.findOne(_id: humansGameID).select(selection).lean().exec (err, humanSession) =>
      if err? then return errors.serverError(res, 'Couldn\'t find the human game')
      LevelSession.findOne(_id: ogresGameID).select(selection).lean().exec (err, ogreSession) =>
        if err? then return errors.serverError(res, 'Couldn\'t find the ogre game')
        taskObject = messageGenerated: Date.now(), sessions: (formatSessionInformation session for session in [humanSession, ogreSession])
        sendResponseObject req, res, taskObject

module.exports.recordTwoGames = (req, res) ->
  sessions = req.body.sessions
  #console.log 'Recording non-chained result of', sessions?[0]?.name, sessions[0]?.metrics?.rank, 'and', sessions?[1]?.name, sessions?[1]?.metrics?.rank
  return if simulatorIsTooOld req, res
  req.body?.simulator?.user = '' + req.user?._id

  yetiGuru = clientResponseObject: req.body, isRandomMatch: true
  async.waterfall [
    fetchLevelSession.bind(yetiGuru)
    updateSessions.bind(yetiGuru)
    indexNewScoreArray.bind(yetiGuru)
    addMatchToSessions.bind(yetiGuru)
    updateUserSimulationCounts.bind(yetiGuru, req.user?._id)
  ], (err, successMessageObject) ->
    if err? then return errors.serverError res, "There was an error recording the single game:#{err}"
    sendResponseObject req, res, {'message': 'The single game was submitted successfully!'}

module.exports.createNewTask = (req, res) ->
  requestSessionID = req.body.session
  originalLevelID = req.body.originalLevelID
  currentLevelID = req.body.levelID
  transpiledCode = req.body.transpiledCode
  requestLevelMajorVersion = parseInt(req.body.levelMajorVersion)

  yetiGuru = {}
  async.waterfall [
    validatePermissions.bind(yetiGuru, req, requestSessionID)
    fetchAndVerifyLevelType.bind(yetiGuru, currentLevelID)
    fetchSessionObjectToSubmit.bind(yetiGuru, requestSessionID)
    updateSessionToSubmit.bind(yetiGuru, transpiledCode)
    fetchInitialSessionsToRankAgainst.bind(yetiGuru, requestLevelMajorVersion, originalLevelID)
    generateAndSendTaskPairsToTheQueue
  ], (err, successMessageObject) ->
    if err? then return errors.serverError res, "There was an error submitting the game to the queue:#{err}"
    sendResponseObject req, res, successMessageObject

validatePermissions = (req, sessionID, callback) ->
  if isUserAnonymous req then return callback 'You are unauthorized to submit that game to the simulator'
  if isUserAdmin req then return callback null

  findParameters =
    _id: sessionID
  selectString = 'creator submittedCode code'
  query = LevelSession
  .findOne(findParameters)
  .select(selectString)
  .lean()

  query.exec (err, retrievedSession) ->
    if err? then return callback err
    userHasPermissionToSubmitCode = retrievedSession.creator is req.user?.id and
      not _.isEqual(retrievedSession.code, retrievedSession.submittedCode)
    unless userHasPermissionToSubmitCode then return callback 'You are unauthorized to submit that game to the simulator'
    callback null

fetchAndVerifyLevelType = (levelID, cb) ->
  findParameters =
    _id: levelID
  selectString = 'type'

  query = Level
  .findOne(findParameters)
  .select(selectString)
  .lean()
  query.exec (err, levelWithType) ->
    if err? then return cb err
    if not levelWithType.type or not (levelWithType.type in ['ladder', 'hero-ladder']) then return cb 'Level isn\'t of type "ladder"'
    cb null

fetchSessionObjectToSubmit = (sessionID, callback) ->
  findParameters =
    _id: sessionID
  selectString = 'team code'

  query = LevelSession
  .findOne(findParameters)
  .select(selectString)

  query.exec (err, session) ->
    callback err, session?.toObject()

updateSessionToSubmit = (transpiledCode, sessionToUpdate, callback) ->
  sessionUpdateObject =
    submitted: true
    submittedCode: sessionToUpdate.code
    transpiledCode: transpiledCode
    submitDate: new Date()
    #meanStrength: 25  # Let's try not resetting the score on resubmission
    standardDeviation: 25/3
    #totalScore: 10  # Let's try not resetting the score on resubmission
    numberOfWinsAndTies: 0
    numberOfLosses: 0
    isRanking: true
  LevelSession.update {_id: sessionToUpdate._id}, sessionUpdateObject, (err, result) ->
    callback err, sessionToUpdate

fetchInitialSessionsToRankAgainst = (levelMajorVersion, levelID, submittedSession, callback) ->
  opposingTeam = calculateOpposingTeam(submittedSession.team)

  findParameters =
    'level.original': levelID
    'level.majorVersion': levelMajorVersion
    submitted: true
    submittedCode:
      $exists: true
    team: opposingTeam

  sortParameters =
    totalScore: 1

  limitNumber = 1
  query = LevelSession.aggregate [
    {$match: findParameters}
    {$sort: sortParameters}
    {$limit: limitNumber}
  ]

  query.exec (err, sessionToRankAgainst) ->
    callback err, sessionToRankAgainst, submittedSession

generateAndSendTaskPairsToTheQueue = (sessionToRankAgainst, submittedSession, callback) ->
  taskPairs = generateTaskPairs(sessionToRankAgainst, submittedSession)
  sendEachTaskPairToTheQueue taskPairs, (taskPairError) ->
    if taskPairError? then return callback taskPairError
    #console.log 'Sent task pairs to the queue!'
    #console.log taskPairs
    callback null, {'message': 'All task pairs were succesfully sent to the queue'}

module.exports.dispatchTaskToConsumer = (req, res) ->
  yetiGuru = {}
  async.waterfall [
    checkSimulationPermissions.bind(yetiGuru, req)
    receiveMessageFromSimulationQueue
    changeMessageVisibilityTimeout
    parseTaskQueueMessage
    constructTaskObject
    constructTaskLogObject.bind(yetiGuru, getUserIDFromRequest(req))
    processTaskObject
  ], (err, taskObjectToSend) ->
    if err?
      if typeof err is 'string' and err.indexOf 'No more games in the queue' isnt -1
        res.send(204, 'No games to score.')
        return res.end()
      else
        return errors.serverError res, "There was an error dispatching the task: #{err}"
    sendResponseObject req, res, taskObjectToSend

checkSimulationPermissions = (req, cb) ->
  if isUserAnonymous req
    cb 'You need to be logged in to simulate games'
  else
    cb null

receiveMessageFromSimulationQueue = (cb) ->
  scoringTaskQueue.receiveMessage (err, message) ->
    if err? then return cb "No more games in the queue, error:#{err}"
    if messageIsInvalid(message) then return cb 'Message received from queue is invalid'
    cb null, message

changeMessageVisibilityTimeout = (message, cb) ->
  message.changeMessageVisibilityTimeout scoringTaskTimeoutInSeconds, (err) -> cb err, message

parseTaskQueueMessage = (message, cb) ->
  try
    if typeof message.getBody() is 'object'
      messageBody = message.getBody()
    else
      messageBody = JSON.parse message.getBody()
    cb null, messageBody, message
  catch e
    cb "There was an error parsing the task.Error: #{e}"

constructTaskObject = (taskMessageBody, message, callback) ->
  async.map taskMessageBody.sessions, getSessionInformation, (err, sessions) ->
    if err? then return callback err
    taskObject = messageGenerated: Date.now(), sessions: (formatSessionInformation session for session in sessions)
    callback null, taskObject, message

constructTaskLogObject = (calculatorUserID, taskObject, message, callback) ->
  taskLogObject = new TaskLog
    'createdAt': new Date()
    'calculator': calculatorUserID
    'sentDate': Date.now()
    'messageIdentifierString': message.getReceiptHandle()
  taskLogObject.save (err) -> callback err, taskObject, taskLogObject, message

processTaskObject = (taskObject, taskLogObject, message, cb) ->
  taskObject.taskID = taskLogObject._id
  taskObject.receiptHandle = message.getReceiptHandle()
  cb null, taskObject

getSessionInformation = (sessionIDString, callback) ->
  findParameters =
    _id: sessionIDString
  selectString = 'submitDate team submittedCode teamSpells levelID creator creatorName transpiledCode submittedCodeLanguage totalScore'
  query = LevelSession
  .findOne(findParameters)
  .select(selectString)
  .lean()

  query.exec (err, session) ->
    if err? then return callback err, {'error': 'There was an error retrieving the session.'}
    callback null, session

module.exports.processTaskResult = (req, res) ->
  return if simulatorIsTooOld req, res
  originalSessionID = req.body?.originalSessionID
  req.body?.simulator?.user = '' + req.user?._id
  yetiGuru = {}
  try
    async.waterfall [
      verifyClientResponse.bind(yetiGuru, req.body)
      fetchTaskLog.bind(yetiGuru)
      checkTaskLog.bind(yetiGuru)
      deleteQueueMessage.bind(yetiGuru)
      fetchLevelSession.bind(yetiGuru)
      checkSubmissionDate.bind(yetiGuru)
      logTaskComputation.bind(yetiGuru)
      updateSessions.bind(yetiGuru)
      indexNewScoreArray.bind(yetiGuru)
      addMatchToSessions.bind(yetiGuru)
      updateUserSimulationCounts.bind(yetiGuru, req.user?._id)
      determineIfSessionShouldContinueAndUpdateLog.bind(yetiGuru)
      findNearestBetterSessionID.bind(yetiGuru)
      addNewSessionsToQueue.bind(yetiGuru)
    ], (err, results) ->
      if err is 'shouldn\'t continue'
        markSessionAsDoneRanking originalSessionID, (err) ->
          if err? then return sendResponseObject req, res, {'error': 'There was an error marking the session as done ranking'}
          sendResponseObject req, res, {'message': 'The scores were updated successfully, person lost so no more games are being inserted!'}
      else if err is 'no session was found'
        markSessionAsDoneRanking originalSessionID, (err) ->
          if err? then return sendResponseObject req, res, {'error': 'There was an error marking the session as done ranking'}
          sendResponseObject req, res, {'message': 'There were no more games to rank (game is at top)!'}
      else if err?
        errors.serverError res, "There was an error:#{err}"
      else
        sendResponseObject req, res, {'message': 'The scores were updated successfully and more games were sent to the queue!'}
  catch e
    errors.serverError res, 'There was an error processing the task result!'

verifyClientResponse = (responseObject, callback) ->
  #TODO: better verification
  if typeof responseObject isnt 'object' or responseObject?.originalSessionID?.length isnt 24
    callback 'The response to that query is required to be a JSON object.'
  else
    @clientResponseObject = responseObject

    #log.info 'Verified client response!'
    callback null, responseObject

fetchTaskLog = (responseObject, callback) ->
  query = TaskLog.findOne _id: responseObject.taskID
  query.exec (err, taskLog) =>
    return callback new Error("Couldn't find TaskLog for _id #{responseObject.taskID}!") unless taskLog
    @taskLog = taskLog
    #log.info 'Fetched task log!'
    callback err, taskLog.toObject()

checkTaskLog = (taskLog, callback) ->
  if taskLog.calculationTimeMS then return callback 'That computational task has already been performed'
  if hasTaskTimedOut taskLog.sentDate then return callback 'The task has timed out'
  #log.info 'Checked task log'
  callback null

deleteQueueMessage = (callback) ->
  scoringTaskQueue.deleteMessage @clientResponseObject.receiptHandle, (err) ->
    #log.info 'Deleted queue message'
    callback err

fetchLevelSession = (callback) ->
  findParameters =
    _id: @clientResponseObject.originalSessionID

  query = LevelSession
  .findOne(findParameters)
  .lean()
  query.exec (err, session) =>
    @levelSession = session
    #log.info 'Fetched level session'
    callback err

checkSubmissionDate = (callback) ->
  supposedSubmissionDate = new Date(@clientResponseObject.sessions[0].submitDate)
  if Number(supposedSubmissionDate) isnt Number(@levelSession.submitDate)
    callback 'The game has been resubmitted. Removing from queue...'
  else
    #log.info 'Checked submission date'
    callback null

logTaskComputation = (callback) ->
  @taskLog.set('calculationTimeMS', @clientResponseObject.calculationTimeMS)
  @taskLog.set('sessions')
  @taskLog.calculationTimeMS = @clientResponseObject.calculationTimeMS
  @taskLog.sessions = @clientResponseObject.sessions
  @taskLog.save (err, saved) ->
    #log.info 'Logged task computation'
    callback err

updateSessions = (callback) ->
  sessionIDs = _.pluck @clientResponseObject.sessions, 'sessionID'

  async.map sessionIDs, retrieveOldSessionData, (err, oldScores) =>
    if err? then callback err, {'error': 'There was an error retrieving the old scores'}
    try
      oldScoreArray = _.toArray putRankingFromMetricsIntoScoreObject @clientResponseObject, oldScores
      newScoreArray = bayes.updatePlayerSkills oldScoreArray
      saveNewScoresToDatabase newScoreArray, callback
    catch e
      callback e

saveNewScoresToDatabase = (newScoreArray, callback) ->
  async.eachSeries newScoreArray, updateScoreInSession, (err) ->
    #log.info 'Saved new scores to database'
    callback err, newScoreArray

updateScoreInSession = (scoreObject, callback) ->
  LevelSession.findOne {'_id': scoreObject.id}, (err, session) ->
    if err? then return callback err, null

    session = session.toObject()
    newTotalScore = scoreObject.meanStrength - 1.8 * scoreObject.standardDeviation
    scoreHistoryAddition = [Date.now(), newTotalScore]
    updateObject =
      meanStrength: scoreObject.meanStrength
      standardDeviation: scoreObject.standardDeviation
      totalScore: newTotalScore
      $push: {scoreHistory: {$each: [scoreHistoryAddition], $slice: -1000}}

    LevelSession.update {'_id': scoreObject.id}, updateObject, callback
    #log.info "New total score for session #{scoreObject.id} is #{updateObject.totalScore}"

indexNewScoreArray = (newScoreArray, callback) ->
  newScoresObject = _.indexBy newScoreArray, 'id'
  @newScoresObject = newScoresObject
  callback null, newScoresObject

addMatchToSessions = (newScoreObject, callback) ->
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

  #log.info "Match object computed, result: #{matchObject}"
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
  currentMatchObject.simulator = @clientResponseObject.simulator
  currentMatchObject.randomSeed = parseInt(@clientResponseObject.randomSeed or 0, 10)
  LevelSession.findOne {'_id': sessionID}, (err, session) ->
    session = session.toObject()
    currentMatchObject.playtime = session.playtime ? 0
    sessionUpdateObject =
      $push: {matches: {$each: [currentMatchObject], $slice: -200}}
    #log.info "Updating session #{sessionID}"
    LevelSession.update {'_id': sessionID}, sessionUpdateObject, callback

updateUserSimulationCounts = (reqUserID, callback) ->
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

determineIfSessionShouldContinueAndUpdateLog = (cb) ->
  sessionID = @clientResponseObject.originalSessionID
  sessionRank = parseInt @clientResponseObject.originalSessionRank

  queryParameters =
    _id: sessionID

  updateParameters =
    '$inc': {}

  if sessionRank is 0
    updateParameters['$inc'] = {numberOfWinsAndTies: 1}
  else
    updateParameters['$inc'] = {numberOfLosses: 1}

  LevelSession.findOneAndUpdate queryParameters, updateParameters, {select: 'numberOfWinsAndTies numberOfLosses'}, (err, updatedSession) ->
    if err? then return cb err, updatedSession
    updatedSession = updatedSession.toObject()

    totalNumberOfGamesPlayed = updatedSession.numberOfWinsAndTies + updatedSession.numberOfLosses
    if totalNumberOfGamesPlayed < 10
      #console.log 'Number of games played is less than 10, continuing...'
      cb null
    else
      ratio = (updatedSession.numberOfLosses) / (totalNumberOfGamesPlayed)
      if ratio > 0.33
        cb 'shouldn\'t continue'
        #console.log "Ratio(#{ratio}) is bad, ending simulation"
      else
        #console.log "Ratio(#{ratio}) is good, so continuing simulations"
        cb null

findNearestBetterSessionID = (cb) ->
  try
    levelOriginalID = @levelSession.level.original
    levelMajorVersion = @levelSession.level.majorVersion
    sessionID = @clientResponseObject.originalSessionID
    sessionTotalScore = @newScoresObject[sessionID].totalScore
    opponentSessionID = _.pull(_.keys(@newScoresObject), sessionID)
    opponentSessionTotalScore = @newScoresObject[opponentSessionID].totalScore
    opposingTeam = calculateOpposingTeam(@clientResponseObject.originalSessionTeam)
  catch e
    cb e

  retrieveAllOpponentSessionIDs sessionID, (err, opponentSessionIDs) ->
    if err? then return cb err, null

    queryParameters =
      totalScore:
        $gt: opponentSessionTotalScore
      _id:
        $nin: opponentSessionIDs
      'level.original': levelOriginalID
      'level.majorVersion': levelMajorVersion
      submitted: true
      submittedCode:
        $exists: true
      team: opposingTeam

    if opponentSessionTotalScore < 30
      # Don't play a ton of matches at low scores--skip some in proportion to how close to 30 we are.
      # TODO: this could be made a lot more flexible.
      queryParameters['totalScore']['$gt'] = opponentSessionTotalScore + 2 * (30 - opponentSessionTotalScore) / 20

    limitNumber = 1

    sortParameters =
      totalScore: 1

    selectString = '_id totalScore'

    query = LevelSession.findOne(queryParameters)
    .sort(sortParameters)
    .limit(limitNumber)
    .select(selectString)
    .lean()

    #console.log "Finding session with score near #{opponentSessionTotalScore}"
    query.exec (err, session) ->
      if err? then return cb err, session
      unless session then return cb 'no session was found'
      #console.log "Found session with score #{session.totalScore}"
      cb err, session._id

retrieveAllOpponentSessionIDs = (sessionID, cb) ->
  query = LevelSession.findOne({'_id': sessionID})
  .select('matches.opponents.sessionID matches.date submitDate')
  .lean()
  query.exec (err, session) ->
    if err? then return cb err, null
    opponentSessionIDs = (match.opponents[0].sessionID for match in session.matches when match.date > session.submitDate)
    cb err, opponentSessionIDs

calculateOpposingTeam = (sessionTeam) ->
  teams = ['ogres', 'humans']
  opposingTeams = _.pull teams, sessionTeam
  return opposingTeams[0]

addNewSessionsToQueue = (sessionID, callback) ->
  sessions = [@clientResponseObject.originalSessionID, sessionID]
  addPairwiseTaskToQueue sessions, callback

messageIsInvalid = (message) -> (not message?) or message.isEmpty()

sendEachTaskPairToTheQueue = (taskPairs, callback) -> async.each taskPairs, sendTaskPairToQueue, callback

generateTaskPairs = (submittedSessions, sessionToScore) ->
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

sendTaskPairToQueue = (taskPair, callback) ->
  scoringTaskQueue.sendMessage {sessions: taskPair}, 5, (err, data) -> callback? err, data

getUserIDFromRequest = (req) -> if req.user? then return req.user._id else return null

isUserAnonymous = (req) -> if req.user? then return req.user.get('anonymous') else return true

isUserAdmin = (req) -> return Boolean(req.user?.isAdmin())

sendResponseObject = (req, res, object) ->
  res.setHeader('Content-Type', 'application/json')
  res.send(object)
  res.end()

hasTaskTimedOut = (taskSentTimestamp) -> taskSentTimestamp + scoringTaskTimeoutInSeconds * 1000 < Date.now()

handleTimedOutTask = (req, res, taskBody) -> errors.clientTimeout res, 'The results weren\'t provided within the timeout'

putRankingFromMetricsIntoScoreObject = (taskObject, scoreObject) ->
  scoreObject = _.indexBy scoreObject, 'id'
  scoreObject[session.sessionID].gameRanking = session.metrics.rank for session in taskObject.sessions
  return scoreObject

retrieveOldSessionData = (sessionID, callback) ->
  LevelSession.findOne {'_id': sessionID}, (err, session) ->
    return callback err, {'error': 'There was an error retrieving the session.'} if err?

    session = session.toObject()
    oldScoreObject =
      'standardDeviation': session.standardDeviation ? 25/3
      'meanStrength': session.meanStrength ? 25
      'totalScore': session.totalScore ? (25 - 1.8*(25/3))
      'id': sessionID
      'submittedCodeLanguage': session.submittedCodeLanguage
    callback err, oldScoreObject

markSessionAsDoneRanking = (sessionID, cb) ->
  #console.log 'Marking session as done ranking...'
  LevelSession.update {'_id': sessionID}, {'isRanking': false}, cb

simulatorIsTooOld = (req, res) ->
  clientSimulator = req.body.simulator
  return false if clientSimulator?.version >= SIMULATOR_VERSION
  message = "Old simulator version #{clientSimulator?.version}, need to clear cache and get version #{SIMULATOR_VERSION}."
  log.debug "400: #{message}"
  res.send 400, message
  res.end()
  true
