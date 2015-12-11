require 'newrelic' if process.env.NEW_RELIC_LICENSE_KEY?

do (setupLodash = this) ->
  GLOBAL._ = require 'lodash'
  _.str = require 'underscore.string'
  _.mixin _.str.exports()

express = require 'express'
http = require 'http'
log = require 'winston'
serverSetup = require './server_setup'

module.exports.startServer = (done) ->
  app = createAndConfigureApp()
  http.createServer(app).listen app.get('port'), -> done?()
  log.info('Express SSL server listening on port ' + app.get('port'))
  app

createAndConfigureApp = ->
  serverSetup.setupLogging()
  serverSetup.connectToDatabase()
  serverSetup.setupMailchimp()

  app = express()
  serverSetup.setExpressConfigurationOptions app
  serverSetup.setupMiddleware app
  serverSetup.setupRoutes app
  app
