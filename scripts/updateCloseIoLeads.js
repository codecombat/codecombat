// Upsert new lead data into Close.io

'use strict';
if (process.argv.length !== 5) {
  log("Usage: node <script> <Close.io API key> <Intercom 'App ID:API key'> <mongo connection Url>");
  process.exit();
}

// TODO: update existing leads
// TODO: support multiple contacts per organization

const scriptStartTime = new Date();
const closeIoApiKey = process.argv[2];
const intercomAppIdApiKey = process.argv[3];
const intercomAppId = intercomAppIdApiKey.split(':')[0];
const intercomApiKey = intercomAppIdApiKey.split(':')[1];
const mongoConnUrl = process.argv[4];
const MongoClient = require('mongodb').MongoClient;
const request = require('request');

const earliestDate = new Date();
earliestDate.setUTCDate(earliestDate.getUTCDate() - 10);

log('Finding leads..');
findLeads((err, leads) => {
  if (err) {
    console.error(err);
    return;
  }
  log(`Num leads ${Object.keys(leads).length}`);
  log('Adding Intercom data..');
  addIntercomData(leads, (err) => {
    if (err) {
      console.error(err);
      return;
    }
    log('Updating leads..');
    updateLeads(leads, (err, numLeadsCreated) => {
      if (err) {
        console.error(err);
        return;
      }
      // // TEMP
      // for (const email in leads) {
      //   console.log(email);
      //   console.log(leads[email]);
      //   break;
      // }
      // // TEMP
      log(`Num leads created ${numLeadsCreated}`);
      log("Script runtime: " + (new Date() - scriptStartTime));
    });
  });
});


/* Helpers */

class Lead {
  constructor(email) {
    this.email = email;
  }
  addClassroom(classroom) {
    this.coco_numClassrooms = this.coco_numClassrooms ? this.coco_numClassrooms + 1 : 1;
    if (classroom.members && classroom.members.length) {
      this.coco_numStudents = this.coco_numStudents ? this.coco_numStudents + classroom.members.length : classroom.members.length;
    }
  }
  addIntercomUser(user) {
    if (user && user.id) {
      this.intercom_url = `https://app.intercom.io/a/apps/${intercomAppId}/users/${user.id}/`;
    }
  }
  addTrialRequest(trialRequest) {
    if (trialRequest.properties) {
      let location = '';
      if (trialRequest.properties.city) location = trialRequest.properties.city;
      if (trialRequest.properties.state) location += `${location ? ', ' : ''}${trialRequest.properties.state}`;
      if (trialRequest.properties.country) location += `${location ? ', ' : ''}${trialRequest.properties.country}`;
      if (location) this['trial_location'] = location;
      if (trialRequest.properties.educationLevel) {
        this['trial_educationLevel'] = trialRequest.properties.educationLevel.join(', ');
      }
      for (const prop in trialRequest.properties) {
        if (['educationLevel', 'city', 'state', 'country'].indexOf(prop) >= 0) continue;
        this[`trial_${prop}`] = trialRequest.properties[prop];
      }
    }
    this.trial_created = trialRequest.created;
    this.trial_userID = trialRequest.applicant;
    if (this.trial_name) this.name = this.trial_name;
    this.userID = trialRequest.applicant;
  }
  addUser(user) {
    // if (this.userID && !this.userID.equals(user._id)) {
    //   // console.log(`Trial request user ID mismatch for ${this.email} replacing ${this.userID} with ${user._id}`);
    //   this.trialUserID = this.userID;
    // }
    this.userID = user._id;
    if (!this.name) {
      if (user.firstName && user.lastName) {
        this.name = `${user.firstName} ${user.lastName}`;
      }
      else if (user.name) {
        this.name = user.name;
      }
    }
    if (user.firstName) this.coco_firstName = user.firstName;
    if (user.lastName) this.coco_lastName = user.lastName;
    if (user.name) this.coco_name = user.name;
    if (user.gender) this.coco_gender = user.gender;
    if (user.lastLevel) this.coco_lastLevel = user.lastLevel;
    if (user.role) this.coco_role = user.role;
    if (user.schoolName) this.coco_schoolName = user.schoolName;
    if (user.stats) this.coco_stats = JSON.stringify(user.stats);
  }
}

function findLeads(done) {
  // Recent trial requests
  // Recent users with teacher role

  MongoClient.connect(mongoConnUrl, (err, db) => {
    if (err) return done(err);

    const query = {$and: [{created: {$gte: earliestDate}}, {type: 'course'}]};
    db.collection('trial.requests').find(query).toArray((err, trialRequests) => {
      if (err) {
        db.close();
        return done(err);
      }
      const leads = {};
      for (const trialRequest of trialRequests) {
        const email = trialRequest.properties.email;
        if (!leads[email]) leads[email] = new Lead(email);
        leads[email].addTrialRequest(trialRequest);
      }

      const query = {$and: [
        {dateCreated: {$gte: earliestDate}},
        {anonymous: false},
        {role: {$in: ['teacher', 'technology coordinator', 'advisor', 'principal', 'superintendent']}}
      ]};
      db.collection('users').find(query).toArray((err, users) => {
        if (err) {
          db.close();
          return done(err);
        }
        const userIDs = [];
        const userEmailMap = {};
        for (const user of users) {
          const email = user.emailLower;
          if (!leads[email]) leads[email] = new Lead(email);
          leads[email].addUser(user);
          userIDs.push(user._id);
          userEmailMap[user._id.valueOf()] = email;
        }

        const query = {ownerID: {$in: userIDs}};
        db.collection('classrooms').find(query).toArray((err, classrooms) => {
          if (err) {
            db.close();
            return done(err);
          }

          for (const classroom of classrooms) {
            leads[userEmailMap[classroom.ownerID.valueOf()]].addClassroom(classroom);
          }
          db.close();
          return done(null, leads);
        });
      });
    });
  });
}

function addIntercomData(leads, done) {
  const leadEmails = Object.keys(leads);
  let leadIndex = 0;

  function nextUser() {
    if (leadIndex < leadEmails.length) {
      return getUser(leadEmails[leadIndex++]);
    }
    return done();
  }
  function getUser(email) {
    const options = {
      url: `https://api.intercom.io/users?email=${encodeURIComponent(email)}`,
      auth: {
        user: intercomAppId,
        pass: intercomApiKey
      },
      headers: {
        'Accept': 'application/json'
      }
    };
    request.get(options, (error, response, body) => {
      if (error) return done(error);
      const user = JSON.parse(body);
      leads[email].addIntercomUser(user);
      return nextUser();
    });
  }

  getUser(leadEmails[leadIndex++]);
}

function updateLeads(leads, done) {
  const leadEmails = Object.keys(leads);
  let leadIndex = 0;
  let numLeadsCreated = 0;

  function nextLead() {
    if (leadIndex < leadEmails.length) {
      return updateLead(leadEmails[leadIndex++]);
    }
    return done(null, numLeadsCreated);
  }
  function saveNewLead(email) {
    const newLeadData = leads[email]; 
    const name = newLeadData.name || email;
    const postData = {
      display_name: newLeadData.trial_organization || newLeadData.coco_schoolName ||name,
      name: newLeadData.trial_organization || newLeadData.coco_schoolName || name,
      contacts: [{
        emails: [{email: email}],
        name: name
      }],
      custom: {
        lastUpdated: new Date()
      }
    };
    if (newLeadData.trialData && newLeadData.trial_phoneNumber) {
      postData.contacts[0].phones = [{phone: newLeadData.trial_phoneNumber}];
    }
    for (const key in newLeadData) {
      postData.custom[key] = newLeadData[key];
    }
    const options = {
      uri: `https://${closeIoApiKey}:X@app.close.io/api/v1/lead/`,
      body: JSON.stringify(postData)
    };
    request.post(options, (error, response, body) => {
      if (error) return done(error);
      const result = JSON.parse(body);
      if (result.errors || result['field-errors']) {
        console.error(`New lead POST error for ${email}`);
        console.error(body);
      }
      else {
        numLeadsCreated++;
      }
      return nextLead();
    });
  }
  function updateLead(email) {
    const url = `https://${closeIoApiKey}:X@app.close.io/api/v1/lead/?query=email_address:${encodeURIComponent(email)}`;
    request.get(url, (error, response, body) => {
      if (error) return done(error);
      const data = JSON.parse(body);
      if (data.total_results === 0) {
        return saveNewLead(email);
      }
      return nextLead();
    });
  }

  updateLead(leadEmails[leadIndex++]);
}

function log(str) {
  console.log(new Date().toISOString() + " " + str);
}

