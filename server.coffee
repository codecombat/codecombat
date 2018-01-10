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
{ runHealthcheck }  = require './server/middleware/healthcheck'
Promise = require 'bluebird'

module.exports.startServer = (done) ->
  app = createAndConfigureApp()
  httpServer = http.createServer(app).listen app.get('port'), -> done?()
  log.info('Express SSL server listening on port ' + app.get('port'))
  runHealthcheckForever() if config.isProduction
  {app, httpServer}
  
runHealthcheckForever = ->
  log.info('Running healthchecks forever')
  co ->
    sleep = (time, result=null) -> new Promise((resolve) -> setTimeout((-> resolve(result)), time))
    failures = 0
    yield sleep(15000) # give server time to start up
    while true
      passed = yield Promise.race([
        runHealthcheck()
        new sleep(5000, false)
      ])
      if passed
        failures = 0
        yield sleep(15000)
      else
        failures += 1
        log.warn("Healthcheck failure ##{failures}.")
      if failures >= 3
        log.error('Three healthcheck failures in a row. Killing self.')
        process.exit(1)

createAndConfigureApp = module.exports.createAndConfigureApp = ->
  serverSetup.setupLogging()
  serverSetup.connectToDatabase()
  
  app = express()
  if config.forceCompression
    compression = require('compression')
    app.use(compression())
  serverSetup.setExpressConfigurationOptions app
  serverSetup.setupMiddleware app
  serverSetup.setupRoutes app
  app
