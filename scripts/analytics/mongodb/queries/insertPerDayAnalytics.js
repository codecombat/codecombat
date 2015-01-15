// Insert per-day analytics into analytics.perdays collection

// Usage:
// mongo <address>:<port>/<database> <script file> -u <username> -p <password>

// Completion rates (funnels) are calculated like Mixpanel
// For a given date range, start count is the number of first steps (e.g. started a level)
// Finish count for the same start date is how many unique users finished the remaining steps in the following ~30 days
// https://mixpanel.com/help/questions/articles/how-are-funnels-calculated

// TODO: Why are Mixpanel level finish events significantly lower?
// TODO: dungeons-of-kithgard completion rate is 62% vs. 77%
// TODO: Similar start events, finish events off by 20% (5334 vs 6486)
// TODO: Are Mixpanel rates accounting for finishing steps likely to be completed in the future?
// TODO: Use Mixpanel export API to investigate

// TODO: Output documents updated/inserted

var scriptStartTime = new Date();
var analyticsStringCache = {};

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

function getLevelFunnelData(startDay, eventFunnel) {
  if (!startDay || !eventFunnel || eventFunnel.length === 0) return {};

  var startObj = objectIdWithTimestamp(ISODate(startDay + "T00:00:00.000Z"));
  var queryParams = {$and: [{_id: {$gte: startObj}},{"event": {$in: eventFunnel}}]};
  var cursor = db['analytics.log.events'].find(queryParams);

  // Map ordering: level, user, event, created
  var userDataMap = {};
  while (cursor.hasNext()) {
    var doc = cursor.next();
    var created = doc._id.getTimestamp().toISOString().substring(0, 10);
    var event = doc.event;
    var properties = doc.properties;
    var user = doc.user;
    var level;

    // TODO: Switch to properties.levelID for 'Saw Victory'
    if (event === 'Saw Victory' && properties.level) level = properties.level.toLowerCase().replace(/ /g, '-');
    else if (properties.levelID) level = properties.levelID
    else continue

    if (!userDataMap[level]) userDataMap[level] = {};
    if (!userDataMap[level][user]) userDataMap[level][user] = {};
    if (!userDataMap[level][user][event] || userDataMap[level][user][event].localeCompare(created) > 0) {
      // if (userDataMap[level][user][event]) log("Found earlier date " + level + " " + event + " " + user + " " + userDataMap[level][user][event] + " " + created);
      userDataMap[level][user][event] = created;
    }
  }

  // Data: level, created, event
  var levelFunnelData = {};
  for (level in userDataMap) {
    for (user in userDataMap[level]) {

      // Find first event date
      var funnelStartDay = null;
      for (event in userDataMap[level][user]) {
        var created = userDataMap[level][user][event];
        if (!levelFunnelData[level]) levelFunnelData[level] = {};
        if (!levelFunnelData[level][created]) levelFunnelData[level][created] = {};
        if (!levelFunnelData[level][created][event]) levelFunnelData[level][created][event] = 0;
        if (eventFunnel[0] === event) {
          // First event gets attributed to current date
          levelFunnelData[level][created][event]++;
          funnelStartDay = created;
          break;
        }
      }

      if (funnelStartDay) {
        // Add remaining funnel steps/events to first step's date
        for (event in userDataMap[level][user]) {
          if (!levelFunnelData[level][funnelStartDay][event]) levelFunnelData[level][funnelStartDay][event] = 0;
          if (eventFunnel[0] != event) levelFunnelData[level][funnelStartDay][event]++;
        }
        // Zero remaining funnel events
        for (var i = 1; i < eventFunnel.length; i++) {
          var event = eventFunnel[i];
          if (!levelFunnelData[level][funnelStartDay][event]) levelFunnelData[level][funnelStartDay][event] = 0;
        }
      }
      // Else no start event in this date range
    }
  }
  return levelFunnelData;
}

function insertEventCount(event, level, day, count) {
  // analytics.perdays schema in server/analytics/AnalyticsPeryDay.coffee
  day = day.replace(/-/g, '');

  var eventID = getAnalyticsString(event);
  var levelID = getAnalyticsString(level);
  var filterID = getAnalyticsString('all');

  var startObj = objectIdWithTimestamp(ISODate(startDay + "T00:00:00.000Z"));
  var queryParams = {$and: [{d: day}, {e: eventID}, {l: levelID}, {f: filterID}]};
  var doc = db['analytics.perdays'].findOne(queryParams);
  if (doc && doc.c === count) return;

  if (doc && doc.c !== count) {
    // Update existing count, assume new one is more accurate
    // log("Updating count in db for " + day + " " + event + " " + level + " " + doc.c + " => " + count);
    var results = db['analytics.perdays'].update(queryParams, {$set: {c: count}});
    if (results.nMatched !== 1 && results.nModified !== 1) {
      log("ERROR: update count failed");
      printjson(results);
    }
  }
  else {
    var insertDoc = {d: day, e: eventID, l: levelID, f: filterID, c: count};
    var results = db['analytics.perdays'].insert(insertDoc);
    if (results.nInserted !== 1) {
      log("ERROR: insert event failed");
      printjson(results);
      printjson(insertDoc);
    }
    // else {
    //   log("Added " + day + " " + event + " " + count + " " + level);
    // }
  }
}

try {
  // Look at last 30 days, same as Mixpanel
  var numDays = 30;
  
  var startDay = new Date();
  today = startDay.toISOString().substr(0, 10);
  startDay.setUTCDate(startDay.getUTCDate() - numDays);
  startDay = startDay.toISOString().substr(0, 10);

  var levelCompletionFunnel = ['Started Level', 'Saw Victory'];

  log("Today is " + today);
  log("Start day is " + startDay);
  log("Funnel events are " + levelCompletionFunnel);
  
  log("Getting level completion data...");
  var levelCompletionData = getLevelFunnelData(startDay, levelCompletionFunnel);
  
  log("Inserting aggregated level completion data...");
  for (level in levelCompletionData) {
    for (created in levelCompletionData[level]) {
      if (today === created) continue; // Never save data for today because it's incomplete
      for (event in levelCompletionData[level][created]) {
        insertEventCount(event, level, created, levelCompletionData[level][created][event]);
      }
    }
  }
} 
catch(err) {
  log("ERROR: " + err);
  printjson(err);
}

log("Script runtime: " + (new Date() - scriptStartTime));