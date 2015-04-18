// Analyze sub purchase decisions via user event histories

// Usage:
// mongo <address>:<port>/analytics <script file> -u <username> -p <password>

// NOTES
// Starting from beginning wasn't as interesting at looking at 20 events or so before and after purchase
//

// TODO: Group events: clicked level, inventory play, started level => started level X
// TODO: What event-specific data should we grab?
// TODO: How do we compare users?

var scriptStartTime = new Date();

try {
  var analyticsStringCache = {};
  var analyticsStringIDCache = {};

  var numSubscribers = 30;
  var beforeCount = 20;
  var afterCount = 10;

  var excludedEvents = ['Inventory Play'];

  var subscribers = getSubscribers(numSubscribers);
  log("Retrieved subscribers: " + subscribers.length);

  var histories = getHistories(subscribers, excludedEvents, beforeCount, afterCount);

  for(var user in histories) {
    print(user + " " + histories[user].length);
    for (var i = 0; i < histories[user].length; i++) {
      print(histories[user][i].created + " " +  i + " " + histories[user][i].event + " " + histories[user][i].level);
    }
  }

}
catch(err) {
  log("ERROR: " + err);
  printjson(err);
}
finally {
  log("Script runtime: " + (new Date() - scriptStartTime));
}

// *** Helper functions ***

function log(str) {
  print(new Date().toISOString() + " " + str);
}

function getSubscribers(count) {
  if (!count || count < 1) return [];

  var queryParams = {event: 'Finished subscription purchase'};
  var cursor = db['log'].find(queryParams).sort({_id: -1}).limit(count);

  var subscribers = [];
  while (cursor.hasNext()) {
    var doc = cursor.next();
    // if (doc.user !== '5491a42c037fb13f0741dac5') continue;
    subscribers.push({created: doc._id, userID: doc.user});
  }
  return subscribers;
}

function getHistories(subscribers, excludedEvents, beforeCount, afterCount) {
  if (!subscribers) return {};

  var userEventsMap = {};
  for (var i = 0; i < subscribers.length; i++) {
    var subscriber = subscribers[i];
    var user = subscriber.userID.valueOf();
    userEventsMap[user] = [];

    var queryParams = {$and: [{_id: {$lte: subscriber.created}},{user: subscriber.userID}]};
    var cursor = db['log'].find(queryParams).sort({_id: -1}).limit(beforeCount);

    while (cursor.hasNext()) {
      var doc = cursor.next();
      var created = doc._id.getTimestamp().toISOString();
      var event = doc.event;

      if (excludedEvents.indexOf(event) >= 0) continue;

      var properties = doc.properties;
      var level = '';
      if (properties) {
        level = properties.levelID || properties.level || '';
        if (properties.label) {
          level += ' ' + properties.label;
        }
      }
      userEventsMap[user].push({event: event, created: created, level: level});
    }
    userEventsMap[user].sort(function (a,b) {return a.created < b.created ? -1 : 1});

    queryParams = {$and: [{_id: {$gt: subscriber.created}},{user: subscriber.userID}]};
    cursor = db['log'].find(queryParams).sort({_id: 1}).limit(afterCount);

    while (cursor.hasNext()) {
      var doc = cursor.next();
      var created = doc._id.getTimestamp().toISOString();
      var event = doc.event;

      if (excludedEvents.indexOf(event) >= 0) continue;
      var properties = doc.properties;
      var level = '';
      if (properties) {
        level = properties.levelID || properties.level || '';
        if (properties.label) {
          level += ' ' + properties.label;
        }
      }
      userEventsMap[user].push({event: event, created: created, level: level});
    }
  }

  return userEventsMap;
}
