// Help button and video usage

// Usage:
// mongo <address>:<port>/<database> <script file> -u <username> -p <password>

// What do we want to know?
// For each level, how many clicks, starts, finishes
// Individual users only counted once for a level/event combo

try {
  var scriptStartTime = new Date();
  var analyticsStringCache = {};

  // Look at last 30 days, same as Mixpanel
  var numDays = 30;

  var startDay = new Date();
  today = startDay.toISOString().substr(0, 10);
  startDay.setUTCDate(startDay.getUTCDate() - numDays);
  startDay = startDay.toISOString().substr(0, 10);

  log("Today is " + today);
  log("Start day is " + startDay);

  var events = ['Problem alert help clicked', 'Spell palette help clicked', 'Start help video', 'Finish help video'];

  var helpData = getHelpData(startDay, events);
  helpData.sort(function (a,b) {
    var clickedA = a['Problem alert help clicked'] || 0;
    clickedA += a['Spell palette help clicked'] || 0;
    var clickedB = b['Problem alert help clicked'] || 0;
    clickedB += b['Spell palette help clicked'] || 0;
    return clickedA < clickedB ? 1 : -1;
  });

  log('Help Clicks\tVideo Starts\tStart Rate\tVideo Finishes\tFinish Rate\tLevel')
  for(var i = 0; i < helpData.length; i++) {
    var level = helpData[i].level;
    var clicked = helpData[i]['Problem alert help clicked'] || 0;
    clicked += helpData[i]['Spell palette help clicked'] || 0;
    var started = helpData[i]['Start help video'] || 0;
    var startRate = clicked > 0 ? started / clicked * 100 : 0.0;
    var finished = helpData[i]['Finish help video'] || 0;
    var finishRate = clicked > 0 ? finished / clicked * 100 : 0.0;
    if (started > 1) {
      log(clicked + '\t' + started + '\t' + startRate.toFixed(2) + '%\t' + finished + '\t' + finishRate.toFixed(2) + '%\t' + level);
    }
  }

  log("Script runtime: " + (new Date() - scriptStartTime));
}
catch(err) {
  log("ERROR: " + err);
  printjson(err);
}

// *** Helper functions ***

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

  // TODO: Not sure we want to always insert strings here.
  // // Insert string
  // // http://docs.mongodb.org/manual/tutorial/create-an-auto-incrementing-field/#auto-increment-optimistic-loop
  // doc = {v: str};
  // while (true) {
  //   var cursor = db['analytics.strings'].find({}, {_id: 1}).sort({_id: -1}).limit(1);
  //   var seq = cursor.hasNext() ? cursor.next()._id + 1 : 1;
  //   doc._id = seq;
  //   var results = db['analytics.strings'].insert(doc);
  //   if (results.hasWriteError()) {
  //     if ( results.writeError.code == 11000 /* dup key */ ) continue;
  //     else throw new Error("ERROR: Unexpected error inserting data: " + tojson(results));
  //   }
  //   break;
  // }
  //
  // // Find new string entry
  // doc = db['analytics.strings'].findOne({v: str});
  // if (doc) {
  //   analyticsStringCache[str] = doc._id;
  //   return analyticsStringCache[str];
  // }
  throw new Error("ERROR: Did not find analytics.strings insert for: " + str);
}

function getHelpData(startDay, events) {
  if (!startDay || !events || events.length === 0) return {};

  var startObj = objectIdWithTimestamp(ISODate(startDay + "T00:00:00.000Z"));
  var queryParams = {$and: [{_id: {$gte: startObj}},{"event": {$in: events}}]};
  var cursor = db['analytics.log.events'].find(queryParams);

  // Map ordering: level, user, event
  var levelUserEventMap = {};
  while (cursor.hasNext()) {
    var doc = cursor.next();
    var created = doc._id.getTimestamp().toISOString();
    var event = doc.event;
    var user = doc.user.valueOf();
    var properties = doc.properties;
    var level = properties.level || properties.levelID;

    if (!levelUserEventMap[level]) levelUserEventMap[level] = {};
    if (!levelUserEventMap[level][user]) levelUserEventMap[level][user] = {};
    if (!levelUserEventMap[level][user][event]) levelUserEventMap[level][user][event] = 1;
  }
  // printjson(levelUserEventMap);

  // Data: level, event, count
  var levelEventMap = {};
  for (level in levelUserEventMap) {
    for (user in levelUserEventMap[level]) {
      for (event in levelUserEventMap[level][user]) {
        if (!levelEventMap[level]) levelEventMap[level] = {};
        if (!levelEventMap[level][event]) levelEventMap[level][event] = 0;
        levelEventMap[level][event] += levelUserEventMap[level][user][event];
      }
    }
  }
  // printjson(levelEventMap);

  helpData = [];
  for (level in levelEventMap) {
    var data = {level: level};
    for (event in levelEventMap[level]) {
      data[event] = levelEventMap[level][event];
    }
    for (var i = 0; i < events.length; i++) {
      if (!data[events[i]]) data[events[i]] = 0
    }
    helpData.push(data);
  }
  return helpData;
}
