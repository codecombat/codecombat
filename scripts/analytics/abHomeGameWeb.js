'use strict';
// Find % home users that navigated to web-dev, game-dev, or forest worlds first

// Find all events, sort by create time, grab oldest one for each user
// gd1 and wd1 added to world selector on 8/9/16

if (process.argv.length !== 3) {
  log("Usage: node <script> <mongo connection Url analytics>");
  log("Include ?readPreference=secondary in connection URLs");
  process.exit();
}

const scriptStartTime = new Date();
const co = require('co');
const MongoClient = require('mongodb').MongoClient;
const mongoose = require('mongoose');
const mongoConnUrlAnalytics = process.argv[2];
const debugOutput = true;
const startDay = "2016-11-10";
debug(`Start day ${startDay}`);

co(function*() {
  const analyticsDb = yield MongoClient.connect(mongoConnUrlAnalytics, {connectTimeoutMS: 1000 * 60 * 60, socketTimeoutMS: 1000 * 60 * 60});
  const startObjectId = objectIdWithTimestamp(new Date(`${startDay}T00:00:00.000Z`));
  debug(`Finding events..`);

  // User sanity check
  // db.log.find({user: '<user id>', event: 'Pageview', 'properties.url': {$in: ['play/campaign-game-dev-1', 'play/campaign-game-dev-1', 'play/forest']}}, {'properties.url': 1}).sort({_id: 1}).forEach(function(a) { print(a._id + " " + a._id.getTimestamp() + " " + a.properties.url)});

  // 11/10 70s, 8/15 2980s
  const firstUserPlayEvent = yield analyticsDb.collection('log').mapReduce(
    function() {
      emit(this.user, {created: this._id.getTimestamp(), url: this.properties.url});
    },
    function (key, values) {
      values.sort(function(a, b) {
        if (a.created < b.created) return -1;
        if (a.created > b.created) return 1;
        return 0;
      });
      return values[0];
    },
    {
      query: {_id: {$gte: startObjectId},
        event: 'Pageview',
        'properties.url': {$in: ['play/campaign-game-dev-1', 'play/campaign-web-dev-1', 'play/forest']}
      },
      out: {inline: 1}
    }
  );
  const firstWorldPlayMap = {};
  for (const event of firstUserPlayEvent) {
    const url = event.value.url;
    if (!firstWorldPlayMap[url]) firstWorldPlayMap[url] = 0;
    firstWorldPlayMap[url]++;
  }
  const total = firstUserPlayEvent.length;
  debug(`Users found ${total}`);
  for (const url in firstWorldPlayMap) {
    console.log(`${(firstWorldPlayMap[url] / total * 100).toFixed(2)}% ${url} ${firstWorldPlayMap[url]}`);
  }

  analyticsDb.close();
  debug(`Script runtime: ${new Date() - scriptStartTime}`);
})

// * Helper functions

function debug(msg) {
  if (debugOutput) console.log(`${new Date().toISOString()} ${msg}`);
}

function objectIdWithTimestamp(timestamp) {
  // Convert string date to Date object (otherwise assume timestamp is a date)
  if (typeof(timestamp) == 'string') timestamp = new Date(timestamp);
  // Convert date object to hex seconds since Unix epoch
  var hexSeconds = Math.floor(timestamp/1000).toString(16);
  // Create an ObjectId with that hex timestamp
  var constructedObjectId = mongoose.Types.ObjectId(hexSeconds + "0000000000000000");
  return constructedObjectId;
}
