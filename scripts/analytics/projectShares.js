'use strict';
// Output Hints style a/b test results in csv format

if (process.argv.length !== 5) {
  console.log("Usage: node <script> <mongo connection Url> <mongo connection Url analytics> <mongo connection Url level sessions>");
  console.log("Include ?readPreference=secondary in connection URLs");
  process.exit();
}

require('coffee-script');
require('coffee-script/register');
GLOBAL._ = require('lodash')
_.str = require('underscore.string')
_.mixin(_.str.exports())


const mongoConnUrl = process.argv[2];
const mongoConnUrlAnalytics = process.argv[3];
const mongoConnUrlLevelSessions = process.argv[4];
const config = require('../../server_config');
config.mongo.level_session_replica_string = mongoConnUrlLevelSessions;

const mongoose = require('mongoose');
const MongoClient = require('mongodb').MongoClient;
const ObjectID = require('mongodb').ObjectID;
const Promise = require('bluebird');
const genstats = require('genstats');
const co = require('co');
const moment = require('moment');
const LevelSession = require('../../server/models/LevelSession');

const startDay = "2017-02-18";
const sessionWindow = 180; // days
const sessionEndDay = moment(startDay).add(sessionWindow, 'days').toDate()
const waitWindow = 180; // days
const eventEndDay = moment(startDay).add(sessionWindow + waitWindow, 'days').toDate()
console.log('\nDates: ', {startDay, sessionEndDay, eventEndDay})
if(moment(eventEndDay).isAfter(moment())) {
  console.log('\n* * * WARNING: Latest date is in the future! * * *')
}

console.log('\nConnecting...')
co(function*() {
  yield mongoose.connect(mongoConnUrl);
  const analyticsDb = yield MongoClient.connect(mongoConnUrlAnalytics);
  console.log('Connected');
  
  // Get all levels which are shareable.
  const Level = require('../../server/models/Level');
  var levels = yield Level.find(
    {shareable: 'project', slug: 'palimpsest'},
    {original: 1, name: 1, type: 1}
  )
  
  console.log(`Loaded ${levels.length} levels. Loading sessions...`);
  var levelOriginals = levels.map((l) => l.get('original').toString());
  
  // Get all sessions created during a certain window for those levels,
  // which also have a dateFirstCompleted.
  // put in object id -> { user, views }

  const sessionQuery = {
    _id: {
      $gte: objectIdWithTimestamp(startDay),
      $lt: objectIdWithTimestamp(sessionEndDay)
    },
    'level.original': {
      $in: levelOriginals
    },
    'dateFirstCompleted': {$exists: true}
  };
    const sessionCursor = LevelSession.find(sessionQuery).sort('-_id').cursor()
  const levelSessionViews = {};
  while(true) {
    const levelSession = yield sessionCursor.next()
    if (!levelSession) break;
    levelSessionViews[levelSession._id.toString()] = {
      user: levelSession.get('creator'),
      views: 0,
      cutoff: moment(levelSession.get('dateFirstCompleted')).add(waitWindow, 'days')
    }
      if(true) { //_.size(levelSessionViews) % 200 === 0) {
      console.log('...', _.size(levelSessionViews))
    }
  }
  console.log(`Gathered ${_.size(levelSessionViews)} sessions.`)

  // Look at all events, count views that are:
  // * Not by the creator
  // * Before the cutoff 'wait' window
  
  const eventQuery = {
    _id: {
      $gte: objectIdWithTimestamp(startDay),
      $lt: objectIdWithTimestamp(eventEndDay)
    },
    event: {
      $in: ['Play WebDev Level - Load', 'Play GameDev Level - Load']
    }
  }
  const cursor = analyticsDb.collection('log').find(eventQuery)
  var totalViews = 0;
  while(true) {
    const event = yield cursor.next()
    if(!event) { break; }
    if(!event.properties) { continue }
    var sessionID = event.properties.sessionID;
    if(levelSessionViews[sessionID]) {
      if(event.user !== levelSessionViews[sessionID].user) {
        if (moment(event._id.getTimestamp()).isBefore(levelSessionViews[sessionID].cutoff)) {
          totalViews += 1;
          levelSessionViews[sessionID].views += 1;
        }
      }
    }
  }
  console.log("RESULT: ", (totalViews / _.size(levelSessionViews)).toFixed(3), 'views per completed shareable project.')

  var bestProjects = [];
  for(var sessionId in levelSessionViews) {
    bestProjects.push({views: levelSessionViews[sessionId].views, sessionId: sessionId});
  }
  bestProjects = _.sortBy(bestProjects, function(project) { return -project.views; });
  console.log(bestProjects.slice(0, 50));

  mongoose.disconnect();
  analyticsDb.close();
}).catch(function(e) {
  console.log('Error: ', e)
  process.exit();
});

// * Helper functions

function objectIdWithTimestamp(timestamp) {
  // Convert string date to Date object (otherwise assume timestamp is a date)
  if (typeof(timestamp) == 'string') timestamp = new Date(timestamp);
  // Convert date object to hex seconds since Unix epoch
  var hexSeconds = Math.floor(timestamp/1000).toString(16);
  // Create an ObjectId with that hex timestamp
  var constructedObjectId = mongoose.Types.ObjectId(hexSeconds + "0000000000000000");
  return constructedObjectId;
}

function debug(msg) {
  if (debugOutput) console.log(`${new Date().toISOString()} ${msg}`);
}
