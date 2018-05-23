// @ts-nocheck

// Send onetime emails to inactive old unpaid EU users
// Assumes prod env variables to run

// TODO: locally, with only sendwithus production keys
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

const oneTimeEmailType = 'delete inactive unpaid EU user';

const newestDate = new Date();
newestDate.setUTCMonth(newestDate.getUTCMonth() - 23);
const newestStr = newestDate.toISOString();
const euCountries = utils.countries.filter((c) => c.inEU).map((c) => c.country);

function* sendOptInEmail(user) {
  return new Promise((resolve, reject) => {
    setTimeout(() => {
      console.log('hi', user.get('emailLower'), user.get('country'));
      // reject('oh no! ' + user.get('emailLower'));
      resolve();
    }, 1000)

    let opt_in_link = `https://codecombat.com/user/${user.id}/opt-in/${user.verificationCode((new Date()).getTime())}?no_delete_inactive_eu=true`;
    if (!user.isTeacher()) {
      opt_in_link += "&prompt_keep_me_updated=true";
    }

    const context = {
      email_id: sendwithus.templates.delete_inactive_eu_users,
      recipient: {
        address: 'matt@codecombat.com', // TODO: use real users email address
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
      // yield user.update({$push: {"emails.oneTimes": {type: oneTimeEmailType, email: user.get('emailLower'), sent: new Date()}}})
      return resolve(user);
    });
  });
}

co(function*() {
  const query = {$and: [
    {$and: [{'emails.oneTimes': {$exists: true}}, {$where : `!this.emails.oneTimes.find(function(o){return o.type === '${oneTimeEmailType}'})`}]},
    {$or: [
        {$and: [
            {'activity.login.last': {$exists: true}}, {'activity.login.last': {$lt: newestStr}}
        ]},
        {$and: [
            {'activity.login.last': {$exists: false}}, {dateCreated: {$lt: newestDate}}
        ]}
    ]},
    {$or: [{country: {$in: euCountries}}, {country: {$exists: false}}]},
    {'stripe.subscriptionID': {$exists: false}},
    {'stripe.sponsorID': {$exists: false}},
    {anonymous: false}
  ]};
  const select = {emailLower: 1, country: 1, 'activity.login.last': 1, dateCreated: 1, stripe: 1};

  const batchSize = 2;
  while (true) {
    const users = yield User.find(query, select).limit(batchSize);
    if (users.length < 1) break;

    console.log(`${new Date().toISOString()} queuing up ${users.length} users..`);
    const tasks = [];
    for (const user of users) {
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
