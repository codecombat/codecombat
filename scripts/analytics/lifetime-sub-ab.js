Promise = require('bluebird')
pg = require('pg')
co = require('co')
_ = require('lodash')
mongoose = require('mongoose')

require('coffee-script');
require('coffee-script/register');
var server = require('../../server');
var serverSetup = require('../../server_setup');
serverSetup.connectToDatabase()
config = require('../../server_config')

AnalyticsLogEvent = require('../../server/models/AnalyticsLogEvent')
utils = require('../../server/lib/utils')

co(function * () {
  var pool = new pg.Pool(config.snowplow);

  pool.connectAsync = Promise.promisify(pool.connect);
  var client = yield pool.connectAsync();

  client.queryAsync = Promise.promisify(client.query);
  var res = yield client.queryAsync("select \"user\", root_tstamp from atomic.com_codecombat_view_load_1 where view_id = 'subscribe-modal' and root_tstamp > '2017-02-15';", [])
  
  var viewLoadLogs = res.rows;

  User = require('../../server/models/User')
  events = [
    //'Started subscription purchase',
    'Finished subscription purchase',
    //'Failed to finish subscription purchase',
    'Started 1 year subscription purchase',
    'Finished 1 year subscription purchase',
    'Failed to finish 1 year subscription purchase',
    'Start Lifetime Purchase',
    'Finish Lifetime Purchase',
    'Fail Lifetime Purchase'
  ]
  startId = utils.objectIdFromTimestamp(new Date('2017-02-15').getTime())
  var eventLogs = yield AnalyticsLogEvent.find({
    'event': { $in: events },
    _id: { $gte: startId }
  }).sort({_id:1})
  
  
  // Some logic for checking our events against actual payment data
  
  //check = _(eventLogs)
  //  .filter(function (eventLog) {
  //    return _.contains(['Finished subscription purchase'], eventLog.event)
  //  })
  //  .map(function (eventLog) {
  //    return eventLog.user // + ' ' + eventLog._id.getTimestamp() 
  //  })
  //  .value()
  //console.log(JSON.stringify(check, null, '\t'))
  //console.log(check.join('\n'))
  //return
  
  var compiled = {};
  for (var i in viewLoadLogs) {
    var viewLoadLog = viewLoadLogs[i];
    if(!compiled[viewLoadLog.user])
      compiled[viewLoadLog.user] = {};
    if(!compiled[viewLoadLog.user].views)
      compiled[viewLoadLog.user].views = []
    compiled[viewLoadLog.user].views.push(viewLoadLog.root_tstamp)
  }
  
  for (var j in eventLogs) {
    var eventLog = eventLogs[j];
    if(!compiled[eventLog.user])
      compiled[eventLog.user] = {};
    if(!compiled[eventLog.user].events)
      compiled[eventLog.user].events = {};
    compiled[eventLog.user].events[eventLog.event] = true
    if(!eventLog.event) {
      throw new Error('stop')
    }
  }
  
  
  var userIds = _.keys(compiled);
  while (userIds.length) {
    console.log(userIds.length);
    var userIdChunk = userIds.splice(0, 100);
    var userObjectIds = _.map(userIdChunk, function(id) { return mongoose.Types.ObjectId(id); });
    var users = yield User.find({_id: {$in: userObjectIds}}).lean().select('testGroupNumber')
    _.forEach(users, function(user) { compiled[user._id+''].group = (user.testGroupNumber || 0) % 2 === 0 ? 'lifetime' : 'year' })
  }

  userIds = _.keys(compiled);
  var counts = {
    year: {
      views: 0,
      started: 0,
      finished: 0,
      failed: 0,
      subs: 0
    },
    lifetime: {
      views: 0,
      started: 0,
      finished: 0,
      failed: 0,
      subs: 0
    },
    mismatches: 0
  }
  for (var k in userIds) {
    var userId = userIds[k];
    if(!compiled[userId].group)
      continue
    if(!compiled[userId].views) {
      continue
    }
    counts[compiled[userId].group].views += 1
    var userEvents = _.keys(compiled[userId].events)
    for(var l in userEvents) {
      var eventName = userEvents[l];
      if(eventName.indexOf('year') > -1 && compiled[userId].group !== 'year') {
        console.log('Year event found for lifetime user!', userId, compiled[userId])
        counts.mismatches += 1
      }
      if(eventName.indexOf('Lifetime') > -1 && compiled[userId].group !== 'lifetime') {
        console.log('Lifetime event found for year user!', userId, compiled[userId])
        counts.mismatches += 1
      }
      if(eventName === 'Finished subscription purchase') {
        counts[compiled[userId].group].subs += 1
      }
      else {
        if(_.str.startsWith(eventName, 'Start')) {
          counts[compiled[userId].group].started += 1
        }
        if(_.str.startsWith(eventName, 'Finish')) {
          counts[compiled[userId].group].finished += 1
        }
        if(_.str.startsWith(eventName, 'Fail')) {
          counts[compiled[userId].group].failed += 1
        }
      }
    }
  }
  
  console.log(JSON.stringify(counts, null, '\t'))
})
.catch(function (err) {
  console.log('err', err.stack);
  process.exit(1)
})
.then(function () {
  process.exit(0)
})
