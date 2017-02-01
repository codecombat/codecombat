'use strict';

// Find average classroom completion rate for first week of cs1 activity

// Two timespans:
// 1. A specific 7 days for a classroom to create it's first level session in and be included
// 2. Per classroom, 7 days from it's first level session for students to complete levels

// Algorithm
// 1. Find initial classroom student activity for first cs1 level between 14 and 7 days back from target end date
// 2. Find course instances for newly active students
// 3. Find free teachers for student course instances
// 4. Find first non-empty cs1 course instances for teachers
// 5. Find per-classroom cs1 course completion averages
// 6. Compute overall average

// NOTE: update the endDay variable below to control the date range
// NOTE: assumes a couple unchanged course and first level Ids

// TODO: use lodash
// TODO: better handling of archived classrooms
// TODO: corner cases around classroom membership changes not reflected in course instances

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

const cs1CampaignId = '55b29efd1cd6abe8ce07db0d';
const cs1CourseId = '560f1a9f22961295f9427742';

const daysToFirstLevelSession = 7;
const daysToCompleteCs1 = 7;

const endDay = "2017-02-01";

let startDay = new Date(`${endDay}T00:00:00.000Z`);
if (isNaN(startDay.getTime())) throw new Error(`Invalid endDay set ${endDay}`);
startDay.setUTCDate(startDay.getUTCDate() - daysToCompleteCs1);
const midpointDay = startDay.toISOString().substring(0, 10);
startDay.setUTCDate(startDay.getUTCDate() - daysToFirstLevelSession);
startDay = startDay.toISOString().substring(0, 10);
const startObjectId = objectIdWithTimestamp(new Date(`${startDay}T00:00:00.000Z`));
const midpointObjectId = objectIdWithTimestamp(new Date(`${midpointDay}T00:00:00.000Z`));
console.log(`Measuring days ${startDay} to ${midpointDay} to ${endDay}`);

co(function*() {
  const prodDb = yield MongoClient.connect(mongoConnUrl, {connectTimeoutMS: 1000 * 60 * 60, socketTimeoutMS: 1000 * 60 * 60});
  const lsDb = yield MongoClient.connect(mongoConnUrlLevelSessions, {connectTimeoutMS: 1000 * 60 * 60, socketTimeoutMS: 1000 * 60 * 60});

  console.log('Find cs1 course campaign levels..');
  const cs1Campaign = yield prodDb.collection('campaigns').findOne({_id: mongoose.Types.ObjectId(cs1CampaignId)});
  const cs1OriginalLevelIds = [];
  for (const originalId in cs1Campaign.levels) {
    if (!cs1Campaign.levels[originalId].practice) {
      cs1OriginalLevelIds.push(originalId);
    }
  }
  debug(`cs1 levels ${cs1OriginalLevelIds.length}`);

  // Find initial classroom student activity for first cs1 level between start and midpoint times
  console.log(`Finding initial activity between ${startDay} and ${midpointDay}..`);
  const firstLevelSessions = yield lsDb.collection('level.sessions').find(
    {$and: [{_id: {$gte: startObjectId}}, {_id: {$lt: midpointObjectId}}, {'level.original': cs1OriginalLevelIds[0]}, {isForClassroom: true}]},
    {created: 1, creator: 1}).toArray();
  debug(`firstLevelSessions ${firstLevelSessions.length}`);
  const studentObjectIds = [];
  for (const levelSession of firstLevelSessions) {
    studentObjectIds.push(mongoose.Types.ObjectId(levelSession.creator));
  }

  // Find course instances for newly active students
  console.log('Find course instances for newly active students..');
  const studentCourseInstances = yield prodDb.collection('course.instances').find(
    {members: {$in: studentObjectIds}, courseID: mongoose.Types.ObjectId(cs1CourseId), classroomID: {$exists: true}, hourOfCode: {$ne: true}},
    {ownerID: 1}).toArray();
  debug(`studentCourseInstances ${studentCourseInstances.length}`);

  // Find free teachers for student course instances
  console.log('Find free teachers for newly active student course instances..');
  const teacherObjectIds = [];
  for (const courseInstance of studentCourseInstances) {
    teacherObjectIds.push(courseInstance.ownerID)
  }
  const licenses = yield prodDb.collection('prepaids').find(
    {creator: {$in: teacherObjectIds}, type: {$in: ['course', 'starter_license']}},
    {creator: 1}).toArray();
  // debug(`licenses ${licenses.length}`);
  const teacherLicenseMap = {};
  for (const license of licenses) {
    teacherLicenseMap[license.creator.toHexString()] = true;
  }
  const freeTeacherObjectIds = [];
  for (const id of teacherObjectIds) {
    if (!teacherLicenseMap[id.toHexString()]) {
      freeTeacherObjectIds.push(id);
    }
  }
  debug(`Free teachers ${freeTeacherObjectIds.length}`);

  // Now have free teachers with students that created their first level session during start-mid timeframe
  // Need to restrict to teacher's first cs1 course instance with first activity in start-mid timeframe

  // Find first non-empty cs1 course instances for teachers
  console.log('Find first cs1 course instances for free teachers that also have newly active students..');
  const courseInstanceFirsts = yield prodDb.collection('course.instances').aggregate([
    {$match: {$and: [{ownerID: {$in: freeTeacherObjectIds}}, {courseID: mongoose.Types.ObjectId(cs1CourseId)}, {members: {$exists: true, $ne: []}}]}},
    {$group: {_id: '$ownerID', first: {$first: '$_id'}}}
    ]).toArray();
  debug(`courseInstanceFirsts ${courseInstanceFirsts.length}`);
  const firstCourseInstances = yield prodDb.collection('course.instances').find(
    {_id: {$in: courseInstanceFirsts.map((ci) => ci.first)}, hourOfCode: {$ne: true}}).toArray();
  debug(`firstCourseInstances ${firstCourseInstances.length}`);

  // Find per-classroom cs1 course completion averages
  let classroomCount = 0;
  let classroomCompletionsTotal = 0;
  for (let i = 0; i < firstCourseInstances.length; i++) {
    const courseInstance = firstCourseInstances[i];
    debug(`Processing classroom ${i + 1}/${firstCourseInstances.length} ${courseInstance.classroomID}..`);

    // Find classroom for this course instance and do some sanity checking
    const classroom = yield prodDb.collection('classrooms').findOne(
      {_id: courseInstance.classroomID}, {courses: 1, members: 1, ownerID: 1});
    if (!classroom) {
      console.log(`ERROR: could not find classroom ${courseInstance.classroomID} from course instance ${courseInstance._id}`);
      continue;
    }
    if (classroom.archived) {
      debug(`Skipping archived classroom ${classroom._id}`);
      continue;
    }
    if ((classroom.members || []).length <= 0) {
      debug(`Skipping empty classroom ${classroom._id}`);
      continue;
    }
    debug(`classroom ${classroom._id} teacher ${classroom.ownerID}`);

    // Find classroom versioned cs1 course level sessions
    const studentIds = [];
    for (const memberId of courseInstance.members) {
      studentIds.push(memberId.toString());
    }
    debug(`studentIds ${studentIds.length}`);
    const levelOriginalIds = [];
    for (const course of classroom.courses) {
      if (course._id.toString() === cs1CourseId) {
        for (const level of course.levels) {
          if (level.practice) continue;
          levelOriginalIds.push(level.original.toString());
        }
        break;
      }
    }
    const levelSessions = yield lsDb.collection('level.sessions').find(
      {$and: [{creator: {$in: studentIds}}, {'level.original': {$in: levelOriginalIds}}]},
      {created: 1, creator: 1, dateFirstCompleted: 1, 'level.original': 1}).toArray();
    debug(`levelSessions ${levelSessions.length}`);

    // Find first level session for classroom
    let firstLevelSession = null;
    for (const levelSession of levelSessions) {
      if (!firstLevelSession || levelSession.created < firstLevelSession.created) {
        firstLevelSession = levelSession;
      }
    }
    // debug(`classroom ${courseInstance.classroomID} first progress on ${firstLevelSession ? firstLevelSession.created.toISOString() : 'n/a'}`);
    if (firstLevelSession && firstLevelSession.created < new Date(`${startDay}T00:00:00.000Z`)) {
      // Skip this classroom, progress before timeframe
      debug(`Skipping classroom ${courseInstance.classroomID} with student ${firstLevelSession.creator} progress from ${firstLevelSession.created}`);
      continue;
    }
    if (!firstLevelSession || firstLevelSession.created > new Date(`${midpointDay}T00:00:00.000Z`)) {
      // Teacher's first course instance might not be the one with first activity in timeframe
      debug(`Skipping classroom ${courseInstance.classroomID} with NO progress before ${midpointDay}`);
      continue;
    }

    classroomCount++;

    // Have a target classroom, find per-student completions
    const progressCutoff = new Date(firstLevelSession.created);
    progressCutoff.setUTCDate(progressCutoff.getUTCDate() + daysToCompleteCs1);
    const studentLevelCompletedMap = {};
    for (const levelSession of levelSessions) {
      // console.log(`student ${levelSession.creator} level ${levelSession.level.original} created ${levelSession.created} completed ${levelSession.dateFirstCompleted}`);
      if (!levelSession.dateFirstCompleted) continue;
      const studentId = levelSession.creator;
      const levelOriginalId = levelSession.level.original;
      if (levelSession.dateFirstCompleted < progressCutoff) {
        if (!studentLevelCompletedMap[studentId]) studentLevelCompletedMap[studentId] = {};
        studentLevelCompletedMap[studentId][levelOriginalId] = true;
      }
    }
    let memberCompletionsTotal = 0;
    for (const memberObjectId of courseInstance.members) {
      const studentId = memberObjectId.toString();
      const studentCompleted = studentLevelCompletedMap[studentId] ? Object.keys(studentLevelCompletedMap[studentId]).length : 0;
      memberCompletionsTotal += studentCompleted / levelOriginalIds.length;
      debug(`Student ${studentId} completion: ${studentCompleted} / ${levelOriginalIds.length} = ${studentCompleted / levelOriginalIds.length}`);
    }
    classroomCompletionsTotal += memberCompletionsTotal / classroom.members.length;
    console.log(`Classroom ${i + 1}/${firstCourseInstances.length} ${classroom._id} completion: ${memberCompletionsTotal} / ${classroom.members.length} = ${memberCompletionsTotal / classroom.members.length}`);
    if (!Number.isFinite(classroomCompletionsTotal)) {
      console.log(`ERROR! classroomCompletionsTotal=${classroomCompletionsTotal}`)
      break;
    }
  }

  console.log(`For days ${startDay} to ${midpointDay} to ${endDay}`);
  console.log(`Overall classroom average completion: ${classroomCompletionsTotal} / ${classroomCount} = ${classroomCompletionsTotal / classroomCount} ${classroomCompletionsTotal * 100.0 / classroomCount}%`);

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
