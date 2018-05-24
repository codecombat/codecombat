// @ts-nocheck

// Send onetime emails to EU non-teachers who are paid or active
// Assumes prod env variables to run

// TODO: test on limited batch of users first

// TODO: delete inactive users 1 month after one-time email sent

require('coffee-script');
require('coffee-script/register');
global._ = require('lodash');
_.str = require('underscore.string');
const database = require('../server/commons/database');
const User = require('../server/models/User');
const co = require('co');
const utils = require('../app/core/utils');
const sendwithus = require('../server/sendwithus');

database.connect();

const oneTimeEmailType = 'explicit consent EU non-teachers who are paid or active';
const batchSize = 1;
const newestDate = new Date();
newestDate.setUTCMonth(newestDate.getUTCMonth() - 23);
const newestStr = newestDate.toISOString();
const euCountries = utils.countries.filter((c) => c.inEU).map((c) => c.country);

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
        address: 'bob@example.com', // TODO: use user.get('emailLower')
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
        resolve();
      });
    });
  });
}

co(function*() {
  const query = {$and: [
    // Do NOT send one time email again
    {$or: [{'emails.oneTimes': {$exists: false}}, {$and: [{'emails.oneTimes': {$exists: true}}, {$where : `!this.emails.oneTimes.find(function(o){return o.type === '${oneTimeEmailType}'})`}]}]},
    {$or: [
      // Active
      {$or: [
        {$and: [
            {'activity.login.last': {$exists: true}}, {'activity.login.last': {$gte: newestStr}}
        ]}, 
        {$and: [
            {'activity.login.last': {$exists: false}}, {dateCreated: {$gte: newestDate}}
        ]}
      ]},
      // Or paid
      {$or: [{'stripe.subscriptionID': {$exists: true}}, {'stripe.sponsorID': {$exists: true}}]}
    ]},
    // In EU
    {$or: [{country: {$in: euCountries}}, {country: {$exists: false}}]},
    // Not a teacher
    {role: {$nin: User.teacherRoles}},
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

    // TODO: remove for full run
    break;
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
