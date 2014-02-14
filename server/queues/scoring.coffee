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
    queues.queueClient.registerQueue "scoring", {}, (err,data) ->
      throwScoringQueueRegistrationError(err) if err?
      scoringTaskQueue = data
      log.info "Connected to scoring task queue!"

throwScoringQueueRegistrationError = (error) ->
  log.error "There was an error registering the scoring queue: #{error}"
  throw new Error  "There was an error registering the scoring queue."

module.exports.createNewTask = (req, res) ->
  return errors.badInput res, "The session ID is invalid" unless typeof req.body.session is "string"
  LevelSession.findOne { "_id": req.body.session}, (err, sessionToScore) ->
    return errors.serverError res, "There was an error finding the given session." if err?
    sessionToScore = sessionToScore.toJSON()
    console.log "Ranking session of team #{sessionToScore.team}"

    LevelSession.update { "_id": req.body.session}, {"submitted":true}, (err, data) ->
      return errors.serverError res, "There was an error saving the submitted bool of the session." if err?
      LevelSession.find { "levelID": "project-dota", "submitted": true}, (err, submittedSessions) ->
        taskPairs = []
        for session in submittedSessions
          session = session.toObject()
          console.log "Attemping to add session of team #{session.team} to taskPairs..."
          if String(session._id) isnt req.body.session and session.team isnt sessionToScore.team and session.team in ["ogres","humans"]
            console.log "Adding game to taskPairs!"
            taskPairs.push [req.body.session,String session._id]
        async.each taskPairs, sendTaskPairToQueue, (taskPairError) ->
          return errors.serverError res, "There was an error sending the task pairs to the queue" if taskPairError?
          sendResponseObject req, res, {"message":"All task pairs were succesfully sent to the queue"}


sendTaskPairToQueue = (taskPair, callback) ->
  taskObject =
    sessions: taskPair

  scoringTaskQueue.sendMessage taskObject, 0, (err,data) ->
    callback err,data

module.exports.dispatchTaskToConsumer = (req, res) ->
  userID = getUserIDFromRequest req,res
  return errors.forbidden res, "You need to be logged in to simulate games" if isUserAnonymous req

  scoringTaskQueue.receiveMessage (taskQueueReceiveError, message) ->
    if (not message?) or message.isEmpty() or taskQueueReceiveError?
      return errors.gatewayTimeoutError res, "No messages were receieved from the queue. Msg:#{taskQueueReceiveError}"


    messageBody = parseTaskQueueMessage req, res, message
    return errors.serverError res, "There was an error parsing the queue message" unless messageBody?

    constructTaskObject messageBody, (taskConstructionError, taskObject) ->
      return errors.serverError res, "There was an error constructing the scoring task" if taskConstructionError?

      message.changeMessageVisibilityTimeout scoringTaskTimeoutInSeconds

      constructTaskLogObject userID,message.getReceiptHandle(), (taskLogError, taskLogObject) ->
        return errors.serverError res, "There was an error creating the task log object." if taskLogError?

        setTaskObjectTaskLogID taskObject, taskLogObject._id

        taskObject.receiptHandle = message.getReceiptHandle()

        sendResponseObject req, res, taskObject


getUserIDFromRequest = (req) -> if req.user? then return req.user._id else return null


isUserAnonymous = (req) -> if req.user? then return req.user.anonymous else return true


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
        "sessionID": session.sessionID
        "sessionChangedTime": session.changed
        "team": session.team ? "No team"
        "code": session.code
        "teamSpells": session.teamSpells ? {}
        "levelID": session.levelID

      taskObject.sessions.push sessionInformation
    callback err, taskObject


getSessionInformation = (sessionIDString, callback) ->
  LevelSession.findOne {"_id": sessionIDString }, (err, session) ->
    return callback err, {"error":"There was an error retrieving the session."} if err?

    session = session.toObject()
    sessionInformation =
      "sessionID": session._id
      "code": _.cloneDeep session.code
      "changed": session.changed
      "creator": session.creator
      "team": session.team
      "teamSpells": session.teamSpells
      "levelID": session.levelID

    callback err, sessionInformation


constructTaskLogObject = (calculatorUserID, messageIdentifierString, callback) ->
  taskLogObject = new TaskLog
    "createdAt": new Date()
    "calculator":calculatorUserID
    "sentDate": Date.now()
    "messageIdentifierString":messageIdentifierString

  taskLogObject.save callback


setTaskObjectTaskLogID = (taskObject, taskLogObjectID) -> taskObject.taskID = taskLogObjectID


sendResponseObject = (req,res,object) ->
  res.setHeader('Content-Type', 'application/json')
  res.send(object)
  res.end()

module.exports.processTaskResult = (req, res) ->
  clientResponseObject = verifyClientResponse req.body, res

  if clientResponseObject?
    TaskLog.findOne {"_id": clientResponseObject.taskID}, (err, taskLog) ->
      return errors.serverError res, "There was an error retrieiving the task log object" if err?

      taskLogJSON = taskLog.toObject()

      return errors.badInput res, "That computational task has already been performed" if taskLogJSON.calculationTimeMS
      return handleTimedOutTask req, res, clientResponseObject if hasTaskTimedOut taskLogJSON.sentDate
      destroyQueueMessage clientResponseObject.receiptHandle, (err) ->
        return errors.badInput res, "The queue message is already back in the queue, rejecting results." if err?

        logTaskComputation clientResponseObject, taskLog, (loggingError) ->
          if loggingError?
            return errors.serverError res, "There as a problem logging the task computation: #{loggingError}"

          updateScores clientResponseObject, (updatingScoresError, newScores) ->
            if updatingScoresError?
              return errors.serverError res, "There was an error updating the scores.#{updatingScoresError}"

            sendResponseObject req, res, {"message":"The scores were updated successfully!"}




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


updateScores = (taskObject,callback) ->
  sessionIDs = _.pluck taskObject.sessions, 'sessionID'

  async.map sessionIDs, retrieveOldScoreMetrics, (err, oldScores) ->
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

retrieveOldScoreMetrics = (sessionID, callback) ->
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




###Sample Messages
sampleQueueMessage =
  {
    "sessions": ["52dea9b77e486eeb97000001","52d981a73cf02dcf260003cb"]
  }

sampleUndoneTaskObject =
  "taskID": "507f191e810c19729de860ea"
  "sessions" : [
    {
      "ID":"52dfeb17c8b5f435c7000025"
      "sessionChangedTime": "2014-01-22T16:28:12.450Z"
      "team":"humans"
      "code": "code goes here"
    },
    {
      "ID":"51eb2714fa058cb20d00fedg"
      "sessionChangedTime": "2014-01-22T16:28:12.450Z"
      "team":"ogres"
      "code": "code goes here"
    }
  ]
sampleResponseObject =
  "taskID": "507f191e810c19729de860ea"
  "calculationTime":3201
  "sessions": [
    {
      "ID":"52dfeb17c8b5f435c7000025"
      "sessionChangedTime": "2014-01-22T16:28:12.450Z"
      "metrics": {
        "rank":2
      }
    },
    {
      "ID":"51eb2714fa058cb20d00fedg"
      "sessionChangedTime": "2014-01-22T16:28:12.450Z"
      "metrics": {
        "rank":1
      }
    }
  ]

sampleTaskLogObject=
{
  "_id":ObjectId("507f191e810c19729de860ea") #datestamp is built into objectId
  "calculatedBy":ObjectId("51eb2714fa058cb20d0006ef")
  "calculationTime":3201
  timedOut: false
  "sessions":[
    {
      "ID":ObjectId("52dfeb17c8b5f435c7000025")
      "metrics": {
        "rank":2
      }
    },
    {
      "ID":ObjectId("51eb2714fa058cb20d00feda")
      "metrics": {
        "rank":1
      }
    }
  ]
}

###