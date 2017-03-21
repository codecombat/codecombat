// A/B test helper functions
// Loaded from ab*.js ab test result scripts
// Main APIs are getFunnelData() and printFunnelData()

// TODO: use levelSlugs in query if available
// TODO: Stop looking up testGroupNumber when test group data is available in analytics.log.events
// TODO: These are super slow, need to aggregate into analytics.perdays collection

var browserCountPrintThreshold = 1000;

var analyticsStringCache = {};
var analyticsStringIDCache = {};

// *** Helper functions ***

function log(str) {
  str = Array.prototype.slice.call(arguments).join(' ');
  print(new Date().toISOString() + " " + str);
}

function objectIdWithTimestamp(timestamp) {
  // Convert string date to Date object (otherwise assume timestamp is a date)
  if (typeof(timestamp) == 'string') timestamp = new Date(timestamp);
  // Convert date object to hex seconds since Unix epoch
  var hexSeconds = Math.floor(timestamp/1000).toString(16);
  // Create an ObjectId with that hex timestamp
  var constructedObjectId = ObjectId(hexSeconds + "0000000000000000");
  return constructedObjectId;
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

function getFunnelData(startDay, eventFunnel, testGroupFn, levelSlugs, logDB) {
  if (!startDay || !eventFunnel || eventFunnel.length === 0 || !testGroupFn) return {};

  // log('getFunnelData:');
  // log(startDay);
  // log(eventFunnel);

  var startObj = objectIdWithTimestamp(ISODate(startDay + "T00:00:00.000Z"));
  var queryParams = {$and: [{_id: {$gte: startObj}},{"event": {$in: eventFunnel}}]};
  var cursor = (logDB.log || db['analytics.log.events']).find(queryParams);

  log("Fetching events..");
  // Map ordering: level, user, event, day
  var levelUserEventMap = {};
  var levelSessions = [];
  var users = [];
  var eventsCounted = 0;
  while (cursor.hasNext()) {
    var doc = cursor.next();
    var created = doc._id.getTimestamp().toISOString();
    var day = created.substring(0, 10);
    var event = doc.event;
    var properties = doc.properties;
    var user = doc.user.valueOf();
    var level = 'n/a';
    var ls = null;
    if (eventsCounted++ % 10000 == 0)
      log("Counted", eventsCounted, "events, up to", created);

    // TODO: Switch to properties.levelID for 'Saw Victory'
    if (event === 'Saw Victory' && properties.level) level = properties.level.toLowerCase().replace(/ /g, '-');
    else if (properties.levelID) level = properties.levelID;

    if (levelSlugs && levelSlugs.indexOf(level) < 0) continue;

    if (properties && properties.ls) {
      ls = properties.ls.valueOf();
      levelSessions.push(properties.ls);
    }

    users.push(ObjectId(user));

    if (!levelUserEventMap[level]) levelUserEventMap[level] = {};
    if (!levelUserEventMap[level][user]) levelUserEventMap[level][user] = {};
    if (!levelUserEventMap[level][user][event]
      || levelUserEventMap[level][user][event]['day'].localeCompare(day) > 0) {
      levelUserEventMap[level][user][event] = {day: day};
      if (ls) {
        levelUserEventMap[level][user][event]['ls'] = ls;
      }
    }
  }
  // printjson(levelUserEventMap);
  // printjson(users);

  log("Fetching users..");
  var userGroupMap = {};
  var groupSubscribedMap = {};
  var countedSubscriberMap = {};
  for (var userOffset = 0; userOffset < users.length; userOffset += 1000) {
    cursor = db['users'].find({_id : {$in: users.slice(userOffset, userOffset + 1000)}});
    while (cursor.hasNext()) {
      var doc = cursor.next();
      var user = doc._id.valueOf();
      userGroupMap[user] = group = testGroupFn(doc.testGroupNumber);
      if (!countedSubscriberMap[doc._id + ''] &&
          doc.created >= ISODate(startDay + "T00:00:00.000Z") &&
          doc.stripe &&
          doc.stripe.customerID &&
          doc.purchased &&
          doc.purchased.gems &&
          !doc.stripe.free
        ) {
          countedSubscriberMap[doc._id + ''] = true;
          groupSubscribedMap[group] = (groupSubscribedMap[group] || 0) + 1;
        }
    }
    log("Fetched", Math.min(userOffset, users.length), "users");
  }
  // printjson(userGroupMap);

  log("Fetching level sessions..");
  var lsBrowserMap = {};
  var userBrowserMap = {};
  for (var sessionOffset = 0; sessionOffset < levelSessions.length; sessionOffset += 1000) {
    cursor = db['level.sessions'].find({_id : {$in: levelSessions.slice(sessionOffset, sessionOffset + 1000)}});
    while (cursor.hasNext()) {
      var doc = cursor.next();
      var user = doc._id.valueOf();
      var browser = doc.browser;
      var browserInfo = '';
      if (browser && browser.platform) {
        browserInfo += browser.platform;
      }
      if (browser && browser.name) {
        browserInfo += browser.name;
      }
      if (browserInfo.length > 0) {
        lsBrowserMap[doc._id.valueOf()] = browserInfo;
        userBrowserMap[user] = browserInfo;
      }
    }
    log("Fetched", Math.min(sessionOffset, levelSessions.length), "sessions");
  }
  // printjson(lsBrowserMap);

  log("Mapping data..");
  // Data: level, day, event
  var levelDayGroupBrowserEventMap = {};
  for (level in levelUserEventMap) {
    for (user in levelUserEventMap[level]) {
      var group = userGroupMap[user];
      var browser = userBrowserMap[user] || 'unknown';

      // Find first event date
      var funnelStartDay = null;
      var funnelStartBrowser = null;
      for (event in levelUserEventMap[level][user]) {
        var day = levelUserEventMap[level][user][event]['day'];
        var ls = levelUserEventMap[level][user][event]['ls'];
        if (lsBrowserMap[ls]) {
          browser = lsBrowserMap[ls];
        }
        if (!levelDayGroupBrowserEventMap[level]) levelDayGroupBrowserEventMap[level] = {};
        if (!levelDayGroupBrowserEventMap[level][day]) levelDayGroupBrowserEventMap[level][day] = {};
        if (!levelDayGroupBrowserEventMap[level][day][group]) levelDayGroupBrowserEventMap[level][day][group] = {};
        if (!levelDayGroupBrowserEventMap[level][day][group][browser]) {
          levelDayGroupBrowserEventMap[level][day][group][browser] = {};
        }
        if (!levelDayGroupBrowserEventMap[level][day][group][browser][event]) {
          levelDayGroupBrowserEventMap[level][day][group][browser][event] = 0;
        }
        if (eventFunnel[0] === event) {
          // First event gets attributed to current date
          levelDayGroupBrowserEventMap[level][day][group][browser][event]++;
          funnelStartDay = day;
          funnelStartBrowser = browser;
          break;
        }
      }

      if (funnelStartDay) {
        // Add remaining funnel steps/events to first step's date
        for (event in levelUserEventMap[level][user]) {
          if (!levelDayGroupBrowserEventMap[level][funnelStartDay][group][funnelStartBrowser]) {
            levelDayGroupBrowserEventMap[level][funnelStartDay][group][funnelStartBrowser] = {};
          }
          if (!levelDayGroupBrowserEventMap[level][funnelStartDay][group][funnelStartBrowser][event]) {
            levelDayGroupBrowserEventMap[level][funnelStartDay][group][funnelStartBrowser][event] = 0;
          }
          if (eventFunnel[0] !== event) {
            levelDayGroupBrowserEventMap[level][funnelStartDay][group][funnelStartBrowser][event]++;
          }
        }
        // Zero remaining funnel events
        for (var i = 1; i < eventFunnel.length; i++) {
          var event = eventFunnel[i];
          if (!levelDayGroupBrowserEventMap[level][funnelStartDay][group][funnelStartBrowser][event]) {
            levelDayGroupBrowserEventMap[level][funnelStartDay][group][funnelStartBrowser][event] = 0;
          }
          if (!levelDayGroupBrowserEventMap[level][funnelStartDay][group][funnelStartBrowser][event]) {
            levelDayGroupBrowserEventMap[level][funnelStartDay][group][funnelStartBrowser][event] = 0;
          }
        }
      }
      // Else no start event in this date range
    }
  }
  // printjson(levelDayGroupBrowserEventMap);

  log("Building results..");
  var funnelData = [];
  for (level in levelDayGroupBrowserEventMap) {
    for (day in levelDayGroupBrowserEventMap[level]) {
      for (group in levelDayGroupBrowserEventMap[level][day]) {
        for (browser in levelDayGroupBrowserEventMap[level][day][group]) {
          var started = 0;
          var finished = 0;
          for (event in levelDayGroupBrowserEventMap[level][day][group][browser]) {
            if (event === eventFunnel[0]) {
              started = levelDayGroupBrowserEventMap[level][day][group][browser][event];
            }
            else if (event === eventFunnel[eventFunnel.length - 1]) {
              finished = levelDayGroupBrowserEventMap[level][day][group][browser][event];
            }
          }
          funnelData.push({
            level: level,
            day: day,
            group: group,
            browser: browser,
            started: started,
            finished: finished
          });
        }
      }
    }
  }

  log("Sorting results..");
  funnelData.sort(function (a,b) {
    if (a.level !== b.level) {
      return a.level < b.level ? -1 : 1;
    }
    else if (a.day !== b.day) {
      return a.day < b.day ? -1 : 1;
    }
    else if (a.browser !== b.browser) {
      return a.browser < b.browser ? -1 : 1;
    }
    return a.group < b.group ? -1 : 1;
  });

  log("Subscribers by group:", JSON.stringify(groupSubscribedMap, null, 2));

  return funnelData;
}

function printFunnelData(funnelData, printFn) {
  log("Day\t\tGroup\t\tStarted\tFinished\tCompletion Rate");
  var levelBrowserGroupCounts = {};
  var levelGroupCounts = {};
  var groupCounts = {};
  for (var i = 0; i < funnelData.length; i++) {
    var level = funnelData[i].level;
    var day = funnelData[i].day;
    var browser = funnelData[i].browser;
    var group = funnelData[i].group;
    var started = funnelData[i].started;
    var finished = funnelData[i].finished;
    var rate = started > 0 ? finished / started * 100 : 0.0;
    printFn(day, level, browser, group, started, finished, rate);

    if (!levelBrowserGroupCounts[level]) levelBrowserGroupCounts[level] = {};
    if (!levelBrowserGroupCounts[level][browser]) levelBrowserGroupCounts[level][browser] = {};
    if (!levelBrowserGroupCounts[level][browser][group]) {
      levelBrowserGroupCounts[level][browser][group] = {started: 0, finished: 0};
    }
    levelBrowserGroupCounts[level][browser][group]['started'] += started;
    levelBrowserGroupCounts[level][browser][group]['finished'] += finished;

    if (!levelGroupCounts[level]) levelGroupCounts[level] = {};
    if (!levelGroupCounts[level][group]) levelGroupCounts[level][group] = {started: 0, finished: 0};
    levelGroupCounts[level][group]['started'] += started;
    levelGroupCounts[level][group]['finished'] += finished;

    if (!groupCounts[group]) groupCounts[group] = {started: 0, finished: 0};
    groupCounts[group]['started'] += started;
    groupCounts[group]['finished'] += finished;
  }

  log("");
  log("Browser totals:");
  for (level in levelBrowserGroupCounts) {
    for (browser in levelBrowserGroupCounts[level]) {
      for (group in levelBrowserGroupCounts[level][browser]) {
        var started = levelBrowserGroupCounts[level][browser][group].started;
        if (started < browserCountPrintThreshold) continue;
        var finished = levelBrowserGroupCounts[level][browser][group].finished;
        var rate = started > 0 ? finished / started * 100 : 0.0;
        printFn(null, level, browser, group, started, finished, rate);
      }
    }
  }

  log("");
  log("Level totals:");
  for (level in levelGroupCounts) {
    for (group in levelGroupCounts[level]) {
      var started = levelGroupCounts[level][group].started;
      var finished = levelGroupCounts[level][group].finished;
      var rate = started > 0 ? finished / started * 100 : 0.0;
      printFn(null, level, null, group, started, finished, rate);
    }
  }

  log("");
  log("Group totals:");
  for (group in groupCounts) {
    var started = groupCounts[group].started;
    var finished = groupCounts[group].finished;
    var rate = started > 0 ? finished / started * 100 : 0.0;
    printFn(null, null, null, group, started, finished, rate);
  }
}
