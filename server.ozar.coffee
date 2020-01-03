require 'newrelic' if process.env.NEW_RELIC_LICENSE_KEY?

do (setupLodash = this) ->
  GLOBAL._ = require 'lodash'
  _.str = require 'underscore.string'
  _.mixin _.str.exports()

express = require 'express'
http = require 'http'
log = require 'winston'
serverSetup = require './server_setup'
co = require 'co'
config = require './server_config'
Promise = require 'bluebird'

module.exports.startServer = (done) ->
  app = createAndConfigureApp()
  httpServer = http.createServer(app).listen app.get('port'), -> done?()
  log.info('Express SSL server listening on port ' + app.get('port'))
  {app, httpServer}

createAndConfigureApp = module.exports.createAndConfigureApp = ->
  
  app = express()
  if config.forceCompression
    compression = require('compression')
    app.use(compression())
  serverSetup.setExpressConfigurationOptions app
  serverSetup.setupMiddleware app
  app
