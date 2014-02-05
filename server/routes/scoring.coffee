config = require '../../server_config'
winston = require 'winston'
mongoose = require 'mongoose'
async = require 'async'
errors = require '../commons/errors'
aws = require 'aws-sdk'
db = require './db'
mongoose = require 'mongoose'
events = require 'events'
queues = require '../commons/queue'

module.exports.connectToScoringQueue = -> queues.initializeScoringTaskQueue() unless queues.scoringTaskQueue?

module.exports.setupRoutes = (app) ->
  app.get '/scoring/queue', (req,res) ->
    #must also include the
    queues.scoringTaskQueue.receieveMessage (err, data) ->
      #once the data is recieved


      levelAndUserCodeMapResponse = {}
    sendResponseObject req,res,levelAndUserCodeMapResponse

  app.post '/scoring/queue', (req, res) ->
    clientResponseObject = req.body

    res.end("You posted an object to score!")




sendResponseObject = (req,res,object) ->
  res.setHeader('Content-Type', 'application/json')
  res.send(object)
  res.end()


constructTaskObject = (data, callback) ->
  #task includes session ID,


