config = require '../server_config'
winston = require 'winston'
mongoose = require 'mongoose'
async = require 'async'
errors = require './errors'
aws = require 'aws-sdk'

queueInstance = null

module.exports.setupRoutes = (app) ->
  queueInstance = generateQueueInstance()





generateQueueInstance = ->
  if config.isProduction
    return new RemoteQueue()
  else
    return new LocalQueue()



class AbstractQueue
  configure: ->
    throw new Error "Subclasses must override the configure method"

  connect: ->
    throw new Error "Subclasses must override the connect method"

  createSimulationQueue: ->
    throw new Error "Subclasses must override the createSimulationQueue method"




class RemoteQueue extends AbstractQueue
  constructor: ->
    @configure()
    @sqs = @generateSQSInstance()
    @createSimulationQueueAndSetUrl (err, data) =>
      @sendMessage "This is a new test message",5, =>
        winston.info "Sent test message!"
    setTimeout @receiveMessage.bind(this, (err, data) =>
      if err?
        winston.error "Error receiving message, reason: #{JSON.stringify err}"
      else
        winston.info "Received message, content: #{JSON.stringify data}"
        winston.info "Deleting message..."
        @deleteMessage data.Messages?[0].ReceiptHandle, ->
          winston.info "Deleted message!"
    ), 5000

  configure: ->
    aws.config.update @generateAWSConfigurationObject()


  createSimulationQueueAndSetUrl: (callback) ->
    @sqs.createQueue {QueueName: config.queue.simulationQueueName}, (err, data) =>
      if err?
        winston.error "Failed to create simulation queue!"
        throw new Error "Failed to create simulation queue."
      else
        winston.info "Created simulation queue, URL is #{data.QueueUrl}"
        @simulationQueueUrl = data.QueueUrl
        callback?(null,data)


  receiveMessage: (callback) ->
    @sqs.receiveMessage {QueueUrl: @simulationQueueUrl, WaitTimeSeconds: 20}, callback

  deleteMessage: (receiptHandle, callback) ->
    @sqs.deleteMessage {QueueUrl: @simulationQueueUrl, ReceiptHandle: receiptHandle}, callback

  sendMessage: (messageBody, delaySeconds, callback) ->
    @sqs.sendMessage {QueueUrl: @simulationQueueUrl, MessageBody: messageBody, DelaySeconds: delaySeconds}, callback


  generateAWSConfigurationObject: ->
    awsConfigurationObject =
      accessKeyId: config.queue.accessKeyId
      secretAccessKey: config.queue.secretAccessKey
      region: config.queue.region


  generateSQSInstance: ->
    new aws.SQS()

  testConnection: ->
    @sqs.listQueues {}, (err, data) ->
      if err?
        winston.error "Error connecting to SQS, reason: #{err}"
        throw new Error("Couldn't connect to SQS.")
      else
        winston.info "Connected to SQS!"



class LocalQueue extends AbstractQueue
  constructor: ()->
    return

  configure: () ->
    super()


