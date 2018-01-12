'use strict';
// Find conversion rate between viewing the teacher sign up form and creating a class

// Rough algorithm
// 1. Find all users that saw teacher form between 7 and 14 days ago
// 2. Find subset of those users that also created a class in last 14 days

// NOTE: update the endDay variable below to control the date range
// NOTE: assumes events happened in correct order, and can't be skipped somehow

// TODO: users that saw teacher form earlier in date range have more time to create a class

if (process.argv.length !== 4) {
  console.log("Usage: node <script> <mongo connection Url analytics> <mongo connection Url>");
  console.log("Include ?readPreference=secondary in connection URLs");
  process.exit();
}

const scriptStartTime = new Date();
const co = require('co');
const MongoClient = require('mongodb').MongoClient;
const mongoose = require('mongoose');
const mongoConnUrlAnalytics = process.argv[2];
const mongoConnUrl = process.argv[3];

const debugOutput = true;
const daysToViewForm = 7;
const daysToCreateClass = 7;
const endDay = "2017-10-01";

let startDay = new Date(`${endDay}T00:00:00.000Z`);
startDay.setUTCDate(startDay.getUTCDate() - daysToViewForm - daysToCreateClass);
startDay = startDay.toISOString().substring(0, 10);
debug(`Measuring days ${startDay} to ${endDay}`);

const startEventValues = ['Teachers Request Demo Loaded', 'Teachers Create Account Loaded', 'Teachers Convert Account Loaded', 'Homepage Click Teacher Button CTA'];

// TODO: demo request path has different steps and events than standard teacher account creation

const remainingOrderedEventValues = [
  // 'CreateAccountModal Teacher BasicInfoView Submit Clicked',
  // 'CreateAccountModal Teacher BasicInfoView Submit Success',
  // 'CreateAccountModal Teacher SchoolInfoPanel Continue Clicked',
  // 'CreateAccountModal Teacher SchoolInfoPanel Continue Success',
  // 'CreateAccountModal Teacher TeacherRolePanel Continue Clicked',
  // 'CreateAccountModal Teacher TeacherRolePanel Continue Success',
  'Teachers Classes Loaded',
  // 'Teachers Classes Create New Class Started',
  // 'Teachers Classes Create New Class Finished'
];

co(function*() {
  const analyticsDb = yield MongoClient.connect(mongoConnUrlAnalytics, {connectTimeoutMS: 1000 * 60 * 60, socketTimeoutMS: 1000 * 60 * 60});
  const prodDb = yield MongoClient.connect(mongoConnUrl, {connectTimeoutMS: 1000 * 60 * 60, socketTimeoutMS: 1000 * 60 * 60});
  debug(`Connected to databases`);

  const startObjectId = objectIdWithTimestamp(new Date(`${startDay}T00:00:00.000Z`));
  const formEndDate = new Date(`${endDay}T00:00:00.000Z`);
  formEndDate.setUTCDate(formEndDate.getUTCDate() - daysToCreateClass);
  const midObjectId = objectIdWithTimestamp(formEndDate);
  debug(`Finding view teacher form events between ${startDay} and ${formEndDate.toISOString().substring(0, 10)}...`);

  let query = {$and: [{_id: {$gte: startObjectId}}, {_id: {$lt: midObjectId}}, {event: {$in: startEventValues}}]};
  const startEvents = yield analyticsDb.collection('log').find(query, {user: 1}).toArray();
  debug(`Teacher form events found ${startEvents.length}`);
  const userFormMap = {};
  for (const event of startEvents) {
    userFormMap[event.user] = event._id.getTimestamp();
  }
  const userIds = Object.keys(userFormMap);
  debug(`Unique users ${userIds.length}`);

  debug(`Finding rest of create class funnel events between ${startDay} and ${endDay}...`);
  const endObjectId = objectIdWithTimestamp(new Date(`${endDay}T00:00:00.000Z`));

  query = {$and: [{_id: {$gte: startObjectId}}, {_id: {$lt: endObjectId}}, {event: {$in: remainingOrderedEventValues}}, {user: {$in: userIds}}]};
  const classEvents = yield analyticsDb.collection('log').find(query, {event: 1, user: 1}).toArray();
  debug(`Class created events found ${classEvents.length}`);
  const userFunnelEventsMap = {};
  for (const event of classEvents) {
    const progressCutoff = new Date(userFormMap[event.user]);
    progressCutoff.setUTCDate(progressCutoff.getUTCDate() + daysToCreateClass);
    if (progressCutoff < event._id.getTimestamp()) {
      // Skip events outside of timeframe to create class
      continue;
    }
    if (!userFunnelEventsMap[event.event]) userFunnelEventsMap[event.event] = {};
    userFunnelEventsMap[event.event][event.user] = true;
  }

  const usersSawTeacherForm = userIds.length;
  let teachersCreatedClass = 0;
  debug(`Looking at events from ${startDay} to ${endDay}:`);
  console.log(`100% ${usersSawTeacherForm} users saw teacher form`);
  for (const event of remainingOrderedEventValues) {
    const currentEventCount = Object.keys(userFunnelEventsMap[event] || {}).length;
    console.log(`${(currentEventCount * 100.0 / usersSawTeacherForm).toFixed(2)}% ${currentEventCount} users saw event ${event}`);
    if (event === remainingOrderedEventValues[remainingOrderedEventValues.length - 1]) {
      teachersCreatedClass = currentEventCount;
    }
  }
  // console.log(`Saw teacher signup form= ${usersSawTeacherForm} Created class= ${teachersCreatedClass} Conversion= ${teachersCreatedClass / usersSawTeacherForm} ${teachersCreatedClass * 100.0 / usersSawTeacherForm}%`);
  console.log(`Saw teacher signup form= ${usersSawTeacherForm} Created account= ${teachersCreatedClass} Conversion= ${teachersCreatedClass / usersSawTeacherForm} ${teachersCreatedClass * 100.0 / usersSawTeacherForm}%`);

  // Find percentage of teachers that have students
  const userObjectIds = userIds.map((stringId) => mongoose.Types.ObjectId(stringId));
  const classrooms = yield prodDb.collection('classrooms').find({ownerID: {$in: userObjectIds}, $where: 'this.members.length > 0'}, {ownerID: 1, member: 1}).toArray();
  // debug(`${classrooms.length} classrooms`);
  const teachersWithStudents = classrooms.reduce((s, c) => {
    s.add(c.ownerID.toString());
    return s;
  }, new Set());
  console.log(`${teachersWithStudents.size} teachers have students, ${Math.round(teachersWithStudents.size / teachersCreatedClass * 100)}% of those that finished account creation.`);

  prodDb.close();
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
