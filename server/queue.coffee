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
    return new RemoteQueue(config.queue.simulationQueueName)
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
  constructor: (queueName) ->
    @configure()
    @sqs = @generateSQSInstance()
    @createSimulationQueueAndSetUrl queueName, (err, data) =>
      @sendMessage "This is a new test message",5, (error,data) ->
        if err?
          winston.error "#{JSON.stringify error}"
      @enterReceieveMessageForeverLoop()




  configure: ->
    aws.config.update @generateAWSConfigurationObject()

  enterReceieveMessageForeverLoop: ->
    async.forever (asyncCallback) =>
      @receiveMessage (err, data) =>
        if err?
          winston.error "Error receiving message, reason: #{JSON.stringify err}"
        else
          if data.Messages?
            winston.info "Received message, content: #{JSON.stringify data.Messages[0].Body}"
            winston.info "Deleting message..."
            @deleteMessage data.Messages?[0].ReceiptHandle, ->
              winston.info "Deleted message!"
          else
            winston.info "No messages to receieve"
          asyncCallback(null)

  createSimulationQueueAndSetUrl: (queueName, callback) ->
    @sqs.createQueue {QueueName: queueName}, (err, data) =>
      if err?
        throw new Error "Failed to create queue \"#{queueName}\""
      else
        winston.info "Created queue, URL is #{data.QueueUrl}"
        @queueUrl = data.QueueUrl
        callback?(err,data)


  receiveMessage: (callback) ->
    @sqs.receiveMessage {QueueUrl: @queueUrl, WaitTimeSeconds: 20}, callback

  deleteMessage: (receiptHandle, callback) ->
    @sqs.deleteMessage {QueueUrl: @queueUrl, ReceiptHandle: receiptHandle}, callback

  sendMessage: (messageBody, delaySeconds, callback) ->
    @sqs.sendMessage {QueueUrl: @queueUrl, MessageBody: messageBody, DelaySeconds: delaySeconds}, callback


  generateAWSConfigurationObject: ->
    awsConfigurationObject =
      accessKeyId: config.queue.accessKeyId
      secretAccessKey: config.queue.secretAccessKey
      region: config.queue.region


  generateSQSInstance: ->
    new aws.SQS()




class LocalQueue extends AbstractQueue
  constructor: ()->
    return

  configure: () ->
    super()


