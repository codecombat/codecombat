express = require 'express'
path = require 'path'
authentication = require 'passport'
useragent = require 'express-useragent'
fs = require 'graceful-fs'
log = require 'winston'
compressible = require 'compressible'
geoip = require 'geoip-lite'

database = require './server/commons/database'
perfmon = require './server/commons/perfmon'
baseRoute = require './server/routes/base'
user = require './server/handlers/user_handler'
logging = require './server/commons/logging'
config = require './server_config'
auth = require './server/commons/auth'
routes = require './server/routes'
UserHandler = require './server/handlers/user_handler'
slack = require './server/slack'
Mandate = require './server/models/Mandate'
global.tv4 = require 'tv4' # required for TreemaUtils to work
global.jsondiffpatch = require 'jsondiffpatch'
global.stripe = require('stripe')(config.stripe.secretKey)
errors = require './server/commons/errors'
request = require 'request'
Promise = require 'bluebird'
Promise.promisifyAll(request, {multiArgs: true})


productionLogging = (tokens, req, res) ->
  status = res.statusCode
  color = 32
  if status >= 500 then color = 31
  else if status >= 400 then color = 33
  else if status >= 300 then color = 36
  elapsed = (new Date()) - req._startTime
  elapsedColor = if elapsed < 500 then 90 else 31
  return null if status is 404 and /\/feedback/.test req.originalUrl  # We know that these usually 404 by design (bad design?)
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
  s = "\x1b[90m#{req.method} #{req.originalUrl} \x1b[#{color}m#{res.statusCode} \x1b[#{elapsedColor}m#{elapsed}ms\x1b[0m"
  s += ' (proxied)' if req.proxied
  return s

setupErrorMiddleware = (app) ->
  app.use (err, req, res, next) ->
    if err
      if err.name is 'MongoError' and err.code is 11000
        err = new errors.Conflict('MongoDB conflict error.')
      if err.code is 422 and err.response
        err = new errors.UnprocessableEntity(err.response)
      if err.code is 409 and err.response
        err = new errors.Conflict(err.response)

      # TODO: Make all errors use this
      if err instanceof errors.NetworkError
        return res.status(err.code).send(err.toJSON())

      if err.status and 400 <= err.status < 500
        res.status(err.status).send("Error #{err.status}")
        return

      res.status(err.status ? 500).send(error: "Something went wrong!")
      message = "Express error: #{req.method} #{req.path}: #{err.message}"
      log.error "#{message}, stack: #{err.stack}"
      if global.testing
        console.log "#{message}, stack: #{err.stack}"
      slack.sendSlackMessage(message, ['ops'], {papertrail: true})
    else
      next(err)

setupExpressMiddleware = (app) ->
  if config.isProduction
    express.logger.format('prod', productionLogging)
    app.use(express.logger('prod'))
    app.use express.compress filter: (req, res) ->
      return false if req.headers.host is 'codecombat.com'  # CloudFlare will gzip it for us on codecombat.com
      compressible res.getHeader('Content-Type')
  else if not global.testing
    express.logger.format('dev', developmentLogging)
    app.use(express.logger('dev'))
  app.use(express.static(path.join(__dirname, 'public'), maxAge: 0))  # CloudFlare overrides maxAge, and we don't want local development caching.
  
  setupProxyMiddleware app # TODO: Flatten setup into one function. This doesn't fit its function name.

  app.use(express.favicon())
  app.use(express.cookieParser())
  app.use(express.bodyParser())
  app.use(express.methodOverride())
  app.use(express.cookieSession({
    key:'codecombat.sess'
    secret:config.cookie_secret
  }))

setupPassportMiddleware = (app) ->
  app.use(authentication.initialize())
  if config.picoCTF
    app.use authentication.authenticate('local', failureRedirect: config.picoCTF_login_URL)
    require('./server/lib/picoctf').init app
  else
    app.use(authentication.session())
  auth.setup()

setupCountryRedirectMiddleware = (app, country="china", countryCode="CN", languageCode="zh", host="cn.codecombat.com") ->
  shouldRedirectToCountryServer = (req) ->
    speaksLanguage = _.any req.acceptedLanguages, (language) -> language.indexOf languageCode isnt -1

    #Work around express 3.0
    reqHost = req.hostname
    reqHost ?= req.host

    unless reqHost.toLowerCase() is host
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
      res.writeHead 302, "Location": 'http://' + host + req.url
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
    try
      v = parseInt ua.Version.split('.')[0], 10
    catch TypeError
      log.error('ua.Version does not have a split function.', JSON.stringify(ua, null, '  '))
      return false
    return true if b is 'Chrome' and v < 17
    return true if b is 'Safari' and v < 6
    return true if b is 'Firefox' and v < 21
    return true if b is 'IE' and v < 11
    false

  app.use('/play/', useragent.express())
  app.use '/play/', (req, res, next) ->
    return next() if req.query['try-old-browser-anyway'] or not isOldBrowser req
    res.sendfile(path.join(__dirname, 'public', 'index_old_browser.html'))

setupRedirectMiddleware = (app) ->
  app.all '/account/profile/*', (req, res, next) ->
    nameOrID = req.path.split('/')[3]
    res.redirect 301, "/user/#{nameOrID}/profile"

setupPerfMonMiddleware = (app) ->
  app.use perfmon.middleware

exports.setupMiddleware = (app) ->
  setupPerfMonMiddleware app
  setupCountryRedirectMiddleware app, "china", "CN", "zh", config.chinaDomain
  setupCountryRedirectMiddleware app, "brazil", "BR", "pt-BR", config.brazilDomain
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

      Mandate.findOne({}).cache(5 * 60 * 1000).exec (err, mandate) ->
        if err
          log.error "Error getting mandate config: #{err}"
          configData = {}
        else
          configData =  _.omit mandate?.toObject() or {}, '_id'
        configData.picoCTF = config.picoCTF
        configData.production = config.isProduction
        data = data.replace '"serverConfigTag"', JSON.stringify configData
        data = data.replace('"userObjectTag"', user)
        data = data.replace('"amActuallyTag"', JSON.stringify(req.session.amActually))
        res.header 'Cache-Control', 'no-cache, no-store, must-revalidate'
        res.header 'Pragma', 'no-cache'
        res.header 'Expires', 0
        res.send 200, data

setupFacebookCrossDomainCommunicationRoute = (app) ->
  app.get '/channel.html', (req, res) ->
    res.sendfile path.join(__dirname, 'public', 'channel.html')

exports.setupRoutes = (app) ->
  routes.setup(app)
  app.use app.router

  baseRoute.setup app
  setupFacebookCrossDomainCommunicationRoute app
  setupFallbackRouteToIndex app

###Miscellaneous configuration functions###

exports.setupLogging = ->
  logging.setup()

exports.connectToDatabase = ->
  return if config.proxy
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

setupProxyMiddleware = (app) ->
  return if config.isProduction
  return unless config.proxy
  httpProxy = require 'http-proxy'
  proxy = httpProxy.createProxyServer({
    target: 'https://direct.codecombat.com'
    secure: false
  })
  log.info 'Using dev proxy server'
  app.use (req, res, next) ->
    req.proxied = true
    proxy.web req, res, (e) ->
      console.warn("Failed to proxy: ", e)
      res.status(502).send({message: 'Proxy failed'})
