'use strict';
// Find lifetime sub counts

if (process.argv.length !== 3) {
  log("Usage: node <script> <mongo connection Url analytics>");
  log("Include ?readPreference=secondary in connection URLs");
  process.exit();
}

const scriptStartTime = new Date();
const co = require('co');
const MongoClient = require('mongodb').MongoClient;
const mongoose = require('mongoose');
const mongoConnUrlAnalytics = process.argv[2];
const debugOutput = true;

const logEvents = ['Finished 1 year subscription purchase', 'Finish Lifetime Purchase'];

const startDay = "2017-06-28";
debug(`Start day ${startDay}`);

co(function*() {
  const analyticsDb = yield MongoClient.connect(mongoConnUrlAnalytics, {connectTimeoutMS: 1000 * 60 * 60, socketTimeoutMS: 1000 * 60 * 60});
  const startObjectId = objectIdWithTimestamp(new Date(`${startDay}T00:00:00.000Z`));
  debug(`Finding events..`);

  const eventServicePriceMap = {};
  const events = yield analyticsDb.collection('log').find({_id: {$gte: startObjectId}, event: {$in: logEvents}}).toArray();
  for (const event of events) {
    if (!event.properties) {
      console.error(event);
      break;
    }
    const eventName = event.event;
    const service = event.properties.service;
    const price = event.properties.value;
    if (!eventServicePriceMap[eventName]) eventServicePriceMap[eventName] = {};
    if (!eventServicePriceMap[eventName][service]) eventServicePriceMap[eventName][service] = {};
    if (!eventServicePriceMap[eventName][service][price]) eventServicePriceMap[eventName][service][price] = 0;
    eventServicePriceMap[eventName][service][price]++;
  }
  console.log(eventServicePriceMap);

  analyticsDb.close();
  debug(`Script runtime: ${new Date() - scriptStartTime}`);
})

// * Helper functions

function debug(msg) {
  if (debugOutput) console.log(`${new Date().toISOString()} ${msg}`);
}

function objectIdWithTimestamp(timestamp) {
  // Convert string date to Date object (otherwise assume timestamp is a date)
  if (typeof(timestamp) == 'string') timestamp = new Date(timestamp);
  // Convert date object to hex seconds since Unix epoch
  var hexSeconds = Math.floor(timestamp/1000).toString(16);
  // Create an ObjectId with that hex timestamp
  var constructedObjectId = mongoose.Types.ObjectId(hexSeconds + "0000000000000000");
  return constructedObjectId;
}
