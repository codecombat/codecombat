config = require '../../server_config'
log = require 'winston'
mongoose = require 'mongoose'
async = require 'async'
errors = require '../commons/errors'
aws = require 'aws-sdk'
db = require './../routes/db'
mongoose = require 'mongoose'
queues = require '../commons/queue'
LevelSession = require '../levels/sessions/LevelSession'
Level = require '../levels/Level'
User = require '../users/User'
TaskLog = require './task/ScoringTask'
bayes = new (require 'bayesian-battle')()

scoringTaskQueue = undefined
scoringTaskTimeoutInSeconds = 240


module.exports.setup = (app) -> connectToScoringQueue()

connectToScoringQueue = ->
  queues.initializeQueueClient ->
    queues.queueClient.registerQueue "scoring", {}, (error,data) ->
      if error? then throw new Error  "There was an error registering the scoring queue: #{error}"
      scoringTaskQueue = data
      log.info "Connected to scoring task queue!"

module.exports.messagesInQueueCount = (req, res) ->
  scoringTaskQueue.totalMessagesInQueue (err, count) ->
    if err? then return errors.serverError res, "There was an issue finding the Mongoose count:#{err}"
    response = String(count)
    res.send(response)
    res.end()


module.exports.addPairwiseTaskToQueueFromRequest = (req, res) ->
  taskPair = req.body.sessions
  addPairwiseTaskToQueue req.body.sessions (err, success) ->
    if err? then return errors.serverError res, "There was an error adding pairwise tasks: #{err}"
    sendResponseObject req, res, {"message":"All task pairs were succesfully sent to the queue"}


addPairwiseTaskToQueue = (taskPair, cb) ->
  LevelSession.findOne(_id:taskPair[0]).lean().exec (err, firstSession) =>
    if err? then return cb err, false
    LevelSession.find(_id:taskPair[1]).exec (err, secondSession) =>
      if err? then return cb err, false
      try
        taskPairs = generateTaskPairs(secondSession, firstSession)
      catch e
        if e then return cb e, false

      sendEachTaskPairToTheQueue taskPairs, (taskPairError) ->
        if taskPairError? then return cb taskPairError,false
        cb null, true

module.exports.resimulateAllSessions = (req, res) ->
  unless isUserAdmin req then return errors.unauthorized res, "Unauthorized. Even if you are authorized, you shouldn't do this"

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
    async.each result, resimulateSession.bind(@,originalLevelID,levelMajorVersion), (err) ->
      if err? then return errors.serverError res, err
      sendResponseObject req, res, {"message":"All task pairs were succesfully sent to the queue"}

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




module.exports.createNewTask = (req, res) ->
  requestSessionID = req.body.session
  originalLevelID = req.body.originalLevelID
  currentLevelID = req.body.levelID
  requestLevelMajorVersion = parseInt(req.body.levelMajorVersion)
  
  async.waterfall [
    validatePermissions.bind(@,req,requestSessionID)
    fetchAndVerifyLevelType.bind(@,currentLevelID)
    fetchSessionObjectToSubmit.bind(@, requestSessionID)
    updateSessionToSubmit
    fetchInitialSessionsToRankAgainst.bind(@, requestLevelMajorVersion, originalLevelID)
    generateAndSendTaskPairsToTheQueue
    
  ], (err, successMessageObject) ->
    if err? then return errors.serverError res, "There was an error submitting the game to the queue:#{err}"
    sendResponseObject req, res, successMessageObject

    
validatePermissions = (req,sessionID, callback) ->
  if isUserAnonymous req then return callback "You are unauthorized to submit that game to the simulator"
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
    unless userHasPermissionToSubmitCode then return callback "You are unauthorized to submit that game to the simulator"
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
    if not levelWithType.type or levelWithType.type isnt "ladder" then return cb "Level isn't of type 'ladder'"
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

updateSessionToSubmit = (sessionToUpdate, callback) ->
  sessionUpdateObject =
    submitted: true
    submittedCode: sessionToUpdate.code
    submitDate: new Date()
    meanStrength: 25
    standardDeviation: 25/3
    totalScore: 10
    numberOfWinsAndTies: 0
    numberOfLosses: 0
    isRanking: true
  LevelSession.update {_id: sessionToUpdate._id}, sessionUpdateObject, (err, result) ->
    callback err, sessionToUpdate

fetchInitialSessionsToRankAgainst = (levelMajorVersion, levelID, submittedSession, callback) ->
  opposingTeam = calculateOpposingTeam(submittedSession.team)

  findParameters =
    "level.original": levelID
    "level.majorVersion": levelMajorVersion
    submitted: true
    submittedCode:
      $exists: true
    team: opposingTeam

  sortParameters =
    totalScore: 1

  limitNumber = 1

  query = LevelSession.find(findParameters)
  .sort(sortParameters)
  .limit(limitNumber)

  query.exec (err, sessionToRankAgainst) ->
    callback err, sessionToRankAgainst, submittedSession


generateAndSendTaskPairsToTheQueue = (sessionToRankAgainst,submittedSession, callback) ->
  taskPairs = generateTaskPairs(sessionToRankAgainst, submittedSession)
  sendEachTaskPairToTheQueue taskPairs, (taskPairError) ->
    if taskPairError? then return callback taskPairError
    callback null, {"message": "All task pairs were succesfully sent to the queue"}
  

module.exports.dispatchTaskToConsumer = (req, res) ->
  async.waterfall [
    checkSimulationPermissions.bind(@,req)
    receiveMessageFromSimulationQueue
    changeMessageVisibilityTimeout
    parseTaskQueueMessage
    constructTaskObject
    constructTaskLogObject.bind(@, getUserIDFromRequest(req))
    processTaskObject
  ], (err, taskObjectToSend) ->
    if err? 
      if typeof err is "string" and err.indexOf "No more games in the queue" isnt -1
        res.send(204, "No games to score.")
        return res.end()
      else
        return errors.serverError res, "There was an error dispatching the task: #{err}"
    sendResponseObject req, res, taskObjectToSend

  
  
checkSimulationPermissions = (req, cb) ->
  if isUserAnonymous req 
    cb "You need to be logged in to simulate games"
  else
    cb null
    
receiveMessageFromSimulationQueue = (cb) ->
  scoringTaskQueue.receiveMessage (err, message) -> 
    if err? then return cb "No more games in the queue, error:#{err}"
    if messageIsInvalid(message) then return cb "Message received from queue is invalid"
    cb null, message

changeMessageVisibilityTimeout = (message, cb) ->
  message.changeMessageVisibilityTimeout scoringTaskTimeoutInSeconds, (err) -> cb err, message

parseTaskQueueMessage = (message,cb) ->
  try
    if typeof message.getBody() is "object"
      messageBody = message.getBody()
    else
      messageBody = JSON.parse message.getBody()
    cb null, messageBody, message
  catch e
    cb "There was an error parsing the task.Error: #{e}"

constructTaskObject = (taskMessageBody, message, callback) ->
  async.map taskMessageBody.sessions, getSessionInformation, (err, sessions) ->
    if err? then return callback err

    taskObject =
      "messageGenerated": Date.now()
      "sessions": []

    for session in sessions
      sessionInformation =
        "sessionID": session._id
        "submitDate": session.submitDate
        "team": session.team ? "No team"
        "code": session.submittedCode
        "teamSpells": session.teamSpells ? {}
        "levelID": session.levelID
        "creator": session.creator
        "creatorName":session.creatorName

      taskObject.sessions.push sessionInformation
    callback null, taskObject, message

constructTaskLogObject = (calculatorUserID, taskObject, message, callback) ->
  taskLogObject = new TaskLog
    "createdAt": new Date()
    "calculator":calculatorUserID
    "sentDate": Date.now()
    "messageIdentifierString":message.getReceiptHandle()
  taskLogObject.save (err) -> callback err, taskObject, taskLogObject, message

processTaskObject = (taskObject,taskLogObject, message, cb) ->
  taskObject.taskID = taskLogObject._id
  taskObject.receiptHandle = message.getReceiptHandle()
  cb null, taskObject

getSessionInformation = (sessionIDString, callback) ->
  findParameters = 
    _id: sessionIDString
  selectString = 'submitDate team submittedCode teamSpells levelID creator creatorName'
  query = LevelSession
    .findOne(findParameters)
    .select(selectString)
    .lean()
  
  query.exec (err, session) ->
    if err? then return callback err, {"error":"There was an error retrieving the session."}
    callback null, session


module.exports.processTaskResult = (req, res) ->
  clientResponseObject = verifyClientResponse req.body, res

  return unless clientResponseObject?
  TaskLog.findOne {_id: clientResponseObject.taskID}, (err, taskLog) ->
    return errors.serverError res, "There was an error retrieiving the task log object" if err?

    taskLogJSON = taskLog.toObject()

    return errors.badInput res, "That computational task has already been performed" if taskLogJSON.calculationTimeMS
    return handleTimedOutTask req, res, clientResponseObject if hasTaskTimedOut taskLogJSON.sentDate

    scoringTaskQueue.deleteMessage clientResponseObject.receiptHandle, (err) ->
      console.log "Deleted message."
      if err? then return errors.badInput res, "The queue message is already back in the queue, rejecting results."

      LevelSession.findOne(_id: clientResponseObject.originalSessionID).lean().exec (err, levelSession) ->
        if err? then return errors.serverError res, "There was a problem finding the level session:#{err}"

        supposedSubmissionDate = new Date(clientResponseObject.sessions[0].submitDate)

        if Number(supposedSubmissionDate) isnt Number(levelSession.submitDate)
          return sendResponseObject req, res, {"message":"The game has been resubmitted. Removing from queue..."}

        logTaskComputation clientResponseObject, taskLog, (logErr) ->
          if logErr? then return errors.serverError res, "There as a problem logging the task computation: #{logErr}"

          updateSessions clientResponseObject, (updateError, newScoreArray) ->
            if updateError? then return errors.serverError res, "There was an error updating the scores.#{updateError}"

            newScoresObject = _.indexBy newScoreArray, 'id'

            addMatchToSessions clientResponseObject, newScoresObject, (err, data) ->
              if err? then return errors.serverError res, "There was an error updating the sessions with the match! #{JSON.stringify err}"

              incrementUserSimulationCount req.user._id, 'simulatedBy'
              incrementUserSimulationCount levelSession.creator, 'simulatedFor'

              originalSessionID = clientResponseObject.originalSessionID
              originalSessionTeam = clientResponseObject.originalSessionTeam
              originalSessionRank = parseInt clientResponseObject.originalSessionRank

              determineIfSessionShouldContinueAndUpdateLog originalSessionID, originalSessionRank, (err, sessionShouldContinue) ->
                if err? then return errors.serverError res, "There was an error determining if the session should continue, #{err}"

                if sessionShouldContinue
                  opposingTeam = calculateOpposingTeam(originalSessionTeam)
                  opponentID = _.pull(_.keys(newScoresObject), originalSessionID)
                  sessionNewScore = newScoresObject[originalSessionID].totalScore
                  opponentNewScore = newScoresObject[opponentID].totalScore

                  levelOriginalID = levelSession.level.original
                  levelOriginalMajorVersion = levelSession.level.majorVersion
                  findNearestBetterSessionID levelOriginalID, levelOriginalMajorVersion, originalSessionID, sessionNewScore, opponentNewScore, opponentID, opposingTeam, (err, opponentSessionID) ->
                    if err? then return errors.serverError res, "There was an error finding the nearest sessionID!"
                    if opponentSessionID
                      addPairwiseTaskToQueue [originalSessionID, opponentSessionID], (err, success) ->
                        if err? then return errors.serverError res, "There was an error sending the pairwise tasks to the queue!"
                        sendResponseObject req, res, {"message":"The scores were updated successfully and more games were sent to the queue!"}
                    else
                      LevelSession.update {_id: originalSessionID}, {isRanking: false}, {multi: false}, (err, affected) ->
                        if err? then return errors.serverError res, "There was an error marking the victorious session as not being ranked."
                        return sendResponseObject req, res, {"message":"There were no more games to rank (game is at top)!"}
                else
                  console.log "Player lost, achieved rank #{originalSessionRank}"
                  LevelSession.update {_id: originalSessionID}, {isRanking: false}, {multi: false}, (err, affected) ->
                    if err? then return errors.serverError res, "There was an error marking the completed session as not being ranked."
                    sendResponseObject req, res, {"message":"The scores were updated successfully, person lost so no more games are being inserted!"}


determineIfSessionShouldContinueAndUpdateLog = (sessionID, sessionRank, cb) ->
  queryParameters =
    _id: sessionID

  updateParameters =
    "$inc": {}

  if sessionRank is 0
    updateParameters["$inc"] = {numberOfWinsAndTies: 1}
  else
    updateParameters["$inc"] = {numberOfLosses: 1}

  LevelSession.findOneAndUpdate queryParameters, updateParameters,{select: 'numberOfWinsAndTies numberOfLosses'}, (err, updatedSession) ->
    if err? then return cb err, updatedSession
    updatedSession = updatedSession.toObject()

    totalNumberOfGamesPlayed = updatedSession.numberOfWinsAndTies + updatedSession.numberOfLosses
    if totalNumberOfGamesPlayed < 10
      console.log "Number of games played is less than 10, continuing..."
      cb null, true
    else
      ratio = (updatedSession.numberOfLosses) / (totalNumberOfGamesPlayed)
      if ratio > 0.33
        cb null, false
        console.log "Ratio(#{ratio}) is bad, ending simulation"
      else
        console.log "Ratio(#{ratio}) is good, so continuing simulations"
        cb null, true


findNearestBetterSessionID = (levelOriginalID, levelMajorVersion, sessionID, sessionTotalScore, opponentSessionTotalScore, opponentSessionID, opposingTeam, cb) ->
  retrieveAllOpponentSessionIDs sessionID, (err, opponentSessionIDs) ->
    if err? then return cb err, null

    queryParameters =
      totalScore:
        $gt: opponentSessionTotalScore
      _id:
        $nin: opponentSessionIDs
      "level.original": levelOriginalID
      "level.majorVersion": levelMajorVersion
      submitted: true
      submittedCode:
        $exists: true
      team: opposingTeam

    if opponentSessionTotalScore < 30
      # Don't play a ton of matches at low scores--skip some in proportion to how close to 30 we are.
      # TODO: this could be made a lot more flexible.
      queryParameters["totalScore"]["$gt"] = opponentSessionTotalScore + 2 * (30 - opponentSessionTotalScore) / 20

    limitNumber = 1

    sortParameters =
      totalScore: 1

    selectString = '_id totalScore'

    query = LevelSession.findOne(queryParameters)
      .sort(sortParameters)
      .limit(limitNumber)
      .select(selectString)
      .lean()

    console.log "Finding session with score near #{opponentSessionTotalScore}"
    query.exec (err, session) ->
      if err? then return cb err, session
      unless session then return cb err, null
      console.log "Found session with score #{session.totalScore}"
      cb err, session._id


retrieveAllOpponentSessionIDs = (sessionID, cb) ->
  query = LevelSession.findOne({"_id":sessionID})
    .select('matches.opponents.sessionID matches.date submitDate')
    .lean()
  query.exec (err, session) ->
    if err? then return cb err, null
    opponentSessionIDs = (match.opponents[0].sessionID for match in session.matches when match.date > session.submitDate)
    cb err, opponentSessionIDs


calculateOpposingTeam = (sessionTeam) ->
  teams = ['ogres','humans']
  opposingTeams = _.pull teams, sessionTeam
  return opposingTeams[0]

incrementUserSimulationCount = (userID, type) ->
  inc = {}
  inc[type] = 1
  User.update {_id: userID}, {$inc: inc}, (err, affected) ->
    log.error "Error incrementing #{type} for #{userID}: #{err}" if err


addMatchToSessions = (clientResponseObject, newScoreObject, callback) ->
  matchObject = {}
  matchObject.date = new Date()
  matchObject.opponents = {}
  for session in clientResponseObject.sessions
    sessionID = session.sessionID
    matchObject.opponents[sessionID] = {}
    matchObject.opponents[sessionID].sessionID = sessionID
    matchObject.opponents[sessionID].userID = session.creator
    matchObject.opponents[sessionID].metrics = {}
    matchObject.opponents[sessionID].metrics.rank = Number(newScoreObject[sessionID].gameRanking)

  log.info "Match object computed, result: #{matchObject}"
  log.info "Writing match object to database..."
  #use bind with async to do the writes
  sessionIDs = _.pluck clientResponseObject.sessions, 'sessionID'
  async.each sessionIDs, updateMatchesInSession.bind(@,matchObject), (err) -> callback err, null

updateMatchesInSession = (matchObject, sessionID, callback) ->
  currentMatchObject = {}
  currentMatchObject.date = matchObject.date
  currentMatchObject.metrics = matchObject.opponents[sessionID].metrics
  opponentsClone = _.cloneDeep matchObject.opponents
  opponentsClone = _.omit opponentsClone, sessionID
  opponentsArray = _.toArray opponentsClone
  currentMatchObject.opponents = opponentsArray

  sessionUpdateObject =
    $push: {matches: {$each: [currentMatchObject], $slice: -200}}
  log.info "Updating session #{sessionID}"
  LevelSession.update {"_id":sessionID}, sessionUpdateObject, callback



messageIsInvalid = (message) -> (not message?) or message.isEmpty()

sendEachTaskPairToTheQueue = (taskPairs, callback) -> async.each taskPairs, sendTaskPairToQueue, callback






generateTaskPairs = (submittedSessions, sessionToScore) ->
  taskPairs = []
  for session in submittedSessions
    session = session.toObject()
    teams = ['ogres','humans']
    opposingTeams = _.pull teams, sessionToScore.team
    if String(session._id) isnt String(sessionToScore._id) and session.team in opposingTeams
      console.log "Adding game to taskPairs!"
      taskPairs.push [sessionToScore._id,String session._id]
  return taskPairs

sendTaskPairToQueue = (taskPair, callback) ->
  scoringTaskQueue.sendMessage {sessions: taskPair}, 5, (err,data) -> callback? err,data

getUserIDFromRequest = (req) -> if req.user? then return req.user._id else return null

isUserAnonymous = (req) -> if req.user? then return req.user.get('anonymous') else return true

isUserAdmin = (req) -> return Boolean(req.user?.isAdmin())





sendResponseObject = (req,res,object) ->
  res.setHeader('Content-Type', 'application/json')
  res.send(object)
  res.end()

hasTaskTimedOut = (taskSentTimestamp) -> taskSentTimestamp + scoringTaskTimeoutInSeconds * 1000 < Date.now()

handleTimedOutTask = (req, res, taskBody) -> errors.clientTimeout res, "The results weren't provided within the timeout"

verifyClientResponse = (responseObject, res) ->
  unless typeof responseObject is "object"
    errors.badInput res, "The response to that query is required to be a JSON object."
    null
  else
    responseObject

logTaskComputation = (taskObject,taskLogObject, callback) ->
  taskLogObject.calculationTimeMS = taskObject.calculationTimeMS
  taskLogObject.sessions = taskObject.sessions
  taskLogObject.save callback


updateSessions = (taskObject,callback) ->
  sessionIDs = _.pluck taskObject.sessions, 'sessionID'

  async.map sessionIDs, retrieveOldSessionData, (err, oldScores) ->
    if err? then callback err, {"error": "There was an error retrieving the old scores"}

    oldScoreArray = _.toArray putRankingFromMetricsIntoScoreObject taskObject, oldScores
    newScoreArray = bayes.updatePlayerSkills oldScoreArray
    saveNewScoresToDatabase newScoreArray, callback


saveNewScoresToDatabase = (newScoreArray, callback) ->
  async.eachSeries newScoreArray, updateScoreInSession, (err) -> callback err,newScoreArray


updateScoreInSession = (scoreObject,callback) ->
  LevelSession.findOne {"_id": scoreObject.id}, (err, session) ->
    if err? then return callback err, null

    session = session.toObject()
    newTotalScore = scoreObject.meanStrength - 1.8 * scoreObject.standardDeviation
    scoreHistoryAddition = [Date.now(), newTotalScore]
    updateObject =
      meanStrength: scoreObject.meanStrength
      standardDeviation: scoreObject.standardDeviation
      totalScore: newTotalScore
      $push: {scoreHistory: {$each: [scoreHistoryAddition], $slice: -1000}}

    LevelSession.update {"_id": scoreObject.id}, updateObject, callback
    log.info "New total score for session #{scoreObject.id} is #{updateObject.totalScore}"


putRankingFromMetricsIntoScoreObject = (taskObject,scoreObject) ->
  scoreObject = _.indexBy scoreObject, 'id'
  scoreObject[session.sessionID].gameRanking = session.metrics.rank for session in taskObject.sessions
  return scoreObject

retrieveOldSessionData = (sessionID, callback) ->
  LevelSession.findOne {"_id":sessionID}, (err, session) ->
    return callback err, {"error":"There was an error retrieving the session."} if err?

    session = session.toObject()
    oldScoreObject =
      "standardDeviation":session.standardDeviation ? 25/3
      "meanStrength":session.meanStrength ? 25
      "totalScore":session.totalScore ? (25 - 1.8*(25/3))
      "id": sessionID
    callback err, oldScoreObject
