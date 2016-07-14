/* global db */
/* global Mongo */
/* global ISODate */
// Insert per-day active class counts into analytics.perdays collection

// Usage:
// mongo <address>:<port>/<database> <script file> -u <username> -p <password>

// TODO: Does not handle course prepaid updates on a user
// TODO: Does not handle class membership changes

// TODO: Investigate abrupt trial drop off at 4/1/16.  Showed up when fixing coursePrepaid.

var analyticsDB = new Mongo("localhost").getDB("analytics")
var scriptStartTime = new Date();
var analyticsStringCache = {};

var minClassSize = 12;
var minActiveCount = 6;

var eventNamePaid = 'Active classes paid';
var eventNameTrial = 'Active classes trial';
var eventNameFree = 'Active classes free';

var numDays = 40;
var daysInMonth = 30;

var startDay = new Date();
var today = startDay.toISOString().substr(0, 10);
startDay.setUTCDate(startDay.getUTCDate() - numDays);
startDay = startDay.toISOString().substr(0, 10);

log("Today is " + today);
log("Start day is " + startDay);

log("Getting active class counts..");
var activeClassCounts = getActiveClassCounts(startDay);
// printjson(activeClassCounts);
// log("Inserting active class counts..");
for (var event in activeClassCounts) {
  for (var day in activeClassCounts[event]) {
    if (today === day) continue; // Never save data for today because it's incomplete
    // print(event, day, activeClassCounts[event][day]);
    insertEventCount(event, day, activeClassCounts[event][day]);
  }
}

log("Script runtime: " + (new Date() - scriptStartTime));

function getActiveClassCounts(startDay) {
  // Tally active classes per day, for paid, trial, and free

  if (!startDay) return {};

  var cursor, doc;

  // Classrooms
  // paid: at least one paid member
  // trial: not paid, at least one trial member
  // free: not paid, not free trial
  // user.coursePrepaidID or user.coursePrepaid set means access to paid courses
  // prepaid.properties.trialRequestID means access was via trial

  // Find classroom users
  log("Finding classrooms..");
  var userClassroomsMap = {};
  var classroomUsersMap = {};
  var classroomUserIDs = [];
  var classroomUserObjectIds = [];
  cursor = db.classrooms.find({}, {members: 1});
  while (cursor.hasNext()) {
    doc = cursor.next();
    if (doc.members) {
      var classroomID = doc._id.valueOf();
      for (var i = 0; i < doc.members.length; i++) {
        if (doc.members.length < minClassSize) continue;
        var userID = doc.members[i].valueOf();
        if (!userClassroomsMap[userID]) userClassroomsMap[userID] = [];
        userClassroomsMap[userID].push(classroomID);
        if (!classroomUsersMap[classroomID]) classroomUsersMap[classroomID] = [];
        classroomUsersMap[classroomID].push(userID)
        classroomUserIDs.push(doc.members[i].valueOf());
        classroomUserObjectIds.push(doc.members[i]);
      }
    }
  }
  // log("DEBUG: Classroom users: " + classroomUserIDs.length);

  log("Find user types..");
  var userEventEndDateMap = {};
  var prepaidUsersMap = {};
  var prepaidIDs = [];
  cursor = db.users.find({_id: {$in: classroomUserObjectIds}}, {coursePrepaid: 1, coursePrepaidID: 1});
  while (cursor.hasNext()) {
    doc = cursor.next();
    userEventEndDateMap[doc._id.valueOf()] = {};
    userEventEndDateMap[doc._id.valueOf()][eventNameFree] = new Date();
    if (doc.coursePrepaid) {
      if (!doc.coursePrepaid.endDate) throw new Error("No endDate for new prepaid " + doc._id.valuOf());
      userEventEndDateMap[doc._id.valueOf()][eventNamePaid] = new Date(doc.coursePrepaid.endDate);
      if (!prepaidUsersMap[doc.coursePrepaid._id.valueOf()]) prepaidUsersMap[doc.coursePrepaid._id.valueOf()] = [];
      prepaidUsersMap[doc.coursePrepaid._id.valueOf()].push(doc._id.valueOf()); 
      prepaidIDs.push(doc.coursePrepaid._id);
    }
    if (doc.coursePrepaidID) {
      if (!userEventEndDateMap[doc._id.valueOf()][eventNamePaid]) {
        userEventEndDateMap[doc._id.valueOf()][eventNamePaid] = new Date();
      }
      if (!prepaidUsersMap[doc.coursePrepaidID.valueOf()]) prepaidUsersMap[doc.coursePrepaidID.valueOf()] = [];
      prepaidUsersMap[doc.coursePrepaidID.valueOf()].push(doc._id.valueOf()); 
      prepaidIDs.push(doc.coursePrepaidID);
    }
  }
  cursor = db.prepaids.find({_id: {$in: prepaidIDs}}, {endDate: 1, properties: 1});
  while (cursor.hasNext()) {
    doc = cursor.next();
    if (doc.properties && doc.properties.trialRequestID) {
      var endDate = new Date();
      if (doc.endDate) {
        endDate = new Date(doc.endDate);
      }
      else if (doc.properties.endDate) {
        endDate = new Date(doc.properties.endDate);
      }
      for (var i = 0; i < prepaidUsersMap[doc._id.valueOf()].length; i++) {
        userEventEndDateMap[prepaidUsersMap[doc._id.valueOf()][i]][eventNameTrial] = endDate;
      }
    }
  }

  log("Find Started Level log events for all classroom members for last " + (numDays + daysInMonth) + " days..");
  var userPlayedMap = {};
  var startDate = ISODate(startDay + "T00:00:00.000Z");
  startDate.setUTCDate(startDate.getUTCDate() - daysInMonth);
  var endDate = ISODate(startDay + "T00:00:00.000Z");
  var todayDate = new Date(new Date().toISOString().substring(0, 10));
  var startObj = objectIdWithTimestamp(startDate);
  // Batch size test times: 10k 427005, 5k 361361, 1k 799068, 2k 791521
  var batchSize = 5000;
  for (var j = 0; j < classroomUserIDs.length / batchSize + 1; j++) {
    // log("DEBUG: Fetching classroom events batch " + (j * batchSize) + " " + (j * batchSize + batchSize));
    var queryParams = {$and: [
      {_id: {$gte: startObj}},
      {user: {$in: classroomUserIDs.slice(j * batchSize, j * batchSize + batchSize)}},
      {event: 'Started Level'}
    ]};
    cursor = analyticsDB['log'].find(queryParams, {user: 1});
    while (cursor.hasNext()) {
      doc = cursor.next();
      if (!userPlayedMap[doc.user]) userPlayedMap[doc.user] = [];
      userPlayedMap[doc.user].push(doc._id.getTimestamp());
    }
  }

  log("Calculate number of active members per classroom per day per event type..");
  var classDayTypeMap = {};
  for (var classroom in classroomUsersMap) {
    if (classroomUsersMap[classroom].length < minClassSize) continue;

    // For each each day in our target date range
    classDayTypeMap[classroom] = {};
    startDate = ISODate(startDay + "T00:00:00.000Z");
    startDate.setUTCDate(startDate.getUTCDate() - daysInMonth);
    endDate = ISODate(startDay + "T00:00:00.000Z");
    while (endDate < todayDate) {
      var endDay = endDate.toISOString().substring(0, 10);
      classDayTypeMap[classroom][endDay] = {};
      classDayTypeMap[classroom][endDay][eventNamePaid] = 0;
      classDayTypeMap[classroom][endDay][eventNameTrial] = 0;
      classDayTypeMap[classroom][endDay][eventNameFree] = 0;

      // Count active users of each type for current day
      for (var j = 0; j < classroomUsersMap[classroom].length; j++) {
        var member = classroomUsersMap[classroom][j];

        // Was member active during current timeframe?
        if (userPlayedMap[member]) {
          for (var k = 0; k < userPlayedMap[member].length; k++) {
            if (userPlayedMap[member][k] > startDate && userPlayedMap[member][k] <= endDate) {
              if (userEventEndDateMap[member][eventNameTrial] > endDate) {
                classDayTypeMap[classroom][endDay][eventNameTrial]++;
              }
              else if (userEventEndDateMap[member][eventNamePaid] > endDate) {
                classDayTypeMap[classroom][endDay][eventNamePaid]++;
              }
              else if (userEventEndDateMap[member][eventNameFree] > endDate) {
                classDayTypeMap[classroom][endDay][eventNameFree]++;
              }
              else {
                print("ERROR: no event for " + member);
                printjson(userEventEndDateMap[member]);
              }
              break;
            }
          }
        }
      }

      startDate.setUTCDate(startDate.getUTCDate() + 1);
      endDate.setUTCDate(endDate.getUTCDate() + 1);
    }
  }

  log("Aggregate class counts by day and type..");
  var activeClassCounts = {};
  for (var classroom in classDayTypeMap) {
    for (var endDay in classDayTypeMap[classroom]) {
      var activeStudents = 0;
      var classEvent = eventNameFree;
      for (var event in classDayTypeMap[classroom][endDay]) {
        if (classDayTypeMap[classroom][endDay][event] > 1) {
          activeStudents += classDayTypeMap[classroom][endDay][event];
          if (event === eventNamePaid) classEvent = event;
          if (classEvent !== eventNamePaid && event === eventNameTrial) classEvent = event;
        } 
      }
      if (activeStudents >= minActiveCount) {
        if (!activeClassCounts[classEvent]) activeClassCounts[classEvent] = {};
        if (!activeClassCounts[classEvent][endDay]) activeClassCounts[classEvent][endDay] = 0;
        activeClassCounts[classEvent][endDay]++;
      }
    }
  }
  return activeClassCounts;
}


// *** Helper functions ***

function log(str) {
  print(new Date().toISOString() + " " + str);
}

function objectIdWithTimestamp(timestamp) {
  // Convert string date to Date object (otherwise assume timestamp is a date)
  if (typeof(timestamp) == 'string') timestamp = new Date(timestamp);
  // Convert date object to hex seconds since Unix epoch
  var hexSeconds = Math.floor(timestamp/1000).toString(16);
  // Create an ObjectId with that hex timestamp
  var constructedObjectId = ObjectId(hexSeconds + "0000000000000000");
  return constructedObjectId
}

function getAnalyticsString(str) {
  if (analyticsStringCache[str]) return analyticsStringCache[str];

  // Find existing string
  var doc = db['analytics.strings'].findOne({v: str});
  if (doc) {
    analyticsStringCache[str] = doc._id;
    return analyticsStringCache[str];
  }

  // Insert string
  // http://docs.mongodb.org/manual/tutorial/create-an-auto-incrementing-field/#auto-increment-optimistic-loop
  doc = {v: str};
  while (true) {
    var cursor = db['analytics.strings'].find({}, {_id: 1}).sort({_id: -1}).limit(1);
    var seq = cursor.hasNext() ? cursor.next()._id + 1 : 1;
    doc._id = seq;
    var results = db['analytics.strings'].insert(doc);
    if (results.hasWriteError()) {
      if ( results.writeError.code == 11000 /* dup key */ ) continue;
      else throw new Error("ERROR: Unexpected error inserting data: " + tojson(results));
    }
    break;
  }

  // Find new string entry
  doc = db['analytics.strings'].findOne({v: str});
  if (doc) {
    analyticsStringCache[str] = doc._id;
    return analyticsStringCache[str];
  }
  throw new Error("ERROR: Did not find analytics.strings insert for: " + str);
}

function insertEventCount(event, day, count) {
  // analytics.perdays schema in server/analytics/AnalyticsPeryDay.coffee
  day = day.replace(/-/g, '');

  var eventID = getAnalyticsString(event);
  var filterID = getAnalyticsString('all');

  var startObj = objectIdWithTimestamp(new Date(startDay + "T00:00:00.000Z"));
  var queryParams = {$and: [{d: day}, {e: eventID}, {f: filterID}]};
  var doc = db['analytics.perdays'].findOne(queryParams);
  if (doc && doc.c === count) return;

  if (doc && doc.c !== count) {
    // Update existing count, assume new one is more accurate
    // log("Updating count in db for " + day + " " + event + " " + doc.c + " => " + count);
    var results = db['analytics.perdays'].update(queryParams, {$set: {c: count}});
    if (results.nMatched !== 1 && results.nModified !== 1) {
      log("ERROR: update event count failed");
      printjson(results);
    }
  }
  else {
    var insertDoc = {d: day, e: eventID, f: filterID, c: count};
    var results = db['analytics.perdays'].insert(insertDoc);
    if (results.nInserted !== 1) {
      log("ERROR: insert event failed");
      printjson(results);
      printjson(insertDoc);
    }
    // else {
    //   log("Added " + day + " " + event + " " + count);
    // }
  }
}
