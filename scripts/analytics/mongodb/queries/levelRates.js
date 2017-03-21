// Print out level completion rates

// Usage:
// mongo <address>:<port>/<database> <script file> -u <username> -p <password>

// Bucketize start/finish events into days, then bucketize into levels
// Average playtime: level sessions created in timeframe, state.complete = true, then average 'playtime'

// TODO: Should this be total code problems / levels finished, or total / level session count instead?
// Average code problems: total code problems / levels staretd

// TODO: Why do a small number of 'Started level' not have properties.levelID set?

// TODO: Fix addPlaytimeAverages() and addUserCodeProblemCounts()
// TODO: getLevelFunnelData() outputs different data structure now.

var startTime = new Date();

var today = new Date();
today = today.toISOString().substr(0, 10);
print("Today is " + today);

// var todayMinus6 = new Date();
// todayMinus6.setUTCDate(todayMinus6.getUTCDate() - 6);
// var startDate = todayMinus6.toISOString().substr(0, 10) + "T00:00:00.000Z";
// startDate = "2015-01-23T00:00:00.000Z";
// print("Start date is " + startDate)
// var endDate = "2015-01-24T00:00:00.000Z";
// print("End date is " + endDate)

var levelCompletionFunnel = ['Started Level', 'Saw Victory'];
var dataStartDay = "2015-01-15";
var startDay = "2015-01-23";
var endDay = "2015-01-24";
print(startDay + " to " + endDay);
print("Data start day " + dataStartDay);

var targetLevels = ['dungeons-of-kithgard'];

function objectIdWithTimestamp(timestamp)
{
  // Convert string date to Date object (otherwise assume timestamp is a date)
  if (typeof(timestamp) == 'string') timestamp = new Date(timestamp);
  // Convert date object to hex seconds since Unix epoch
  var hexSeconds = Math.floor(timestamp/1000).toString(16);
  // Create an ObjectId with that hex timestamp
  var constructedObjectId = ObjectId(hexSeconds + "0000000000000000");
  return constructedObjectId
}

function getLevelFunnelData(startDay, endDay, eventFunnel) {
  // Copied from insertPerDayAnalytics.js
  if (!startDay || !eventFunnel || eventFunnel.length === 0) return {};

  // var startObj = objectIdWithTimestamp(ISODate(startDay + "T00:00:00.000Z"));
  var startObj = objectIdWithTimestamp(ISODate(dataStartDay + "T00:00:00.000Z"));
  var endObj = objectIdWithTimestamp(ISODate(endDay + "T00:00:00.000Z"));
  var queryParams = {$and: [{_id: {$gte: startObj}},{_id: {$lt: endObj}},{"event": {$in: eventFunnel}}]};
  // var queryParams = {$and: [{user: ObjectId("539c630f30a67c3b05d98d95")},{_id: {$gte: startObj}},{_id: {$lt: endObj}},{"event": {$in: eventFunnel}}]};
  var cursor = db['analytics.log.events'].find(queryParams);

  // Map ordering: level, user, event, day
  var recordCount = 0;
  var duplicates = {};
  var levelEventUserDayMap = {};
  var levelUserEventDayMap = {};
  while (cursor.hasNext()) {
    recordCount++;
    var doc = cursor.next();
    var created = doc._id.getTimestamp().toISOString();
    var day = created.substring(0, 10);
    var event = doc.event;
    var properties = doc.properties;
    var user = doc.user;
    var level;

    // TODO: Switch to properties.levelID for 'Saw Victory'
    if (event === 'Saw Victory' && properties.level) level = properties.level.toLowerCase().replace(/ /g, '-');
    else if (properties.levelID) level = properties.levelID
    else continue

    // if (targetLevels.indexOf(level) < 0) continue;

    // print(day + " " + created);
    // print(JSON.stringify(doc, null, 2));

    if (level.length > longestLevelName) longestLevelName = level.length;

    if (!levelUserEventDayMap[level]) levelUserEventDayMap[level] = {};
    if (!levelUserEventDayMap[level][user]) levelUserEventDayMap[level][user] = {};
    if (levelUserEventDayMap[level][user][event]) {
      if (!duplicates[event]) duplicates[event] = 0;
      duplicates[event]++;
    }
    if (!levelUserEventDayMap[level][user][event] || levelUserEventDayMap[level][user][event].localeCompare(day) > 0) {
    // if (!levelUserEventDayMap[level][user][event] || day.localeCompare(levelUserEventDayMap[level][user][event]) > 0) {
      // day is earlier than levelUserEventDayMap[level][user][event]
      levelUserEventDayMap[level][user][event] = day;
    }

    if (!levelEventUserDayMap[level]) levelEventUserDayMap[level] = {};
    if (!levelEventUserDayMap[level][event]) levelEventUserDayMap[level][event] = {};
    if (!levelEventUserDayMap[level][event][user] || levelEventUserDayMap[level][event][user].localeCompare(day) > 0) {
      levelEventUserDayMap[level][event][user] = day;
    }
  }

  // print("Records: " + recordCount);
  // print("Duplicates");
  // print(JSON.stringify(duplicates, null, 2));
  longestLevelName += 2;

  // Data: level, day, event
  var noStartDayUsers = [];
  var levelFunnelData = {};
  for (level in levelUserEventDayMap) {
    for (user in levelUserEventDayMap[level]) {

      // Find first event date
      var funnelStartDay = null;
      for (event in levelUserEventDayMap[level][user]) {
        var day = levelUserEventDayMap[level][user][event];
        if (day.localeCompare(startDay) < 0) {
          // day earlier than startDay
          continue;
        }
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
        for (event in levelUserEventDayMap[level][user]) {
          if (!levelFunnelData[level][funnelStartDay][event]) levelFunnelData[level][funnelStartDay][event] = 0;
          if (eventFunnel[0] != event) levelFunnelData[level][funnelStartDay][event]++;
        }
        // Zero remaining funnel events
        for (var i = 1; i < eventFunnel.length; i++) {
          var event = eventFunnel[i];
          if (!levelFunnelData[level][funnelStartDay][event]) levelFunnelData[level][funnelStartDay][event] = 0;
        }
      }
      else {
        // TODO: calc no start days
        for (event in levelUserEventDayMap[level][user]) {
          var day = levelUserEventDayMap[level][user][event];
          if (day.localeCompare(startDay) < 0) {
            // day earlier than startDay
            continue;
          }
          if (eventFunnel[0] != event) {
            noStartDayUsers.push(user);
          }
        }
      }
    }
  }

  // print("No start day count: " + noStartDayUsers.length);
  // for (var i = 0; i < noStartDayUsers.length && i < 50; i++) {
  //   print(noStartDayUsers[i]);
  // }

  return levelFunnelData;
}

function addPlaytimeAverages(startDay, endDay, levelRates) {
  print("Getting playtimes...");
  var startObj = objectIdWithTimestamp(ISODate(dataStartDay + "T00:00:00.000Z"));
  var endObj = objectIdWithTimestamp(ISODate(endDay + "T00:00:00.000Z"));
  // var match = {"$match" : {$and: [{_id: { $gte: startObj}}, {_id: { $lt: endObj}}]}};
  var match = {
    "$match" : {
      $and: [
      {_id: { $gte: startObj}},
      {_id: { $lt: endObj}},
      {"state.complete": true},
      {"playtime": {$gt: 0}}
      ]
  }};

  var proj0 = {"$project": {
    "_id" : 0,
    "levelID" : 1,
    "playtime": 1,
    "day": {"$substr" :  ["$created", 0, 10]}
  }};

  var group = {"$group" : {
    "_id" : {
      "day" : "$day",
      "level": "$levelID"
    },
    "average" : {
      "$avg" : "$playtime"
    }
  }};

  var cursor = db['level.sessions'].aggregate(match, proj0, group);

  var levelPlaytimeData = {};
  while (cursor.hasNext()) {
    var doc = cursor.next();
    var day = doc._id.day;
    var level = doc._id.level;
    if (!levelPlaytimeData[level]) levelPlaytimeData[level] = {};
    levelPlaytimeData[level][day] = doc.average;
  }

  for (levelIndex in levelRates) {
    for (dateIndex in levelRates[levelIndex]) {
      var level = levelRates[levelIndex][dateIndex].level;
      var day = levelRates[levelIndex][dateIndex].day;
      if (levelPlaytimeData[level] && levelPlaytimeData[level][day]) {
        levelRates[levelIndex][dateIndex].averagePlaytime = levelPlaytimeData[level][day];
      }
    }
  }
}

function addUserCodeProblemCounts(startDay, endDay, levelRates) {
  print("Getting user code problem counts...");
  var startObj = objectIdWithTimestamp(ISODate(dataStartDay + "T00:00:00.000Z"));
  var endObj = objectIdWithTimestamp(ISODate(endDay + "T00:00:00.000Z"));
  var match = {"$match" : {$and: [{_id: { $gte: startObj}}, {_id: { $lt: endObj}}]}};

  var proj0 = {"$project": {
    "_id" : 0,
    "levelID" : 1,
    "day": {"$substr" :  ["$created", 0, 10]}
  }};

  var group = {"$group" : {
    "_id" : {
      "day" : "$day",
      "level": "$levelID"
    },
    "count" : {
      "$sum" : 1
    }
  }};

  var cursor = db['level.sessions'].aggregate(match, proj0, group);

  var levelPlaytimeData = {};
  while (cursor.hasNext()) {
    var doc = cursor.next();
    var day = doc._id.day;
    var level = doc._id.level;
    if (!levelPlaytimeData[level]) levelPlaytimeData[level] = {};
    levelPlaytimeData[level][day] = doc.count;
  }

  for (levelIndex in levelRates) {
    for (dateIndex in levelRates[levelIndex]) {
      var level = levelRates[levelIndex][dateIndex].level;
      var day = levelRates[levelIndex][dateIndex].day;
      if (levelPlaytimeData[level] && levelPlaytimeData[level][day]) {
        levelRates[levelIndex][dateIndex].codeProblems = levelPlaytimeData[level][day];
      }
    }
  }
}

var longestLevelName = -1;
var dates = [];

var levelRates = getLevelFunnelData(startDay, endDay, levelCompletionFunnel);
// addPlaytimeAverages(startDay, endDay, levelRates);
// addUserCodeProblemCounts(startDay, endDay, levelRates);

// print(JSON.stringify(levelRates, null, 2))

// Print out all data
// print("Columns: level, day, started, finished, completion rate, average finish playtime, average code problem count");
print("Columns: level, day, started, finished, completion rate");
for (levelKey in levelRates) {
  for (dateKey in levelRates[levelKey]) {
    // var day = levelRates[levelKey][dateKey].day;
    // var level = levelRates[levelKey][dateKey].level;
    // var started = levelRates[levelKey][dateKey].started;
    // var finished = levelRates[levelKey][dateKey].finished;
    var started = levelRates[levelKey][dateKey][levelCompletionFunnel[0]] || 0;
    var finished = levelRates[levelKey][dateKey][levelCompletionFunnel[levelCompletionFunnel.length - 1]] || 0;
    var completionRate = started > 0 ? finished / started : 0;
    // var averagePlaytime = levelRates[levelKey][dateKey].averagePlaytime;
    // averagePlaytime = averagePlaytime ? Math.round(averagePlaytime) : 0;
    // var averageCodeProblems = levelRates[levelKey][dateKey].codeProblems;
    // averageCodeProblems = averageCodeProblems ? (averageCodeProblems / started).toFixed(2) : 0.0;
    if ((longestLevelName - levelKey.length) < 0)
      throw new Error(longestLevelName + " " + levelKey.length);
    var levelSpacer = new Array(longestLevelName - levelKey.length).join(' ');
    // print(levelKey + levelSpacer + dateKey + "\t" + started + "\t" + finished + "\t" + (completionRate * 100).toFixed(2) + "% " + averagePlaytime + "s " + averageCodeProblems);
    print(levelKey + levelSpacer + dateKey + "\t" + started + "\t" + finished + "\t" + (completionRate * 100).toFixed(2) + "%");
  }
}

// Print out a nice grid of levels with 7 days of data
// print("Columns: level, completion rate/average playtime/average code problems, completion rate/average playtime/average code problems ...");
// print(new Array(longestLevelName).join(' ') + dates.join('\t\t'));
// for (levelKey in levelRates) {
//   var hasStarted = false;
//   for (dateKey in levelRates[levelKey]) {
//     if (levelRates[levelKey][dateKey].started > 0) {
//       hasStarted = true;
//       break;
//     }
//   }
//   if (!hasStarted) continue;
//
//   if (levelRates[levelKey].length < 6) continue;
//
//   var level = levelRates[levelKey][0].level;
//   var levelSpacer = new Array(longestLevelName - level.length).join(' ');
//   var msg = level + levelSpacer;
//
//   for (dateKey in levelRates[levelKey]) {
//     var day = levelRates[levelKey][dateKey].day;
//     var started = levelRates[levelKey][dateKey].started;
//     var finished = levelRates[levelKey][dateKey].finished;
//     var averagePlaytime = levelRates[levelKey][dateKey].averagePlaytime;
//     averagePlaytime = averagePlaytime ? Math.round(averagePlaytime) : 0;
//     var averageCodeProblems = levelRates[levelKey][dateKey].codeProblems;
//     averageCodeProblems = averageCodeProblems ? averageCodeProblems / started : 0.0;
//     var completionRate = started > 0 ? finished / started : 0;
//     msg += (completionRate * 100).toFixed(2) + "/" + averagePlaytime + "/" + averageCodeProblems.toFixed(2) + "\t";
//   }
//   print(msg);
// }

var endTime = new Date();
print("Runtime: " + (endTime - startTime));
