// @ts-nocheck

// Send onetime emails to inactive old unpaid EU users
// Assumes prod env variables to run

// TODO: delete inactive users 1 month after one-time email sent

require('coffee-script');
require('coffee-script/register');
global._ = require('lodash');
_.str = require('underscore.string');
const database = require('../server/commons/database');
const User = require('../server/models/User');
const co = require('co');
const utils = require('../app/core/utils');
const sendgrid = require('../server/sendgrid');

database.connect();

const oneTimeEmailType = 'delete inactive unpaid EU user';
const batchSize = 1000; // 10K yields sendwithus 503 service unavailable
const batchSleepMS = 1000;
const newestDate = new Date();
newestDate.setUTCMonth(newestDate.getUTCMonth() - 23);
// const euCountries = utils.countries.filter((c) => c.inEU).map((c) => c.country);
const upperEUCountries = ['Austria', 'Belgium', 'Bulgaria', 'Broatia', 'Cyprus', 'Czech Republic', 'Denmark', 'Estonia', 'Finland', 'France', 'Germany', 'Greece', 'Hungary', 'Ireland', 'Italy', 'Latvia', 'Lithuania', 'Luxembourg', 'Malta', 'Netherlands', 'Poland', 'Portugal', 'Romania', 'Slovakia', 'Slovenia', 'Spain', 'Sweden', 'United-kingdom']

let errors = 0;
function sendOptInEmail(user) {
  return new Promise((resolve, reject) => {
    // Testing
    // setTimeout(() => {
    //   console.log('hi', user.get('emailLower'), user.get('country'));
    //   resolve();
    // }, 1000)
    // return;

    let opt_in_link = `https://codecombat.com/user/${user.id}/opt-in/${user.verificationCode((new Date()).getTime())}?no_delete_inactive_eu=true`;
    if (!user.isTeacher()) opt_in_link += "&prompt_keep_me_updated=true";

    const message = {
      templateId: sendgrid.templates.delete_inactive_eu_users,
      to: {
        email: user.get('emailLower'),
        name: user.broadName()
      },
      from: {
        email: 'team@codecombat.com',
        name: 'CodeCombat'
      },
      substitutions: {
        opt_in_link: opt_in_link,
        email: user.get('emailLower')
      }
    }

    sendgrid.api.send(message, (err, result) => {
      if (err) {
        console.log(`${new Date().toISOString()} ${errors} Error sending email to ${user.get('emailLower')}`);
        ++errors;
        if (!/Request failed with/.test(err.message) && !/getaddrinfo ENOTFOUND api.sendgrid.com/.test(err.message))
          return reject(err);
        if (errors > batchSize / 10)
          return reject(err);
      }
      user.update({$push: {"emails.oneTimes": {type: oneTimeEmailType, email: user.get('emailLower'), sent: new Date()}}}, (err, numAffected) => {
        if (err) {
          console.log(`${new Date().toISOString()} Error updating emails.oneTimes for ${user.get('emailLower')}`);
          return reject(err);
        }
        resolve();
      });
    });
  });
}

const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

co(function*() {
  const query = {$and: [
    // Do NOT send one time email again
    {$or: [{'emails.oneTimes': {$exists: false}}, {$and: [{'emails.oneTimes': {$exists: true}}, {$where : `!this.emails.oneTimes.find(function(o){return o.type === '${oneTimeEmailType}'})`}]}]},
    // Inactive
    {$or: [
        {$and: [
            {'activity.login.last': {$exists: true}}, {'activity.login.last': {$lt: newestDate}}
        ]},
        {$and: [
            {'activity.login.last': {$exists: false}}, {dateCreated: {$lt: newestDate}}
        ]}
    ]},
    // In EU
    {$or: [
      {country: {$in: upperEUCountries}},
      {'geo.countryName': {$in: upperEUCountries}},
      {$and: [{country: {$exists: false}}, {'geo.countryName': {$exists: false}}]},
    ]},
    // Unpaid
    {'stripe.subscriptionID': {$exists: false}},
    {'stripe.sponsorID': {$exists: false}},
    {anonymous: false}
  ]};
  const select = {emailLower: 1, country: 1, email: 1}; // email required for verification code generation

  while (true) {
    const users = yield User.find(query, select).limit(batchSize);
    if (users.length < 1) break;

    console.log(`${new Date().toISOString()} processing ${users.length} users..`);
    const tasks = [];
    for (const user of users) {
      // console.log(user.get('emailLower'));
      tasks.push(sendOptInEmail(user));
    }
    yield tasks;

    errors = 0;
    console.log(`${new Date().toISOString()} sleeping for ${batchSleepMS / 1000} seconds..`);
    yield sleep(batchSleepMS);
  }
})
.then(() => {
  console.log('Done')
  process.exit()
})
.catch((e) => {
  console.log("Error: ")
  console.log(e)
  process.exit()
})
