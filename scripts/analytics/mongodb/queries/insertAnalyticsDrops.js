// Insert per-day level completion drop counts into analytics.perdays collection

// Usage:
// mongo <address>:<port>/<database> <script file> -u <username> -p <password>

try {
  logDB = new Mongo("localhost").getDB("analytics")
  var scriptStartTime = new Date();

  var StringCache = function() {
    this.lookup = {};
    this.strings = [];
  }
  StringCache.prototype.get = function(index) {
    return this.strings[parseInt(index)];
  }
  StringCache.prototype.set = function(str) {
    if (!this.lookup.hasOwnProperty(str)) {
      this.lookup[str] = this.strings.length;
      this.strings.push(str);
    }
    return this.lookup[str];
  }

  var dayCache = new StringCache();
  var eventCache = new StringCache();
  var levelCache = new StringCache();
  var userCache = new StringCache();

  // TODO: convert to StringCache?
  var analyticsStringCache = {};

  // This needs to be enough days to encompass the start and finish events for most levels
  var numDays = 20;
  var levelCompletionFunnel = ['Started Level', 'Saw Victory'];

  var today = new Date().toISOString().substr(0, 10);
  log("Today is " + today);
  log("numDays " + numDays);

  var campaignLevelSlugs = getCampaignLevelSlugs();

  log("Getting level drop counts...");
  var levelDropCounts = getLevelDropCounts(numDays, levelCompletionFunnel, campaignLevelSlugs);
  log("Inserting level drop counts...");
  for (var level in levelDropCounts) {
    for (var day in levelDropCounts[level]) {
      if (today === dayCache.get(day)) continue; // Never save data for today because it's incomplete
      // print('User Dropped', levelCache.get(level), dayCache.get(day), levelDropCounts[level][day]);
      insertLevelEventCount(numDays, 'User Dropped', levelCache.get(level), dayCache.get(day), levelDropCounts[level][day]);
    }
  }

  log("Script runtime: " + (new Date().getTime() - scriptStartTime.getTime()));
}
catch(err) {
  log("ERROR: " + err);
  printjson(err);
}

function getLevelDropCounts(startDay, eventFunnel) {
  // How many unique users did one of these events last?
  // Return level/day breakdown

  // Faster to request analytics db data in batches of days
  var dayIncrement = 3;
  var startDate = new Date();
  startDate.setUTCDate(startDate.getUTCDate() - numDays);
  var startDay = startDate.toISOString().substr(0, 10);
  var endDate = new Date();
  endDate.setUTCDate(endDate.getUTCDate() - numDays + dayIncrement);
  var endDay = endDate.toISOString().substr(0, 10);

  log("Start day is " + startDay);

  var userProgression = {};
  while (startDay < today) {
    // log(startDay + " " + endDay);
    var startObj = objectIdWithTimestamp(ISODate(startDay + "T00:00:00.000Z"));
    var endObj = objectIdWithTimestamp(ISODate(endDay + "T00:00:00.000Z"));

    for (var i = 0; i < eventFunnel.length; i++) {
      var queryParams = {$and: [{_id: {$gte: startObj}}, {_id: {$lt: endObj}}, {"event": eventFunnel[i]}, {'properties.levelID': {$in: campaignLevelSlugs}}]};
      var selectParams = {event: 1, 'properties.levelID': 1, user: 1};
      var cursor = logDB['log'].find(queryParams);
      while (cursor.hasNext()) {
        var doc = cursor.next();
        if (!doc.properties || !doc.properties.levelID) continue;

        var created = doc._id.getTimestamp().toISOString();
        var event = eventCache.set(doc.event);
        var level = levelCache.set(doc.properties.levelID);
        var user = userCache.set(doc.user);

        if (!userProgression[user]) userProgression[user] = [];
        userProgression[user].push({
          created: created,
          event: event,
          level: level
        });
      }
    }
    startDate.setUTCDate(startDate.getUTCDate() + dayIncrement);
    startDay = startDate.toISOString().substr(0, 10);
    endDate.setUTCDate(endDate.getUTCDate() + dayIncrement);
    endDay = endDate.toISOString().substr(0, 10);
  }

  var levelDropCounts = {};
  for (var user in userProgression) {
    userProgression[user].sort(function (a,b) {return a.created < b.created ? -1 : 1});
    var lastEvent = userProgression[user][userProgression[user].length - 1];
    var level = lastEvent.level;
    var day = dayCache.set(lastEvent.created.substring(0, 10));
    if (!levelDropCounts[level]) levelDropCounts[level] = {};
    if (!levelDropCounts[level][day]) levelDropCounts[level][day] = 0
      levelDropCounts[level][day]++;
  }
  return levelDropCounts;
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

  var startDate = new Date();
  startDate.setUTCDate(startDate.getUTCDate() - numDays);
  var startDay = startDate.toISOString().substr(0, 10);
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
