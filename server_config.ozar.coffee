fs = require 'fs'
path = require 'path'
os = require 'os'
cluster = require 'cluster'

config = {}

config.clusterID = "#{os.hostname()}"
if cluster.worker?
 config.clusterID += "/#{cluster.worker.id}"

config.unittest = global.testing
config.proxy = process.env.COCO_PROXY

config.timeout = parseInt(process.env.COCO_TIMEOUT) or 60*1000

config.chinaDomain = "cn.codecombat.com;ccombat.cn;contributors.codecombat.com"
config.chinaInfra = process.env.COCO_CHINA_INFRASTRUCTURE or false

config.brazilDomain = "br.codecombat.com;contributors.codecombat.com"
config.port = process.env.COCO_PORT or process.env.COCO_NODE_PORT or process.env.PORT  or 3000
config.ssl_port = process.env.COCO_SSL_PORT or process.env.COCO_SSL_NODE_PORT or 3443
config.cloudflare =
  token: process.env.COCO_CLOUDFLARE_API_KEY or ''
  email: process.env.COCO_CLOUDFLARE_API_EMAIL or ''

config.github =
  client_id: process.env.COCO_GITHUB_CLIENT_ID or 'fd5c9d34eb171131bc87'
  client_secret: process.env.COCO_GITHUB_CLIENT_SECRET or '2555a86b83f850bc44a98c67c472adb2316a3f05'

config.mongo =
  port: process.env.COCO_MONGO_PORT or 27017
  host: process.env.COCO_MONGO_HOST or 'localhost'
  db: process.env.COCO_MONGO_DATABASE_NAME or 'coco'
  analytics_port: process.env.COCO_MONGO_ANALYTICS_PORT or 27017
  analytics_host: process.env.COCO_MONGO_ANALYTICS_HOST or 'localhost'
  analytics_db: process.env.COCO_MONGO_ANALYTICS_DATABASE_NAME or 'analytics'
  analytics_collection: process.env.COCO_MONGO_ANALYTICS_COLLECTION or 'analytics.log.event'
  mongoose_replica_string: process.env.COCO_MONGO_MONGOOSE_REPLICA_STRING or ''
  readpref: process.env.COCO_MONGO_READPREF or 'primary'

if process.env.COCO_MONGO_ANALYTICS_REPLICA_STRING?
  config.mongo.analytics_replica_string = process.env.COCO_MONGO_ANALYTICS_REPLICA_STRING
else
  config.mongo.analytics_replica_string = "mongodb://#{config.mongo.analytics_host}:#{config.mongo.analytics_port}/#{config.mongo.analytics_db}"

if process.env.COCO_MONGO_LS_REPLICA_STRING?
  config.mongo.level_session_replica_string = process.env.COCO_MONGO_LS_REPLICA_STRING

if process.env.COCO_MONGO_LS_AUX_REPLICA_STRING?
  config.mongo.level_session_aux_replica_string = process.env.COCO_MONGO_LS_AUX_REPLICA_STRING

config.sphinxServer = process.env.COCO_SPHINX_SERVER or ''

config.apple =
  verifyURL: process.env.COCO_APPLE_VERIFY_URL or 'https://sandbox.itunes.apple.com/verifyReceipt'

config.closeIO =
  apiKey: process.env.COCO_CLOSEIO_API_KEY or ''

config.google =
  recaptcha_secret_key: process.env.COCO_GOOGLE_RECAPTCHA_SECRET_KEY or ''

config.stripe =
  secretKey: process.env.COCO_STRIPE_SECRET_KEY or 'sk_test_MFnZHYD0ixBbiBuvTlLjl2da'

config.paypal =
  clientID: process.env.COCO_PAYPAL_CLIENT_ID or 'AcS4lYmr_NwK_TTWSJzOzTh01tVDceWDjB_N7df3vlvW4alTV_AF2rtmcaZDh0AmnTcOof9gKyLyHkm-'
  clientSecret: process.env.COCO_PAYPAL_CLIENT_SECRET or 'EEp-AscLo_-_59jMBgrPFWUaMrI_HJEY8Mf1ESD7OJ8DSIFbKtVe1btqP2SAZXR_llP_oosvJYFWEjUZ'

if config.unittest
  config.port += 1
  config.ssl_port += 1
  config.mongo.host = 'localhost'
else
  config.mongo.username = process.env.COCO_MONGO_USERNAME or ''
  config.mongo.password = process.env.COCO_MONGO_PASSWORD or ''

config.mail =
  username: process.env.COCO_MAIL_SERVICE_USERNAME or ''
  supportPrimary: process.env.COCO_MAIL_SUPPORT_PRIMARY or ''
  supportPremium: process.env.COCO_MAIL_SUPPORT_PREMIUM or ''
  supportSchools: process.env.COCO_MAIL_SUPPORT_SCHOOLS or ''
  mailChimpAPIKey: process.env.COCO_MAILCHIMP_API_KEY or ''
  mailChimpWebhook: process.env.COCO_MAILCHIMP_WEBHOOK or '/mail/webhook'
  sendgridAPIKey: process.env.COCO_SENDGRID_API_KEY or ''
  delightedAPIKey: process.env.COCO_DELIGHTED_API_KEY or ''
  cronHandlerPublicIP: process.env.COCO_CRON_PUBLIC_IP or ''
  cronHandlerPrivateIP: process.env.COCO_CRON_PRIVATE_IP or ''

config.hipchat =
  main: process.env.COCO_HIPCHAT_API_KEY or ''
  tower: process.env.COCO_HIPCHAT_TOWER_API_KEY or ''
  artisans: process.env.COCO_HIPCHAT_ARTISANS_API_KEY or ''

config.slackToken = process.env.COCO_SLACK_TOKEN or ''

config.clever =
    client_id: process.env.COCO_CLEVER_CLIENTID
    client_secret: process.env.COCO_CLEVER_SECRET
    redirect_uri: process.env.COCO_CLEVER_REDIRECT_URI

config.queue =
  accessKeyId: process.env.COCO_AWS_ACCESS_KEY_ID or ''
  secretAccessKey: process.env.COCO_AWS_SECRET_ACCESS_KEY or ''
  region: 'us-east-1'
  simulationQueueName: 'simulationQueue'

config.mongoQueue =
  queueDatabaseName: 'coco_queue'

config.salt = process.env.COCO_SALT or 'pepper'
config.cookie_secret = process.env.COCO_COOKIE_SECRET or 'chips ahoy'

config.isProduction = config.mongo.host isnt 'localhost'

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

if process.env.COCO_STATSD_HOST
  config.statsd =
    host: process.env.COCO_STATSD_HOST
    port: process.env.COCO_STATSD_PORT or 8125
    prefix: process.env.COCO_STATSD_PREFIX or ''

config.snowplow =
  user: process.env.COCO_SNOWPLOW_USER or 'user'
  database: process.env.COCO_SNOWPLOW_DATABASE or 'database'
  password: process.env.COCO_SNOWPLOW_PASSWORD or 'password'
  host: process.env.COCO_SNOWPLOW_HOST or 'host'
  port: process.env.COCO_SNOWPLOW_PORT or 1

config.buildInfo = { sha: 'dev' }

config.intercom =
  accessToken: process.env.COCO_INTERCOM_ACCESS_TOKEN or 'dGVzdA==' #base64 "test"
  webhookHubSecret: process.env.COCO_INTERCOM_WEBHOOK_HUB_SECRET or 'abcd'

config.bitly =
  accessToken: process.env.COCO_BITLY_ACCESS_TOKEN or ''

config.zenProspect =
  apiKey: process.env.COCO_ZENPROSPECT_API_KEY or ''

config.apcspFileUrl = process.env.COCO_APCSP_FILE_URL or "http://localhost:#{config.port}/apcsp-local/"

if fs.existsSync path.join(__dirname, '.build_info.json')
  config.buildInfo = JSON.parse fs.readFileSync path.join(__dirname, '.build_info.json'), 'utf8'

# This logs a stack trace every time an endpoint sends a response or throws an error.
# It's great for finding where a mystery endpoint is!
config.TRACE_ROUTES = process.env.TRACE_ROUTES?

# Enables server-side gzip compression for network responses
# Only use this if testing network response sizes in development
# (In production, CloudFlare compresses things for us!)
config.forceCompression = process.env.COCO_FORCE_COMPRESSION?

module.exports = config
