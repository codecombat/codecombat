express = require 'express'
path = require 'path'
useragent = require 'express-useragent'
fs = require 'graceful-fs'
log = require 'winston'
compressible = require 'compressible'
compression = require 'compression'

geoip = require '@basicer/geoip-lite'
crypto = require 'crypto'
config = require './server_config'
global.tv4 = require 'tv4' # required for TreemaUtils to work
global.jsondiffpatch = require('jsondiffpatch')
global.stripe = require('stripe')(config.stripe.secretKey)
request = require 'request'
Promise = require 'bluebird'
Promise.promisifyAll(request, {multiArgs: true})
Promise.promisifyAll(fs)
wrap = require 'co-express'
morgan = require 'morgan'
timeout = require('connect-timeout')

{countries} = require './app/core/utils'

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
    return "[#{config.clusterID}] \x1b[90m#{req.method} #{req.originalUrl} \x1b[#{color}m#{res.statusCode} \x1b[#{elapsedColor}m#{elapsed}ms\x1b[0m"
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

setupExpressMiddleware = (app) ->
  if config.isProduction
    morgan.format('prod', productionLogging)
    app.use(morgan('prod'))
    app.use compression filter: (req, res) ->
      return false if req.headers.host is 'codecombat.com'  # CloudFlare will gzip it for us on codecombat.com
      compressible res.getHeader('Content-Type')
  else if not global.testing or config.TRACE_ROUTES
    morgan.format('dev', developmentLogging)
    app.use(morgan('dev'))

  app.use (req, res, next) ->
    res.header 'X-Cluster-ID', config.clusterID
    next()

  public_path = path.join(__dirname, 'public')

  app.use('/', express.static(path.join(public_path, 'templates', 'static')))

  if config.buildInfo.sha isnt 'dev' and config.isProduction
    app.use("/#{config.buildInfo.sha}", express.static(public_path, maxAge: '1y'))
  else
    app.use('/dev', express.static(public_path, maxAge: 0))  # CloudFlare overrides maxAge, and we don't want local development caching.

  app.use(express.static(public_path, maxAge: 0))

  if config.proxy
    # Don't proxy static files with sha prefixes, redirect them
    regex = /\/[0-9a-f]{40}\/.*/
    regex2 = /\/[0-9a-f]{40}-[0-9a-f]{40}\/.*/
    app.use (req, res, next) ->
      if regex.test(req.path)
        newPath = req.path.slice(41)
        return res.redirect(newPath)
      if regex2.test(req.path)
        newPath = req.path.slice(82)
        return res.redirect(newPath)
      next()

  setupProxyMiddleware app # TODO: Flatten setup into one function. This doesn't fit its function name.

  app.use require('serve-favicon') path.join(__dirname, 'public', 'images', 'favicon.ico')
  app.use require('cookie-parser')()
  app.use require('body-parser').json({limit: '25mb', strict: false, verify: (req, res, buf, encoding) ->
    if req.headers['x-hub-signature']
      # this is an intercom webhook request, with signature that needs checking
      try
        digest = crypto.createHmac('sha1', config.intercom.webhookHubSecret).update(buf).digest('hex')
        req.signatureMatches = req.headers['x-hub-signature'] is "sha1=#{digest}"
      catch e
        log.info 'Error checking hub signature on Intercom webhook: ' + e
  })
  app.use require('body-parser').urlencoded extended: true, limit: '25mb'
  app.use require('method-override')()
  app.use require('cookie-session')
    key: 'codecombat.sess'
    secret: config.cookie_secret

setupCountryTaggingMiddleware = (app) ->
  app.use (req, res, next) ->
    return next() if req.country or req.user?.get('country')
    return next() unless ip = req.headers['x-forwarded-for'] or req.ip or req.connection.remoteAddress
    ip = ip.split(/,? /)[0]  # If there are two IP addresses, say because of CloudFlare, we just take the first.
    geo = geoip.lookup(ip)
    if countryInfo = _.find(countries, countryCode: geo?.country)
      req.country = countryInfo.country
    next()

setupCountryRedirectMiddleware = (app, country='china', host='cn.codecombat.com') ->
  hosts = host.split /;/g
  shouldRedirectToCountryServer = (req) ->
    reqHost = (req.hostname ? req.host ? '').toLowerCase()  # Work around express 3.0
    return req.country is country and reqHost not in hosts and reqHost.indexOf(config.unsafeContentHostname) is -1

  app.use (req, res, next) ->
    if shouldRedirectToCountryServer(req) and hosts.length
      res.writeHead 302, "Location": 'http://' + hosts[0] + req.url
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

  app.use '/play/', useragent.express()
  app.use '/play/', (req, res, next) ->
    return next() if req.path?.indexOf('web-dev-level') >= 0
    return next() if req.query['try-old-browser-anyway'] or not isOldBrowser req
    res.sendfile(path.join(__dirname, 'public', 'index_old_browser.html'))

setupRedirectMiddleware = (app) ->
  app.all '/account/profile/*', (req, res, next) ->
    nameOrID = req.path.split('/')[3]
    res.redirect 301, "/user/#{nameOrID}/profile"

setupFeaturesMiddleware = (app) ->
  app.use (req, res, next) ->
    # TODO: Share these defaults with run-tests.js
    req.features = features = {
      freeOnly: false
    }

    if req.headers.host is 'brainpop.codecombat.com' or req.session.featureMode is 'brain-pop'
      features.freeOnly = true
      features.campaignSlugs = ['dungeon']
      features.playViewsOnly = true
      features.noAuth = true
      features.brainPop = true
      features.noAds = true

    if req.headers.host is 'cp.codecombat.com' or req.session.featureMode is 'code-play'
      features.freeOnly = true
      features.campaignSlugs = ['dungeon', 'forest', 'desert']
      features.playViewsOnly = true
      features.codePlay = true # for one-off changes. If they're shared across different scenarios, refactor

    if /cn\.codecombat\.com/.test(req.get('host')) or /koudashijie/.test(req.get('host')) or req.session.featureMode is 'china'
      features.china = true
      features.freeOnly = true
      features.noAds = true

    if config.picoCTF or req.session.featureMode is 'pico-ctf'
      features.playOnly = true
      features.noAds = true
      features.picoCtf = true

    if config.chinaInfra
      features.chinaInfra = true

    next()

# When config.TRACE_ROUTES is set, this logs a stack trace every time an endpoint sends a response.
# It's great for finding where a mystery endpoint is!
# The same is done for errors in the error-handling middleware.
setupHandlerTraceMiddleware = (app) ->
  app.use (req, res, next) ->
    oldSend = res.send
    res.send = ->
      result = oldSend.apply(@, arguments)
      console.trace()
      return result
    next()

setupSecureMiddleware = (app) ->
  # Cannot use express request `secure` property in production, due to
  # cluster setup.
  isSecure = ->
    return @secure or @headers['x-forwarded-proto'] is 'https'

  app.use (req, res, next) ->
    req.isSecure = isSecure
    next()

exports.setupMiddleware = (app) ->
  app.use(timeout(config.timeout))
  setupHandlerTraceMiddleware app if config.TRACE_ROUTES
  setupSecureMiddleware app

  setupQuickBailToMainHTML app


  setupCountryTaggingMiddleware app

  setupMiddlewareToSendOldBrowserWarningWhenPlayersViewLevelDirectly app
  setupExpressMiddleware app
  setupFeaturesMiddleware app

  setupCountryRedirectMiddleware app, 'china', config.chinaDomain
  setupCountryRedirectMiddleware app, 'brazil', config.brazilDomain

  setupOneSecondDelayMiddleware app
  setupRedirectMiddleware app
  setupAjaxCaching app
  setupJavascript404s app

###Routing function implementations###

setupAjaxCaching = (app) ->
  # IE/Edge are more aggressive about caching than other browsers, so we'll override their caching here.
  # Assumes our CDN will override these with its own caching rules.
  app.get '/db/*', (req, res, next) ->
    return next() unless req.xhr
    # http://stackoverflow.com/questions/19999388/check-if-user-is-using-ie-with-jquery
    userAgent = req.header('User-Agent') or ""
    if userAgent.indexOf('MSIE ') > 0 or !!userAgent.match(/Trident.*rv\:11\.|Edge\/\d+/)
      res.header 'Cache-Control', 'no-cache, no-store, must-revalidate'
      res.header 'Pragma', 'no-cache'
      res.header 'Expires', 0
    next()

setupJavascript404s = (app) ->
  app.get '/javascripts/*', (req, res) ->
    res.status(404).send('Not found')
  app.get(/^\/?[a-f0-9]{40}/, (req, res) ->
    res.status(404).send('Wrong hash')
  )

templates = {}
getStaticTemplate = (file) ->
  # Don't cache templates in devlopment so you can just edit then.
  return templates[file] if templates[file] and config.isProduction
  templates[file] = fs.readFileAsync(path.join(__dirname, 'public', 'templates', 'static', file), 'utf8')

renderMain = wrap (template, req, res) ->
  template = yield getStaticTemplate(template)

  res.status(200).send template

setupQuickBailToMainHTML = (app) ->

  fast = (template) ->
    (req, res, next) ->
      req.features = features = {}

      if config.isProduction or true
        res.header 'Cache-Control', 'public, max-age=60'
        res.header 'Expires', 60
      else
        res.header 'Cache-Control', 'no-cache, no-store, must-revalidate'
        res.header 'Pragma', 'no-cache'
        res.header 'Expires', 0

      if req.headers.host is 'cp.codecombat.com'
        features.codePlay = true # for one-off changes. If they're shared across different scenarios, refactor
      if /cn\.codecombat\.com/.test(req.get('host'))
        features.china = true

      if config.chinaInfra
        features.chinaInfra = true

      renderMain(template, req, res)

  app.get '/', fast('home.html')
  app.get '/home', fast('home.html')
  app.get '/about', fast('about.html')
  app.get '/features', fast('premium-features.html')
  app.get '/privacy', fast('privacy.html')
  app.get '/legal', fast('legal.html')
  app.get '/play', fast('overworld.html')
  app.get '/play/level/:slug', fast('main.html')
  app.get '/play/:slug', fast('main.html')

# Mongo-cache doesnt support the .exec() promise, so we manually wrap it.
# getMandate = (app) ->
#   return new Promise (res, rej) ->
#     Mandate.findOne({}).cache(5 * 60 * 1000).exec (err, data) ->
#       return rej(err) if err
#       res(data)

###Miscellaneous configuration functions###

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

  target = 'https://very.direct.codecombat.com'
  headers = {}

  if (process.env.COCO_PROXY_NEXT)
    target = 'https://next.codecombat.com'
    headers['Host'] = 'next.codecombat.com'

  proxy = httpProxy.createProxyServer({
    target: target
    secure: false,
    headers: headers
  })
  log.info 'Using dev proxy server'
  app.use (req, res, next) ->
    req.proxied = true
    proxy.web req, res, (e) ->
      console.warn("Failed to proxy: ", e)
      res.status(502).send({message: 'Proxy failed'})
