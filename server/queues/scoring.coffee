config = require '../../server_config'
log = require 'winston'
mongoose = require 'mongoose'
async = require 'async'
errors = require '../commons/errors'
aws = require 'aws-sdk'
db = require './../routes/db'
queues = require '../commons/queue'
LevelSession = require '../models/LevelSession'
Level = require '../models/Level'
User = require '../models/User'
TaskLog = require './../models/ScoringTask'
scoringUtils = require './scoring/scoringUtils'
getTwoGames = require './scoring/getTwoGames'
recordTwoGames = require './scoring/recordTwoGames'
createNewTask = require './scoring/createNewTask'
dispatchTaskToConsumer = require './scoring/dispatchTaskToConsumer'
processTaskResult = require './scoring/processTaskResult'

module.exports.setup = (app) ->
  # Connect to scoring queue
  queues.initializeQueueClient ->
    queues.queueClient.registerQueue 'scoring', {}, (error, data) ->
      if error? then throw new Error "There was an error registering the scoring queue: #{error}"
      scoringUtils.scoringTaskQueue = data
      #log.info 'Connected to scoring task queue!'

module.exports.messagesInQueueCount = (req, res) ->
  scoringUtils.scoringTaskQueue.totalMessagesInQueue (err, count) ->
    if err? then return errors.serverError res, "There was an issue finding the Mongoose count:#{err}"
    response = String(count)
    res.send(response)
    res.end()

module.exports.addPairwiseTaskToQueueFromRequest = (req, res) ->
  taskPair = req.body.sessions
  scoringUtils.addPairwiseTaskToQueue req.body.sessions, (err, success) ->
    if err? then return errors.serverError res, "There was an error adding pairwise tasks: #{err}"
    scoringUtils.sendResponseObject res, {message: 'All task pairs were succesfully sent to the queue'}


module.exports.getTwoGames = getTwoGames
module.exports.recordTwoGames = recordTwoGames
module.exports.createNewTask = createNewTask
module.exports.dispatchTaskToConsumer = dispatchTaskToConsumer
module.exports.processTaskResult = processTaskResult
