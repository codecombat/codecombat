'use strict';
// Find return rate for individual players

// Rough algorithm
// 1. Given an end date, find events in previous 11 days and non-teacher/student users created in previous 11-4 days
// 2. Find subset of users with events greater than 4 hours apart

// NOTE: update the endDay variable below to control the date range

// TODO: could include /play or campaign view events too for home players

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

const minHoursForReturn = 4;
const daysToVisit = 7;
const daysToReturn = 4;
const endDay = "2017-01-27";

if(new Date(`${endDay}T00:00:00.000Z`) > new Date()) {
  console.log('\n* * * ERROR: Latest date is in the future! * * *')
  process.exit()
}
let startDay = new Date(`${endDay}T00:00:00.000Z`);
startDay.setUTCDate(startDay.getUTCDate() - daysToVisit - daysToReturn);
startDay = startDay.toISOString().substring(0, 10);
debug(`Measuring days ${startDay} to ${endDay}`);

co(function*() {
  const analyticsDb = yield MongoClient.connect(mongoConnUrlAnalytics, {connectTimeoutMS: 1000 * 60 * 60, socketTimeoutMS: 1000 * 60 * 60});

  const startObjectId = objectIdWithTimestamp(new Date(`${startDay}T00:00:00.000Z`));
  const firstVisitEndDate = new Date(`${endDay}T00:00:00.000Z`);
  firstVisitEndDate.setUTCDate(firstVisitEndDate.getUTCDate() - daysToReturn);
  let middleObjectId = objectIdWithTimestamp(firstVisitEndDate);
  let endObjectId = objectIdWithTimestamp(new Date(`${endDay}T00:00:00.000Z`));

  const users = yield analyticsDb.collection('log').aggregate([
    {$match: {$and: [
        {_id: {$gte: startObjectId}},
        {_id: {$lt: endObjectId}},
        {user: {$gte: startObjectId.valueOf() + ''}},
        {user: {$lt: middleObjectId.valueOf() + ''}},
        {event: {$in: ['Identify', 'Started Level']}}
      ]}},
    {$group: {_id: '$user', max: {$max: '$_id'}, min: {$min: '$_id'}, role: {$max: '$properties.traits.role'}}},
    {$match: {role: {$nin: ['student', 'teacher', 'technology coordinator', 'advisor', 'principal', 'superintendent', 'parent']}}},
    ]).toArray();

  // Find # of users with min/max distance > minHoursForReturn hours
  let returnees = 0;
  for (const user of users) {
    if (new mongoose.Types.ObjectId(user.max).getTimestamp() - new mongoose.Types.ObjectId(user.min).getTimestamp() > 1000 * 60 * 60 * minHoursForReturn) {
      returnees++;
    }
  }
  console.log(`Total visitors= ${users.length} returning visitors= ${returnees}`);
  console.log(`${returnees * 100.0 / users.length}% ${returnees / users.length}`);

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
