// Print out level completion rates

// Usage:
// mongo <address>:<port>/<database> <script file> -u <username> -p <password>

// Bucketize start/finish events into days, then bucketize into levels?

// TODO: Why do a small number of 'Started level' not have properties.levelID set?

// TODO: spot check the data: NaN, only some 0.0 dates, etc.
// TODO: exclude levels with no interesting data?

// TODO: average playtime?

var today = new Date();
today = today.toISOString().substr(0, 10);
print("Today is " + today);

var todayMinus6 = new Date();
todayMinus6.setDate(todayMinus6.getUTCDate() - 6);
var startDate = todayMinus6.toISOString().substr(0, 10) + "T00:00:00.000Z";
print("Start date is " + startDate)

var match={
  "$match" : {
    $and: [
    {"created": { $gte: ISODate(startDate)}},
    {$or: [ {"properties.level": {$exists: true}}, {"properties.levelID": {$exists: true}}]},
    {$or: [ {"event" : 'Started Level'}, {"event" : 'Saw Victory'}]}
    ]
  }
};

// TODO: project level to level slug

var proj0 = {"$project": {
  "_id" : 0,
  "event" : 1,
  "level" : { $ifNull : ["$properties.level", "$properties.levelID"]},
  "created": { "$concat": [{"$substr" :  ["$created", 0, 4]}, "-", {"$substr" :  ["$created", 5, 2]}, "-", {"$substr" :  ["$created", 8, 2]}]}
}};

// var proj0={"$project" : {
//   "_id" : 0,
//   "event" : 1,
//   "created" : 1,
//   "level" : "$properties.level",
//   "h" : {"$hour" : "$created"},
//   "m" : {"$minute" : "$created"},
//   "s" : {"$second" : "$created"},
//   "ml" : {"$millisecond" : "$created"}
// }};

// var proj1={"$project" : {
//   "_id" : 0,
//   "created" : 1,
//   "event" : 1,
//   "level" : 1,
//   "h" : {"$hour" : "$created"},
//   "m" : {"$minute" : "$created"},
//   "s" : {"$second" : "$created"},
//   "ml" : {"$millisecond" : "$created"}
// }};
// 
// var proj2={"$project" : {
//   "_id" : 0,
//   "event" : 1,
//   "level" : 1,
//   "created" : {
//     "$subtract" : [
//     "$created",
//     {"$add" : ["$ml",{"$multiply" : ["$s", 1000]}, {"$multiply" : ["$m",60,1000]}, {"$multiply" : ["$h",60,60,1000]}]}
//     ]}
// }};

var group={"$group" : {
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
var longestLevelName = -1;
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
var dates = [];
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

// Print out all data
for (levelKey in levelRates) {
  for (dateKey in levelRates[levelKey]) {
    var created = levelRates[levelKey][dateKey].created;
    var level = levelRates[levelKey][dateKey].level;
    var started = levelRates[levelKey][dateKey].started;
    var finished = levelRates[levelKey][dateKey].finished;
    var rate = finished / started;
    var levelSpacer = new Array(longestLevelName - level.length).join(' ');
    print(level + levelSpacer + created + "\t" + started + "\t" + finished + "\t" + (finished / started * 100).toFixed(2) + "%");
    // print(levelRates[key].level + "\t" + started + "\t" + finished + "\t" + (levelRates[key].rate * 100).toFixed(2) + "%");
  }
}

// Print out a nice grid of levels with 7 days of data
print(new Array(longestLevelName).join(' ') + dates.join('\t'));
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
    var rate = finished / started;
    msg += (finished / started * 100).toFixed(2) + "\t";
    // print(level + levelSpacer + started + "\t" + finished + "\t" + (finished / started * 100).toFixed(2) + "%");
    // print(levelRates[key].level + "\t" + started + "\t" + finished + "\t" + (levelRates[key].rate * 100).toFixed(2) + "%");
  }
  print(msg);
}
