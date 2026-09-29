/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS104: Avoid inline assignments
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
const express = require('express')
const path = require('path')
const fs = require('graceful-fs')

const config = require('./server_config')
global.tv4 = require('tv4') // required for TreemaUtils to work
global.jsondiffpatch = require('jsondiffpatch')
const Promise = require('bluebird')
Promise.promisifyAll(fs)
const wrap = require('co-express')
const morgan = require('morgan')
const timeout = require('connect-timeout')
const PWD = process.env.PWD || __dirname
const devUtils = require('./development/utils')
const {
  publicFolderName,
} = devUtils
const publicPath = path.join(PWD, publicFolderName)

const developmentLogging = function (tokens, req, res) {
  const status = res.statusCode
  let color = 32
  if (status >= 500) {
    color = 31
  } else if (status >= 400) {
    color = 33
  } else if (status >= 300) { color = 36 }
  const elapsed = (new Date()) - req._startTime
  const elapsedColor = elapsed < 500 ? 90 : 31
  let s = `\x1b[90m${req.method} ${req.originalUrl} \x1b[${color}m${res.statusCode} \x1b[${elapsedColor}m${elapsed}ms\x1b[0m`
  if (req.proxied) { s += ' (proxied)' }
  return s
}

const setupExpressMiddleware = function (app) {
  morgan.format('dev', developmentLogging)
  app.use(morgan('dev'))

  app.use(function (req, res, next) {
    res.header('X-Cluster-ID', config.clusterID)
    return next()
  })

  app.use('/', express.static(path.join(publicPath, 'templates', 'static')))

  app.use('/dev', express.static(publicPath, { maxAge: 0 })) // CloudFlare overrides maxAge, and we don't want local development caching.

  app.use(express.static(publicPath, { maxAge: 0 }))

  // setupProxyMiddleware's catch-all handles (and terminates) every request that
  // isn't already served as a static file above. The real backend — a separate,
  // more secure server — is responsible for cookies/sessions/auth/etc, so this
  // repo has no need for its own favicon, cookie/body parsing, or feature-mode
  // middleware.
  return setupProxyMiddleware(app) // TODO: Flatten setup into one function. This doesn't fit its function name.
}

exports.setupMiddleware = function (app) {
  app.use(timeout(config.timeout))

  setupQuickBailToMainHTML(app)

  return setupExpressMiddleware(app)
}

/* Routing function implementations */

const getStaticTemplate = function (file) {
  return fs.readFileAsync(path.join(publicPath, 'templates', 'static', file), 'utf8')
}

const renderMain = wrap(function * (template, req, res) {
  template = yield getStaticTemplate(template)

  return res.status(200).send(template)
})

const setupQuickBailToMainHTML = function (app) {
  const fast = template => function (req, res, next) {
    let features
    req.features = (features = {})

    res.header('Cache-Control', 'public, max-age=60')
    res.header('Expires', 60)

    if (/(cn\.codecombat\.com|koudashijie|aojiarui)/.test(req.get('host'))) {
      features.china = true
      if ((template === 'home.html') && (config.product === 'codecombat')) {
        template = 'home-cn.html'
      }
    }

    if (config.chinaInfra) {
      features.chinaInfra = true
    }

    return renderMain(template, req, res)
  }

  app.get('/', fast('home.html'))
  app.get('/home', fast('home.html'))
  app.get('/play', fast('overworld.html'))
  app.get('/play/level/:slug', fast('main.html'))
  app.get('/play/:slug', fast('main.html'))
  if (config.product === 'codecombat') {
    app.get('/about', fast('about.html'))
    if (config.product === 'codecombat') { app.get('/features', fast('premium-features.html')) }
    app.get('/privacy', fast('privacy.html'))
    app.get('/legal', fast('legal.html'))
  }
  if (config.product === 'ozaria') {
    app.get('/teachers/classes/:slug', fast('main.html'))
    return app.get('/teachers/:slug', fast('main.html'))
  }
}

/* Miscellaneous configuration functions */

exports.setExpressConfigurationOptions = function (app) {
  app.set('port', config.port)
  app.set('views', PWD + '/app/views')
  app.set('view engine', 'jade')
  app.set('view options', { layout: false })
  app.set('env', 'development')
}

const setupProxyMiddleware = function (app) {
  // Don't proxy static files with sha prefixes, redirect them
  const regex = /\/[0-9a-f]{40}\/.*/
  const regex2 = /\/[0-9a-f]{40}-[0-9a-f]{40}\/.*/
  // based on new format of branch name + date
  const regex3 = /^\/(production|next)-\d{4}-\d{2}-\d{2}-\d{2}-\d{2}-\d{2}\/.*/
  app.use(function (req, res, next) {
    let newPath
    if (regex.test(req.path)) {
      newPath = req.path.slice(41)
      return res.redirect(newPath)
    }
    if (regex2.test(req.path)) {
      newPath = req.path.slice(82)
      return res.redirect(newPath)
    }
    if (regex3.test(req.path)) {
      const split = req.path.split('/')
      newPath = '/' + split.slice(2).join('/')
      return res.redirect(newPath)
    }
    return next()
  })

  const httpProxy = require('http-proxy')

  let target = process.env.COCO_PROXY_TARGET || `https://direct.staging.${config.product}.com`
  const headers = {}

  if (process.env.COCO_PROXY_NEXT) {
    target = `https://direct.next.${config.product}.com`
    headers.Host = `next.${config.product}.com`
  }

  const proxy = httpProxy.createProxyServer({
    target,
    headers,
    secure: false,
  })
  console.info('Using dev proxy server')
  return app.use(function (req, res, next) {
    req.proxied = true
    return proxy.web(req, res, function (e) {
      console.warn('Failed to proxy: ', e)
      return res.status(502).send({ message: 'Proxy failed' })
    })
  })
}
