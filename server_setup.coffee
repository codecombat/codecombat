express = require 'express'
path = require 'path'
passport = require 'passport'
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

setupExpressMiddleware = (app) ->
  setupRequestTimeoutMiddleware app
  app.use(express.logger('dev'))
  app.use(express.static(path.join(__dirname, 'public')))
  app.use(useragent.express())

  app.use(express.favicon())
  app.use(express.cookieParser(config.cookie_secret))
  app.use(express.bodyParser())
  app.use(express.methodOverride())
  app.use(express.cookieSession({secret:'defenestrate'}))

setupPassportMiddleware = (app) ->
  app.use(passport.initialize())
  app.use(passport.session())

setupOneSecondDelayMiddlware = (app) ->
  if(config.slow_down)
    app.use((req, res, next) -> setTimeout((-> next()), 1000))

setupUserMiddleware = (app) ->
  user.setupMiddleware(app)

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
  setupUserMiddleware app

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



