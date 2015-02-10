// A/B test helper functions
// Loaded from ab*.js ab test result scripts
// Main API is getFunnelData() which returns per-day funnel completion rates

// TODO: use levelSlugs in query if available
// TODO: Stop looking up testGroupNumber when test group data is available in analytics.log.events
// TODO: These are super slow, need to aggregate into analytics.perdays collection

var analyticsStringCache = {};
var analyticsStringIDCache = {};

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

function getAnalyticsString(strID) {
  if (analyticsStringCache[strID]) return analyticsStringCache[strID];
  var doc = db['analytics.strings'].findOne({_id: strID});
  if (doc) {
    analyticsStringCache[strID] = doc.v;
    return analyticsStringCache[strID];
  }
  throw new Error("ERROR: Did not find analytics.strings insert for: " + str);
}

function getAnalyticsStringID(str) {
  if (analyticsStringIDCache[str]) return analyticsStringIDCache[str];
  var doc = db['analytics.strings'].findOne({v: str});
  if (doc) {
    analyticsStringIDCache[str] = doc._id;
    return analyticsStringIDCache[str];
  }
  throw new Error("ERROR: Did not find analytics.strings insert for: " + str);
}

function getFunnelData(startDay, eventFunnel, testGroupFn, levelSlugs) {
  if (!startDay || !eventFunnel || eventFunnel.length === 0 || !testGroupFn) return {};

  // log('getFunnelData:');
  // log(startDay);
  // log(eventFunnel);

  var startObj = objectIdWithTimestamp(ISODate(startDay + "T00:00:00.000Z"));
  var queryParams = {$and: [{_id: {$gte: startObj}},{"event": {$in: eventFunnel}}]};
  var cursor = db['analytics.log.events'].find(queryParams);

  // Map ordering: level, user, event, day
  var levelUserEventMap = {};
  var users = [];
  while (cursor.hasNext()) {
    var doc = cursor.next();
    var created = doc._id.getTimestamp().toISOString();
    var day = created.substring(0, 10);
    var event = doc.event;
    var properties = doc.properties;
    var user = doc.user.valueOf();
    var level;

    // TODO: Switch to properties.levelID for 'Saw Victory'
    if (event === 'Saw Victory' && properties.level) level = properties.level.toLowerCase().replace(/ /g, '-');
    else if (properties.levelID) level = properties.levelID
    else level = 'n/a'

    if (levelSlugs && levelSlugs.indexOf(level) < 0) continue;

    users.push(ObjectId(user));

    if (!levelUserEventMap[level]) levelUserEventMap[level] = {};
    if (!levelUserEventMap[level][user]) levelUserEventMap[level][user] = {};
    if (!levelUserEventMap[level][user][event]
      || levelUserEventMap[level][user][event].localeCompare(day) > 0) {
      levelUserEventMap[level][user][event] = day;
    }
  }
  // printjson(levelUserEventMap);
  // printjson(users);

  var userGroupMap = {};
  cursor = db['users'].find({_id : {$in: users}});
  while (cursor.hasNext()) {
    var doc = cursor.next();
    var user = doc._id.valueOf();
    userGroupMap[user] = testGroupFn(doc.testGroupNumber);
  }
  // printjson(userGroupMap);

  // Data: level, day, event
  var levelDayGroupEventMap = {};
  for (level in levelUserEventMap) {
    for (user in levelUserEventMap[level]) {
      var group = userGroupMap[user];

      // Find first event date
      var funnelStartDay = null;
      for (event in levelUserEventMap[level][user]) {
        var day = levelUserEventMap[level][user][event];
        if (!levelDayGroupEventMap[level]) levelDayGroupEventMap[level] = {};
        if (!levelDayGroupEventMap[level][day]) levelDayGroupEventMap[level][day] = {};
        if (!levelDayGroupEventMap[level][day][group]) levelDayGroupEventMap[level][day][group] = {};
        if (!levelDayGroupEventMap[level][day][group][event]) levelDayGroupEventMap[level][day][group][event] = 0;
        if (eventFunnel[0] === event) {
          // First event gets attributed to current date
          levelDayGroupEventMap[level][day][group][event]++;
          funnelStartDay = day;
          break;
        }
      }

      if (funnelStartDay) {
        if (!levelDayGroupEventMap[level][funnelStartDay][group]) {
          levelDayGroupEventMap[level][funnelStartDay][group] = {};
        }
        // Add remaining funnel steps/events to first step's date
        for (event in levelUserEventMap[level][user]) {
          if (!levelDayGroupEventMap[level][funnelStartDay][group][event]) {
            levelDayGroupEventMap[level][funnelStartDay][group][event] = 0;
          }
          if (eventFunnel[0] !== event) levelDayGroupEventMap[level][funnelStartDay][group][event]++;
        }
        // Zero remaining funnel events
        for (var i = 1; i < eventFunnel.length; i++) {
          var event = eventFunnel[i];
          if (!levelDayGroupEventMap[level][funnelStartDay][group][event]) {
            levelDayGroupEventMap[level][funnelStartDay][group][event] = 0;
          }
        }
      }
      // Else no start event in this date range
    }
  }
  // printjson(levelDayGroupEventMap);

  var funnelData = [];
  for (level in levelDayGroupEventMap) {
    for (day in levelDayGroupEventMap[level]) {
      for (group in levelDayGroupEventMap[level][day]) {
        var started = 0;
        var finished = 0;
        for (event in levelDayGroupEventMap[level][day][group]) {
          if (event === eventFunnel[0]) {
            started = levelDayGroupEventMap[level][day][group][event];
          }
          else if (event === eventFunnel[eventFunnel.length - 1]) {
            finished = levelDayGroupEventMap[level][day][group][event];
          }
        }
        funnelData.push({
          level: level,
          day: day,
          group: group,
          started: started,
          finished: finished
        });
      }
    }
  }

  funnelData.sort(function (a,b) {
    if (a.level !== b.level) {
      return a.level < b.level ? -1 : 1;
    }
    else if (a.day !== b.day) {
      return a.day < b.day ? -1 : 1;
    }
    return a.group < b.group ? -1 : 1;
  });

  return funnelData;
}
