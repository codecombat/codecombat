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
  generateQueueInstance()
  ###queueClient.registerQueue "simulationQueue", {}, (err,data) ->
    simulationQueue = data
    simulationQueue.subscribe 'message', (err, data) ->
      if data.Messages?
        winston.info "Receieved message #{data.Messages?[0].Body}"
        simulationQueue.deleteMessage data.Messages?[0].ReceiptHandle, ->
          winston.info "Deleted message"
###



generateQueueInstance = ->
  if config.isProduction
    queueClient = new SQSQueueClient()
  else
    queueClient = new MongoQueueClient()


class SQSQueueClient extends AbstractQueueClient
  constructor: ->
    @configure()
    @sqs = @generateSQSInstance()

  configure: ->
    aws.config.update
      accessKeyId: config.queue.accessKeyId
      secretAccessKey: config.queue.secretAccessKey
      region: config.queue.region

  registerQueue: (queueName, options, callback) ->
    #returns new queue in data argument of callback
    @sqs.createQueue {QueueName: queueName}, (err,data) =>
      if err?
        winston.error("There was an error creating a new SQS queue, reason: #{JSON.stringify err}")
        throw new Error("Fatal SQS error, see Winston output")
      newQueue = new SQSQueue(queueName, data.QueueUrl, @sqs)
      callback err, newQueue

  generateSQSInstance: ->
    new aws.SQS()


class SQSQueue extends events.EventEmitter
  constructor: (@queueName, @queueUrl, @sqs) ->

  subscribe: (eventName, callback) ->
    @on eventName, callback
    return {eventName, callback}

  unsubscribe: (subscriptionObject) ->
    @removeListener subscriptionObject.eventName, subscriptionObject.callback


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




class MongoQueueClient extends AbstractQueueClient
  constructor: ->
    @configure()

  registerQueue: (queueName, options, callback) ->
    channel = new MongoQueue queueName,options,this
    callback(null, channel)

  configure: ->
    @databaseAddress = db.generateDatabaseAddress()
    @mongoDatabaseName = config.mongoQueue.queueDatabaseName;
    @createMongoConnection()

  createMongoConnection: ->
    @mongooseConnection = mongoose.createConnection "mongodb://#{@databaseAddress}/#{@mongoDatabaseName}"
    @mongooseConnection.on 'error', ->
      winston.error "There was an error connecting to the queue in MongoDB"
    @mongooseConnection.once 'open', ->
      winston.info "Successfully connected to MongoDB queue!"



class MongoQueue extends events.EventEmitter
  constructor: (@queueName, options, mubSubClient) ->
    @channel = mubSubClient.channel queueName, options
    @subscribe 'message', receieveMessage
  subscribe: (eventName, callback) ->
    @channel.subscribe eventName, callback

  unsubscribe: (subscriptionObject) ->
    subscriptionObject.unsubscribe()

  publish: (messageBody, delayInSeconds, callback) ->
    #TODO: Mongo-based persistence of delayed messages
    setTimeout @channel.publish.bind(this), delayInSeconds * 1000, @queueName, messageBody, callback

  receieveMessage: (callback) ->
    throw new Error "MongoQueue does not support fetching one message, it continually listens"
  deleteMessage: (callback) ->
    throw new Error "MongoQueue "








