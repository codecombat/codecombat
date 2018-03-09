'use strict';

// Delete anonymous level sessions 90 days or older

if (process.argv.length !== 4) {
  log("Usage: node <script> <mongo connection Url> <mongo connection Url level session>");
  log("Include ?readPreference=secondary in connection URLs");
  process.exit();
}

const mongoConnUrlRead = process.argv[2];
const mongoConnUrlLevelSessionsWRITE = process.argv[3];

const scriptStartTime = new Date();
const co = require('co');
const mongoose = require('mongoose');
const MongoClient = require('mongodb').MongoClient;
const ObjectID = require('mongodb').ObjectID;
const Promise = require('bluebird');
const moment = require('moment');
const _ = require('lodash');

const debugOutput = true;

const dayRange = 10;

const startDate = new Date('2017-11-01'); // No data before this point due to previous anonymous clean up
const newestDate = new Date();
newestDate.setUTCDate(newestDate.getUTCDate() - 90);
debug(`Cutoff date for old anonymous users = ${newestDate.toISOString()}`);

co(function*() {
  const mainDb = yield MongoClient.connect(mongoConnUrlRead, {connectTimeoutMS: 1000 * 60 * 60, socketTimeoutMS: 1000 * 60 * 60});
  const lsDb = yield MongoClient.connect(mongoConnUrlLevelSessionsWRITE, {connectTimeoutMS: 1000 * 60 * 60, socketTimeoutMS: 1000 * 60 * 60});

  let totalUsers = 0;
  let totalLevelSessionsDeleted = 0;

  const currentDate = new Date(startDate);
  while (currentDate < newestDate) {
    let endDate = new Date(currentDate);
    endDate.setUTCDate(endDate.getUTCDate() + dayRange);
    if (endDate > newestDate) endDate = newestDate;
    debug(`*** Processing ${currentDate.toISOString().substring(0, 10)} to ${endDate.toISOString().substring(0, 10)} ***`);

    // Find anonymous users
    const query = {$and: [{anonymous: true}, {_id: {$gte: ObjectID(objectIdWithTimestamp(currentDate))}}, {_id: {$lt: ObjectID(objectIdWithTimestamp(endDate))}}]};
    const users = yield mainDb.collection('users').find(query, {'activity.login.last': 1, dateCreated: 1}).toArray();
    debug(`${users.length} old anonymous users found.`);
    // console.log(users);
    const allUserIdStrings = users.map((u) => u._id.toString());

    totalUsers += users.length;

    const userBatchSize = 10000;
    for (let i = 0; i * userBatchSize < allUserIdStrings.length; i++) {
      debug(`* User Batch ${i + 1} of ${Math.ceil(allUserIdStrings.length / userBatchSize)} for ${currentDate.toISOString().substring(0, 10)} to ${endDate.toISOString().substring(0, 10)} *`);
      const start = i * userBatchSize;
      const end = Math.min(i * userBatchSize + userBatchSize - 1, allUserIdStrings.length - 1);
      const userIdStrings = allUserIdStrings.slice(start, end);

      // Delete level sessions
      // const levelSessions = yield lsDb.collection('level.sessions').find({$and: [{creator: {$in: userIdStrings}}, {_id: {$gte: ObjectID(objectIdWithTimestamp(currentDate))}}, {_id: {$lt: ObjectID(objectIdWithTimestamp(endDate))}}]}, {_id: 1}).toArray();
      const response = yield lsDb.collection('level.sessions').remove({creator: {$in: userIdStrings}, _id: {$lt: ObjectID(objectIdWithTimestamp(newestDate))}});
      // debug(`${levelSessions.length} level sessions found.`);
      
      if (response.result.n > 0) {
        debug(`Deleted ${response.result.n}`);
      }

      totalLevelSessionsDeleted += response.result.n;

      // Don't hammer the databases constantly
      var waitTill = new Date(new Date().getTime() + 500);
      while(waitTill > new Date());
      // break;
    }

    // Don't hammer the databases constantly
    var waitTill = new Date(new Date().getTime() + 500);
    while(waitTill > new Date());

    currentDate.setUTCDate(currentDate.getUTCDate() + dayRange);
    // break;
  }

  console.log(`${totalUsers} anonymous users and ${totalLevelSessionsDeleted} level sessions deleted`);

  mainDb.close();
  lsDb.close();
  debug(`Script runtime: ${new Date() - scriptStartTime}ms`);
}).catch(function(e) {
  console.log('Error: ', e.stack)
  console.log(`Script runtime: ${new Date() - scriptStartTime}ms`);
  process.exit();
});

// * Helper functions

function objectIdWithTimestamp(timestamp) {
  // Convert string date to Date object (otherwise assume timestamp is a date)
  if (typeof(timestamp) == 'string') timestamp = new Date(timestamp);
  // Convert date object to hex seconds since Unix epoch
  var hexSeconds = Math.floor(timestamp/1000).toString(16);
  // Create an ObjectId with that hex timestamp
  var constructedObjectId = mongoose.Types.ObjectId(hexSeconds + "0000000000000000");
  return constructedObjectId;
}

function debug(msg) {
  if (debugOutput) console.log(`${new Date().toISOString()} ${msg}`);
}

function getMedian(values) {
  if (values.length === 0) return -1;
  values.sort((a, b) => a - b);
  const lowMiddle = Math.floor((values.length - 1) / 2);
  const highMiddle = Math.ceil((values.length - 1) / 2);
  return (values[lowMiddle] + values[highMiddle]) / 2;
}
