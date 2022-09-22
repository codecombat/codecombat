express = require 'express'
path = require 'path'
fs = require 'graceful-fs'
compressible = require 'compressible'
compression = require 'compression'

crypto = require 'crypto'
config = require './server_config'
global.tv4 = require 'tv4' # required for TreemaUtils to work
global.jsondiffpatch = require('jsondiffpatch')
Promise = require 'bluebird'
Promise.promisifyAll(fs)
wrap = require 'co-express'
morgan = require 'morgan'
timeout = require('connect-timeout')
PWD = process.env.PWD || __dirname
devUtils = require './development/utils'
productSuffix = devUtils.productSuffix
publicFolderName = devUtils.publicFolderName
publicPath = path.join(PWD, publicFolderName)

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

  app.use('/', express.static(path.join(publicPath, 'templates', 'static')))

  if config.buildInfo.sha isnt 'dev' and config.isProduction
    app.use("/#{config.buildInfo.sha}", express.static(publicPath, maxAge: '1y'))
  else
    app.use('/dev', express.static(publicPath, maxAge: 0))  # CloudFlare overrides maxAge, and we don't want local development caching.

  app.use(express.static(publicPath, maxAge: 0))

  setupProxyMiddleware app # TODO: Flatten setup into one function. This doesn't fit its function name.


  app.use require('serve-favicon') path.join(publicPath, 'images', 'favicon', "favicon-#{productSuffix}", 'favicon.ico')
  app.use require('cookie-parser')()
  app.use require('body-parser').json limit: '25mb', strict: false
  app.use require('body-parser').urlencoded extended: true, limit: '25mb'
  app.use require('method-override')()
  app.use require('cookie-session')
    key: 'codecombat.sess'
    secret: config.cookie_secret

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

    if /(cn\.codecombat\.com|koudashijie|aojiarui)/.test(req.get('host')) or req.session.featureMode is 'china'
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

  setupExpressMiddleware app
  setupFeaturesMiddleware app

  setupCountryRedirectMiddleware app, 'china', config.chinaDomain

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
  # Don't cache templates in development so you can just edit then.
  return templates[file] if templates[file] and config.isProduction
  templates[file] = fs.readFileAsync(path.join(publicPath, 'templates', 'static', file), 'utf8')

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

      if /(cn\.codecombat\.com|koudashijie|aojiarui)/.test(req.get('host'))
        features.china = true
        if template is 'home.html' and config.product is 'codecombat'
          template = 'home-cn.html'

      if config.chinaInfra
        features.chinaInfra = true

      renderMain(template, req, res)

  app.get '/', fast('home.html')
  app.get '/home', fast('home.html')
  app.get '/play', fast('overworld.html')
  app.get '/play/level/:slug', fast('main.html')
  app.get '/play/:slug', fast('main.html')
  if config.product is 'codecombat'
    app.get '/about', fast('about.html')
    app.get '/features', fast('premium-features.html') if config.product is 'codecombat'
    app.get '/privacy', fast('privacy.html')
    app.get '/legal', fast('legal.html')
  if config.product is 'ozaria'
    app.get '/teachers/classes/:slug', fast('main.html')
    app.get '/teachers/:slug', fast('main.html')

###Miscellaneous configuration functions###

exports.setExpressConfigurationOptions = (app) ->
  app.set('port', config.port)
  app.set('views', PWD + '/app/views')
  app.set('view engine', 'jade')
  app.set('view options', { layout: false })
  app.set('env', if config.isProduction then 'production' else 'development')
  app.set('json spaces', 0) if config.isProduction

setupProxyMiddleware = (app) ->
  return if config.isProduction
  return unless config.proxy

  # Don't proxy static files with sha prefixes, redirect them
  regex = /\/[0-9a-f]{40}\/.*/
  regex2 = /\/[0-9a-f]{40}-[0-9a-f]{40}\/.*/
  # based on new format of branch name + date
  regex3 = /^\/(production|next)-\d{4}-\d{2}-\d{2}-\d{2}-\d{2}-\d{2}\/.*/
  app.use (req, res, next) ->
    if regex.test(req.path)
      newPath = req.path.slice(41)
      return res.redirect(newPath)
    if regex2.test(req.path)
      newPath = req.path.slice(82)
      return res.redirect(newPath)
    if regex3.test(req.path)
      split = req.path.split('/')
      newPath = '/' + split.slice(2).join('/')
      return res.redirect(newPath)
    next()

  httpProxy = require 'http-proxy'

  target = process.env.COCO_PROXY_TARGET or "https://direct.staging.#{config.product}.com"
  headers = {}

  if process.env.COCO_PROXY_NEXT
    target = "https://direct.next.#{config.product}.com"
    headers['Host'] = "next.#{config.product}.com"

  proxy = httpProxy.createProxyServer({
    target,
    headers,
    secure: false
  })
  console.info 'Using dev proxy server'
  app.use (req, res, next) ->
    req.proxied = true
    proxy.web req, res, (e) ->
      console.warn("Failed to proxy: ", e)
      res.status(502).send({message: 'Proxy failed'})
