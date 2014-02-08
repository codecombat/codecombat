config = require '../../server_config'
winston = require 'winston'
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

connectToScoringQueue = ->
  queues.initializeQueueClient ->
    queues.queueClient.registerQueue "scoring", {}, (err,data) ->
      throwScoringQueueRegistrationError(err) if err?
      scoringTaskQueue = data
      winston.info "Connected to scoring task queue!"

throwScoringQueueRegistrationError = (error) ->
  winston.error "There was an error registering the scoring queue: #{error}"
  throw new Error  "There was an error registering the scoring queue."


module.exports.setup = (app) -> connectToScoringQueue()


module.exports.dispatchTaskToConsumer = (req, res) ->

  userID = getUserIDFromRequest req
  return errors.forbidden res, "You need to be logged in to simulate games" unless userID?

  scoringTaskQueue.receiveMessage (taskQueueReceiveError, message) ->
    if message.isEmpty() or taskQueueReceiveError?
      return errors.gatewayTimeoutError res, "No messages were receieved from the queue.#{taskQueueReceiveError}"

    messageBody = parseTaskQueueMessage req, res, message
    return errors.serverError res, "There was an error parsing the queue message" unless messageBody?

    constructTaskObject messageBody, (taskConstructionError, taskObject) ->
      return errors.serverError res, "There was an error constructing the scoring task" if taskConstructionError?

      taskProcessingTimeInSeconds = 10
      message.changeMessageVisibilityTimeout scoringTaskTimeoutInSeconds + taskProcessingTimeInSeconds

      constructTaskLogObject userID,message.getReceiptHandle(), (taskLogError, taskLogObject) ->
        return errors.serverError res, "There was an error creating the task log object." if taskLogError?

        setTaskObjectTaskLogID taskObject, taskLogObject._id

        sendResponseObject req, res, taskObject



setTaskObjectTaskLogID = (taskObject, taskLogObjectID) -> taskObject.taskID = taskLogObjectID

parseTaskQueueMessage = (req, res, message) ->
  try
    return messageBody = JSON.parse message.getBody()
  catch e
    sendResponseObject req, res, {"error":"There was an error parsing the task.Error: #{e}" }
    return null

getUserIDFromRequest = (req) ->
  if req.user? and req.user._id?
    return req.user._id
  else
    return null

constructTaskLogObject = (calculatorUserID, messageIdentifierString, callback) ->
  taskLogObject = new TaskLog
    "createdAt": new Date()
    "calculator":calculatorUserID
    "sentDate": Date.now()
    "messageIdentifierString":messageIdentifierString

  taskLogObject.save callback

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
        "team": session.team? "No team"
        "code": session.code
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


    callback err, sessionInformation


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

      #return errors.badInput res, "That computational task has already been performed" if taskLogJSON.calculationTimeMS
      #return handleTimedOutTask req, res, clientResponseObject if hasTaskTimedOut taskLogJSON.sentDate

      logTaskComputation clientResponseObject, taskLog, (loggingError) ->
        return errors.serverError res, "There as a problem logging the task computation: #{loggingError}" if loggingError?
        updateScores clientResponseObject, (updatingScoresError, newScores) ->
          return errors.serverError res, "There was an error updating the scores.#{updatingScoresError}" if updatingScoresError?
          sendResponseObject req, res, newScores



hasTaskTimedOut = (taskSentTimestamp) -> taskSentTimestamp + scoringTaskTimeoutInSeconds * 1000 < Date.now()

handleTimedOutTask = (req, res, taskBody) ->
  errors.clientTimeout res, "The task results were not provided within a timely manner"


verifyClientResponse = (responseObject, res) ->
  unless typeof responseObject is "object"
    errors.badInput res, "The response to that query is required to be a JSON object."
    return null
  return responseObject



logTaskComputation = (taskObject,taskLogObject, callback) ->
  taskLogObject.calculationTimeMS = taskObject.calculationTimeMS
  taskLogObject.sessions = taskObject.sessions
  taskLogObject.save (err) -> callback err



updateScores = (taskObject,callback) ->
  winston.info "Updating scores"
  sessionIDs = _.pluck taskObject.sessions, 'sessionID'
  async.map sessionIDs, retrieveOldScoreMetrics, (err, oldScores) ->
    callback err, {"error": "There was an error retrieving the old scores"} if err?
    oldScoreArray = _.toArray putRankingFromMetricsIntoScoreObject taskObject, oldScores

    newScoreArray = bayes.updatePlayerSkills oldScoreArray
    
    #TODO: database persistence here
    callback err, newScoreArray

putRankingFromMetricsIntoScoreObject = (taskObject,scoreObject) ->
  scoreObject = _.indexBy scoreObject, 'id'
  for session in taskObject.sessions
    scoreObject[session.sessionID].gameRanking = session.metrics.rank

  return scoreObject

retrieveOldScoreMetrics = (sessionID, callback) ->
  LevelSession.findOne {"_id":sessionID}, (err, session) ->
    return callback err, {"error":"There was an error retrieving the session."} if err?
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
  sessions: [
    "52dfeb17c8b5f435c7000025"
    "52dfe03ac8b5f435c7000009"
  ]

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