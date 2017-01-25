'use strict';
// Find conversion rate between viewing the teacher sign up form and creating a class

// Rough algorithm
// 1. Find all users that saw teacher form between 7 and 30 days ago
// 2. Find subset of those users that also created a class in last 30 days

// NOTE: update the endDay variable below to control the date range

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
const daysToViewForm = 7;
const daysToCreateClass = 4;
const endDay = "2017-01-13";
let startDay = new Date(`${endDay}T00:00:00.000Z`);
startDay.setUTCDate(startDay.getUTCDate() - daysToViewForm - daysToCreateClass);
startDay = startDay.toISOString().substring(0, 10);
debug(`Measuring days ${startDay} to ${endDay}`);

const teacherFormEvents = ['Teachers Request Demo Loaded', 'Teachers Create Account Loaded', 'Teachers Convert Account Loaded'];
const classCreatedEvent = 'Teachers Classes Create New Class Finished';

co(function*() {
  const analyticsDb = yield MongoClient.connect(mongoConnUrlAnalytics, {connectTimeoutMS: 1000 * 60 * 60, socketTimeoutMS: 1000 * 60 * 60});

  const startObjectId = objectIdWithTimestamp(new Date(`${startDay}T00:00:00.000Z`));
  const formEndDate = new Date(`${endDay}T00:00:00.000Z`);
  formEndDate.setUTCDate(formEndDate.getUTCDate() - daysToCreateClass);
  let endObjectId = objectIdWithTimestamp(formEndDate);
  debug(`Finding view teacher form events between ${startDay} and ${formEndDate.toISOString().substring(0, 10)}..`);

  let query = {$and: [{_id: {$gte: startObjectId}}, {_id: {$lt: endObjectId}}, {event: {$in: teacherFormEvents}}]};
  const formEvents = yield analyticsDb.collection('log').find(query, {user: 1}).toArray();
  debug(`Teacher form events found ${formEvents.length}`);
  const userFormMap = {};
  for (const event of formEvents) {
    userFormMap[event.user] = true;
  }
  const userIds = Object.keys(userFormMap);
  debug(`Unique users ${userIds.length}`);

  debug(`Finding created class events between ${startDay} and ${endDay}..`);
  endObjectId = objectIdWithTimestamp(new Date(`${endDay}T00:00:00.000Z`));
  query = {$and: [{_id: {$gte: startObjectId}}, {_id: {$lt: endObjectId}}, {event: classCreatedEvent}, {user: {$in: userIds}}]};
  const classEvents = yield analyticsDb.collection('log').find(query, {user: 1}).toArray();
  debug(`Class created events found ${classEvents.length}`);
  const userClassMap = {};
  for (const event of classEvents) {
    userClassMap[event.user] = true;
  }

  const usersSawTeacherForm = userIds.length;
  let teachersCreatedClass = 0;
  for (const userId in userFormMap) {
    if (userClassMap[userId]) {
      teachersCreatedClass++;
    }
  }
  console.log(`Looking at data from ${startDay} to ${endDay}:`);
  console.log(`Saw teacher signup form= ${usersSawTeacherForm} Created class= ${teachersCreatedClass} Conversion= ${(teachersCreatedClass / usersSawTeacherForm).toFixed(4)}`);

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
