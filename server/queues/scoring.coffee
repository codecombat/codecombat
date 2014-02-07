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

scoringTaskQueue = undefined
scoringTaskTimeoutInSeconds = 20

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

      message.changeMessageVisibilityTimeout scoringTaskTimeoutInSeconds + 10 #10 seconds processing time

      constructTaskLogObject userID,message.getReceiptHandle(), (taskLogError, taskLogObject) ->
        return errors.serverError res, "There was an error creating the task log object." if taskLogError?

        taskObject.taskLogID = taskLogObject._id

        sendResponseObject req, res, taskObject


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

    session = session.toJSON()
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
  clientResponseObject = parseClientResponseObject req, res

  if clientResponseObject?

    return handleTimedOutTask req, res, clientResponseObject if hasTaskTimedOut clientResponseObject

    logTaskComputation clientResponseObject
    updateScores clientResponseObject


hasTaskTimedOut = (taskBody) ->

  taskBody.messageGenerated + scoringTaskTimeoutInSeconds < Date.now()

handleTimedOutTask = (req, res, taskBody) ->
  errors.clientError res, "The task results were not provided within a timely manner"



parseClientResponseObject = (req, res) ->
  try
    return JSON.parse req.body
  catch e
    errors.badInput res, "Unprocessable task response object."
    return null

logTaskComputation = (taskObject) ->
  return

updateScores = (taskObject) ->
  return




###Sample Messages
sampleQueueMessage =
  sessions: [
    "52dfeb17c8b5f435c7000025"
    "52dfe03ac8b5f435c7000009"
  ]

sampleUndoneTaskObject =
  "taskID": "507f191e810c19729de860ea"
  "messageGenerated": 1391811773418
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