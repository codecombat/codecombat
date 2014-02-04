do (setupLodash = this) ->
  GLOBAL._ = require 'lodash'
  _.str = require 'underscore.string'
  _.mixin _.str.exports()

express = require 'express'
http = require 'http'
winston = require 'winston'
serverSetup = require './server_setup'

module.exports.startServer = ->
  app = createAndConfigureApp()
  http.createServer(app).listen(app.get('port'))
  winston.info("Express SSL server listening on port " + app.get('port'))
  return app

createAndConfigureApp = ->
  serverSetup.setupLogging()
  serverSetup.connectToDatabase()
  serverSetup.setupMailchimp()

  app = express()
  serverSetup.setExpressConfigurationOptions app
  serverSetup.setupMiddleware app
  serverSetup.setupRoutes app
  app

