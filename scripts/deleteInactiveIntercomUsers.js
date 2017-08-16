'use strict';
// Delete Intercom users last seen over 30 days ago with no conversations

// NOTE: max 500 requests/minute, scroll closes after 1 minute and returns 100 user batches
// NOTE: and, limit of 83 requests per 10s
// https://developers.intercom.com/v2.0/reference-edit/rate-limiting
// https://medium.com/intercom-developers/be-prepared-3-ways-to-handle-rate-limits-baeb9215c1bc

if (process.argv.length !== 3) {
  console.log("Usage: node <script> <Intercom 'App ID:API write key'> ");
  process.exit();
}

const scriptStartTime = new Date();

const intercomAppId = process.argv[2].split(':')[0];
const intercomApiKey = process.argv[2].split(':')[1];

const Promise = require('bluebird');
const Intercom = require('intercom-client');
const client = new Intercom.Client({ appId: intercomAppId, appApiKey: intercomApiKey });

const scrollIntervalMilliseconds = 10 * 1000;

const latestUpdate = new Date();
latestUpdate.setUTCDate(latestUpdate.getUTCDate() - 30);

// TODO: verify this works, a little unclear after limited testing
const createdSinceDays = 60;

client.users.scroll.each({created_since: createdSinceDays}, function (response) {
  console.log(`${new Date().toISOString()} DEBUG: Rate limit ${response.headers['x-ratelimit-limit']}, limit remaining ${response.headers['x-ratelimit-remaining']}, limit reset ${new Date(parseInt(response.headers['x-ratelimit-reset'])*1000).toISOString()}`);
  // if (parseInt(response.headers['x-ratelimit-remaining']) < parseInt(response.headers['x-ratelimit-limit'])) {
  //   console.log(`${new Date().toISOString()} DEBUG: Rate limit ${response.headers['x-ratelimit-limit']}, limit remaining ${response.headers['x-ratelimit-remaining']}, limit reset ${new Date(parseInt(response.headers['x-ratelimit-reset'])*1000).toISOString()}`);
  // }

  const oldUsers = (response.body.users || []).filter((user) => new Date(user.updated_at * 1000) < latestUpdate);
  if (oldUsers.length > 0) {
    console.log(`${new Date().toISOString()} DEBUG: total users ${(response.body.users || []).length}, old users ${oldUsers.length}`);
  }

  // Find old user conversations
  // TODO: limit to 80 conversations fetches per 10 seconds
  return Promise.mapSeries(oldUsers, (user) => client.conversations.list({ type: 'user', intercom_user_id: user.id }))
  .then((responses) => {
    const usersToDelete = [];
    for (let i = 0; i < responses.length; i++) {
      if (responses[i].body.conversations.length === 0) {
        usersToDelete.push({ delete: { user_id: oldUsers[i].user_id }});
        console.log(`${new Date().toISOString()} DEBUG: deleting user id=${oldUsers[i].id} user_id=${oldUsers[i].user_id} email= user_id=${oldUsers[i].email}`);
      }
    }
    // console.log(`${new Date().toISOString()} DEBUG: deleting ${usersToDelete.length} users, scrolling ${scrollIntervalMilliseconds / 1000} seconds..`);
    return usersToDelete.length > 0 ? client.users.bulk(usersToDelete) : new Promise((resolve) => {return resolve()});
  })
  .then(wait(scrollIntervalMilliseconds));
}).then(() => {
  console.log(`${new Date().toISOString()} script runtime: ${new Date() - scriptStartTime}ms`);
});

function wait(timeout) {
  return (value) => new Promise((resolve) => setTimeout(() => resolve(value), timeout));
}
