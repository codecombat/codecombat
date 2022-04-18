fs = require 'fs'
path = require 'path'
os = require 'os'
cluster = require 'cluster'

config = {}

config.product = process.env.COCO_PRODUCT || 'codecombat'
config.productName = { codecombat: 'CodeCombat', ozaria: 'Ozaria' }[config.product]
config.productMainDomain = { codecombat: 'codecombat.com', ozaria: 'ozaria.com' }[config.product]

if process.env.COCO_SECRETS_JSON_BUNDLE
  for k, v of JSON.parse(process.env.COCO_SECRETS_JSON_BUNDLE)
    process.env[k] = v

config.clusterID = "#{os.hostname()}"
if cluster.worker?
 config.clusterID += "/#{cluster.worker.id}"

config.unittest = global.testing
config.proxy = process.env.COCO_PROXY

config.timeout = parseInt(process.env.COCO_TIMEOUT) or 60*1000

config.chinaDomain = "bridge.koudashijie.com;koudashijie.com;ccombat.cn;contributors.codecombat.com"
config.chinaInfra = process.env.COCO_CHINA_INFRASTRUCTURE or false

config.port = process.env.COCO_PORT or process.env.COCO_NODE_PORT or process.env.PORT or 3000

if config.unittest
  config.port += 1

config.cookie_secret = process.env.COCO_COOKIE_SECRET or 'chips ahoy'

config.isProduction = false

# Domains (without subdomain prefix, with port number) for main hostname (usually codecombat.com)
# and unsafe web-dev iFrame content (usually codecombatprojects.com).
config.mainHostname = process.env.COCO_MAIN_HOSTNAME or 'localhost:3000'
config.unsafeContentHostname = process.env.COCO_UNSAFE_CONTENT_HOSTNAME or 'localhost:3000'

if process.env.COCO_PICOCTF
  config.picoCTF = true
  config.picoCTF_api_url = 'http://staging.picoctf.com/api'
  config.picoCTF_login_URL = 'http://staging.picoctf.com'
  config.picoCTF_auth = {username: 'picodev', password: 'pico2016rox!ftw'}
else
  config.picoCTF = false

if not config.unittest and  not config.isProduction
  # change artificially slow down non-static requests for testing
  config.slow_down = false

config.buildInfo = { sha: 'dev' }

if fs.existsSync path.join(process.env.PWD or __dirname, '.build_info.json')
  config.buildInfo = JSON.parse fs.readFileSync path.join(process.env.PWD or __dirname, '.build_info.json'), 'utf8'

# This logs a stack trace every time an endpoint sends a response or throws an error.
# It's great for finding where a mystery endpoint is!
config.TRACE_ROUTES = process.env.TRACE_ROUTES?

# Enables server-side gzip compression for network responses
# Only use this if testing network response sizes in development
# (In production, CloudFlare compresses things for us!)
config.forceCompression = process.env.COCO_FORCE_COMPRESSION?

module.exports = config
