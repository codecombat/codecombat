// Delete Intercom users last seen over 30 days ago with no conversations

'use strict';
if (process.argv.length !== 3) {
  console.log("Usage: node <script> <Intercom 'App ID:API write key'> ");
  process.exit();
}

const intercomAppId = process.argv[2].split(':')[0];
const intercomApiKey = process.argv[2].split(':')[1];

const Promise = require('bluebird');
const Intercom = require('intercom-client');
const client = new Intercom.Client({ appId: intercomAppId, appApiKey: intercomApiKey });

// NOTE: max 500 requests/minute, scroll closes after 1 minute and returns 100 user batches
// So, scroll every 20s
const scrollIntervalMilliseconds = 20 * 1000;

const latestUpdate = new Date();
latestUpdate.setUTCDate(latestUpdate.getUTCDate() - 30);

client.users.scroll.each({}, function (response) {
  console.log(`${new Date().toISOString()} DEBUG: scrolling ${scrollIntervalMilliseconds / 1000} seconds..`);
  return new Promise((resolve) => {
    setTimeout(() => {
      // Find old users
      // console.log(`${new Date().toISOString()} DEBUG: finding old users..`);
      const oldUsers = [];
      for (const user of response.body.users || []) {
        const updatedDate = new Date(user.updated_at * 1000);
        if (updatedDate < latestUpdate) {
          oldUsers.push(user);
        }
      }

      // Get conversations for each old user
      const convoPromises = [];
      for (const user of oldUsers) {
        convoPromises.push(client.conversations.list({ type: 'user', intercom_user_id: user.id }));
      }
      Promise.all(convoPromises)
      .then((responses) => {

        // Bulk delete old users without conversations
        const deleteItems = [];
        for (let i = 0; i < responses.length; i++) {
          if (responses[i].body.conversations.length === 0) {
            deleteItems.push({ delete: { user_id: oldUsers[i].user_id }});
            // console.log(`DEBUG: deleting user ${oldUsers[i].id}`);
          }
        }
        console.log(`DEBUG: deleting ${deleteItems.length} users`);
        client.users.bulk(deleteItems)
        .then((response) => {
          return resolve();
        })
      }, errorHandler);
   }, scrollIntervalMilliseconds)
 }, errorHandler)
});

function errorHandler(error) {
  console.log(error);
}
