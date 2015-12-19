// Insert per-day active class counts into analytics.perdays collection

// Usage:
// mongo <address>:<port>/<database> <script file> -u <username> -p <password>

try {
  logDB = new Mongo("localhost").getDB("analytics")
  var scriptStartTime = new Date();
  var analyticsStringCache = {};

  var numDays = 40;
  var daysInMonth = 30;

  var startDay = new Date();
  today = startDay.toISOString().substr(0, 10);
  startDay.setUTCDate(startDay.getUTCDate() - numDays);
  startDay = startDay.toISOString().substr(0, 10);

  log("Today is " + today);
  log("Start day is " + startDay);

  log("Getting active class counts...");
  var activeClassCounts = getActiveClassCounts(startDay);
  // printjson(activeClassCounts);
  log("Inserting active class counts...");
  for (var event in activeClassCounts) {
    for (var day in activeClassCounts[event]) {
      if (today === day) continue; // Never save data for today because it's incomplete
      insertEventCount(event, day, activeClassCounts[event][day]);
    }
  }

  log("Script runtime: " + (new Date() - scriptStartTime));
}
catch(err) {
  log("ERROR: " + err);
  printjson(err);
}

function getActiveClassCounts(startDay) {
  // Tally active classes per day
  // TODO: does not handle class membership changes

  if (!startDay) return {};

  var minGroupSize = 12;
  var classes = {
    'Active classes private clan': [],
    'Active classes managed subscription': [],
    'Active classes bulk subscription': [],
    'Active classes prepaid': [],
    'Active classes course free': [],
    'Active classes course paid': []
  };
  var userPlayedMap = {};

  // Private clans
  // TODO: does not handle clan membership changes over time
  var cursor = db.clans.find({$and: [{type: 'private'}, {$where: 'this.members.length >= ' + minGroupSize}]});
  while (cursor.hasNext()) {
    var doc = cursor.next();
    var members = doc.members.map(function(a) {
      userPlayedMap[a.valueOf()] = [];
      return a.valueOf();
    });
    classes['Active classes private clan'].push({
      owner: doc.ownerID.valueOf(),
      members: members,
      activeDayMap: {}
    });
  }

  // Managed subscriptions
  // TODO: does not handle former recipients playing after sponsorship ends
  var bulkSubGroups = {};
  cursor = db.payments.find({$and: [{service: 'stripe'}, {$where: '!this.purchaser.equals(this.recipient)'}]});
  while (cursor.hasNext()) {
    var doc = cursor.next();
    var purchaser = doc.purchaser.valueOf();
    if (!bulkSubGroups[purchaser]) bulkSubGroups[purchaser] = {};
    bulkSubGroups[purchaser][doc.recipient.valueOf()] = true;
  }
  for (var purchaser in bulkSubGroups) {
    if (Object.keys(bulkSubGroups[purchaser]).length >= minGroupSize) {
      for (var member in bulkSubGroups[purchaser]) {
        userPlayedMap[member] = [];
      }
      classes['Active classes managed subscription'].push({
        owner: purchaser,
        members: Object.keys(bulkSubGroups[purchaser]),
        activeDayMap: {}
      });
    }
  }

  // Bulk subscriptions
  bulkSubGroups = {};
  cursor = db.payments.find({$and: [{service: 'external'}, {$where: '!this.purchaser.equals(this.recipient)'}]});
  while (cursor.hasNext()) {
    var doc = cursor.next();
    var purchaser = doc.purchaser.valueOf();
    if (!bulkSubGroups[purchaser]) bulkSubGroups[purchaser] = {};
    bulkSubGroups[purchaser][doc.recipient.valueOf()] = true;
  }
  for (var purchaser in bulkSubGroups) {
    if (Object.keys(bulkSubGroups[purchaser]).length >= minGroupSize) {
      for (var member in bulkSubGroups[purchaser]) {
        userPlayedMap[member] = [];
      }
      classes['Active classes bulk subscription'].push({
        owner: purchaser,
        members: Object.keys(bulkSubGroups[purchaser]),
        activeDayMap: {}
      });
    }
  }

  // Prepaids terminal_subscription
  bulkSubGroups = {};
  cursor = db.prepaids.find(
    {$and: [{type: 'terminal_subscription'}, {$where: 'this.redeemers && this.redeemers.length >= ' + minGroupSize}]},
    {creator: 1, type: 1, redeemers: 1}
  );
  while (cursor.hasNext()) {
    var doc = cursor.next();
    var owner = doc.creator.valueOf();
    var members = [];
    for (var i = 0 ; i < doc.redeemers.length; i++) {
      userPlayedMap[doc.redeemers[i].userID.valueOf()] = [];
      members.push(doc.redeemers[i].userID.valueOf());
    }
    classes['Active classes prepaid'].push({
      owner: owner,
      members: members,
      activeDayMap: {}
    });
  }

  // Classrooms
  var classroomCourseInstancesMap = {};
  cursor = db.course.instances.find(
    {$where: 'this.members && this.members.length >= ' + minGroupSize},
    {classroomID: 1, courseID: 1, members: 1, ownerID: 1}
  );
  while (cursor.hasNext()) {
    var doc = cursor.next();
    var owner = doc.ownerID.valueOf();
    var classroom = doc.classroomID ? doc.classroomID.valueOf() : doc._id.valueOf();
    var members = [];
    for (var i = 0 ; i < doc.members.length; i++) {
      userPlayedMap[doc.members[i].valueOf()] = [];
      members.push(doc.members[i].valueOf());
    }
    if (!classroomCourseInstancesMap[classroom]) classroomCourseInstancesMap[classroom] = [];
    classroomCourseInstancesMap[classroom].push({
      course: doc.courseID.valueOf(),
      owner: owner,
      members: members,
    });
  }

  // printjson(classroomCourseInstancesMap);

  // Find all the started level events for our class members, for startDay - daysInMonth
  var startDate = ISODate(startDay + "T00:00:00.000Z");
  startDate.setUTCDate(startDate.getUTCDate() - daysInMonth);
  var endDate = ISODate(startDay + "T00:00:00.000Z");
  var todayDate = new Date(new Date().toISOString().substring(0, 10));
  var startObj = objectIdWithTimestamp(startDate);
  var queryParams = {$and: [
    {_id: {$gte: startObj}},
    {user: {$in: Object.keys(userPlayedMap)}},
    {event: 'Started Level'}
  ]};
  cursor = logDB['log'].find(queryParams, {user: 1});
  while (cursor.hasNext()) {
    var doc = cursor.next();
    userPlayedMap[doc.user].push(doc._id.getTimestamp());
  }

  // printjson(userPlayedMap);
  // print(startDate, endDate, todayDate);

  // Now we have a set of classes, and when users played
  // For a given day, walk classes and find out how many members were active during the previous daysInMonth
  while (endDate < todayDate) {
    var endDay = endDate.toISOString().substring(0, 10);

    // For each class
    for (var event in classes) {
      for (var i = 0; i < classes[event].length; i++) {

        // For each member of current class
        var activeMemberCount = 0;
        for (var j = 0; j < classes[event][i].members.length; j++) {
          var member = classes[event][i].members[j];

          // Was member active during current timeframe?
          if (userPlayedMap[member]) {
            for (var k = 0; k < userPlayedMap[member].length; k++) {
              if (userPlayedMap[member][k] > startDate && userPlayedMap[member][k] <= endDate) {
                activeMemberCount++;
                break;
              }
            }
          }
        }

        // Classes active for a given day if has minGroupSize members, and at least 1/2 played in last daysInMonth days
        if (activeMemberCount >= Math.round(classes[event][i].members.length / 2)) {
          classes[event][i].activeDayMap[endDay] = true;
        }
      }
    }
    startDate.setUTCDate(startDate.getUTCDate() + 1);
    endDate.setUTCDate(endDate.getUTCDate() + 1);
  }

  // Classrooms are processed differently because they could be free or paid active classes
  var courseNameMap = {};
  cursor = db.courses.find({}, {name: 1});
  while (cursor.hasNext()) {
    var doc = cursor.next();
    courseNameMap[doc._id.valueOf()] = doc.name;
  }

  // For each classroom, check free and paid members separately
  for (var classroom in classroomCourseInstancesMap) {
    var freeMembers = {};
    var paidMembers = {};
    var owner = null;
    for (var i = 0; i < classroomCourseInstancesMap[classroom].length; i++) {
      var courseInstance = classroomCourseInstancesMap[classroom][i];
      if (!owner) owner = courseInstance.owner;
      for (var j = 0; j < courseInstance.members.length; j++) {
        if (courseNameMap[courseInstance.course] === 'Introduction to Computer Science') {
          freeMembers[courseInstance.members[j]] = true;
        }
        else {
          paidMembers[courseInstance.members[j]] = true;
        }
      }
    }

    var freeClass = {
      owner: owner,
      members: Object.keys(freeMembers),
      activeDayMap: {}
    };
    var paidClass = {
      owner: owner,
      members: Object.keys(paidMembers),
      activeDayMap: {}
    };

    // print('Processing classroom', classroom, freeClass.members.length, paidClass.members.length);

    startDate = ISODate(startDay + "T00:00:00.000Z");
    startDate.setUTCDate(startDate.getUTCDate() - daysInMonth);
    endDate = ISODate(startDay + "T00:00:00.000Z");
    while (endDate < todayDate) {
      var endDay = endDate.toISOString().substring(0, 10);

      // For each paid member of current class
      var paidActiveMemberCount = 0;
      for (var j = 0; j < paidClass.members.length; j++) {
        var member = paidClass.members[j];

        // Was member active during current timeframe?
        if (userPlayedMap[member]) {
          for (var k = 0; k < userPlayedMap[member].length; k++) {
            if (userPlayedMap[member][k] > startDate && userPlayedMap[member][k] <= endDate) {
              paidActiveMemberCount++;
              break;
            }
          }
        }
      }

      // Classes active for a given day if has minGroupSize members, and at least 1/2 played in last daysInMonth days
      if (paidClass.members.length > minGroupSize && paidActiveMemberCount >= Math.round(paidClass.members.length / 2)) {
        // print('paid classroom', classroom, endDay);
        paidClass.activeDayMap[endDay] = true;
      }
      else {
        // For each free member of current class
        var freeActiveMemberCount = 0;
        for (var j = 0; j < freeClass.members.length; j++) {
          var member = freeClass.members[j];

          // Was member active during current timeframe?
          if (userPlayedMap[member]) {
            for (var k = 0; k < userPlayedMap[member].length; k++) {
              if (userPlayedMap[member][k] > startDate && userPlayedMap[member][k] <= endDate) {
                freeActiveMemberCount++;
                break;
              }
            }
          }
        }

        if (freeClass.members.length > minGroupSize && freeActiveMemberCount >= Math.round(freeClass.members.length / 2)) {
          // print('free classroom', classroom, endDay);
          freeClass.activeDayMap[endDay] = true;
        }

      }
      startDate.setUTCDate(startDate.getUTCDate() + 1);
      endDate.setUTCDate(endDate.getUTCDate() + 1);
    }

    // printjson(freeClass);
    // printjson(paidClass);

    classes['Active classes course free'].push(freeClass);
    classes['Active classes course paid'].push(paidClass);
  }

  // printjson(classes['Active classes course paid']);

  var activeClassCounts = {};
  for (var event in classes) {
    if (!activeClassCounts[event]) activeClassCounts[event] = {};
    for (var i = 0; i < classes[event].length; i++) {
      for (var endDay in classes[event][i].activeDayMap) {
        if (!activeClassCounts[event][endDay]) activeClassCounts[event][endDay] = 0;
        activeClassCounts[event][endDay]++;
      }
    }
  }
  return activeClassCounts;
}


// *** Helper functions ***

function slugify(text)
// https://gist.github.com/mathewbyrne/1280286
{
  return text.toString().toLowerCase()
    .replace(/\s+/g, '-')           // Replace spaces with -
    .replace(/[^\w\-]+/g, '')       // Remove all non-word chars
    .replace(/\-\-+/g, '-')         // Replace multiple - with single -
    .replace(/^-+/, '')             // Trim - from start of text
    .replace(/-+$/, '');            // Trim - from end of text
}

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
