// @ts-nocheck

// Send onetime emails to EU non-teachers who are paid or active
// Assumes prod env variables to run

// TODO: test on limited batch of users first

// TODO: delete inactive users 1 month after one-time email sent

// TODO: set oneTimes email to true for invalid emails

// TODO: geo.countryName expensive because to index

require('coffee-script');
require('coffee-script/register');
global._ = require('lodash');
_.str = require('underscore.string');
const database = require('../server/commons/database');
const User = require('../server/models/User');
const co = require('co');
// const utils = require('../app/core/utils');
const sendwithus = require('../server/sendwithus');
const forms = require('../app/core/forms');

database.connect();

const oneTimeEmailType = 'explicit consent EU non-teachers who are paid or active';
const batchSize = 1000; // 10K yields sendwithus 503 service unavailable
const batchSleepMS = 1000;
const newestDate = new Date();
newestDate.setUTCMonth(newestDate.getUTCMonth() - 23);
// const euCountries = utils.countries.filter((c) => c.inEU).map((c) => c.country);
const upperEUCountries = ['Austria', 'Belgium', 'Bulgaria', 'Broatia', 'Cyprus', 'Czech Republic', 'Denmark', 'Estonia', 'Finland', 'France', 'Germany', 'Greece', 'Hungary', 'Ireland', 'Italy', 'Latvia', 'Lithuania', 'Luxembourg', 'Malta', 'Netherlands', 'Poland', 'Portugal', 'Romania', 'Slovakia', 'Slovenia', 'Spain', 'Sweden', 'United-kingdom']

function sendOptInEmail(user) {
  return new Promise((resolve, reject) => {
    // Testing
    // setTimeout(() => {
    //   console.log('hi', user.get('emailLower'), user.get('country'));
    //   resolve();
    // }, 1000)
    // return;

    let opt_in_link = `https://codecombat.com/user/${user.id}/opt-in/${user.verificationCode((new Date()).getTime())}?keep_me_updated=true`;

    const context = {
      email_id: sendwithus.templates.eu_nonteacher_explicit_consent,
      recipient: {
        address: user.get('emailLower'),
        name: user.broadName()
      },
      email_data: {
        opt_in_link: opt_in_link
      }
    }
    sendwithus.api.send(context, (err, result) => {
      if (err) {
        console.log(`${new Date().toISOString()} Error sending email to ${user.get('emailLower')}`);
        return reject(err);
      }
      user.update({$push: {"emails.oneTimes": {type: oneTimeEmailType, email: user.get('emailLower'), sent: new Date()}}}, (err, numAffected) => {
        if (err) {
          console.log(`${new Date().toISOString()} Error updating emails.oneTimes for ${user.get('emailLower')}`);
          return reject(err);
        }
        // console.log(`${new Date().toISOString()} Email sent and user.emails.oneTimes set for ${user.get('emailLower')}`);
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
    {$or: [
      // Active
      {$or: [
        {$and: [
            {'activity.login.last': {$exists: true}}, {'activity.login.last': {$gte: newestDate}}
        ]}, 
        {$and: [
            {'activity.login.last': {$exists: false}}, {dateCreated: {$gte: newestDate}}
        ]}
      ]},
      // Or paid
      {$or: [{'stripe.subscriptionID': {$exists: true}}, {'stripe.sponsorID': {$exists: true}}]}
    ]},
    // In EU

    // TODO: using country field first, since we have an index
    // {country: {$exists: true}},
    // {country: {$in: upperEUCountries}},

    // TODO: only geo.countryName EU users
    // {country: {$exists: false}},
    // {'geo.countryName': {$exists: true}},
    // {'geo.countryName': {$in: upperEUCountries}},

    // NOTE: 45s at 500 batch
    // {country: {$exists: false}},
    // {'geo.countryName': {$exists: false}},

    // NOTE: 40s at 500 batch
    // NOTE: 45s at 200 batch
    // NOTE: 45s at 1000 batch
    {$or: [
      {country: {$in: upperEUCountries}},
      {'geo.countryName': {$in: upperEUCountries}},
      {$and: [{country: {$exists: false}}, {'geo.countryName': {$exists: false}}]},
    ]},
    // Not a teacher
    {role: {$nin: User.teacherRoles}},
    {anonymous: false}
  ]};
  // const query = {emailLower: 'robin+ro@codecombat.com'};
  const select = {emailLower: 1, country: 1, email: 1}; // email required for verification code generation

  while (true) {
    // console.log(`${new Date().toISOString()} finding up to ${batchSize} users..`);
    const users = yield User.find(query, select).limit(batchSize);
    if (users.length < 1) break;

    console.log(`${new Date().toISOString()} processing ${users.length} users..`);
    const tasks = [];
    for (const user of users) {
      if (forms.validateEmail(user.get('emailLower'))) {
        // console.log(user.get('emailLower'));
        tasks.push(sendOptInEmail(user));
      }
    }
    yield tasks;

    console.log(`${new Date().toISOString()} sleeping for ${batchSleepMS / 1000} seconds..`);
    yield sleep(batchSleepMS);

    // TODO: remove for full run
    // break;
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
