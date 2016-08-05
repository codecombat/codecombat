// Fix Close.io opportunity owners

'use strict';
if (process.argv.length !== 8) {
  log("Usage: node <script> <Close.io general API key> <Close.io mail API key1> <Close.io mail API key2> <Close.io mail API key3> <Close.io EU mail API key>");
  process.exit();
}

const scriptStartTime = new Date();
const closeIoApiKey = process.argv[2];
const closeIoMailApiKeys = [process.argv[3], process.argv[4], process.argv[5], process.argv[6], process.argv[7]];
const async = require('async');
const request = require('request');

// ** Main program

getUsers((err, ownerId, userApiKeyMap) => {
  if (err) {
    console.error(err);
    return;
  }
  getOpps(ownerId, (err, opps) => {
    if (err) {
      console.error(err);
      return;
    }
    log(`${opps.length} opps owned by ${userApiKeyMap[ownerId].data.first_name}`);
    const tasks = [];
    for (const opp of opps) {
      tasks.push(createUpdateOppFn(ownerId, userApiKeyMap, opp));
    }
    async.parallel(tasks, (err, results) => {
      if (err) console.error(err);
      log("Script runtime: " + (new Date() - scriptStartTime));
    });
  });
});

function getUsers(done) {
  let ownerId = null;
  const userApiKeyMap = {};
  let createGetUserFn = (apiKey) => {
    return (done) => {
      const url = `https://${apiKey}:X@app.close.io/api/v1/me/`;
      request.get(url, (error, response, body) => {
        if (error) return done();
        const results = JSON.parse(body);
        userApiKeyMap[results.id] = {key: apiKey, data: results};
        if (apiKey === closeIoApiKey) {
          ownerId = results.id;
        }
        return done();
      });
    };
  }
  const tasks = [createGetUserFn(closeIoApiKey)];
  for (const apiKey of closeIoMailApiKeys) {
    tasks.push(createGetUserFn(apiKey));
  }
  async.parallel(tasks, (err, results) => {
    if (err) return done(err);
    return done(null, ownerId, userApiKeyMap);
  });
}

function getOpps(ownerId, done) {
  const url = `https://${closeIoApiKey}:X@app.close.io/api/v1/opportunity/?user_id=${ownerId}`;
  request.get(url, (err, response, body) => {
    if (err) return done(err);
    const results = JSON.parse(body);
    return done(null, results.data);
  });
}

function createUpdateOppFn(ownerId, userApiKeyMap, opp) {
  return (done) => {
    findOwner(ownerId, userApiKeyMap, opp, (err, userId) => {
      if (err) return done(err);
      // console.log(`DEBUG: ${opp.lead_id} owner ${userApiKeyMap[userId].data.first_name}`);
      return updateOpp(opp, userId, userApiKeyMap, done);
    });
  };
}

function findOwner(ownerId, userApiKeyMap, opp, done) {
  const url = `https://${closeIoApiKey}:X@app.close.io/api/v1/activity/?lead_id=${opp.lead_id}`;
  request.get(url, (err, response, body) => {
    if (err) return done(err);
    const results = JSON.parse(body);
    if (results.has_more) {
      console.log(`ERROR: ${lead.id} has more activities than ${results.data.length} returned!`);
    }
    for (const activity of results.data) {
      if (activity._type === 'Email' && userApiKeyMap[activity.user_id] && activity.user_id !== ownerId) {
        return done(null, activity.user_id);
      }
    }
    return done(`ERROR: No owner found for ${opp.lead_id}`);
  });
}

function updateOpp(opp, userId, userApiKeyMap, done) {
  const putData = {
    user_id: userId,
    user_name: `${userApiKeyMap[userId].data.first_name} ${userApiKeyMap[userId].data.last_name}`
  };
  console.log(`DEBUG: updating ${opp.lead_id} ${opp.id} to ${putData.user_name}`);
  const options = {
    uri: `https://${closeIoApiKey}:X@app.close.io/api/v1/opportunity/${opp.id}/`,
    body: JSON.stringify(putData)
  };
  request.put(options, (err, response, body) => {
    if (err) return done(err);
    const result = JSON.parse(body);
    if (result.errors || result['field-errors']) {
      console.log(`PUT error for ${opp.lead_id} ${opp.id}`);
      return done(result.errors || result['field-errors']);
    }
    return done();
  });
}

// ** Utilities

function log(str) {
  console.log(new Date().toISOString() + " " + str);
}
