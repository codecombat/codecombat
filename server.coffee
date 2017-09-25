require 'newrelic' if process.env.NEW_RELIC_LICENSE_KEY?

do (setupLodash = this) ->
  GLOBAL._ = require 'lodash'
  _.str = require 'underscore.string'
  _.mixin _.str.exports()

express = require 'express'
compression = require('compression')
http = require 'http'
log = require 'winston'
serverSetup = require './server_setup'

module.exports.startServer = (done) ->
  app = createAndConfigureApp()
  httpServer = http.createServer(app).listen app.get('port'), -> done?()
  log.info('Express SSL server listening on port ' + app.get('port'))
  {app, httpServer}

createAndConfigureApp = module.exports.createAndConfigureApp = ->
  serverSetup.setupLogging()
  serverSetup.connectToDatabase()
  
  app = express()
  app.use(compression()) # TODO Webpack: Disable locally? Maybe.
  serverSetup.setExpressConfigurationOptions app
  serverSetup.setupMiddleware app
  serverSetup.setupRoutes app
  app
