/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS104: Avoid inline assignments
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
const express = require('express');
const path = require('path');
const fs = require('graceful-fs');
const compressible = require('compressible');
const compression = require('compression');

const crypto = require('crypto');
const config = require('./server_config');
global.tv4 = require('tv4'); // required for TreemaUtils to work
global.jsondiffpatch = require('jsondiffpatch');
const Promise = require('bluebird');
Promise.promisifyAll(fs);
const wrap = require('co-express');
const morgan = require('morgan');
const timeout = require('connect-timeout');
const PWD = process.env.PWD || __dirname;
const devUtils = require('./development/utils');
const {
  productSuffix
} = devUtils;
const {
  publicFolderName
} = devUtils;
const publicPath = path.join(PWD, publicFolderName);

const {countries} = require('./app/core/utils');

const productionLogging = function(tokens, req, res) {
  const status = res.statusCode;
  let color = 32;
  if (status >= 500) { color = 31;
  } else if (status >= 400) { color = 33;
  } else if (status >= 300) { color = 36; }
  const elapsed = (new Date()) - req._startTime;
  const elapsedColor = elapsed < 500 ? 90 : 31;
  if ((status === 404) && /\/feedback/.test(req.originalUrl)) { return null; }  // We know that these usually 404 by design (bad design?)
  if (((status !== 200) && (status !== 201) && (status !== 204) && (status !== 304) && (status !== 302)) || (elapsed > 500)) {
    return `[${config.clusterID}] \x1b[90m${req.method} ${req.originalUrl} \x1b[${color}m${res.statusCode} \x1b[${elapsedColor}m${elapsed}ms\x1b[0m`;
  }
  return null;
};

const developmentLogging = function(tokens, req, res) {
  const status = res.statusCode;
  let color = 32;
  if (status >= 500) { color = 31;
  } else if (status >= 400) { color = 33;
  } else if (status >= 300) { color = 36; }
  const elapsed = (new Date()) - req._startTime;
  const elapsedColor = elapsed < 500 ? 90 : 31;
  let s = `\x1b[90m${req.method} ${req.originalUrl} \x1b[${color}m${res.statusCode} \x1b[${elapsedColor}m${elapsed}ms\x1b[0m`;
  if (req.proxied) { s += ' (proxied)'; }
  return s;
};

const setupExpressMiddleware = function(app) {
  if (config.isProduction) {
    morgan.format('prod', productionLogging);
    app.use(morgan('prod'));
    app.use(compression({filter(req, res) {
      if (req.headers.host === 'codecombat.com') { return false; }  // CloudFlare will gzip it for us on codecombat.com
      return compressible(res.getHeader('Content-Type'));
    }
    })
    );
  } else if (!global.testing || config.TRACE_ROUTES) {
    morgan.format('dev', developmentLogging);
    app.use(morgan('dev'));
  }

  app.use(function(req, res, next) {
    res.header('X-Cluster-ID', config.clusterID);
    return next();
  });

  app.use('/', express.static(path.join(publicPath, 'templates', 'static')));

  if ((config.buildInfo.sha !== 'dev') && config.isProduction) {
    app.use(`/${config.buildInfo.sha}`, express.static(publicPath, {maxAge: '1y'}));
  } else {
    app.use('/dev', express.static(publicPath, {maxAge: 0}));  // CloudFlare overrides maxAge, and we don't want local development caching.
  }

  app.use(express.static(publicPath, {maxAge: 0}));

  setupProxyMiddleware(app); // TODO: Flatten setup into one function. This doesn't fit its function name.

  try {
    app.use(require('serve-favicon')(path.join(publicPath, 'images', 'favicon', `favicon-${productSuffix}`, 'favicon.ico')));
  } catch (e) {
    console.error(`Error. Couldn't find ${path.join(publicPath, 'images', 'favicon', 'favicon-' + productSuffix)}. It is likely that the ${publicFolderName} folder is not built. Try:\n\n  npm run build\n\nfor an initial build, or\n\n  npm run dev\n\nfor live rebuilding of your front-end changes. If those don't work, make sure you are running the correct version of node and have installed all dependencies with:\n\n  npm install --also=dev\n`);
    process.exit(1);
  }
  app.use(require('cookie-parser')());
  app.use(require('body-parser').json({limit: '25mb', strict: false}));
  app.use(require('body-parser').urlencoded({extended: true, limit: '25mb'}));
  app.use(require('method-override')());
  return app.use(require('cookie-session')({
    key: 'codecombat.sess',
    secret: config.cookie_secret
  })
  );
};

const setupCountryRedirectMiddleware = function(app, country, host) {
  if (country == null) { country = 'china'; }
  if (host == null) { host = 'cn.codecombat.com'; }
  const hosts = host.split(/;/g);
  const shouldRedirectToCountryServer = function(req) {
    let left;
    const reqHost = ((left = req.hostname != null ? req.hostname : req.host) != null ? left : '').toLowerCase();  // Work around express 3.0
    return (req.country === country) && !Array.from(hosts).includes(reqHost) && (reqHost.indexOf(config.unsafeContentHostname) === -1);
  };

  return app.use(function(req, res, next) {
    if (shouldRedirectToCountryServer(req) && hosts.length) {
      res.writeHead(302, {"Location": 'http://' + hosts[0] + req.url});
      return res.end();
    } else {
      return next();
    }
  });
};

const setupOneSecondDelayMiddleware = function(app) {
  if(config.slow_down) {
    return app.use((req, res, next) => setTimeout((() => next()), 1000));
  }
};

const setupRedirectMiddleware = app => app.all('/account/profile/*', function(req, res, next) {
  const nameOrID = req.path.split('/')[3];
  return res.redirect(301, `/user/${nameOrID}/profile`);
});

const setupFeaturesMiddleware = app => app.use(function(req, res, next) {
  // TODO: Share these defaults with run-tests.js
  let features;
  req.features = (features = {
    freeOnly: false
  });

  if ((req.headers.host === 'brainpop.codecombat.com') || (req.session.featureMode === 'brain-pop')) {
    features.freeOnly = true;
    features.campaignSlugs = ['dungeon'];
    features.playViewsOnly = true;
    features.noAuth = true;
    features.brainPop = true;
    features.noAds = true;
  }

  if (/(cn\.codecombat\.com|koudashijie|aojiarui)/.test(req.get('host')) || (req.session.featureMode === 'china')) {
    features.china = true;
    features.freeOnly = true;
    features.noAds = true;
  }

  if (config.picoCTF || (req.session.featureMode === 'pico-ctf')) {
    features.playOnly = true;
    features.noAds = true;
    features.picoCtf = true;
  }

  if (config.chinaInfra) {
    features.chinaInfra = true;
  }

  return next();
});

// When config.TRACE_ROUTES is set, this logs a stack trace every time an endpoint sends a response.
// It's great for finding where a mystery endpoint is!
// The same is done for errors in the error-handling middleware.
const setupHandlerTraceMiddleware = app => app.use(function(req, res, next) {
  const oldSend = res.send;
  res.send = function() {
    const result = oldSend.apply(this, arguments);
    console.trace();
    return result;
  };
  return next();
});

const setupSecureMiddleware = function(app) {
  // Cannot use express request `secure` property in production, due to
  // cluster setup.
  const isSecure = function() {
    return this.secure || (this.headers['x-forwarded-proto'] === 'https');
  };

  return app.use(function(req, res, next) {
    req.isSecure = isSecure;
    return next();
  });
};

exports.setupMiddleware = function(app) {
  app.use(timeout(config.timeout));
  if (config.TRACE_ROUTES) { setupHandlerTraceMiddleware(app); }
  setupSecureMiddleware(app);

  setupQuickBailToMainHTML(app);

  setupExpressMiddleware(app);
  setupFeaturesMiddleware(app);

  setupCountryRedirectMiddleware(app, 'china', config.chinaDomain);

  setupOneSecondDelayMiddleware(app);
  setupRedirectMiddleware(app);
  setupAjaxCaching(app);
  return setupJavascript404s(app);
};

/*Routing function implementations*/

var setupAjaxCaching = app => // IE/Edge are more aggressive about caching than other browsers, so we'll override their caching here.
// Assumes our CDN will override these with its own caching rules.
app.get('/db/*', function(req, res, next) {
  if (!req.xhr) { return next(); }
  // http://stackoverflow.com/questions/19999388/check-if-user-is-using-ie-with-jquery
  const userAgent = req.header('User-Agent') || "";
  if ((userAgent.indexOf('MSIE ') > 0) || !!userAgent.match(/Trident.*rv\:11\.|Edge\/\d+/)) {
    res.header('Cache-Control', 'no-cache, no-store, must-revalidate');
    res.header('Pragma', 'no-cache');
    res.header('Expires', 0);
  }
  return next();
});

var setupJavascript404s = function(app) {
  app.get('/javascripts/*', (req, res) => res.status(404).send('Not found'));
  return app.get(/^\/?[a-f0-9]{40}/, (req, res) => res.status(404).send('Wrong hash'));
};

const templates = {};
const getStaticTemplate = function(file) {
  // Don't cache templates in development so you can just edit then.
  if (templates[file] && config.isProduction) { return templates[file]; }
  return templates[file] = fs.readFileAsync(path.join(publicPath, 'templates', 'static', file), 'utf8');
};

const renderMain = wrap(function*(template, req, res) {
  template = yield getStaticTemplate(template);

  return res.status(200).send(template);
});

var setupQuickBailToMainHTML = function(app) {

  const fast = template => (function(req, res, next) {
    let features;
    req.features = (features = {});

    if (config.isProduction || true) {
      res.header('Cache-Control', 'public, max-age=60');
      res.header('Expires', 60);
    } else {
      res.header('Cache-Control', 'no-cache, no-store, must-revalidate');
      res.header('Pragma', 'no-cache');
      res.header('Expires', 0);
    }

    if (/(cn\.codecombat\.com|koudashijie|aojiarui)/.test(req.get('host'))) {
      features.china = true;
      if ((template === 'home.html') && (config.product === 'codecombat')) {
        template = 'home-cn.html';
      }
    }

    if (config.chinaInfra) {
      features.chinaInfra = true;
    }

    return renderMain(template, req, res);
  });

  app.get('/', fast('home.html'));
  app.get('/home', fast('home.html'));
  app.get('/play', fast('overworld.html'));
  app.get('/play/level/:slug', fast('main.html'));
  app.get('/play/:slug', fast('main.html'));
  if (config.product === 'codecombat') {
    app.get('/about', fast('about.html'));
    if (config.product === 'codecombat') { app.get('/features', fast('premium-features.html')); }
    app.get('/privacy', fast('privacy.html'));
    app.get('/legal', fast('legal.html'));
  }
  if (config.product === 'ozaria') {
    app.get('/teachers/classes/:slug', fast('main.html'));
    return app.get('/teachers/:slug', fast('main.html'));
  }
};

/*Miscellaneous configuration functions*/

exports.setExpressConfigurationOptions = function(app) {
  app.set('port', config.port);
  app.set('views', PWD + '/app/views');
  app.set('view engine', 'jade');
  app.set('view options', { layout: false });
  app.set('env', config.isProduction ? 'production' : 'development');
  if (config.isProduction) { return app.set('json spaces', 0); }
};

var setupProxyMiddleware = function(app) {
  if (config.isProduction) { return; }
  if (!config.proxy) { return; }

  // Don't proxy static files with sha prefixes, redirect them
  const regex = /\/[0-9a-f]{40}\/.*/;
  const regex2 = /\/[0-9a-f]{40}-[0-9a-f]{40}\/.*/;
  // based on new format of branch name + date
  const regex3 = /^\/(production|next)-\d{4}-\d{2}-\d{2}-\d{2}-\d{2}-\d{2}\/.*/;
  app.use(function(req, res, next) {
    let newPath;
    if (regex.test(req.path)) {
      newPath = req.path.slice(41);
      return res.redirect(newPath);
    }
    if (regex2.test(req.path)) {
      newPath = req.path.slice(82);
      return res.redirect(newPath);
    }
    if (regex3.test(req.path)) {
      const split = req.path.split('/');
      newPath = '/' + split.slice(2).join('/');
      return res.redirect(newPath);
    }
    return next();
  });

  const httpProxy = require('http-proxy');

  let target = process.env.COCO_PROXY_TARGET || `https://direct.staging.${config.product}.com`;
  const headers = {};

  if (process.env.COCO_PROXY_NEXT) {
    target = `https://direct.next.${config.product}.com`;
    headers['Host'] = `next.${config.product}.com`;
  }

  const proxy = httpProxy.createProxyServer({
    target,
    headers,
    secure: false
  });
  console.info('Using dev proxy server');
  return app.use(function(req, res, next) {
    req.proxied = true;
    return proxy.web(req, res, function(e) {
      console.warn("Failed to proxy: ", e);
      return res.status(502).send({message: 'Proxy failed'});
    });
  });
};
