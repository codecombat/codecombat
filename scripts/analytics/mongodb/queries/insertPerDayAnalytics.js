// Insert per-day analytics into analytics.perdays collection

// Usage:
// mongo <address>:<port>/<database> <script file> -u <username> -p <password>

// Completion rates (funnels) are calculated like Mixpanel
// For a given date range, start count is the number of first steps (e.g. started a level)
// Finish count for the same start date is how many unique users finished the remaining steps in the following ~30 days
// https://mixpanel.com/help/questions/articles/how-are-funnels-calculated

// Drop count: last started or finished level event for a given unique user

// TODO: Convert this to a node script so it can use proper libraries (e.g. slugify)

try {
  logDB = new Mongo("localhost").getDB("analytics")
  var scriptStartTime = new Date();
  var analyticsStringCache = {};

  var numDays = 32;
  var daysInMonth = 30;

  var startDay = new Date();
  today = startDay.toISOString().substr(0, 10);
  startDay.setUTCDate(startDay.getUTCDate() - numDays);
  startDay = startDay.toISOString().substr(0, 10);

  var levelCompletionFunnel = ['Started Level', 'Saw Victory'];
  var levelHelpEvents = ['Problem alert help clicked', 'Spell palette help clicked', 'Start help video'];
  var activeUserEvents = ['Finished Signup', 'Started Level'];

  log("Today is " + today);
  log("Start day is " + startDay);
  log("Funnel events are " + levelCompletionFunnel);

  log("Getting level completion data...");
  var levelCompletionData = getLevelFunnelData(startDay, levelCompletionFunnel);
  log("Inserting aggregated level completion data...");
  for (level in levelCompletionData) {
    for (day in levelCompletionData[level]) {
      if (today === day) continue; // Never save data for today because it's incomplete
      for (event in levelCompletionData[level][day]) {
        insertLevelEventCount(event, level, day, levelCompletionData[level][day][event]);
      }
    }
  }

  log("Getting level drop counts...");
  var levelDropCounts = getLevelDropCounts(startDay, levelCompletionFunnel);
  log("Inserting level drop counts...");
  for (level in levelDropCounts) {
    for (day in levelDropCounts[level]) {
      if (today === day) continue; // Never save data for today because it's incomplete
      insertLevelEventCount('User Dropped', level, day, levelDropCounts[level][day]);
    }
  }

  log("Getting level help counts...");
  var levelHelpCounts = getLevelHelpCounts(startDay, levelHelpEvents);
  log("Inserting level help counts...");
  for (level in levelHelpCounts) {
    for (day in levelHelpCounts[level]) {
      if (today === day) continue; // Never save data for today because it's incomplete
      for (event in levelHelpCounts[level][day]) {
        insertLevelEventCount(event, level, day, levelHelpCounts[level][day][event]);
      }
    }
  }

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

  log("Getting active user counts...");
  var activeUserCounts = getActiveUserCounts(startDay, activeUserEvents);
  // printjson(activeUserCounts);
  log("Inserting active user counts...");
  for (day in activeUserCounts) {
    if (today === day) continue; // Never save data for today because it's incomplete
    for (event in activeUserCounts[day]) {
      insertEventCount(event, day, activeUserCounts[day][event]);
    }
  }

  log("Script runtime: " + (new Date() - scriptStartTime));
}
catch(err) {
  log("ERROR: " + err);
  printjson(err);
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

function getLevelFunnelData(startDay, eventFunnel) {
  if (!startDay || !eventFunnel || eventFunnel.length === 0) return {};

  var startObj = objectIdWithTimestamp(ISODate(startDay + "T00:00:00.000Z"));
  var queryParams = {$and: [{_id: {$gte: startObj}},{"event": {$in: eventFunnel}}]};
  var cursor = logDB['log'].find(queryParams);

  // Map ordering: level, user, event, day
  var userDataMap = {};
  while (cursor.hasNext()) {
    var doc = cursor.next();
    var created = doc._id.getTimestamp().toISOString();
    var day = created.substring(0, 10);
    var event = doc.event;
    var properties = doc.properties;
    var user = doc.user;
    var level;

    // TODO: Switch to properties.levelID for 'Saw Victory'
    if (event === 'Saw Victory' && properties.level) level = slugify(properties.level);
    else if (properties.levelID) level = properties.levelID
    else continue

    if (!userDataMap[level]) userDataMap[level] = {};
    if (!userDataMap[level][user]) userDataMap[level][user] = {};
    if (!userDataMap[level][user][event] || userDataMap[level][user][event].localeCompare(day) > 0) {
      // if (userDataMap[level][user][event]) log("Found earlier date " + level + " " + event + " " + user + " " + userDataMap[level][user][event] + " " + day);
      userDataMap[level][user][event] = day;
    }
  }

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

function getLevelHelpCounts(startDay, events) {
  if (!startDay || !events || events.length === 0) return {};

  var startObj = objectIdWithTimestamp(ISODate(startDay + "T00:00:00.000Z"));
  var queryParams = {$and: [{_id: {$gte: startObj}},{"event": {$in: events}}]};
  var cursor = logDB['log'].find(queryParams);

  // Map ordering: level, user, event, day
  var userDataMap = {};
  while (cursor.hasNext()) {
    var doc = cursor.next();
    var created = doc._id.getTimestamp().toISOString();
    var day = created.substring(0, 10);
    var event = doc.event;
    var properties = doc.properties;
    var user = doc.user;
    var level;

    if (properties.level) level = properties.level;
    else if (properties.levelID) level = properties.levelID
    else continue

    if (!userDataMap[level]) userDataMap[level] = {};
    if (!userDataMap[level][user]) userDataMap[level][user] = {};
    if (!userDataMap[level][user][event] || userDataMap[level][user][event].localeCompare(day) > 0) {
      // if (userDataMap[level][user][event]) log("Found earlier date " + level + " " + event + " " + user + " " + userDataMap[level][user][event] + " " + day);
      userDataMap[level][user][event] = day;
    }
  }

  // Data: level, day, event
  var levelEventData = {};
  for (level in userDataMap) {
    for (user in userDataMap[level]) {
      for (event in userDataMap[level][user]) {
        var day = userDataMap[level][user][event];
        if (!levelEventData[level]) levelEventData[level] = {};
        if (!levelEventData[level][day]) levelEventData[level][day] = {};
        if (!levelEventData[level][day][event]) levelEventData[level][day][event] = 0;
        levelEventData[level][day][event]++;
      }
    }
  }
  return levelEventData;
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

function getActiveUserCounts(startDay, activeUserEvents) {
  // Counts active users per day
  if (!startDay) return {};

  var startObj = objectIdWithTimestamp(ISODate(startDay + "T00:00:00.000Z"));
  var queryParams = {$and: [
    {_id: {$gte: startObj}},
    {'event': {$in: activeUserEvents}}
  ]};
  var cursor = logDB['log'].find(queryParams);

  var dayUserMap = {};
  while (cursor.hasNext()) {
    var doc = cursor.next();
    var created = doc._id.getTimestamp().toISOString();
    var day = created.substring(0, 10);
    var user = doc.user;

    if (!dayUserMap[day]) dayUserMap[day] = {};
    dayUserMap[day][user] = true;
  }
  // printjson(dayUserMap['2015-11-01']);

  var activeUsersCounts = {};
  var monthlyActives = [];
  for (day in dayUserMap) {
    activeUsersCounts[day] = {'Daily Active Users': Object.keys(dayUserMap[day]).length};
    monthlyActives.push({day: day, users: dayUserMap[day]});
  }

  monthlyActives.sort(function (a, b) {return a.day.localeCompare(b.day);});

  // Calculate monthly actives for each day, starting when we have enough data
  for (var i = daysInMonth - 1; i < monthlyActives.length; i++) {
    var monthUserMap = {};
    for (var j = i - daysInMonth + 1; j <= i; j++) {
      for (var user in monthlyActives[j].users) {
        monthUserMap[user] = true;
      }
    }
    activeUsersCounts[monthlyActives[i].day]['Monthly Active Users'] = Object.keys(monthUserMap).length;
  }
  return activeUsersCounts;
}

function insertEventCount(event, day, count) {
  // analytics.perdays schema in server/analytics/AnalyticsPeryDay.coffee
  day = day.replace(/-/g, '');

  var eventID = getAnalyticsString(event);
  var filterID = getAnalyticsString('all');

  var startObj = objectIdWithTimestamp(ISODate(startDay + "T00:00:00.000Z"));
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

function insertLevelEventCount(event, level, day, count) {
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
