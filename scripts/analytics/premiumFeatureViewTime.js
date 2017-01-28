'use strict';

if (process.argv.length !== 4) {
  log("Usage: node <script> <mongo connection Url> <mongo connection Url analytics>");
  log("Include ?readPreference=secondary in connection URLs");
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

const startOfWeek = 5 // Friday morning at 00:00
const today = new Date();
const daysAgoToStart = (today.getUTCDay() - startOfWeek + 7) % 7 + 7
console.log();
if(today.getUTCDay() !== 5){
  console.log('NOTE: To get data for the last week including thursday, run this script after UTC midnight thursday! (4pm Pacific/7pm Eastern)');
}
const startDay = (moment(today).subtract(daysAgoToStart, 'days').utc().startOf('day')).toDate()
const eventWindow = 7 // days
const endDay = moment(startDay).add(eventWindow, 'days').toDate()
console.log('start: ', startDay, '\n  end: ', endDay);
if(moment(endDay).isAfter(moment())) {
  console.log('\n* * * WARNING: Latest date is in the future! * * *')
}

console.log('\nConnecting...')

co(function*() {
  yield mongoose.connect(mongoConnUrl);
  const analyticsDb = yield MongoClient.connect(mongoConnUrlAnalytics, { connectTimeoutMS: 60*60*1000, connectTimeoutMS: 60*60*1000 });
  console.log('Connected');

var objectIdFromDate = function (date) {
  return mongoose.Types.ObjectId(Math.floor(date.getTime() / 1000).toString(16) + "0000000000000000");
};

const startObjectId = objectIdFromDate(startDay);
const endObjectId = objectIdFromDate(endDay);

const totalRecentUsers = (yield analyticsDb.collection('log').distinct('user',
  {
    _id: { $gt: startObjectId, $lt: endObjectId },
    // user: { $regex: /^.{24}$/ }
  }
)).length;
console.log("totalRecentUsers:", totalRecentUsers);

const results = (yield analyticsDb.collection('log').mapReduce(function(){
  emit('timeTotal', parseFloat(this.properties.timeViewed))
  emit('usersThatViewedPremiumFeatures', 1)
}, function(key, values){
  return Array.sum(values);
}, {
  query: { event: "Premium Feature Viewed", _id: {$gt: startObjectId } },
  out: {inline: 1}
}));

var usersThatViewedPremiumFeatures;
var totalPremiumViewTime;

results.forEach((obj)=>{
  switch(obj._id){
    case 'timeTotal':
      totalPremiumViewTime = obj.value;
    case 'usersThatViewedPremiumFeatures':
      usersThatViewedPremiumFeatures = obj.value;
  }
})

console.log("usersThatViewedPremiumFeatures:", usersThatViewedPremiumFeatures);
console.log("totalPremiumViewTime:", totalPremiumViewTime, 'ms');
console.log("Final G1KR2 value:", (totalPremiumViewTime/totalRecentUsers).toFixed(0), 'ms/user');

mongoose.connection.close();
analyticsDb.close();

}).catch(function(e) {
  console.log('Error: ', e)
  console.log(e.stack);
});
