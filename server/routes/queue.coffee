log = require 'winston'
errors = require '../commons/errors'
scoringQueue = require '../queues/scoring'

module.exports.setup = (app) ->
  scoringQueue.setup()

  #app.post '/queue/scoring/pairwise', (req, res) ->
  #  handler = loadQueueHandler 'scoring'
  #  handler.addPairwiseTaskToQueue req, res

  app.get '/queue/messagesInQueueCount', (req, res) ->
    handler = loadQueueHandler 'scoring'
    handler.messagesInQueueCount req, res

  app.post '/queue/scoring/getTwoGames', (req, res) ->
    handler = loadQueueHandler 'scoring'
    handler.getTwoGames req, res

  app.put '/queue/scoring/recordTwoGames', (req, res) ->
    handler = loadQueueHandler 'scoring'
    handler.recordTwoGames req, res

  app.all '/queue/*', (req, res) ->
    setResponseHeaderToJSONContentType res

    queueName = getQueueNameFromPath req.path
    try
      handler = loadQueueHandler queueName
      if isHTTPMethodGet req
        handler.dispatchTaskToConsumer req, res
      else if isHTTPMethodPut req
        handler.processTaskResult req, res
      else
        sendMethodNotSupportedError req, res
    catch error
      log.error error
      sendQueueError req, res, error

setResponseHeaderToJSONContentType = (res) -> res.setHeader('Content-Type', 'application/json')

getQueueNameFromPath = (path) ->
  pathPrefix = '/queue/'
  pathAfterPrefix = path[pathPrefix.length..]
  partsOfURL = pathAfterPrefix.split '/'
  queueName = partsOfURL[0]
  queueName

loadQueueHandler = (queueName) -> require ('../queues/' + queueName)

isHTTPMethodGet = (req) -> return req.method is 'GET'

isHTTPMethodPost = (req) -> return req.method is 'POST'

isHTTPMethodPut = (req) -> return req.method is 'PUT'

sendMethodNotSupportedError = (req, res) -> errors.badMethod(res, ['GET', 'POST', 'PUT'], 'Queues do not support the HTTP method used.' )

sendQueueError = (req, res, error) -> errors.serverError(res, "Route #{req.path} had a problem: #{error}")
