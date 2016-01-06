// Insert per-day recurring revenue counts into analytics.perdays collection

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

  log("Getting recurring revenue counts...");
  var recurringRevenueCounts = getRecurringRevenueCounts(startDay);
  // printjson(recurringRevenueCounts);
  log("Inserting recurring revenue counts...");
  for (var event in recurringRevenueCounts) {
    for (var day in recurringRevenueCounts[event]) {
      if (today === day) continue; // Never save data for today because it's incomplete
      insertEventCount(event, day, recurringRevenueCounts[event][day]);
    }
  }

  log("Script runtime: " + (new Date() - scriptStartTime));
}
catch(err) {
  log("ERROR: " + err);
  printjson(err);
}

function getRecurringRevenueCounts(startDay) {
  if (!startDay) return {};

  var dailyRevenueCounts = {};
  var startObj = objectIdWithTimestamp(ISODate(startDay + "T00:00:00.000Z"));
  var cursor = db.payments.find({_id: {$gte: startObj}});
  while (cursor.hasNext()) {
    var doc = cursor.next();
    var day;
    if (doc.created) {
      day = doc.created.substring(0, 10);
    }
    else {
      day = doc._id.getTimestamp().toISOString().substring(0, 10);
    }

    if (doc.service === 'ios' || doc.service === 'bitcoin') continue;

    if (doc.productID && doc.productID.indexOf('gems_') === 0) {
      if (!dailyRevenueCounts['DRR gems']) dailyRevenueCounts['DRR gems'] = {};
      if (!dailyRevenueCounts['DRR gems'][day]) dailyRevenueCounts['DRR gems'][day] = 0;
      dailyRevenueCounts['DRR gems'][day] += doc.amount
    }
    else if (doc.productID === 'custom' || doc.service === 'external' || doc.service === 'invoice') {
      if (!dailyRevenueCounts['DRR school sales']) dailyRevenueCounts['DRR school sales'] = {};
      if (!dailyRevenueCounts['DRR school sales'][day]) dailyRevenueCounts['DRR school sales'][day] = 0;
      dailyRevenueCounts['DRR school sales'][day] += doc.amount
    }
    else if (doc.service === 'stripe' && doc.gems === 42000) {
      if (!dailyRevenueCounts['DRR yearly subs']) dailyRevenueCounts['DRR yearly subs'] = {};
      if (!dailyRevenueCounts['DRR yearly subs'][day]) dailyRevenueCounts['DRR yearly subs'][day] = 0;
      dailyRevenueCounts['DRR yearly subs'][day] += doc.amount
    }
    else if (doc.service === 'stripe') {
      // Catches prepaids, and assumes all are type terminal_subscription
      if (!dailyRevenueCounts['DRR monthly subs']) dailyRevenueCounts['DRR monthly subs'] = {};
      if (!dailyRevenueCounts['DRR monthly subs'][day]) dailyRevenueCounts['DRR monthly subs'][day] = 0;
      dailyRevenueCounts['DRR monthly subs'][day] += doc.amount
    }
    else if (doc.service === 'paypal') {
      if (!dailyRevenueCounts['DRR monthly subs']) dailyRevenueCounts['DRR monthly subs'] = {};
      if (!dailyRevenueCounts['DRR monthly subs'][day]) dailyRevenueCounts['DRR monthly subs'][day] = 0;
      dailyRevenueCounts['DRR monthly subs'][day] += doc.amount
    }
    // else {
    //   // printjson(doc);
    //   // print(doc.service, doc.amount, doc.description, JSON.stringify(doc.stripe));
    // }
  }

  return dailyRevenueCounts;
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
