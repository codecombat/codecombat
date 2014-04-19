express = require 'express'
path = require 'path'
authentication = require 'passport'
useragent = require 'express-useragent'
fs = require 'graceful-fs'
log = require 'winston'
compressible = require 'compressible'

database = require './server/commons/database'
baseRoute = require './server/routes/base'
user = require './server/users/user_handler'
logging = require './server/commons/logging'
config = require './server_config'
auth = require './server/routes/auth'
UserHandler = require './server/users/user_handler'

productionLogging = (tokens, req, res) ->
  status = res.statusCode
  color = 32
  if status >= 500 then color = 31
  else if status >= 400 then color = 33
  else if status >= 300 then color = 36
  elapsed = (new Date()) - req._startTime
  elapsedColor = if elapsed < 500 then 90 else 31
  if (status isnt 200 and status isnt 304 and status isnt 302) or elapsed > 500
    return "\x1b[90m#{req.method} #{req.originalUrl} \x1b[#{color}m#{res.statusCode} \x1b[#{elapsedColor}m#{elapsed}ms\x1b[0m"
  null

setupExpressMiddleware = (app) ->
  if config.isProduction
    express.logger.format('prod', productionLogging)
    app.use(express.logger('prod'))
    app.use express.compress filter: (req, res) ->
      return false if req.headers.host is 'codecombat.com'  # Cloudflare will gzip it for us on codecombat.com
      compressible res.getHeader('Content-Type')
  else
    app.use(express.logger('dev'))
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
  app.all '*', (req, res) ->
    if req.user
      sendMain(req, res)
    else
      user = auth.makeNewUser(req)
      makeNext = (req, res) -> -> sendMain(req, res)
      next = makeNext(req, res)
      auth.loginUser(req, res, user, false, next)

sendMain = (req, res) ->
  fs.readFile path.join(__dirname, 'public', 'main.html'), 'utf8', (err, data) ->
    log.error "Error modifying main.html: #{err}" if err
    # insert the user object directly into the html so the application can have it immediately
    data = data.replace('"userObjectTag"', JSON.stringify(UserHandler.formatEntity(req, req.user)))
    res.send data

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
  app.set('env', if config.isProduction then 'production' else 'development')
  app.set('json spaces', 0)
