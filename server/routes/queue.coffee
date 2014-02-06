log = require 'winston'
errors = require '../commons/errors'
scoringQueue = require '../queues/scoring'


module.exports.setup = (app) ->
  scoringQueue.setup()

  app.all '/queue/*', (req, res) ->
    setResponseHeaderToJSONContentType res

    queueName = getQueueNameFromPath req.path
    try
      handler = loadQueueHandler queueName
      if isHTTPMethodGet req
        handler.dispatchTaskToConsumer req,res
      else if isHTTPMethodPost req
        handler.processTaskResult req,res
      else
        sendMethodNotSupportedError req, res
    catch error
      log.error error
      sendQueueNotFoundError req, res

setResponseHeaderToJSONContentType = (res) -> res.setHeader('Content-Type', 'application/json')

getQueueNameFromPath = (path) ->
  pathPrefix = '/queue/'
  pathAfterPrefix = path[pathPrefix.length..]
  partsOfURL = pathAfterPrefix.split '/'
  queueName = partsOfURL[0]
  queueName

loadQueueHandler = (queueName) -> require ('../queues/' + queueName)


isHTTPMethodGet = (req) -> return req.route.method is 'get'

isHTTPMethodPost = (req) -> return req.route.method is 'post'


sendMethodNotSupportedError = (req, res) -> errors.badMethod(res,"Queues do not support the HTTP method used." )

sendQueueNotFoundError = (req,res) -> errors.notFound(res, "Route #{req.path} not found.")

