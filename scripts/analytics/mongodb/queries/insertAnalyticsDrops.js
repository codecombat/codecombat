// Insert per-day level completion drop counts into analytics.perdays collection

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

  var levelCompletionFunnel = ['Started Level', 'Saw Victory'];

  log("Today is " + today);
  log("Start day is " + startDay);

  log("Getting level drop counts...");
  var levelDropCounts = getLevelDropCounts(startDay, levelCompletionFunnel);
  log("Inserting level drop counts...");
  for (level in levelDropCounts) {
    for (day in levelDropCounts[level]) {
      if (today === day) continue; // Never save data for today because it's incomplete
      insertLevelEventCount('User Dropped', level, day, levelDropCounts[level][day]);
    }
  }

  log("Script runtime: " + (new Date() - scriptStartTime));
}
catch(err) {
  log("ERROR: " + err);
  printjson(err);
}

function getLevelDropCounts(startDay, events) {
  // How many unique users did one of these events last?
  // Return level/day breakdown

  if (!startDay || !events || events.length === 0) return {};

  var startObj = objectIdWithTimestamp(ISODate(startDay + "T00:00:00.000Z"));
  var queryParams = {$and: [{_id: {$gte: startObj}},{"event": {$in: events}}]};
  var cursor = logDB['log'].find(queryParams);

  var userProgression = {};
  while (cursor.hasNext()) {
    var doc = cursor.next();
    var created = doc._id.getTimestamp().toISOString();
    var event = doc.event;
    var properties = doc.properties;
    var user = doc.user;
    var level;

    // TODO: Switch to properties.levelID for 'Saw Victory'
    if (event === 'Saw Victory' && properties.level) level = slugify(properties.level);
    else if (properties.levelID) level = properties.levelID
    else continue

    if (!userProgression[user]) userProgression[user] = [];
    userProgression[user].push({
      created: created,
      event: event,
      level: level
    });
  }

  var levelDropCounts = {};
  for (user in userProgression) {
    userProgression[user].sort(function (a,b) {return a.created < b.created ? -1 : 1});
    var lastEvent = userProgression[user][userProgression[user].length - 1];
    var level = lastEvent.level;
    var day = lastEvent.created.substring(0, 10);
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
