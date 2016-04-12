// Insert per-day subscription counts into analytics.perdays collection

// Usage:
// mongo <address>:<port>/<database> <script file> -u <username> -p <password>

try {
  logDB = new Mongo("localhost").getDB("analytics")
  var scriptStartTime = new Date();
  var analyticsStringCache = {};

  var numDays = 20;

  var startDay = new Date();
  today = startDay.toISOString().substr(0, 10);
  startDay.setUTCDate(startDay.getUTCDate() - numDays);
  startDay = startDay.toISOString().substr(0, 10);

  log("Today is " + today);
  log("Start day is " + startDay);

  log("Getting level subscription counts...");
  var levelSubscriptionCounts = getLevelSubscriptionCounts(startDay);
  log("Inserting level subscription counts...");
  for (level in levelSubscriptionCounts) {
    for (day in levelSubscriptionCounts[level]) {
      if (today === day) continue; // Never save data for today because it's incomplete
      for (event in levelSubscriptionCounts[level][day]) {
        insertLevelEventCount(event, level, day, levelSubscriptionCounts[level][day][event]);
      }
    }
  }

  log("Script runtime: " + (new Date() - scriptStartTime));
}
catch(err) {
  log("ERROR: " + err);
  printjson(err);
}

function getLevelSubscriptionCounts(startDay) {
  // Counts subscriptions shown per day, only for events that have levels
  // Subscription purchased event counts are attributed to last shown subscription modal event's day and level
  if (!startDay) return {};

  var startObj = objectIdWithTimestamp(ISODate(startDay + "T00:00:00.000Z"));
  var queryParams = {$and: [
    {_id: {$gte: startObj}},
    {$or: [
      {$and: [{'event': 'Show subscription modal'}, {'properties.level': {$exists: true}}]},
      {'event': 'Finished subscription purchase'}]
    }
  ]};
  var cursor = logDB['log'].find(queryParams);

  // Map ordering: user, event, level, day
  // Map ordering: user, event, day
  var userDataMap = {};
  while (cursor.hasNext()) {
    var doc = cursor.next();
    var created = doc._id.getTimestamp().toISOString();
    var day = created.substring(0, 10);
    var event = doc.event;
    var user = doc.user;

    if (!userDataMap[user]) userDataMap[user] = {};

    if (event === 'Show subscription modal') {
      var level = doc.properties.level;

      // TODO: This is for legacy data.
      // TODO: Event tracking updated to use level slug for loading level view on ~1/21/15
      level = slugify(level);

      if (!userDataMap[user][event]) userDataMap[user][event] = {};
      if (!userDataMap[user][event][level] || userDataMap[user][event][level].localeCompare(day) > 0) {
        userDataMap[user][event][level] = day;
      }
    }
    else if (event === 'Finished subscription purchase') {
      if (!userDataMap[user][event] || userDataMap[user][event].localeCompare(day) > 0) {
        userDataMap[user][event] = day;
      }
    } else {
      continue;
    }
  }

  // Data: level, day, event
  var levelFunnelData = {};
  for (user in userDataMap) {
    if (userDataMap[user]['Show subscription modal']) {
      var lastDay = null;
      var lastLevel = null;
      for (level in userDataMap[user]['Show subscription modal']) {
        var day = userDataMap[user]['Show subscription modal'][level];
        if (!lastDay || lastDay.localeCompare(day) > 0) {
          lastDay = day;
          lastLevel = level;
        }
        if (!levelFunnelData[level]) levelFunnelData[level] = {};
        if (!levelFunnelData[level][day]) levelFunnelData[level][day] = {};
        if (!levelFunnelData[level][day][event]) levelFunnelData[level][day]['Show subscription modal'] = 0;
        levelFunnelData[level][day]['Show subscription modal']++;
      }
      if (lastDay && userDataMap[user]['Finished subscription purchase']) {
        if (!levelFunnelData[lastLevel][lastDay]['Finished subscription purchase']) {
          levelFunnelData[lastLevel][lastDay]['Finished subscription purchase'] = 0;
        }
        levelFunnelData[lastLevel][lastDay]['Finished subscription purchase']++;
      }
    }
  }
  return levelFunnelData;
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

function insertLevelEventCount(event, level, day, count) {
  // analytics.perdays schema in server/analytics/AnalyticsPeryDay.coffee
  day = day.replace(/-/g, '');

  var eventID = getAnalyticsString(event);
  var levelID = getAnalyticsString(level);
  var filterID = getAnalyticsString('all');

  var startObj = objectIdWithTimestamp(new Date(startDay + "T00:00:00.000Z"));
  var queryParams = {$and: [{d: day}, {e: eventID}, {l: levelID}, {f: filterID}]};
  var doc = db['analytics.perdays'].findOne(queryParams);
  if (doc && doc.c === count) return;

  if (doc && doc.c !== count) {
    // Update existing count, assume new one is more accurate
    // log("Updating count in db for " + day + " " + event + " " + level + " " + doc.c + " => " + count);
    var results = db['analytics.perdays'].update(queryParams, {$set: {c: count}});
    if (results.nMatched !== 1 && results.nModified !== 1) {
      log("ERROR: update event count failed");
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
