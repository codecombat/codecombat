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
TaskLog = require './task/ScoringTask'
bayes = new (require 'bayesian-battle')()

scoringTaskQueue = undefined
scoringTaskTimeoutInSeconds = 400


module.exports.setup = (app) -> connectToScoringQueue()

connectToScoringQueue = ->
  queues.initializeQueueClient ->
    queues.queueClient.registerQueue "scoring", {}, (error,data) ->
      if error? then throw new Error  "There was an error registering the scoring queue: #{error}"
      scoringTaskQueue = data
      log.info "Connected to scoring task queue!"

module.exports.createNewTask = (req, res) ->
  requestSessionID = req.body.session
  if isUserAnonymous req then return errors.forbidden res, "You need to be logged in to be added to the leaderboard"
  return errors.badInput res, "The session ID is invalid" unless typeof requestSessionID is "string"

  fetchSessionToSubmit requestSessionID, (err, sessionToSubmit) ->
    if err? then return errors.serverError res, "There was an error finding the given session."

    updateSessionToSubmit sessionToSubmit, (err, data) ->
      if err? then return errors.serverError res, "There was an error updating the session"

      fetchSessionsToRankAgainst (err, sessionsToRankAgainst) ->
        if err? then return errors.serverError res, "There was an error fetching the sessions to rank against"

        taskPairs = generateTaskPairs(sessionsToRankAgainst, sessionToSubmit)
        sendEachTaskPairToTheQueue taskPairs, (taskPairError) ->
          if taskPairError? then return errors.serverError res, "There was an error sending the task pairs to the queue"

          sendResponseObject req, res, {"message":"All task pairs were succesfully sent to the queue"}

module.exports.dispatchTaskToConsumer = (req, res) ->
  if isUserAnonymous(req) then return errors.forbidden res, "You need to be logged in to simulate games"

  scoringTaskQueue.receiveMessage (err, message) ->
    if err? or messageIsInvalid(message) then return errors.gatewayTimeoutError res, "Queue Receive Error:#{err}"
    console.log "Received Message"
    messageBody = parseTaskQueueMessage req, res, message
    return unless messageBody?

    constructTaskObject messageBody, (taskConstructionError, taskObject) ->
      if taskConstructionError? then return errors.serverError res, "There was an error constructing the scoring task"
      console.log "Constructed task body"
      message.changeMessageVisibilityTimeout scoringTaskTimeoutInSeconds, (err) ->
        if err? then return errors.serverError res, "There was an error changing the message visibility timeout."
        console.log "Changed visibility timeout"
        constructTaskLogObject getUserIDFromRequest(req),message.getReceiptHandle(), (taskLogError, taskLogObject) ->
          if taskLogError? then return errors.serverError res, "There was an error creating the task log object."

          taskObject.taskID = taskLogObject._id
          taskObject.receiptHandle = message.getReceiptHandle()

          sendResponseObject req, res, taskObject

module.exports.processTaskResult = (req, res) ->
  clientResponseObject = verifyClientResponse req.body, res

  return unless clientResponseObject?
  TaskLog.findOne {_id: clientResponseObject.taskID}, (err, taskLog) ->
    return errors.serverError res, "There was an error retrieiving the task log object" if err?

    taskLogJSON = taskLog.toObject()

    return errors.badInput res, "That computational task has already been performed" if taskLogJSON.calculationTimeMS
    return handleTimedOutTask req, res, clientResponseObject if hasTaskTimedOut taskLogJSON.sentDate

    scoringTaskQueue.deleteMessage clientResponseObject.receiptHandle, (err) ->
      if err? then return errors.badInput res, "The queue message is already back in the queue, rejecting results."

      logTaskComputation clientResponseObject, taskLog, (logErr) ->
        if logErr? then return errors.serverError res, "There as a problem logging the task computation: #{logErr}"

        updateSessions clientResponseObject, (updateError, newScoreArray) ->
          if updateError? then return errors.serverError res, "There was an error updating the scores.#{updateError}"

          newScoresObject = _.indexBy newScoreArray, 'id'

          addMatchToSessions clientResponseObject, newScoresObject, (err, data) ->
            if err? then return errors.serverError res, "There was an error updating the sessions with the match! #{JSON.stringify err}"
            console.log "Sending response object"
            sendResponseObject req, res, {"message":"The scores were updated successfully!"}


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
    $push: {matches: currentMatchObject}
  log.info "Updating session #{sessionID}"
  LevelSession.update {"_id":sessionID}, sessionUpdateObject, callback



messageIsInvalid = (message) -> (not message?) or message.isEmpty()

sendEachTaskPairToTheQueue = (taskPairs, callback) -> async.each taskPairs, sendTaskPairToQueue, callback

fetchSessionToSubmit = (submittedSessionID, callback) ->
  LevelSession.findOne {_id: submittedSessionID}, (err, session) -> callback err, session?.toObject()


updateSessionToSubmit = (sessionToUpdate, callback) ->
  sessionUpdateObject =
    submitted: true
    submittedCode: sessionToUpdate.code
    submitDate: new Date()
    matches: []
    meanStrength: 25
    standardDeviation: 25/3
    totalScore: 10
  LevelSession.update {_id: sessionToUpdate._id}, sessionUpdateObject, callback

fetchSessionsToRankAgainst = (callback) ->
  submittedSessionsQuery =
    levelID: "project-dota"
    submitted: true
    submittedCode:
      $exists: true
  LevelSession.find submittedSessionsQuery, callback

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
  scoringTaskQueue.sendMessage {sessions: taskPair}, 0, (err,data) -> callback? err,data

getUserIDFromRequest = (req) -> if req.user? then return req.user._id else return null

isUserAnonymous = (req) -> if req.user? then return req.user.get('anonymous') else return true

parseTaskQueueMessage = (req, res, message) ->
  try
    if typeof message.getBody() is "object" then return message.getBody()
    return messageBody = JSON.parse message.getBody()
  catch e
    sendResponseObject req, res, {"error":"There was an error parsing the task.Error: #{e}" }
    return null

constructTaskObject = (taskMessageBody, callback) ->
  async.map taskMessageBody.sessions, getSessionInformation, (err, sessions) ->
    return callback err, data if err?

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

      taskObject.sessions.push sessionInformation
    callback err, taskObject


getSessionInformation = (sessionIDString, callback) ->
  LevelSession.findOne {_id:sessionIDString}, (err, session) ->
    if err? then return callback err, {"error":"There was an error retrieving the session."}

    sessionInformation = session.toObject()
    callback err, sessionInformation


constructTaskLogObject = (calculatorUserID, messageIdentifierString, callback) ->
  taskLogObject = new TaskLog
    "createdAt": new Date()
    "calculator":calculatorUserID
    "sentDate": Date.now()
    "messageIdentifierString":messageIdentifierString
  taskLogObject.save callback

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
    updateObject =
      meanStrength: scoreObject.meanStrength
      standardDeviation: scoreObject.standardDeviation
      totalScore: scoreObject.meanStrength - 1.8 * scoreObject.standardDeviation
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

