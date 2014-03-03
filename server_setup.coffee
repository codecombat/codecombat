express = require 'express'
path = require 'path'
authentication = require 'passport'
useragent = require 'express-useragent'
fs = require 'graceful-fs'

database = require './server/commons/database'
baseRoute = require './server/routes/base'
user = require './server/users/user_handler'
logging = require './server/commons/logging'
config = require './server_config'

###Middleware setup functions implementation###
setupRequestTimeoutMiddleware = (app) ->
  app.use (req, res, next) ->
    req.setTimeout 15000, ->
      console.log 'timed out!'
      req.abort()
      self.emit('pass',message)
    next()

productionLogging = (tokens, req, res)->
  status = res.statusCode
  color = 31
  if(status != 200 && status != 304)
    return '\x1b[90m' + req.method+ ' ' + req.originalUrl + ' '+ '\x1b[' + color + 'm' + res.statusCode+ ' \x1b[90m'+ (new Date - req._startTime)+ 'ms' + '\x1b[0m';

setupExpressMiddleware = (app) ->
  setupRequestTimeoutMiddleware app
  express.logger.format('prod', productionLogging)
  app.use(express.logger('prod'))
  app.use(express.static(path.join(__dirname, 'public')))
  app.use(useragent.express())

  app.use(express.favicon())
  app.use(express.cookieParser(config.cookie_secret))
  app.use(express.bodyParser())
  app.use(express.methodOverride())
  app.use(express.cookieSession({secret:'defenestrate'}))

setupPassportMiddleware = (app) ->
  app.use(authentication.initialize())
  app.use(authentication.session())

setupOneSecondDelayMiddlware = (app) ->
  if(config.slow_down)
    app.use((req, res, next) -> setTimeout((-> next()), 1000))

setupMiddlewareToSendOldBrowserWarningWhenPlayersViewLevelDirectly = (app) ->
  isOldBrowser = (req) ->
    # https://github.com/biggora/express-useragent/blob/master/lib/express-useragent.js
    return false unless ua = req.useragent
    return true if ua.isiPad or ua.isiPod or ua.isiPhone or ua.isOpera
    return false unless ua and ua.Browser in ["Chrome", "Safari", "Firefox", "IE"] and ua.Version
    b = ua.Browser
    v = parseInt ua.Version.split('.')[0], 10
    return true if b is 'Chrome' and v < 17
    return true if b is 'Safari' and v < 6
    return true if b is 'Firefox' and v < 21
    return true if b is 'IE' and v < 10
    false

  app.use '/play/', (req, res, next) ->
    return next() if req.query['try-old-browser-anyway'] or not isOldBrowser req
    res.sendfile(path.join(__dirname, 'public', 'index_old_browser.html'))

exports.setupMiddleware = (app) ->
  setupMiddlewareToSendOldBrowserWarningWhenPlayersViewLevelDirectly app
  setupExpressMiddleware app
  setupPassportMiddleware app
  setupOneSecondDelayMiddlware app

###Routing function implementations###

setupFallbackRouteToIndex = (app) ->
  app.get '*', (req, res) ->
    res.sendfile path.join(__dirname, 'public', 'index.html')

setupFacebookCrossDomainCommunicationRoute = (app) ->
  app.get '/channel.html', (req, res) ->
    res.sendfile path.join(__dirname, 'public', 'channel.html')

exports.setupRoutes = (app) ->
  app.use app.router

  baseRoute.setup app
  setupFacebookCrossDomainCommunicationRoute app
  setupFallbackRouteToIndex app

###Miscellaneous configuration functions###

exports.setupLogging = ->
  logging.setup()

exports.connectToDatabase = ->
  database.connect()

exports.setupMailchimp = ->
  mcapi = require 'mailchimp-api'
  mc = new mcapi.Mailchimp(config.mail.mailchimpAPIKey)
  GLOBAL.mc = mc

exports.setExpressConfigurationOptions = (app) ->
  app.set('port', config.port)
  app.set('views', __dirname + '/app/views')
  app.set('view engine', 'jade')
  app.set('view options', { layout: false })



