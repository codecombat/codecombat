express = require 'express'
path = require 'path'
authentication = require 'passport'
useragent = require 'express-useragent'
fs = require 'graceful-fs'
log = require 'winston'
compressible = require 'compressible'
geoip = require 'geoip-lite'

database = require './server/commons/database'
baseRoute = require './server/routes/base'
user = require './server/users/user_handler'
logging = require './server/commons/logging'
config = require './server_config'
auth = require './server/routes/auth'
UserHandler = require './server/users/user_handler'
hipchat = require './server/hipchat'
global.tv4 = require 'tv4' # required for TreemaUtils to work
global.jsondiffpatch = require 'jsondiffpatch'
global.stripe = require('stripe')(config.stripe.secretKey)


productionLogging = (tokens, req, res) ->
  status = res.statusCode
  color = 32
  if status >= 500 then color = 31
  else if status >= 400 then color = 33
  else if status >= 300 then color = 36
  elapsed = (new Date()) - req._startTime
  elapsedColor = if elapsed < 500 then 90 else 31
  if (status isnt 200 and status isnt 201 and status isnt 204 and status isnt 304 and status isnt 302) or elapsed > 500
    return "\x1b[90m#{req.method} #{req.originalUrl} \x1b[#{color}m#{res.statusCode} \x1b[#{elapsedColor}m#{elapsed}ms\x1b[0m"
  null

developmentLogging = (tokens, req, res) ->
  status = res.statusCode
  color = 32
  if status >= 500 then color = 31
  else if status >= 400 then color = 33
  else if status >= 300 then color = 36
  elapsed = (new Date()) - req._startTime
  elapsedColor = if elapsed < 500 then 90 else 31
  "\x1b[90m#{req.method} #{req.originalUrl} \x1b[#{color}m#{res.statusCode} \x1b[#{elapsedColor}m#{elapsed}ms\x1b[0m"

setupErrorMiddleware = (app) ->
  app.use (err, req, res, next) ->
    if err
      if err.status and 400 <= err.status < 500
        res.status(err.status).send("Error #{err.status}")
        return
      res.status(err.status ? 500).send(error: "Something went wrong!")
      message = "Express error: #{req.method} #{req.path}: #{err.message}"
      log.error "#{message}, stack: #{err.stack}"
      hipchat.sendHipChatMessage(message, ['tower'], {papertrail: true})
    else
      next(err)

setupExpressMiddleware = (app) ->
  if config.isProduction
    express.logger.format('prod', productionLogging)
    app.use(express.logger('prod'))
    app.use express.compress filter: (req, res) ->
      return false if req.headers.host is 'codecombat.com'  # CloudFlare will gzip it for us on codecombat.com
      compressible res.getHeader('Content-Type')
  else
    express.logger.format('dev', developmentLogging)
    app.use(express.logger('dev'))
  app.use(express.static(path.join(__dirname, 'public'), maxAge: 0))  # CloudFlare overrides maxAge, and we don't want local development caching.
  app.use(useragent.express())

  app.use(express.favicon())
  app.use(express.cookieParser(config.cookie_secret))
  app.use(express.bodyParser())
  app.use(express.methodOverride())
  app.use(express.cookieSession({secret:'defenestrate'}))

setupPassportMiddleware = (app) ->
  app.use(authentication.initialize())
  app.use(authentication.session())

setupCountryRedirectMiddleware = (app, country="china", countryCode="CN", languageCode="zh", serverID="tokyo") ->
  shouldRedirectToCountryServer = (req) ->
    speaksLanguage = _.any req.acceptedLanguages, (language) -> language.indexOf languageCode isnt -1
    unless config[serverID]
      ip = req.headers['x-forwarded-for'] or req.connection.remoteAddress
      ip = ip?.split(/,? /)[0]  # If there are two IP addresses, say because of CloudFlare, we just take the first.
      geo = geoip.lookup(ip)
      #if speaksLanguage or geo?.country is countryCode
      #  log.info("Should we redirect to #{serverID} server? speaksLanguage: #{speaksLanguage}, acceptedLanguages: #{req.acceptedLanguages}, ip: #{ip}, geo: #{geo} -- so redirecting? #{geo?.country is 'CN' and speaksLanguage}")
      return geo?.country is countryCode and speaksLanguage
    else
      #log.info("We are on #{serverID} server. speaksLanguage: #{speaksLanguage}, acceptedLanguages: #{req.acceptedLanguages[0]}")
      req.country = country if speaksLanguage
      return false  # If the user is already redirected, don't redirect them!

  app.use (req, res, next) ->
    if shouldRedirectToCountryServer req
      res.writeHead 302, "Location": config[country + 'Domain'] + req.url
      res.end()
    else
      next()

setupOneSecondDelayMiddleware = (app) ->
  if(config.slow_down)
    app.use((req, res, next) -> setTimeout((-> next()), 1000))

setupMiddlewareToSendOldBrowserWarningWhenPlayersViewLevelDirectly = (app) ->
  isOldBrowser = (req) ->
    # https://github.com/biggora/express-useragent/blob/master/lib/express-useragent.js
    return false unless ua = req.useragent
    return true if ua.isiPad or ua.isiPod or ua.isiPhone or ua.isOpera
    return false unless ua and ua.Browser in ['Chrome', 'Safari', 'Firefox', 'IE'] and ua.Version
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

setupRedirectMiddleware = (app) ->
  app.all '/account/profile/*', (req, res, next) ->
    nameOrID = req.path.split('/')[3]
    res.redirect 301, "/user/#{nameOrID}/profile"


exports.setupMiddleware = (app) ->
  setupCountryRedirectMiddleware app, "china", "CN", "zh", "tokyo"
  setupCountryRedirectMiddleware app, "brazil", "BR", "pt-BR", "saoPaulo"
  setupMiddlewareToSendOldBrowserWarningWhenPlayersViewLevelDirectly app
  setupExpressMiddleware app
  setupPassportMiddleware app
  setupOneSecondDelayMiddleware app
  setupRedirectMiddleware app
  setupErrorMiddleware app
  setupJavascript404s app

###Routing function implementations###

setupJavascript404s = (app) ->
  app.get '/javascripts/*', (req, res) ->
    res.status(404).send('Not found')

setupFallbackRouteToIndex = (app) ->
  app.all '*', (req, res) ->
    fs.readFile path.join(__dirname, 'public', 'main.html'), 'utf8', (err, data) ->
      log.error "Error modifying main.html: #{err}" if err
      # insert the user object directly into the html so the application can have it immediately. Sanitize </script>
      user = if req.user then JSON.stringify(UserHandler.formatEntity(req, req.user)).replace(/\//g, '\\/') else '{}'
      data = data.replace('"userObjectTag"', user)
      res.header 'Cache-Control', 'no-cache, no-store, must-revalidate'
      res.header 'Pragma', 'no-cache'
      res.header 'Expires', 0
      res.send 200, data

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
  app.set('json spaces', 0) if config.isProduction
