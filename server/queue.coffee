config = require '../server_config'
winston = require 'winston'
mongoose = require 'mongoose'
async = require 'async'
errors = require './errors'
aws = require 'aws-sdk'

queueInstance = null

module.exports.connect = ->
  queueInstance = generateQueueInstance()
  queueInstance.connect()


module.exports.connectToRemoteQueue = ->
  return

module.exports.connectToLocalQueue = ->
  return


generateQueueInstance = ->
  if config.isProduction
    return new RemoteQueue()
  else
    return new LocalQueue()

class Queue
  constructor: ->
   @configure()

  configure: ->
    return

  connect: ->
    throw new Error("Subclasses must override this method")


class RemoteQueue extends Queue
  constructor: ->
    super()
    @sqs = @generateSQSInstance()
    @testConnection()


  configure: ->
    super()
    awsConfigurationObject =
      accessKeyId: config.queue.accessKeyId
      secretAccessKey: config.queue.secretAccessKey
      region: config.queue.region
    aws.config.update remoteConfigurationObject

  generateSQSInstance: ->
    return new aws.SQS()

  testConnection: ->
    @sqs.listQueues {}, (err, data) ->
      if err?
        winston.error "Error connecting to SQS, reason: #{err}"
        throw new Error("Couldn't connect to SQS.")
      else
        winston.info "Connected to SQS!"



class LocalQueue extends Queue
  constructor: ()->
    super()

  configure: () ->
    super()


