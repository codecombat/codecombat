config = require '../server_config'
winston = require 'winston'
mongoose = require 'mongoose'
async = require 'async'
errors = require './errors'
aws = require 'aws-sdk'
db = require './db'
mongoose = require 'mongoose'
events = require 'events'
queues = require 'queue'

module.exports.connectToScoringQueue = -> queues.initializeScoringTaskQueue() unless queues.scoringTaskQueue?

module.exports.setupRoutes = (app) ->
  return


module.exports.setupRoutes = (app) ->
  app.all '/multiplayer/*', (req, res) ->
    unless scoringTaskQueue?

      errors.custom res, 503, "Currently initializing scoring queue"

  return



