'use strict';

// Find % of pilot classrooms with 30%+ students starting a project level within a given timeframe

// Two timespans:
// 1. A specific 14 days for a classroom to create it's first level session in CS2, GD1, WD1
// 2. Per classroom, 14 days from it's first level session for 30%+ students to start a project level

// Algorithm
// 1. Find initial classroom student activity for first levels in pilot content between 28 and 14 days back from target end date
// 2. Find course instances for newly active students
// 3. Find paid teachers for student course instances
// 4. Find classrooms for paid teachers with newly active students
// 5. Check each classroom for 30%+ students starting a project level within 14 days
// 6. Compute overall classroom average

// NOTE: this is super similar to trialClassAverageCompletion.js
// NOTE: update the endDay variable below to control the date range
// NOTE: assumes a couple unchanged course and campaign Ids

// TODO: use lodash

if (process.argv.length !== 4) {
  console.log("Usage: node <script> <mongo connection Url> <mongo connection Url level session>");
  console.log("Include ?readPreference=secondary in connection URLs");
  process.exit();
}

const scriptStartTime = new Date();
const co = require('co');
const MongoClient = require('mongodb').MongoClient;
const mongoose = require('mongoose');
const mongoConnUrl = process.argv[2];
const mongoConnUrlLevelSessions = process.argv[3];

const debugOutput = false;

const courseCampaignIds = [
  mongoose.Types.ObjectId('562f88e84df18473073c74e2'), // cs2
  mongoose.Types.ObjectId('5789236960deed1f00ec2ab8'), // gd1
  mongoose.Types.ObjectId('578913f2c8871ac2326fa3e4'), // wd1
  ];
const courseIds = [
  mongoose.Types.ObjectId('5632661322961295f9428638'), // cs2
  mongoose.Types.ObjectId('5789587aad86a6efb573701e'), // gd1
  mongoose.Types.ObjectId('5789587aad86a6efb573701f'), // wd1
];
const allowedLicenseTypes = ['course'];
const minimumClassroomMembers = 4;
const minimumClassroomMembersStartedProject = 0.3;

const daysToStartProgress = 14;
const daysToCompleteProgress = 14;

const endDay = "2017-02-01";

let startDay = new Date(`${endDay}T00:00:00.000Z`);
if (isNaN(startDay.getTime())) throw new Error(`Invalid endDay set ${endDay}`);
startDay.setUTCDate(startDay.getUTCDate() - daysToCompleteProgress);
const midpointDay = startDay.toISOString().substring(0, 10);
startDay.setUTCDate(startDay.getUTCDate() - daysToStartProgress);
startDay = startDay.toISOString().substring(0, 10);
const startObjectId = objectIdWithTimestamp(new Date(`${startDay}T00:00:00.000Z`));
const midpointObjectId = objectIdWithTimestamp(new Date(`${midpointDay}T00:00:00.000Z`));
debug(`Measuring days ${startDay} to ${midpointDay} to ${endDay}`);

co(function*() {
  const prodDb = yield MongoClient.connect(mongoConnUrl, {connectTimeoutMS: 1000 * 60 * 60, socketTimeoutMS: 1000 * 60 * 60});
  const lsDb = yield MongoClient.connect(mongoConnUrlLevelSessions, {connectTimeoutMS: 1000 * 60 * 60, socketTimeoutMS: 1000 * 60 * 60});

  console.log('Finding course campaign levels...');
  const campaigns = yield prodDb.collection('campaigns').find({_id: {$in: courseCampaignIds}}).toArray();
  const firstOriginalLevelIds = [];
  const originalLevelIds = [];
  for (const campaign of campaigns) {
    let haveFirstLevel = false;
    for (const originalId in campaign.levels) {
      if (!campaign.levels[originalId].practice) {
        originalLevelIds.push(originalId);
        if (!haveFirstLevel) {
          firstOriginalLevelIds.push(originalId);
          haveFirstLevel = true;
        }
      }
    }
  }
  debug(`Course levels ${originalLevelIds.length}`);

  // Find initial classroom student activity between start and midpoint times
  console.log(`Finding initial activity between ${startDay} and ${midpointDay}...`);
  const firstLevelSessions = yield lsDb.collection('level.sessions').find(
    {$and: [{_id: {$gte: startObjectId}}, {_id: {$lt: midpointObjectId}}, {'level.original': {$in: firstOriginalLevelIds}}, {isForClassroom: true}]},
    {created: 1, creator: 1}).toArray();
  debug(`firstLevelSessions ${firstLevelSessions.length}`);
  const studentObjectIds = [];
  for (const levelSession of firstLevelSessions) {
    studentObjectIds.push(mongoose.Types.ObjectId(levelSession.creator));
  }

  // Find course instances for newly active students
  console.log('Find course instances for newly active students...');
  const studentCourseInstances = yield prodDb.collection('course.instances').find(
    {members: {$in: studentObjectIds}, courseID: {$in: courseIds}, classroomID: {$exists: true}, hourOfCode: {$ne: true}},
    {ownerID: 1}).toArray();
  debug(`studentCourseInstances ${studentCourseInstances.length}`);

  // Find paid teachers for student course instances
  console.log('Find paid teachers for newly active student course instances...');
  const teacherObjectIds = [];
  for (const courseInstance of studentCourseInstances) {
    teacherObjectIds.push(courseInstance.ownerID)
  }
  const licenses = yield prodDb.collection('prepaids').find(
    {creator: {$in: teacherObjectIds}, type: {$in: allowedLicenseTypes}},
    {creator: 1}).toArray();
  debug(`licenses ${licenses.length}`);
  const paidTeacherObjectIds = [];
  for (const license of licenses) {
    paidTeacherObjectIds.push(license.creator);
  }
  debug(`Paid teachers ${paidTeacherObjectIds.length}`);

  // Now have paid teachers with students that created their first level session during start-mid timeframe
  // Need to restrict to paid teacher's course instances with first activity in start-mid timeframe

  console.log('Find classrooms for paid teachers that also have newly active students...');
  const classrooms = yield prodDb.collection('classrooms').find(
    {$and: [{ownerID: {$in: paidTeacherObjectIds}}, {members: {$in: studentObjectIds}}]},
    {courses: 1, members: 1, ownerID: 1}).toArray();
  console.log(`Found ${classrooms.length} classrooms, but many will be skipped for progress before ${startDay}, archived, etc.`);

  // Find per-classroom course completion averages
  let classroomsProjectsStarted = 0;
  let classroomCount = 0;
  let classroomCompletionsTotal = 0;
  for (let i = 0; i < classrooms.length; i++) {
    const classroom = classrooms[i];
    debug(`Processing classroom ${i + 1}/${classrooms.length} classroom=${classroom._id} teacher=${classroom.ownerID}...`);

    if (classroom.archived) {
      console.log(`ERROR: Skipping archived classroom ${classroom._id}`);
      continue;
    }
    if ((classroom.members || []).length < minimumClassroomMembers) {
      debug(`Skipping classroom ${classroom._id} with only ${(classroom.members || []).length} students.`);
      continue;
    }

    // Find classroom versioned cs1 course level sessions
    const studentIds = [];
    for (const memberObjectId of classroom.members) {
      studentIds.push(memberObjectId.toString());
    }
    debug(`studentIds ${studentIds.length}`);
    const levelOriginalIds = [];
    const projectLevelIdMap = {};
    for (const course of classroom.courses) {
      if (courseIds.find((id) => id.toString() === course._id.toString())) {
        for (const level of course.levels) {
          if (level.practice) continue;
          if (level.shareable === 'project') {
            projectLevelIdMap[level.original.toString()] = true;
          }
          levelOriginalIds.push(level.original.toString());
        }
      }
    }
    const levelSessions = yield lsDb.collection('level.sessions').find(
      {$and: [{creator: {$in: studentIds}}, {'level.original': {$in: levelOriginalIds}}]},
      {created: 1, creator: 1, 'level.original': 1}).toArray();
    debug(`levelSessions ${levelSessions.length}`);

    // Find first level session for classroom
    let firstLevelSession = null;
    for (const levelSession of levelSessions) {
      if (!firstLevelSession || levelSession.created < firstLevelSession.created) {
        firstLevelSession = levelSession;
      }
    }
    // debug(`classroom ${classroom._id} first progress on ${firstLevelSession ? firstLevelSession.created.toISOString() : 'n/a'}`);
    if (firstLevelSession && firstLevelSession.created < new Date(`${startDay}T00:00:00.000Z`)) {
      // Skip this classroom, progress before timeframe
      debug(`Skipping classroom ${classroom._id} with student ${firstLevelSession.creator} progress from ${firstLevelSession.created}`);
      continue;
    }
    if (!firstLevelSession || firstLevelSession.created > new Date(`${midpointDay}T00:00:00.000Z`)) {
      // Teacher's first course instance might not be the one with first activity in timeframe
      debug(`Skipping classroom ${classroom._id} with NO progress before ${midpointDay}`);
      continue;
    }

    classroomCount++;

    // Have a target classroom, find per-student completions
    const progressCutoff = new Date(firstLevelSession.created);
    progressCutoff.setUTCDate(progressCutoff.getUTCDate() + daysToCompleteProgress);
    const studentProjectCompletedMap = {};
    for (const levelSession of levelSessions) {
      const levelOriginalId = levelSession.level.original;
      if (!projectLevelIdMap[levelOriginalId]) continue;
      const studentId = levelSession.creator;
      if (levelSession.created < progressCutoff) {
        studentProjectCompletedMap[studentId] = true;
      }
    }
    const membersAnyProjectCompleted = Object.keys(studentProjectCompletedMap).length;
    if (membersAnyProjectCompleted / classroom.members.length >= minimumClassroomMembersStartedProject) {
      classroomsProjectsStarted++;
    }
    console.log(`Classroom ${i + 1}/${classrooms.length} c=${classroom._id} t=${classroom.ownerID}: ${membersAnyProjectCompleted} / ${classroom.members.length} = ${membersAnyProjectCompleted / classroom.members.length}`);
  }

  console.log(`For pilot content started between ${startDay} and ${midpointDay}, *any* project level started within ${daysToCompleteProgress} days`);
  console.log(`Of ${classroomCount} classrooms, ${classroomsProjectsStarted} had at least ${minimumClassroomMembersStartedProject * 100.0}% students that started a project level: ${classroomsProjectsStarted * 100.0 / classroomCount}%`);

  prodDb.close();
  lsDb.close();
  console.log(`Script runtime: ${new Date() - scriptStartTime}ms`);
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
