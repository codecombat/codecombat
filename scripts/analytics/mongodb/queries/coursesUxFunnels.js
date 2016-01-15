// Print courses Ux funnel step counts

// Usage:
// Assumes analytics database is local, and Coco database is via command parameters
// mongo <address>:<port>/<database> <script file> -u <username> -p <password>

// TODO: generalize event formats in ux flow definitions
// TODO: there are users jumping past course pageviews and directly to 'Started course prepaid purchase'

var scriptStartTime = new Date();
var logDB = new Mongo("localhost").getDB("analytics")

var startDay = '2015-12-06';
var endDay = '2015-12-15';  // Not inclusive
var onlyUniqueEvents = false;

var teacherFlows = [
  [{pageview: ''}, {pageview: 'teachers'}, {pageview: 'courses/teachers'}, {event: 'Create new class'}, {event: 'Classroom started add students'}, {studentEvent: 'Joined classroom'}],
  [{pageview: ''}, {pageview: 'teachers'}, {event: 'Started Signup'}, {event: 'Finished Signup'}, {pageview: 'courses/teachers'}, {event: 'Create new class'}, {event: 'Classroom started add students'}, {studentEvent: 'Joined classroom'}]
];
var purchaseFlows = [
  [{pageviewRegex: /^courses\/\w{20}\w+$/ig, name: 'classroom details'}, {event: 'Classroom started enroll student'}, {pageviewRegex: /^courses\/purchase/ig, name: '/courses/purchase'}, {pageview: 'courses/purchase'}, {event: 'Started course prepaid purchase'}, {event: 'Finished course prepaid purchase'}, {event: 'Course assign student'}],
  [{pageviewRegex: /^courses\/\w{20}\w+$/ig, name: 'classroom details'}, {pageviewRegex: /^courses\/purchase/ig, name: '/courses/purchase'}, {event: 'Started course prepaid purchase'}, {event: 'Finished course prepaid purchase'}, {event: 'Course assign student'}],
  // TODO: This doesn't exclude a pitstop at /courses/:classroomID
  [{pageview: 'courses/teachers'}, {pageviewRegex: /^courses\/purchase/ig, name: '/courses/purchase'}, {event: 'Started course prepaid purchase'}, {event: 'Finished course prepaid purchase'}, {event: 'Course assign student'}],
  [{pageviewRegex: /^courses\/\w{20}\w+$/ig, name: 'classroom details'}, {event: 'Started course prepaid purchase'}, {event: 'Finished course prepaid purchase'}, {event: 'Course assign student'}],
  [{event: 'Started course prepaid purchase'}, {event: 'Finished course prepaid purchase'}, {event: 'Course assign student'}]
];

var salesFlows = [
  // /schools => /courses/teacher => Create new class => Classroom started add student => Student actually added (with join code delivery method)
  // /schools => /courses/:classroomID => /courses/purchase => Started purchase => Completed purchase => Assigned student
  // /schools => /courses/:classroomID => Enroll students modal => /courses/purchase => Started purchase => Completed purchase => Assigned student
  // /schools => /courses/teachers => /courses/purchase => Started purchase => Completed purchase => Assigned student
];

var studentFlows = [
  // TODO: exclude teachers
  [{event: 'Joined classroom'}, {pageview: 'play/level/dungeons-of-kithgard'}]
];

print(startDay, 'up to', endDay);

for (var i = 0; i < teacherFlows.length; i++) {
  print('\tTeacher flow', i + 1);
  var funnelEvents = getFunnelEvents(startDay, endDay, teacherFlows[i]);
  for (var event in funnelEvents) {
    print(funnelEvents[event], '\t', event);
  }
}

for (var i = 0; i < purchaseFlows.length; i++) {
  print('\tPurchase flow', i + 1);
  var funnelEvents = getFunnelEvents(startDay, endDay, purchaseFlows[i]);
  for (var event in funnelEvents) {
    print(funnelEvents[event], '\t', event);
  }
}

for (var i = 0; i < studentFlows.length; i++) {
  print('\tStudent flow', i + 1);
  var funnelEvents = getFunnelEvents(startDay, endDay, studentFlows[i]);
  for (var event in funnelEvents) {
    print(funnelEvents[event], '\t', event);
  }
}

// var userTimelines = getUserTimelines(startDay, endDay, onlyUniqueEvents);
// for (var user in userTimelines) {
//   if (userTimelines[user].length < 50) continue;
//   print('User', user)
//   for (var i = 0; i < userTimelines[user].length; i++) {
//     print(userTimelines[user][i].created, userTimelines[user][i].event);
//   }
//   // printjson(userTimelines[user]);
//   // break;
// }
// // printjson(userTimelines);

log("Script runtime: " + (new Date() - scriptStartTime));


function getFunnelEvents(startDay, endDay, events) {

  var startObj = objectIdWithTimestamp(ISODate(startDay + "T00:00:00.000Z"));
  var endObj = objectIdWithTimestamp(ISODate(endDay + "T00:00:00.000Z"));

  var normalEvents = [];
  var pageviewEvents = [];
  var pageviewRegexEvents = [];
  var studentEvents = [];
  for (var i = 0; i < events.length; i++) {
    if (events[i].hasOwnProperty('event')) {
      normalEvents.push(events[i].event);
    }
    else if (events[i].hasOwnProperty('pageview')) {
      pageviewEvents.push(events[i].pageview);
    }
    else if (events[i].hasOwnProperty('pageviewRegex')) {
      pageviewEvents.push(events[i].pageviewRegex);
      pageviewRegexEvents.push({regex: events[i].pageviewRegex, name: events[i].name});
    }
    else if (events[i].hasOwnProperty('studentEvent')) {
      studentEvents.push(events[i].studentEvent);
    }
    else {
      print("Unknown event:");
      printjson(events[i]);
      return {};
    }
  }
  // printjson(studentEvents);
  // printjson(pageviewEvents);

  var findQuery =  {$and: [
    {_id: {$gte: startObj}},
    {_id: {$lt: endObj}},
    {$or: [
      {event: {$in: normalEvents}},
      {event: {$in: studentEvents}},
      {$and: [
        {event: 'Pageview'},
        {'properties.url': {$in: pageviewEvents}}
      ]}
    ]}
  ]};
  // printjson(findQuery);
  // return {};

  var teacherEventsMap = {};
  var teacherIDs = [];
  var studentEventsMap = {};
  var cursor = logDB.log.find(findQuery, {event: 1, properties: 1, user: 1});
  while (cursor.hasNext()) {
    var doc = cursor.next();
    var created = doc._id.getTimestamp().toISOString();
    var event = doc.event;
    if (event === 'Pageview') {
      var matchedRegex = false;
      for (var i = 0; i < pageviewRegexEvents.length; i++) {
        if (doc.properties.url.match(pageviewRegexEvents[i].regex)) {
          event += ' ' + pageviewRegexEvents[i].name
          matchedRegex = true;
          break;
        }
      }
      if (!matchedRegex) {
        event += ' /' + doc.properties.url;
      }
    }
    var user = doc.user;

    if (studentEvents.indexOf(doc.event) >= 0) {
      if (!studentEventsMap[user]) studentEventsMap[user] = [];
      studentEventsMap[user].push({
        created: created,
        event: '(student) ' + event
      });
    }
    else {
      if (!teacherEventsMap[user]) teacherEventsMap[user] = [];
      teacherEventsMap[user].push({
        created: created,
        event: event
      });
      teacherIDs.push(ObjectId(user));
    }
  }
  // printjson(studentEventsMap);
  // print('Teachers:', Object.keys(teacherEventsMap).length);
  // print('Students:', Object.keys(studentEventsMap).length);
  // return {};

  // Match student events to their teachers via classrooms
  if (Object.keys(studentEventsMap).length > 0) {
    // For all teacher classrooms
    cursor = db.classrooms.find({ownerID: {$in: teacherIDs}}, {members: 1, ownerID: 1, });
    while (cursor.hasNext()) {
      var doc = cursor.next();
      var members = doc.members || [];
      var teacher = doc.ownerID.valueOf();

      // For each classroom non-owner member
      for (var i = 0; i < members.length; i++) {
        if (members[i].valueOf() === doc.ownerID.valueOf()) continue;
        var student = members[i].valueOf();
        if (!studentEventsMap[student]) continue;

        // Add student events to teacher events map
        teacherEventsMap[teacher] = teacherEventsMap[teacher].concat(studentEventsMap[student]);
      }
    }
  }

  var userTimelineMap = {};
  for (var user in teacherEventsMap) {
    // Sort and remove contiguous duplicate events
    teacherEventsMap[user].sort(function (a, b) { return a.created.localeCompare(b.created)});
    userTimelineMap[user] = [];
    var lastEvent = null;
    for (var i = 0; i < teacherEventsMap[user].length; i++) {
      if (teacherEventsMap[user][i].event !== lastEvent) {
        userTimelineMap[user].push(teacherEventsMap[user][i]);
      }
      lastEvent = teacherEventsMap[user][i].event;
    }
  }
  // printjson(userTimelineMap);

  getCurrentEvent = function(eventData) {
    var currentEvent = null;
    if (eventData.hasOwnProperty('event')) {
      currentEvent = eventData.event;
    }
    else if (eventData.hasOwnProperty('pageview')) {
      currentEvent = 'Pageview /' + eventData.pageview;
    }
    else if (eventData.hasOwnProperty('pageviewRegex')) {
      currentEvent = 'Pageview ' + eventData.name;
    }
    else if (eventData.hasOwnProperty('studentEvent')) {
      currentEvent = '(student) ' + eventData.studentEvent;
    }
    return currentEvent;
  }

  var funnelEvents = {};
  for (var user in userTimelineMap) {
    var eventsIndex = 0;
    var timelineIndex = 0;
    while (eventsIndex < events.length && timelineIndex < userTimelineMap[user].length) {
      var currentEvent = getCurrentEvent(events[eventsIndex]);
      var currentTimeline = userTimelineMap[user][timelineIndex];
      if (currentEvent === currentTimeline.event) {
        if (!funnelEvents[currentEvent]) funnelEvents[currentEvent] = 0;
        funnelEvents[currentTimeline.event]++;
        eventsIndex++;
      }
      timelineIndex++;
    }
    while (eventsIndex < events.length) {
      var currentEvent = getCurrentEvent(events[eventsIndex]);
      if (!funnelEvents[currentEvent]) funnelEvents[currentEvent] = 0;
      eventsIndex++;
    }
  }

  return funnelEvents;
}

function getUserTimelines(startDay, endDay, onlyUniqueEvents) {

  var startObj = objectIdWithTimestamp(ISODate(startDay + "T00:00:00.000Z"));
  var endObj = objectIdWithTimestamp(ISODate(endDay + "T00:00:00.000Z"))
  var cursor = logDB.log.find(
    {$and: [
      {_id: {$gte: startObj}},
      {_id: {$lt: endObj}},
      {$or: [
        {event: {$in: [
          'Hour of Code Begin',
          'Started Signup',
          'Classroom edit settings',
          'Create new class',
          'Classroom started add students',
          'Classroom started enroll student',
          'Classroom started enroll students',
          'Classroom removed student'
        ]}},
        {$and: [
          {event: 'Pageview'},
          {$or: [
            {'properties.url': {$regex: /hoc/ig}},
            {'properties.url': {$regex: /teachers/ig}},
            {'properties.url': {$regex: /courses/ig}}
          ]}
        ]}
      ]}
    ]});

  var userEventMap = {};
  var teacherEventsMap = {};
  while (cursor.hasNext()) {
    var doc = cursor.next();
    var created = doc._id.getTimestamp().toISOString();
    var event = doc.event;
    if (event === 'Pageview') {
      event += ' ' + doc.properties.url;
    }
    var user = doc.user.valueOf();

    if (onlyUniqueEvents) {
      if (!userEventMap[user]) userEventMap[user] = {};
      if (!userEventMap[user][event]) {
        userEventMap[user][event] = created;
      }
      else if (created.localeCompare(userEventMap[user][event]) < 0) {
        // print('Found earlier event', user, event, userEventMap[user][event], created);
        userEventMap[user][event] = created;
      }
    }
    else {
      if (!teacherEventsMap[user]) teacherEventsMap[user] = [];
      teacherEventsMap[user].push({
        created: created,
        event: event
      });
    }
  }

  var userTimelineMap = {};
  if (onlyUniqueEvents) {
    for (var user in userEventMap) {
      if (!userTimelineMap[user]) userTimelineMap[user] = [];
      for (var event in userEventMap[user]) {
        userTimelineMap[user].push({
          created: userEventMap[user][event],
          event: event
        })
      }
      userTimelineMap[user].sort(function (a, b) { return a.created.localeCompare(b.created)});
    }
  }
  else {
    for (var user in teacherEventsMap) {
      // Sort and remove contiguous duplicate events
      teacherEventsMap[user].sort(function (a, b) { return a.created.localeCompare(b.created)});
      userTimelineMap[user] = [];
      var lastEvent = null;
      for (var i = 0; i < teacherEventsMap[user].length; i++) {
        if (teacherEventsMap[user][i].event !== lastEvent) {
          userTimelineMap[user].push(teacherEventsMap[user][i]);
        }
        lastEvent = teacherEventsMap[user][i].event;
      }
    }
  }
  printjson(userTimelineMap);

  return userTimelineMap;
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
