var config = {};

config.unittest = process.argv.indexOf('--unittest') > -1;

config.port = process.env.COCO_PORT || process.env.COCO_NODE_PORT || 3000;
config.ssl_port = 
  process.env.COCO_SSL_PORT || process.env.COCO_SSL_NODE_PORT || 3443;

config.mongo = {};
config.mongo.port = process.env.COCO_MONGO_PORT || 27017;
config.mongo.host = process.env.COCO_MONGO_HOST || 'localhost';
config.mongo.db = process.env.COCO_MONGO_DATABASE_NAME || 'coco';

if(config.unittest) {
  config.port += 1;
  config.ssl_port += 1;
  config.mongo.host = 'localhost';
}

else {
  config.mongo.username = process.env.COCO_MONGO_USERNAME || '';
  config.mongo.password = process.env.COCO_MONGO_PASSWORD || '';
}

config.mail = {};
config.mail.service = process.env.COCO_MAIL_SERVICE_NAME || "Zoho";
config.mail.username = process.env.COCO_MAIL_SERVICE_USERNAME || "";
config.mail.password = process.env.COCO_MAIL_SERVICE_PASSWORD || "";
config.mail.mailchimpAPIKey = process.env.COCO_MAILCHIMP_API_KEY || '';
config.mail.sendwithusAPIKey = process.env.COCO_SENDWITHUS_API_KEY || '';

config.queue = {};
config.queue.accessKeyId = process.env.COCO_AWS_ACCESS_KEY_ID || '';
config.queue.secretAccessKey = process.env.COCO_AWS_SECRET_ACCESS_KEY || '';
config.queue.region = 'us-east-1';
config.queue.simulationQueueName = "simulationQueue";
config.mongoQueue = {};
config.mongoQueue.queueDatabaseName = "coco_queue";

config.salt = process.env.COCO_SALT || 'pepper';
config.cookie_secret = process.env.COCO_COOKIE_SECRET || 'chips ahoy';

config.isProduction = config.mongo.host != 'localhost';

if(!config.unittest && !config.isProduction) {
  // change artificially slow down non-static requests for testing
  config.slow_down = false; 
}

module.exports = config;
