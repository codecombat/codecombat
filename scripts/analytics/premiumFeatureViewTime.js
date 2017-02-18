'use strict';

if (process.argv.length !== 4) {
  log("Usage: node <script> <mongo connection Url> <mongo connection Url analytics>");
  log("Include ?readPreference=secondary in connection URLs");
  process.exit();
}

require('coffee-script');
require('coffee-script/register');
const _ = GLOBAL._ = require('lodash');
_.str = require('underscore.string')
_.mixin(_.str.exports())

const mongoConnUrl = process.argv[2];
const mongoConnUrlAnalytics = process.argv[3];
const config = require('../../server_config');

const mongoose = require('mongoose');
const MongoClient = require('mongodb').MongoClient;
const ObjectID = require('mongodb').ObjectID;
const Promise = require('bluebird');
const co = require('co');
const moment = require('moment');
const User = require('../../server/models/User');

// Script will collect information for the last full week ending at the last Friday at 00:00 (because we want the information on fridays)
// This keeps the reporting windows consistent and non-overlapping.
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

  // First event was at 2016-01-19T12:54:05
  // console.log("First premium view tracking event: ", (yield analyticsDb.collection('log').find({event: "Premium Feature Viewed"}).sort({_id:1}).limit(1).toArray())[0]._id);

  console.log("Total premium view events:", yield analyticsDb.collection('log').count({ event: "Premium Feature Viewed", _id: { $gt: startObjectId, $lt: endObjectId} }));

  const recentUserIds = (yield analyticsDb.collection('log').distinct('user',
    {
      _id: { $gt: startObjectId, $lt: endObjectId },
      user: { $regex: /^.{24}$/ }
    }
  ));
  
  const totalRecentUsers = recentUserIds.length;
  console.log("totalRecentUsers:", totalRecentUsers);
  // console.log(JSON.stringify(recentUserIds.toString()).length);
  
  // const recentUsers = yield User.find({
  //   _id: { $in: recentUserIds.map((strId)=>{ return mongoose.Types.ObjectId(strId) }) }
  // })
  //
  // console.log("Recent users:", recentUsers.length);
  
  const recentIndividualUserIds = (yield User.find({
    _id: { $in: recentUserIds.map((strId)=>{ return mongoose.Types.ObjectId(strId) }) },
    role: { $nin: ['student', 'teacher', 'technology coordinator', 'advisor', 'principal', 'superintendent', 'parent'] }
  }, {_id: true})).map((u)=>{ return u.id })
  
  const totalRecentIndividualUsers = recentIndividualUserIds.length;
  
  console.log("Recent Individual Accounts:", recentIndividualUserIds.length);
  
  
  const results = (yield analyticsDb.collection('log').mapReduce(function(){
    emit('timeTotal', parseFloat(this.properties.timeViewed));
  }, function(key, values){
    return Array.sum(values);
  }, {
    query: { event: "Premium Feature Viewed", _id: { $gt: startObjectId, $lt: endObjectId }, user: {$in: recentIndividualUserIds} },
    out: { inline: 1 }
  }));
  
  var totalPremiumViewTime = _.indexBy(results, '_id').timeTotal.value;

  console.log("totalPremiumViewTime:", totalPremiumViewTime, 'ms');
  console.log("Final G1KR2 value:", (totalPremiumViewTime/totalRecentIndividualUsers/1000).toFixed(4), 's/user');

  mongoose.connection.close();
  analyticsDb.close();

}).catch(function(e) {
  console.log('Error: ', e)
  console.log(e.stack);
});
