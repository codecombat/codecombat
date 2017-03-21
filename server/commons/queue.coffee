config = require '../../server_config'
log = require 'winston'
mongoose = require 'mongoose'
async = require 'async'
aws = require 'aws-sdk'
db = require './database'
mongoose = require 'mongoose'
events = require 'events'
crypto = require 'crypto'

module.exports.queueClient = undefined

defaultMessageVisibilityTimeoutInSeconds = 500
defaultMessageReceiptTimeout = 10

module.exports.initializeQueueClient = (cb) ->
  module.exports.queueClient = generateQueueClient() unless queueClient?

  cb?()

generateQueueClient = ->
  #if config.queue.accessKeyId
  if false #TODO: Change this in production
    queueClient = new SQSQueueClient()
  else
    queueClient = new MongoQueueClient()

class SQSQueueClient
  registerQueue: (queueName, options, callback) ->
    queueCreationOptions =
      QueueName: queueName

    @sqs.createQueue queueCreationOptions, (err, data) =>
      @_logAndThrowFatalException "There was an error creating a new SQS queue, reason: #{JSON.stringify err}" if err?

      newQueue = new SQSQueue queueName, data.QueueUrl, @sqs

      callback? err, newQueue

  constructor: ->
    @_configure()
    @sqs = @_generateSQSInstance()

  _configure: ->
    aws.config.update
      accessKeyId: config.queue.accessKeyId
      secretAccessKey: config.queue.secretAccessKey
      region: config.queue.region

  _generateSQSInstance: -> new aws.SQS()

  _logAndThrowFatalException: (errorMessage) ->
    log.error errorMessage
    throw new Error errorMessage

class SQSQueue extends events.EventEmitter
  constructor: (@queueName, @queueUrl, @sqs) ->

  subscribe: (eventName, callback) -> @on eventName, callback
  unsubscribe: (eventName, callback) -> @removeListener eventName, callback

  receiveMessage: (callback) ->
    queueReceiveOptions =
      QueueUrl: @queueUrl
      WaitTimeSeconds: defaultMessageReceiptTimeout

    @sqs.receiveMessage queueReceiveOptions, (err, data) =>
      if err?
        @emit 'error', err, originalData
      else
        originalData = data
        data = new SQSMessage originalData, this
        @emit 'message', err, data

      callback? err, data

  deleteMessage: (receiptHandle, callback) ->
    queueDeletionOptions =
      QueueUrl: @queueUrl
      ReceiptHandle: receiptHandle

    @sqs.deleteMessage queueDeletionOptions, (err, data) =>
      if err? then @emit 'error', err, data else @emit 'message', err, data

      callback? err, data

  changeMessageVisibilityTimeout: (secondsFromNow, receiptHandle, callback) ->
    messageVisibilityTimeoutOptions =
      QueueUrl: @queueUrl
      ReceiptHandle: receiptHandle
      VisibilityTimeout: secondsFromNow

    @sqs.changeMessageVisibility messageVisibilityTimeoutOptions, (err, data) =>
      if err? then @emit 'error', err, data else @emit 'edited', err, data

      callback? err, data

  sendMessage: (messageBody, delaySeconds, callback) ->
    queueSendingOptions =
      QueueUrl: @queueUrl
      MessageBody: messageBody
      DelaySeconds: delaySeconds

    @sqs.sendMessage queueSendingOptions, (err, data) =>
      if err? then @emit 'error', err, data else @emit 'sent', err, data

      callback? err, data

  listenForever: => async.forever (asyncCallback) => @receiveMessage (err, data) -> asyncCallback(null)

class SQSMessage
  constructor: (@originalMessage, @parentQueue) ->

  isEmpty: -> not @originalMessage.Messages?[0]?

  getBody: -> @originalMessage.Messages[0].Body

  getID: -> @originalMessage.Messages[0].MessageId

  removeFromQueue: (callback) -> @parentQueue.deleteMessage @getReceiptHandle(), callback

  requeue: (callback) -> @parentQueue.changeMessageVisibilityTimeout 0, @getReceiptHandle(), callback

  changeMessageVisibilityTimeout: (secondsFromFunctionCall, callback) ->
    @parentQueue.changeMessageVisibilityTimeout secondsFromFunctionCall, @getReceiptHandle(), callback

  getReceiptHandle: -> @originalMessage.Messages[0].ReceiptHandle

class MongoQueueClient
  registerQueue: (queueName, options, callback) ->
    newQueue = new MongoQueue queueName, options, @messageModel
    callback(null, newQueue)

  constructor: ->
    @_configure()
    @_createMongoConnection()
    @messageModel = @_generateMessageModel()

  _configure: -> @databaseAddress = db.generateMongoConnectionString()

  _createMongoConnection:  ->
    @mongooseConnection = mongoose.createConnection @databaseAddress
    @mongooseConnection.on 'error', -> log.error 'There was an error connecting to the queue in MongoDB' unless config.proxy
    @mongooseConnection.once 'open', -> log.info 'Successfully connected to MongoDB queue!'

  _generateMessageModel: ->
    schema = new mongoose.Schema
      messageBody: Object,
      queue: {type: String, index: true}
      scheduledVisibilityTime: {type: Date, index: true}
      receiptHandle: {type: String, index: true}

    @mongooseConnection.model 'messageQueue', schema

class MongoQueue extends events.EventEmitter
  constructor: (queueName, options, messageModel) ->
    @Message = messageModel
    @queueName = queueName

  subscribe: (eventName, callback) -> @on eventName, callback
  unsubscribe: (eventName, callback) -> @removeListener eventName, callback

  totalMessagesInQueue: (callback) -> @Message.count {}, callback

  receiveMessage: (callback) ->
    conditions =
      queue: @queueName
      scheduledVisibilityTime:
        $lte: new Date()

    #options =
    #  sort: 'scheduledVisibilityTime'

    update =
      $set:
        receiptHandle: @_generateRandomReceiptHandle()
        scheduledVisibilityTime: @_constructDefaultVisibilityTimeoutDate()

    @Message.findOneAndUpdate conditions, update, (err, data) =>
      return @emit 'error', err, data if err?

      originalData = data
      data = new MongoMessage originalData, this
      @emit 'message', err, data
      callback? err, data

  deleteMessage: (receiptHandle, callback) ->
    conditions =
      queue: @queueName
      receiptHandle: receiptHandle
      scheduledVisibilityTime:
        $gte: new Date()

    @Message.findOneAndRemove conditions, {}, (err, data) =>
      if err? then @emit 'error', err, data else @emit 'delete', err, data

      callback? err, data

  sendMessage: (messageBody, delaySeconds, callback) ->
    messageToSend = new @Message
      messageBody: messageBody
      queue: @queueName
      scheduledVisibilityTime: @_constructDefaultVisibilityTimeoutDate delaySeconds

    messageToSend.save (err, data) =>
      if err? then @emit 'error', err, data else @emit 'sent', err, data
      callback? err, data

  changeMessageVisibilityTimeout: (secondsFromNow, receiptHandle, callback) ->
    conditions =
      queue: @queueName
      receiptHandle: receiptHandle
      scheduledVisibilityTime:
        $gte: new Date()

    update =
      $set:
        scheduledVisibilityTime: @_constructDefaultVisibilityTimeoutDate secondsFromNow

    @Message.findOneAndUpdate conditions, update, (err, data) =>
      if err?
        log.error "There was a problem updating the message visibility timeout:#{err}"
        @emit 'error', err, data
      else
        @emit 'update', err, data
        #log.info 'The message visibility time was updated'

      callback? err, data

  listenForever: => async.forever (asyncCallback) => @recieveMessage (err, data) -> asyncCallback(null)

  _constructDefaultVisibilityTimeoutDate: (timeoutSeconds) ->
    timeoutSeconds ?= defaultMessageVisibilityTimeoutInSeconds
    newDate = new Date()
    newDate = new Date(newDate.getTime() + 1000 * timeoutSeconds)

    newDate

  _generateRandomReceiptHandle: -> crypto.randomBytes(20).toString('hex')

class MongoMessage
  constructor: (@originalMessage, @parentQueue) ->

  isEmpty: -> not @originalMessage

  getBody: -> @originalMessage.messageBody

  getID: -> @originalMesage._id

  removeFromQueue: (callback) -> @parentQueue.deleteMessage @getReceiptHandle(), callbacks

  requeue: (callback) -> @parentQueue.changeMessageVisibilityTimeout 0, @getReceiptHandle(), callback

  changeMessageVisibilityTimeout: (secondsFromFunctionCall, callback) ->
    @parentQueue.changeMessageVisibilityTimeout secondsFromFunctionCall, @getReceiptHandle(), callback

  getReceiptHandle: -> @originalMessage.receiptHandle
