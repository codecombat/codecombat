config = require '../../server_config'
winston = require 'winston'
mongoose = require 'mongoose'
async = require 'async'
errors = require '../commons/errors'
aws = require 'aws-sdk'
db = require './../routes/db'
mongoose = require 'mongoose'
events = require 'events'
queues = require '../commons/queue'
LevelSession = require '../levels/sessions/LevelSession'

connectToScoringQueue = ->
  unless queues.scoringTaskQueue
    queues.initializeScoringTaskQueue (err, data) ->
      winston.info "Connected to scoring task queue!"  unless err?

module.exports.setup = (app) ->
  connectToScoringQueue()

module.exports.dispatchTaskToConsumer = (req, res) ->
  queues.scoringTaskQueue.receiveMessage (err, message) ->

    if message.isEmpty()
      #TODO: Set message code as 504 Gateway Timeout
      sendResponseObject req, res, {"error":"No messages were received."}
    else
      messageBody = JSON.parse message.getBody()
      constructTaskObject messageBody, (taskConstructionError, taskObject) ->
        if taskConstructionError?
          sendResponseObject req, res, {"error":taskConstructionError}
        else
          sendResponseObject req, res, taskObject


module.exports.processTaskResult = (req, res) ->
  clientResponseObject = JSON.parse req.body
  res.end("You posted an object to score!")
  ###
  sampleClientResponseObject =
    "processorUserID": "51eb2714fa058cb20d0006ef" #user ID of the person processing
    "processingTime": 2745 #time in milliseconds
    "processedSessionID": "52dfeb17c8b5f435c7000025" #the processed session
    "processedSessionChangedTime": ISODate("2014-01-22T16:28:12.450Z") #to see if the session processed is the one in the database
    "playerResults": [
      {"ID":"51eb2714fa058cb20d0006ef", "team":"humans","metrics": {"reachedGoal":false, "rank":2}}
      {"ID":"51eb2714fa058cb20d00fedg", "team":"ogres","metrics": {"reachedGoal":true, "rank":1}}
    ]
  ###




sendResponseObject = (req,res,object) ->
  res.setHeader('Content-Type', 'application/json')
  res.send(object)
  res.end()


constructTaskObject = (taskMessageBody, callback) ->
  getSessionInformation taskMessageBody.sessionID, (err, sessionInformation) ->
    return callback err, data if err?
    taskObject =
      "messageGenerated": Date.now()
      "sessionID": sessionInformation.sessionID
      "sessionChangedTime": sessionInformation.changed
      "taskGeneratingPlayerID": sessionInformation.creator
      "code": sessionInformation.code
      "players": sessionInformation.players

    callback err, taskObject
    ###
    "players" : [
      {"ID":"51eb2714fa058cb20d0006ef", "team":"humans", "userCodeMap": "code goes here"}
      {"ID":"51eb2714fa058cb20d00fedg", "team":"ogres","userCodeMap": "code goes here"}
    ]
    ###



getSessionInformation = (sessionIDString, callback) ->
  LevelSession.findOne {"_id": sessionIDString }, (err, session) ->
    if err?
      callback err, {"error":"There was an error retrieving the session."}
    else
      session = session.toJSON()
      sessionInformation =
        "sessionID": session._id
        "players": _.cloneDeep session.players
        "code": _.cloneDeep session.code
        "changed": session.changed
        "creator": session.creator
      callback err, sessionInformation

processClientResponse = (clientResponseBody, callback) ->
  return



