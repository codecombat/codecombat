config = {}

config.unittest = global.testing
config.proxy = process.env.COCO_PROXY

config.chinaDomain = "cn.codecombat.com"
config.brazilDomain = "br.codecombat.com"
config.port = process.env.COCO_PORT or process.env.COCO_NODE_PORT or process.env.PORT  or 3000
config.ssl_port = process.env.COCO_SSL_PORT or process.env.COCO_SSL_NODE_PORT or 3443
config.cloudflare =
  token: process.env.COCO_CLOUDFLARE_API_KEY or ''

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
  mongoose_tokyo_replica_string: process.env.COCO_MONGO_MONGOOSE_TOKYO_REPLICA_STRING or ''
  mongoose_saoPaulo_replica_string : process.env.COCO_MONGO_MONGOOSE_SAOPAULO_REPLICA_STRING or ''



if config.tokyo or config.saoPaulo
  config.mongo.readpref = 'nearest'
else
  config.mongo.readpref = 'primary'

config.apple =
  verifyURL: process.env.COCO_APPLE_VERIFY_URL or 'https://sandbox.itunes.apple.com/verifyReceipt'

config.closeIO =
  apiKey: process.env.COCO_CLOSEIO_API_KEY or ''

config.stripe =
  secretKey: process.env.COCO_STRIPE_SECRET_KEY or 'sk_test_MFnZHYD0ixBbiBuvTlLjl2da'

config.redis =
  port: process.env.COCO_REDIS_PORT or 6379
  host: process.env.COCO_REDIS_HOST or 'localhost'

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
  mailchimpAPIKey: process.env.COCO_MAILCHIMP_API_KEY or ''
  mailchimpWebhook: process.env.COCO_MAILCHIMP_WEBHOOK or '/mail/webhook'
  sendwithusAPIKey: process.env.COCO_SENDWITHUS_API_KEY or ''
  stackleadAPIKey: process.env.COCO_STACKLEAD_API_KEY or ''
  delightedAPIKey: process.env.COCO_DELIGHTED_API_KEY or ''
  cronHandlerPublicIP: process.env.COCO_CRON_PUBLIC_IP or ''
  cronHandlerPrivateIP: process.env.COCO_CRON_PRIVATE_IP or ''

config.hipchat =
  main: process.env.COCO_HIPCHAT_API_KEY or ''
  tower: process.env.COCO_HIPCHAT_TOWER_API_KEY or ''
  artisans: process.env.COCO_HIPCHAT_ARTISANS_API_KEY or ''

config.slackToken = process.env.COCO_SLACK_TOKEN or ''

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

module.exports = config
