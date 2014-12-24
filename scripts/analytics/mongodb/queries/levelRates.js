// Print out level completion rates

// Usage:
// mongo <address>:<port>/<database> <script file> -u <username> -p <password>

// Bucketize start/finish events into days, then bucketize into levels
// Average playtime: level sessions created in timeframe, state.complete = true, then average 'playtime'

// TODO: Why do a small number of 'Started level' not have properties.levelID set?

// TODO: spot check the data: NaN, only some 0.0 dates, etc.
// TODO: exclude levels with no interesting data?

// TODO: User code problem rate: average count.

var today = new Date();
today = today.toISOString().substr(0, 10);
print("Today is " + today);

var todayMinus6 = new Date();
todayMinus6.setDate(todayMinus6.getUTCDate() - 6);
var startDate = todayMinus6.toISOString().substr(0, 10) + "T00:00:00.000Z";
print("Start date is " + startDate)

function getCompletionRates() {
  print("Getting completion rates...");
  var match = {
    "$match" : {
      $and: [
      {"created": { $gte: ISODate(startDate)}},
      {$or: [ {"properties.level": {$exists: true}}, {"properties.levelID": {$exists: true}}]},
      {$or: [ {"event" : 'Started Level'}, {"event" : 'Saw Victory'}]}
      ]
    }
  };

  var proj0 = {"$project": {
    "_id" : 0,
    "event" : 1,
    "level" : { $ifNull : ["$properties.level", "$properties.levelID"]},
    "created": { "$concat": [{"$substr" :  ["$created", 0, 4]}, "-", {"$substr" :  ["$created", 5, 2]}, "-", {"$substr" :  ["$created", 8, 2]}]}
  }};

  var group = {"$group" : {
    "_id" : {
      "event" : "$event",
      "created" : "$created",
      "level": "$level"
    },
    "count" : {
      "$sum" : 1
    }
  }};

  // TODO: sort by level, date, 
  // var sort = {$sort: { "_id.level" : 1, "_id.created" : -1}};
  //var cursor = db['analytics.log.events'].aggregate(match, proj0, proj1, proj2, group, sort);
  // var cursor = db['analytics.log.events'].aggregate(match, proj0, group, sort);
  var cursor = db['analytics.log.events'].aggregate(match, proj0, group);

  // <level><date><data>
  var levelData = {};
  while (cursor.hasNext()) {
    var doc = cursor.next();
    var created = doc._id.created;
    var event = doc._id.event;
    var level = doc._id.level;
    
    if (event === 'Saw Victory') level = level.toLowerCase().replace(/ /g, '-');
    if (level.length > longestLevelName) longestLevelName = level.length;
    if (!levelData[level]) levelData[level] = {};
    if (!levelData[level][created]) levelData[level][created] = {};
    if (event === 'Started Level') levelData[level][created]['started'] = doc.count;
    else levelData[level][created]['finished'] = doc.count;
  }
  longestLevelName += 2;

  var levelRates = [];
  for (level in levelData) {
    var dateData = [];
    var dateIndex = 0;
    for (created in levelData[level]) {
      dateData.push({
        level: level,
        created: created,
        started: levelData[level][created]['started'] ? levelData[level][created]['started'] : 0,
        finished: levelData[level][created]['finished'] ? levelData[level][created]['finished'] : 0
      });
      if (dates.length === dateIndex) dates.push(created.substring(5));
      dateIndex++;
    }
    levelRates.push(dateData);
  }
  // printjson(levelRates);

  levelRates.sort(function(a,b) {return a[0].level < b[0].level ? -1 : 1});
  for (levelKey in levelRates) levelRates[levelKey].sort(function(a,b) {return a.created < b.created ? 1 : -1});
  
  return levelRates;
}

function addPlaytimeAverages(levelRates) {
  print("Getting playtimes...");
  // printjson(levelRates);
  var match = {
    "$match" : {
      $and: [
      {"created": { $gte: ISODate(startDate)}},
      {"state.complete": true},
      {"playtime": {$gt: 0}}
      ]
  }};

  var proj0 = {"$project": {
    "_id" : 0,
    "levelID" : 1,
    "playtime": 1,
    "created": { "$concat": [{"$substr" :  ["$created", 0, 4]}, "-", {"$substr" :  ["$created", 5, 2]}, "-", {"$substr" :  ["$created", 8, 2]}]}
  }};

  var group = {"$group" : {
    "_id" : {
      "created" : "$created",
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
    var created = doc._id.created;
    var level = doc._id.level;
    
    if (!levelPlaytimeData[level]) levelPlaytimeData[level] = {};
    levelPlaytimeData[level][created] = doc.average;
  }
  // printjson(levelPlaytimeData);

  for (levelIndex in levelRates) {
    for (dateIndex in levelRates[levelIndex]) {
      var level = levelRates[levelIndex][dateIndex].level;
      var created = levelRates[levelIndex][dateIndex].created;
      if (levelPlaytimeData[level] && levelPlaytimeData[level][created]) {
        levelRates[levelIndex][dateIndex].averagePlaytime = levelPlaytimeData[level][created];
      }
    }
  }
}

var longestLevelName = -1;
var dates = [];

var levelRates = getCompletionRates();
// print("Before addPlaytimeAverages");
// printjson(levelRates);
addPlaytimeAverages(levelRates);
// print("After addPlaytimeAverages");
// printjson(levelRates);

// Print out all data
print("Columns: level, day, started, finished, completion rate, average finish playtime");
for (levelKey in levelRates) {
  for (dateKey in levelRates[levelKey]) {
    var created = levelRates[levelKey][dateKey].created;
    var level = levelRates[levelKey][dateKey].level;
    var started = levelRates[levelKey][dateKey].started;
    var finished = levelRates[levelKey][dateKey].finished;
    var completionRate = finished / started;
    var averagePlaytime = levelRates[levelKey][dateKey].averagePlaytime;
    var levelSpacer = new Array(longestLevelName - level.length).join(' ');
    print(level + levelSpacer + created + "\t" + started + "\t" + finished + "\t" + (finished / started * 100).toFixed(2) + "% " + (averagePlaytime ? Math.round(averagePlaytime) : -1) + "s");
  }
}

// Print out a nice grid of levels with 7 days of data
print("Columns: level, completion rate, average playtime, completion rate, average playtime, etc...");
print(new Array(longestLevelName).join(' ') + dates.join('\t\t'));
for (levelKey in levelRates) {
  var hasStarted = false;
  for (dateKey in levelRates[levelKey]) {
    if (levelRates[levelKey][dateKey].started > 0) {
      hasStarted = true;
      break;
    }
  }
  if (!hasStarted) continue;

  if (levelRates[levelKey].length < 7) continue;
  
  var level = levelRates[levelKey][0].level;
  var levelSpacer = new Array(longestLevelName - level.length).join(' ');
  var msg = level + levelSpacer;
  
  for (dateKey in levelRates[levelKey]) {
    var created = levelRates[levelKey][dateKey].created;
    var started = levelRates[levelKey][dateKey].started;
    var finished = levelRates[levelKey][dateKey].finished;
    var averagePlaytime = levelRates[levelKey][dateKey].averagePlaytime;
    var rate = finished / started;
    msg += (finished / started * 100).toFixed(2) + "\t" + (averagePlaytime ? Math.round(averagePlaytime) : -1) + "\t";
    // print(level + levelSpacer + started + "\t" + finished + "\t" + (finished / started * 100).toFixed(2) + "%");
    // print(levelRates[key].level + "\t" + started + "\t" + finished + "\t" + (levelRates[key].rate * 100).toFixed(2) + "%");
  }
  print(msg);
}
