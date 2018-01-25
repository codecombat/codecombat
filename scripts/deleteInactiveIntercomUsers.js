'use strict';
// Delete Intercom users last seen over 30 days ago with no conversations

// NOTE: max 500 requests/minute, scroll closes after 1 minute and returns 100 user batches
// NOTE: and, limit of 83 requests per 10s
// https://developers.intercom.com/v2.0/reference-edit/rate-limiting
// https://medium.com/intercom-developers/be-prepared-3-ways-to-handle-rate-limits-baeb9215c1bc

// TODO: Intercom advised to create a segment where last_heard_from is unknown and whatever other criteria we want, and use the API to just fetch that segment. If it works, would be way easier to do than this, and reliably get responses to our auto messages, too. Future work.
// Since this seems to be not working that well, I'm doing it manually for now based on the segment from the web interface, and disabling this script.
console.log(`${new Date().toISOString()} Skipping deleteInactiveIntercomUsers.js in favor of manual process.`);
process.exit();

if (process.argv.length !== 3) {
  console.log("Usage: node <script> <Intercom Access Token> ");
  process.exit();
}

const scriptStartTime = new Date();

//const intercomAppId = process.argv[2].split(':')[0];
//const intercomApiKey = process.argv[2].split(':')[1];  // Old auth method
const intercomAccessToken = process.argv[2];  // New auth method

const Promise = require('bluebird');
const Intercom = require('intercom-client');
const client = new Intercom.Client({ token: intercomAccessToken });

const scrollIntervalMilliseconds = 10 * 1000;

const latestUpdate = new Date();
latestUpdate.setUTCDate(latestUpdate.getUTCDate() - 60);  // Delete any users we haven't heard from in 2 months

const createdSinceDays = 120;  // Look 4 months back
var totalDeleted = 0;
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
  return Promise.map(oldUsers, (user) => client.conversations.list({ type: 'user', intercom_user_id: user.id }), {concurrency: 2})
  .then((responses) => {
    const usersToDelete = [];
    for (let i = 0; i < responses.length; i++) {
      let userMessaged = false;
      responses[i].body.conversations.forEach(function(conversation) {
        if (conversation.conversation_message.author.type == 'user') {
          userMessaged = true;
        }
        if (conversation.conversation_parts && conversation.conversation_parts.length) {
          // Turns out you would need to fetch each conversation individually before conversation_parts or total_count shows up, so this won't work without getting all the users first and then processing the rest of this later.
          userMessaged = true;
        }
      })
      if (!userMessaged) {
        usersToDelete.push({ delete: { user_id: oldUsers[i].user_id }});
        console.log(`${new Date().toISOString()} DEBUG: deleting user id=${oldUsers[i].id} user_id=${oldUsers[i].user_id} email= user_id=${oldUsers[i].email}`);
      }
    }
    console.log(`${new Date().toISOString()} DEBUG: deleting ${usersToDelete.length} users, scrolling ${scrollIntervalMilliseconds / 1000} seconds..`);
    totalDeleted += usersToDelete.length;
    return usersToDelete.length > 0 ? client.users.bulk(usersToDelete) : new Promise((resolve) => {return resolve()});
  })
  .then(wait(scrollIntervalMilliseconds));
}).then(() => {
  console.log(`${new Date().toISOString()} script runtime: ${new Date() - scriptStartTime}ms`);
  console.log('${new Date().toISOString()} DEBUG: Deleted', totalDeleted, 'users.');
});

function wait(timeout) {
  return (value) => new Promise((resolve) => setTimeout(() => resolve(value), timeout));
}
