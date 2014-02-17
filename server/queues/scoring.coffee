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
  requestSessionID = getSessionIDFromRequest req
  if isUserAnonymous req then return errors.forbidden res, "You need to be logged in to be added to the leaderboard"
  return errors.badInput res, "The session ID is invalid" unless requestSessionID is "string"

  fetchSubmittedSession requestSessionID, (err, sessionToScore) ->
    if err? then return errors.serverError res, "There was an error finding the given session."

    updateSubmittedSession sessionToScore, (err, data) ->
    if err? then return errors.serverError res, "There was an error updating the session"

    fetchSessionsToRankAgainst (err, submittedSessions) ->
      if err? then return errors.serverError res, "There was an error fetching the sessions to rank against"

      taskPairs = generateTaskPairs(submittedSessions, sessionToScore)
      sendEachTaskPairToTheQueue taskPairs, (taskPairError) ->
        if taskPairError? then return errors.serverError res, "There was an error sending the task pairs to the queue"

        sendResponseObject req, res, {"message":"All task pairs were succesfully sent to the queue"}

module.exports.dispatchTaskToConsumer = (req, res) ->
  if isUserAnonymous(req) then return errors.forbidden res, "You need to be logged in to simulate games"

  scoringTaskQueue.receiveMessage (err, message) ->
    if err? or not messageIsInvalid(message) then return errors.gatewayTimeoutError res, "Queue Receive Error:#{err}"

    messageBody = parseTaskQueueMessage req, res, message
    return unless messageBody?

    constructTaskObject messageBody, (taskConstructionError, taskObject) ->
      if taskConstructionError? then return errors.serverError res, "There was an error constructing the scoring task"

      message.changeMessageVisibilityTimeout scoringTaskTimeoutInSeconds, (err) ->
        if err? then return errors.serverError res, "There was an error changing the message visibility timeout."

        constructTaskLogObject getUserIDFromRequest(req),message.getReceiptHandle(), (taskLogError, taskLogObject) ->
          if taskLogError? then return errors.serverError res, "There was an error creating the task log object."

          taskObject.taskID = taskLogObject._id
          taskObject.receiptHandle = message.getReceiptHandle()

          sendResponseObject req, res, taskObject

module.exports.processTaskResult = (req, res) ->
  clientResponseObject = verifyClientResponse req.body, res
  return unless clientResponseObject?

  taskLogQuery = _id: clientResponseObject.taskID

  TaskLog.findOne taskLogQuery, (err, taskLog) ->
    return errors.serverError res, "There was an error retrieiving the task log object" if err?

    taskLogJSON = taskLog.toObject()

    return errors.badInput res, "That computational task has already been performed" if taskLogJSON.calculationTimeMS
    return handleTimedOutTask req, res, clientResponseObject if hasTaskTimedOut taskLogJSON.sentDate

    destroyQueueMessage clientResponseObject.receiptHandle, (err) ->
      return errors.badInput res, "The queue message is already back in the queue, rejecting results." if err?

      logTaskComputation clientResponseObject, taskLog, (loggingErr) ->
        return errors.serverError res, "There as a problem logging the task computation: #{loggingErr}" if loggingErr?

        updateSessions clientResponseObject, (updateError, newScores) ->
          return errors.serverError res, "There was an error updating the scores.#{updateError}" if updateError?

          sendResponseObject req, res, {"message":"The scores were updated successfully!"}


messageIsInvalid = (message) -> (not message?) or message.isEmpty()

getSessionIDFromRequest = (req) -> req.body.session

sendEachTaskPairToTheQueue = (taskPairs, callback) -> async.each taskPairs, sendTaskPairToQueue, callback

fetchSubmittedSession = (submittedSessionID, callback) ->
  sessionQuery =
    _id: submittedSessionID
  LevelSession.findOne sessionQuery, (err, session) -> callback err, session?.toObject()


updateSubmittedSession = (sessionToUpdate, callback) ->
  sessionQuery =
    _id: sessionToUpdate._id

  sessionUpdateObject =
    submitted: true
    submittedCode: sessionToUpdate.code
    submitDate: new Date()

  LevelSession.update sessionQuery, sessionUpdateObject, callback

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
      taskPairs.push [req.body.session,String session._id]
  taskPairs

sendTaskPairToQueue = (taskPair, callback) ->
  taskObject =
    sessions: taskPair

  scoringTaskQueue.sendMessage taskObject, 0, (err,data) ->
    callback? err,data


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

      taskObject.sessions.push sessionInformation
    callback err, taskObject


getSessionInformation = (sessionIDString, callback) ->
  sessionQuery
    _id:sessionIDString

  LevelSession.findOne sessionQuery, (err, session) ->
    levelSessionFindOneError =
      "error":"There was an error retrieving the session."
    return callback err, levelSessionFindOneError if err?

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

destroyQueueMessage = (receiptHandle, callback) -> scoringTaskQueue.deleteMessage receiptHandle, callback

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
    callback err, {"error": "There was an error retrieving the old scores"} if err?

    oldScoreArray = _.toArray putRankingFromMetricsIntoScoreObject taskObject, oldScores

    newScoreArray = bayes.updatePlayerSkills oldScoreArray

    saveNewScoresToDatabase newScoreArray, callback


saveNewScoresToDatabase = (newScoreArray, callback) ->
  async.eachSeries newScoreArray, updateScoreInSession, (err) ->
    if err? then callback err, null else callback err, {"message":"All scores were saved successfully."}


updateScoreInSession = (scoreObject,callback) ->
  sessionObjectQuery =
    "_id": scoreObject.id

  LevelSession.findOne sessionObjectQuery, (err, session) ->
    return callback err, null if err?
    session = session.toObject()
    updateObject =
      meanStrength: scoreObject.meanStrength
      standardDeviation: scoreObject.standardDeviation
      totalScore: scoreObject.meanStrength - 1.8 * scoreObject.standardDeviation
    log.info "New total score for session #{scoreObject.id} is #{updateObject.totalScore}"
    LevelSession.update sessionObjectQuery, updateObject, callback


putRankingFromMetricsIntoScoreObject = (taskObject,scoreObject) ->
  scoreObject = _.indexBy scoreObject, 'id'

  for session in taskObject.sessions
    scoreObject[session.sessionID].gameRanking = session.metrics.rank

  scoreObject

retrieveOldSessionData = (sessionID, callback) ->
  sessionQuery =
    "_id":sessionID

  LevelSession.findOne sessionQuery, (err, session) ->
    return callback err, {"error":"There was an error retrieving the session."} if err?

    session = session.toObject()
    defaultScore = (25 - 1.8*(25/3))
    defaultStandardDeviation = 25/3

    oldScoreObject =
      "standardDeviation":session.standardDeviation ? defaultStandardDeviation
      "meanStrength":session.meanStrength ? 25
      "totalScore":session.totalScore ? defaultScore
      "id": sessionID

    callback err, oldScoreObject




