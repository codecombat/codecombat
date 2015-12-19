// Insert per-day level completion counts into analytics.perdays collection

// Usage:
// mongo <address>:<port>/<database> <script file> -u <username> -p <password>

// Completion rates (funnels) are calculated like Mixpanel
// For a given date range, start count is the number of first steps (e.g. started a level)
// Finish count for the same start date is how many unique users finished the remaining steps in the following ~30 days
// https://mixpanel.com/help/questions/articles/how-are-funnels-calculated

try {
  logDB = new Mongo("localhost").getDB("analytics")
  var scriptStartTime = new Date();
  var analyticsStringCache = {};

  // This needs to be enough days to encompass the start and finish events for most levels
  var numDays = 20;

  var today = new Date().toISOString().substr(0, 10);

  var levelCompletionFunnel = ['Started Level', 'Saw Victory'];

  log("Today is " + today);
  log("numDays " + numDays);

  var campaignLevelSlugs = getCampaignLevelSlugs();

  log("Getting level completion data...");
  var levelCompletionData = getLevelFunnelData(numDays, levelCompletionFunnel, campaignLevelSlugs);
  log("Inserting aggregated level completion data...");
  for (level in levelCompletionData) {
    for (day in levelCompletionData[level]) {
      if (today === day) continue; // Never save data for today because it's incomplete
      for (event in levelCompletionData[level][day]) {
        insertLevelEventCount(event, level, day, levelCompletionData[level][day][event]);
      }
    }
  }

  log("Script runtime: " + (new Date() - scriptStartTime));
}
catch(err) {
  log("ERROR: " + err);
  printjson(err);
}

function getCampaignLevelSlugs() {
  var campaignLevelSlugMap = {};
  var cursor = db.campaigns.find({}, {levels: 1});
  while (cursor.hasNext()) {
    var doc = cursor.next();
    for (var levelID in doc.levels) {
      campaignLevelSlugMap[doc.levels[levelID].slug] = true;
    }
  }
  return Object.keys(campaignLevelSlugMap);
}

function getLevelFunnelData(numDays, eventFunnel, campaignLevelSlugs) {

  // Faster to request analytics db data in batches of days
  var dayIncrement = 3;
  var startDate = new Date();
  startDate.setUTCDate(startDate.getUTCDate() - numDays);
  var startDay = startDate.toISOString().substr(0, 10);
  var endDate = new Date();
  endDate.setUTCDate(endDate.getUTCDate() - numDays + dayIncrement);
  var endDay = endDate.toISOString().substr(0, 10);

  log("Start day is " + startDay);

  // Map ordering: level, user, event, day
  var userDataMap = {};
  while (startDay < today) {
    // log(startDay + " " + endDay);
    var startObj = objectIdWithTimestamp(ISODate(startDay + "T00:00:00.000Z"));
    var endObj = objectIdWithTimestamp(ISODate(endDay + "T00:00:00.000Z"));

    for (var i = 0; i < eventFunnel.length; i++) {
      var queryParams = {$and: [{_id: {$gte: startObj}}, {_id: {$lt: endObj}}, {"event": eventFunnel[i]}, {'properties.levelID': {$in: campaignLevelSlugs}}]};
      var selectParams = {event: 1, 'properties.levelID': 1, user: 1};
      var cursor = logDB.log.find(queryParams, selectParams);
      while (cursor.hasNext()) {
        var doc = cursor.next();
        var created = doc._id.getTimestamp().toISOString();
        var day = created.substring(0, 10);
        var event = doc.event;
        var level = doc.properties ? doc.properties.levelID : null;
        var user = doc.user;

        if (!level) continue;

        if (!userDataMap[level]) userDataMap[level] = {};
        if (!userDataMap[level][user]) userDataMap[level][user] = {};
        if (!userDataMap[level][user][event] || userDataMap[level][user][event].localeCompare(day) > 0) {
          userDataMap[level][user][event] = day;
        }
      }
    }
    startDate.setUTCDate(startDate.getUTCDate() + dayIncrement);
    startDay = startDate.toISOString().substr(0, 10);
    endDate.setUTCDate(endDate.getUTCDate() + dayIncrement);
    endDay = endDate.toISOString().substr(0, 10);
  }

  log("Finished getting events");

  // Data: level, day, event
  var levelFunnelData = {};
  for (level in userDataMap) {
    for (user in userDataMap[level]) {

      // Find first event date
      var funnelStartDay = null;
      for (event in userDataMap[level][user]) {
        var day = userDataMap[level][user][event];
        if (!levelFunnelData[level]) levelFunnelData[level] = {};
        if (!levelFunnelData[level][day]) levelFunnelData[level][day] = {};
        if (!levelFunnelData[level][day][event]) levelFunnelData[level][day][event] = 0;
        if (eventFunnel[0] === event) {
          // First event gets attributed to current date
          levelFunnelData[level][day][event]++;
          funnelStartDay = day;
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
