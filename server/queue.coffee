config = require '../server_config'
winston = require 'winston'
mongoose = require 'mongoose'
async = require 'async'
errors = require './errors'
aws = require 'aws-sdk'
db = require './db'
mongoose = require 'mongoose'
events = require 'events'

queueClient = null
simulationQueue = null

module.exports.setupRoutes = (app) ->
  ###queueClient.registerQueue "simulationQueue", {}, (err,data) ->
    simulationQueue = data
    simulationQueue.subscribe 'message', (err, data) ->
      if data.Messages?
        winston.info "Receieved message #{data.Messages?[0].Body}"
        simulationQueue.deleteMessage data.Messages?[0].ReceiptHandle, ->
          winston.info "Deleted message"
###




module.exports.generateQueueClient = ->
  if config.isProduction
    queueClient = new SQSQueueClient()
  else
    queueClient = new MongoQueueClient()
  return queueClient


class SQSQueueClient
  constructor: ->
    @configure()
    @sqs = @generateSQSInstance()

  ###Public API###
  registerQueue: (queueName, options, callback) ->
    #returns new queue in data argument of callback
    @sqs.createQueue {QueueName: queueName}, (err,data) =>
      if err?
        winston.error("There was an error creating a new SQS queue, reason: #{JSON.stringify err}")
        throw new Error("Fatal SQS error, see Winston output")
      newQueue = new SQSQueue(queueName, data.QueueUrl, @sqs)
      callback err, newQueue
  ###Public API###
  configure: ->
    aws.config.update
      accessKeyId: config.queue.accessKeyId
      secretAccessKey: config.queue.secretAccessKey
      region: config.queue.region

  generateSQSInstance: ->
    new aws.SQS()


class SQSQueue extends events.EventEmitter
  constructor: (@queueName, @queueUrl, @sqs) ->

  subscribe: (eventName, callback) -> @on eventName, callback
  unsubscribe: (eventName, callback) -> @removeListener eventName, callback


  publish: (messageBody,delayInSeconds, callback) ->
    @sendMessage messageBody, delayInSeconds, callback

  receiveMessage: (callback) ->
    @sqs.receiveMessage {QueueUrl: @queueUrl, WaitTimeSeconds: 20}, (err, data) =>
      if err? then @emit 'error',err,data else @emit 'message',err,data
      callback? err,data

  deleteMessage: (receiptHandle, callback) ->
    @sqs.deleteMessage {QueueUrl: @queueUrl, ReceiptHandle: receiptHandle}, (err, data) =>
      if err? then @emit 'error',err,data else @emit 'message',err,data
      callback? err,data


  sendMessage: (messageBody, delaySeconds, callback) ->
    @sqs.sendMessage {QueueUrl: @queueUrl, MessageBody: messageBody, DelaySeconds: delaySeconds}, (err, data) =>
      if err? then @emit 'error',err,data else @emit 'sent',err, data
      callback? err,data

  listenForever: =>
    async.forever (asyncCallback) =>
      @receiveMessage (err, data) ->
        asyncCallback(null)




class MongoQueueClient
  constructor: ->
    @configure()
    @createMongoConnection()
    @messageModel = @generateMessageModel()

  ###Public API###
  registerQueue: (queueName, options, callback) ->
    newQueue = new MongoQueue queueName,options,this
    callback(null, newQueue)
  ###Public API###

  configure: ->
    @databaseAddress = db.generateDatabaseAddress()
    @mongoDatabaseName = config.mongoQueue.queueDatabaseName;

  createMongoConnection: ->
    @mongooseConnection = mongoose.createConnection "mongodb://#{@databaseAddress}/#{@mongoDatabaseName}"
    @mongooseConnection.on 'error', ->
      winston.error "There was an error connecting to the queue in MongoDB"
    @mongooseConnection.once 'open', ->
      winston.info "Successfully connected to MongoDB queue!"

  generateMessageModel: ->
    #do find something like: messages not processing, queue as current queue, visibility time before now, sort by insertion time, findOne
    schema = new mongoose.Schema
      messageBody : Object,
      processing: false,
      insertionTime: {type: Date, default: Date.now }
      queue: String
      scheduledVisibilityTime: Date
    @mongooseConnection.model 'Message',schema


class MongoQueue extends events.EventEmitter
  constructor: (@queueName, options, @Message) ->

  subscribe: (eventName, callback) -> @on eventName, callback
  unsubscribe: (eventName, callback) -> @removeListener eventName, callback

  publish: (messageBody, delayInSeconds, callback) ->
    @sendMessage messageBody, delayInSeconds, callback

  receieveMessage: (callback) ->
    conditions = {queue: @queueName, processing: false, scheduledVisibilityTime: {$lt:Date.now()}}
    options = {sort: 'insertionTime'}
    update = {$set:{processing: true}}
    @Message.findOneAndUpdate conditions, update, options, =>
      if err? then @emit 'error',err,data else @emit 'message',err,data
      callback? err,data

  deleteMessage: (receiptHandle, callback) ->
    #receiptHandle in this case is an ID
    conditions = {queue: @queueName, _id : receiptHandle}
    @Message.findOneAndRemove conditions, {}, =>
      if err? then @emit 'error',err,data else @emit 'message',err,data
      callback? err,data


  sendMessage: (messageBody, delaySeconds, callback) ->
    messageToSend = new @Message
      messageBody: messageBody
      processing: false
      queue: @queueName
      scheduledVisibilityTime: Date.now() + (delaySeconds * 1000)

    messageToSend.save (err,data) =>
      if err? then @emit 'error',err,data else @emit 'sent',err, data
      callback? err,data

  listenForever: =>
    async.forever (asyncCallback) =>
      @recieveMessage (err, data) ->
        asyncCallback(null)

















