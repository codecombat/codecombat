config = require '../server_config'
winston = require 'winston'
mongoose = require 'mongoose'
async = require 'async'
errors = require './errors'
aws = require 'aws-sdk'
mubsub = require 'mubsub'
db = require './db'
events = require 'events'

queueClient = null
simulationQueue = null

module.exports.setupRoutes = (app) ->
  generateQueueInstance()
  queueClient.registerQueue "simulationQueue", {}, (err,data) ->
    simulationQueue = data
    simulationQueue.subscribe 'message', (err, data) ->
      winston.info "Receieved message #{data.Messages?[0].Body}"

    simulationQueue.listenForever()








generateQueueInstance = ->
  if config.isProduction || true
    queueClient = new SQSQueueClient()
  else
    queueClient = new MongoQueueClient()



class AbstractQueueClient
  registerQueue: (queueName, callback) ->
    return


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



class MongoQueueClient extends AbstractQueueClient
  constructor: ->
    @configure()
    @generateMubsubClientInstance()

  registerQueue: (queueName, options, callback) ->
    channel = @localQueueClient.channel(queueName, options)
    callback(null, channel)

  configure: ->
    @databaseAddress = databaseAddress = db.generateDatabaseAddress()

  generateMubsubClientInstance: ->
    @localQueueClient = mubsub(@databaseAddress)





class AbstractQueue
  configure: ->
    throw new Error "Subclasses must override the configure method"



class SQSQueue extends events.EventEmitter
  constructor: (@queueName, @queueUrl, @sqs) ->


  subscribe: (eventName, callback) ->
    this.on eventName, callback

  publish: (eventName) ->
    return



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





class LocalQueue extends AbstractQueue
  constructor: (queueName)->
    return

  configure: () ->
    @client = @generateMubsubClient


  generateMubsubClient: ->

    client = mubsub(databaseAddress)

  registerQueueAndReturnChannel: (queueName) ->
    return



