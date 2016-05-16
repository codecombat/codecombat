log = require 'winston'
async = require 'async'
errors = require '../../commons/errors'
scoringUtils = require './scoringUtils'
LevelSession = require '../../models/LevelSession'
TaskLog = require './../../models/ScoringTask'

module.exports = dispatchTaskToConsumer = (req, res) ->
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
    scoringUtils.sendResponseObject res, taskObjectToSend


checkSimulationPermissions = (req, cb) ->
  if req.user?.get('email')
    cb null
  else
    cb 'You need to be logged in to simulate games'

receiveMessageFromSimulationQueue = (cb) ->
  scoringUtils.scoringTaskQueue.receiveMessage (err, message) ->
    if err? then return cb "No more games in the queue, error: #{err}"
    if not message? or message.isEmpty() then return cb 'Message received from queue is invalid'
    cb null, message

changeMessageVisibilityTimeout = (message, cb) ->
  message.changeMessageVisibilityTimeout scoringUtils.scoringTaskTimeoutInSeconds, (err) ->
    cb err, message

parseTaskQueueMessage = (message, cb) ->
  try
    messageBody = message.getBody()
    unless typeof messageBody is 'object'
      messageBody = JSON.parse messageBody
    cb null, messageBody, message
  catch e
    cb "There was an error parsing the task. Error: #{e}"

constructTaskObject = (taskMessageBody, message, callback) ->
  async.map taskMessageBody.sessions, getSessionInformation, (err, sessions) ->
    if err? then return callback err
    taskObject = messageGenerated: Date.now(), sessions: (scoringUtils.formatSessionInformation session for session in sessions)
    callback null, taskObject, message

getSessionInformation = (sessionIDString, callback) ->
  selectString = 'submitDate team submittedCode teamSpells levelID creator creatorName submittedCodeLanguage totalScore'
  LevelSession.findOne(_id: sessionIDString).select(selectString).lean().exec (err, session) ->
    if err? then return callback err, {'error': 'There was an error retrieving the session.'}
    callback null, scoringUtils.formatSessionInformation session

constructTaskLogObject = (calculatorUserID, taskObject, message, callback) ->
  taskLogObject = new TaskLog
    createdAt: new Date()
    calculator: calculatorUserID
    sentDate: Date.now()
    messageIdentifierString: message.getReceiptHandle()
  taskLogObject.save (err) ->
    callback err, taskObject, taskLogObject, message

getUserIDFromRequest = (req) ->
  if req.user? then return req.user._id else return null

processTaskObject = (taskObject, taskLogObject, message, cb) ->
  taskObject.taskID = taskLogObject._id
  taskObject.receiptHandle = message.getReceiptHandle()
  cb null, taskObject
