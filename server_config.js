/*
 * decaffeinate suggestions:
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
const fs = require('fs');
const path = require('path');
const os = require('os');
const cluster = require('cluster');

const config = {};

config.product = process.env.COCO_PRODUCT || 'codecombat';
config.productName = { codecombat: 'CodeCombat', ozaria: 'Ozaria' }[config.product];
config.productMainDomain = { codecombat: 'codecombat.com', ozaria: 'ozaria.com' }[config.product];

if (process.env.COCO_SECRETS_JSON_BUNDLE) {
  const object = JSON.parse(process.env.COCO_SECRETS_JSON_BUNDLE);
  for (var k in object) {
    var v = object[k];
    process.env[k] = v;
  }
}

config.clusterID = `${os.hostname()}`;
if (cluster.worker != null) {
 config.clusterID += `/${cluster.worker.id}`;
}

config.unittest = global.testing;
config.proxy = process.env.COCO_PROXY;

config.timeout = parseInt(process.env.COCO_TIMEOUT) || (60*1000);

config.chinaDomain = "bridge.koudashijie.com;koudashijie.com;ccombat.cn;contributors.codecombat.com";
config.chinaInfra = process.env.COCO_CHINA_INFRASTRUCTURE || false;

config.port = process.env.COCO_PORT || process.env.COCO_NODE_PORT || process.env.PORT || 3000;

if (config.unittest) {
  config.port += 1;
}

config.cookie_secret = process.env.COCO_COOKIE_SECRET || 'chips ahoy';

config.isProduction = false;

// Domains (without subdomain prefix, with port number) for main hostname (usually codecombat.com)
// and unsafe web-dev iFrame content (usually codecombatprojects.com).
config.mainHostname = process.env.COCO_MAIN_HOSTNAME || 'localhost:3000';
config.unsafeContentHostname = process.env.COCO_UNSAFE_CONTENT_HOSTNAME || 'localhost:3000';

if (process.env.COCO_PICOCTF) {
  config.picoCTF = true;
  config.picoCTF_api_url = 'http://staging.picoctf.com/api';
  config.picoCTF_login_URL = 'http://staging.picoctf.com';
  config.picoCTF_auth = {username: 'picodev', password: 'pico2016rox!ftw'};
} else {
  config.picoCTF = false;
}

if (!config.unittest &&  !config.isProduction) {
  // change artificially slow down non-static requests for testing
  config.slow_down = false;
}

config.buildInfo = { sha: 'dev' };

if (fs.existsSync(path.join(process.env.PWD || __dirname, '.build_info.json'))) {
  config.buildInfo = JSON.parse(fs.readFileSync(path.join(process.env.PWD || __dirname, '.build_info.json'), 'utf8'));
}

// This logs a stack trace every time an endpoint sends a response or throws an error.
// It's great for finding where a mystery endpoint is!
config.TRACE_ROUTES = (process.env.TRACE_ROUTES != null);

// Enables server-side gzip compression for network responses
// Only use this if testing network response sizes in development
// (In production, CloudFlare compresses things for us!)
config.forceCompression = (process.env.COCO_FORCE_COMPRESSION != null);

module.exports = config;
