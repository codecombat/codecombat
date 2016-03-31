// Upsert new lead data into Close.io

'use strict';
if (process.argv.length !== 5) {
  log("Usage: node <script> <Close.io API key> <Intercom 'App ID:API key'> <mongo connection Url>");
  process.exit();
}

// TODO: Test multiple contacts
// TODO: Support multiple emails for the same contact (i.e diff trial and coco emails)
// TODO: Update notes with new data (e.g. coco user or intercom url)
// TODO: Find/fix case-sensitive bugs
// TODO: Use generators and promises

// Save as custom fields instead of user-specific lead notes
const commonTrialProperties = ['organization', 'city', 'state', 'country'];

// Old properties which are deprecated or moved
const customFieldsToRemove = [
  'coco_name', 'coco_firstName', 'coco_lastName', 'coco_gender', 'coco_numClassrooms', 'coco_numStudents', 'coco_role', 'coco_schoolName', 'coco_stats', 'coco_lastLevel',
  'email', 'intercom_url', 'name',
  'trial_created', 'trial_educationLevel', 'trial_phoneNumber', 'trial_email', 'trial_location', 'trial_name', 'trial_numStudents', 'trial_role', 'trial_userID', 'userID', 'trial_organization', 'trial_city', 'trial_state', 'trial_country',
  'demo_request_organization', 'demo_request_city', 'demo_request_state', 'demo_request_country'
];

// Skip these problematic leads
const leadsToSkip = ['6 sınıflar', 'fdsafd', 'ashtasht'];

const scriptStartTime = new Date();
const closeIoApiKey = process.argv[2];
const intercomAppIdApiKey = process.argv[3];
const intercomAppId = intercomAppIdApiKey.split(':')[0];
const intercomApiKey = intercomAppIdApiKey.split(':')[1];
const mongoConnUrl = process.argv[4];
const MongoClient = require('mongodb').MongoClient;
const async = require('async');
const request = require('request');

const earliestDate = new Date();
earliestDate.setUTCDate(earliestDate.getUTCDate() - 10);

// log('DEBUG: Finding leads..');
findLeads((err, leads) => {
  if (err) {
    console.error(err);
    return;
  }
  log(`Num leads ${Object.keys(leads).length}`);
  // log('DEBUG: Adding Intercom data..');
  addIntercomData(leads, (err) => {
    if (err) {
      console.error(err);
      return;
    }
    // log('DEBUG: Updating leads..');
    updateLeads(leads, (err) => {
      if (err) {
        console.error(err);
        return;
      }
      log("Script runtime: " + (new Date() - scriptStartTime));
    });
  });
});


/* Helpers */

class Lead {
  constructor(name) {
    this.contacts = {};
    this.custom = {};
    this.name = name;
  }
  addClassroom(email, classroom) {
    if (!this.contacts[email.toLowerCase()]) this.contacts[email.toLowerCase()] = {};
    const contact = this.contacts[email.toLowerCase()];
    contact.numClassrooms = contact.numClassrooms ? contact.numClassrooms + 1 : 1;
    if (classroom.members && classroom.members.length) {
      contact.numStudents = contact.numStudents ? contact.numStudents + classroom.members.length : classroom.members.length;
    }
  }
  addIntercomUser(email, user) {
    if (user && user.id) {
      if (!this.contacts[email.toLowerCase()]) this.contacts[email.toLowerCase()] = {};
      this.contacts[email.toLowerCase()].intercomUrl = `https://app.intercom.io/a/apps/${intercomAppId}/users/${user.id}/`;
    }
  }
  addTrialRequest(email, trial) {
    if (!this.contacts[email.toLowerCase()]) this.contacts[email.toLowerCase()] = {};
    this.contacts[email.toLowerCase()].name = trial.properties.name;
    this.contacts[email.toLowerCase()].trial = trial;
  }
  addUser(email, user) {
    this.contacts[email.toLowerCase()].user = user;
  }
  getLeadPostData() {
    const postData = {
      display_name: this.name,
      name: this.name,
      status: 'Not Attempted',
      contacts: this.getContactsPostData(),
      custom: {
        lastUpdated: new Date(),
        'Lead Origin': 'Demo Request'
      }
    };
    for (const email in this.contacts) {
      const props = this.contacts[email].trial.properties;
      if (props) {
        for (const prop in props) {
          if (commonTrialProperties.indexOf(prop) >= 0) {
            postData.custom[`demo_${prop}`] = props[prop];
          }
        }
      }
    }
    return postData;
  }
  getLeadPutData(currentLead) {
    // console.log('DEBUG: getLeadPutData', currentLead.name);
    const putData = {};
    const currentCustom = currentLead.custom || {};
    if (currentCustom['Lead Origin'] !== 'Demo Request') {
      putData['custom.Lead Origin'] = 'Demo Request';
    }

    for (const email in this.contacts) {
      const props = this.contacts[email].trial.properties;
      if (props) {
        for (const prop in props) {
          if (commonTrialProperties.indexOf(prop) >= 0 && currentCustom[`demo_${prop}`] !== props[prop]) {
            putData[`custom.demo_${prop}`] = props[prop];
          }
        }
      }
    }
    for (const field of customFieldsToRemove) {
      if (currentCustom[field]) {
        putData[`custom.${field}`] = null;
      }
    }
    if (Object.keys(putData).length > 0) {
      putData[`custom.lastUpdated`] = new Date();
    }
    return putData;
  }
  getContactsPostData(existingLead) {
    const postData = [];
    const existingEmails = {};
    if (existingLead) {
      const existingContacts = existingLead.contacts || [];
      for (const contact of existingContacts) {
        const emails = contact.emails || [];
        for (const email of emails) {
          existingEmails[email.email.toLowerCase()] = true;
        }
      }
    }
    for (const email in this.contacts) {
      if (existingEmails[email]) continue;
      const contact = this.contacts[email];
      const data = {
        emails: [{email: email}],
        name: contact.name
      }
      const props = contact.trial.properties;
      if (props.phoneNumber) {
        data.phones = [{phone: props.phoneNumber}];
      }
      if (props.role) {
        data.title = props.role;
      }
      else if (contact.user || contact.user.role) {
        data.title = contact.user.role;
      }
      postData.push(data);
    }
    return postData;
  }
  getNotesPostData(currentNotes) {
    // Post activity notes for each contact
    function noteExists(email) {
      if (currentNotes) {
        for (const note of currentNotes) {
          if (note.note.indexOf(email) >= 0) {
            return true;
          }
        }
      }
      return false;
    }
    const notes = [];
    for (const email in this.contacts) {
      if (!noteExists(email)) {
        const contact = this.contacts[email];
        let noteData = "";
        const trial = contact.trial
        if (trial.properties) {
          const props = trial.properties;
          if (props.name) {
            noteData += `${props.name}\n`;
          }
          if (props.email) {
            noteData += `demo_email: ${props.email.toLowerCase()}\n`;
          }
          if (trial.created) {
            noteData += `demo_request: ${trial.created}\n`;
          }
          if (props.educationLevel) {
            noteData += `demo_educationLevel: ${props.educationLevel.join(', ')}\n`;
          }
          for (const prop in props) {
            if (['email', 'educationLevel', 'created'].indexOf(prop) >= 0 || commonTrialProperties.indexOf(prop) >= 0) continue;
            noteData += `demo_${prop}: ${props[prop]}\n`;
          }
        }
        if (contact.intercomUrl) noteData += `intercom_url: ${contact.intercomUrl}\n`;
        if (contact.user) {
          const user = contact.user
          noteData += `coco_userID: ${user._id}\n`;
          if (user.firstName) noteData += `coco_firstName: ${user.firstName}\n`;
          if (user.lastName) noteData += `coco_lastName: ${user.lastName}\n`;
          if (user.name) noteData += `coco_name: ${user.name}\n`;
          if (user.emaillower) noteData += `coco_email: ${user.emailLower}\n`;
          if (user.gender) noteData += `coco_gender: ${user.gender}\n`;
          if (user.lastLevel) noteData += `coco_lastLevel: ${user.lastLevel}\n`;
          if (user.role) noteData += `coco_role: ${user.role}\n`;
          if (user.schoolName) noteData += `coco_schoolName: ${user.schoolName}\n`;
          if (user.stats && user.stats.gamesCompleted) noteData += `coco_gamesCompleted: ${user.stats.gamesCompleted}\n`;
          noteData += `coco_preferredLanguage: ${user.preferredLanguage || 'en-US'}\n`;
        }
        if (contact.numClassrooms) {
          noteData += `coco_numClassrooms: ${contact.numClassrooms}\n`
        }
        if (contact.numStudents) {
          noteData += `coco_numStudents: ${contact.numStudents}\n`
        }
        notes.push(noteData);
      }
    }
    return notes;
  }
}

function findLeads(done) {
  MongoClient.connect(mongoConnUrl, (err, db) => {
    if (err) return done(err);

    // Recent trial requests
    const query = {$and: [{created: {$gte: earliestDate}}, {type: 'course'}]};
    db.collection('trial.requests').find(query).toArray((err, trialRequests) => {
      if (err) {
        db.close();
        return done(err);
      }
      const leads = {};
      const emailLeadMap = {};
      const emails = [];
      for (const trialRequest of trialRequests) {
        if (!trialRequest.properties || !trialRequest.properties.email) continue;
        const email = trialRequest.properties.email.toLowerCase();
        emails.push(email);
        const name = trialRequest.properties.organization || trialRequest.properties.name || email;
        if (!leads[name]) leads[name] = new Lead(name);
        leads[name].addTrialRequest(email, trialRequest);
        emailLeadMap[email] = leads[name];
      }

      // Users for trial requests
      const query = {$and: [
        {emailLower: {$in: emails}},
        {anonymous: false}
      ]};
      db.collection('users').find(query).toArray((err, users) => {
        if (err) {
          db.close();
          return done(err);
        }
        const userIDs = [];
        const userLeadMap = {};
        const userEmailMap = {};
        for (const user of users) {
          const email = user.emailLower;
          emailLeadMap[email].addUser(email, user);
          userIDs.push(user._id);
          userLeadMap[user._id.valueOf()] = emailLeadMap[email];
          userEmailMap[user._id.valueOf()] = email;
        }

        // Classrooms for users
        const query = {ownerID: {$in: userIDs}};
        db.collection('classrooms').find(query).toArray((err, classrooms) => {
          if (err) {
            db.close();
            return done(err);
          }

          for (const classroom of classrooms) {
            userLeadMap[classroom.ownerID.valueOf()].addClassroom(userEmailMap[classroom.ownerID.valueOf()], classroom);
          }
          db.close();
          return done(null, leads);
        });
      });
    });
  });
}

function createAddIntercomDataFn(lead, email) {
  return (done) => {
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
      lead.addIntercomUser(email, user);
      return done();
    });
  };
}

function addIntercomData(leads, done) {
  const tasks = []
  for (const name in leads) {
    for (const email in leads[name].contacts) {
      tasks.push(createAddIntercomDataFn(leads[name], email));
    }
  }
  async.parallel(tasks, (err, results) => {
    return done(err);
  });
}

function updateExistingLead(lead, existingLead, done) {
  // console.log('DEBUG: updateExistingLead', existingLead.id);
  const putData = lead.getLeadPutData(existingLead);
  const options = {
    uri: `https://${closeIoApiKey}:X@app.close.io/api/v1/lead/${existingLead.id}/`,
    body: JSON.stringify(putData)
  };
  request.put(options, (error, response, body) => {
    if (error) return done(error);
    const result = JSON.parse(body);
    if (result.errors || result['field-errors']) {
      console.error(`Update existing lead PUT error for ${lead.name}`);
      console.error(body);
      // console.log(putData);
      return done();
    }

    // Add contacts
    const newContacts = lead.getContactsPostData(existingLead);
    const tasks = []
    for (const newContact of newContacts) {
      newContact.lead_id = existingLead.id;
      tasks.push(createAddContactFn(newContact));
    }
    async.parallel(tasks, (err, results) => {
      if (err) return done(err);

      // Add notes
      const url = `https://${closeIoApiKey}:X@app.close.io/api/v1/activity/note/?lead_id=${existingLead.id}`;
      request.get(url, (error, response, body) => {
        if (error) return done(error);
        const currentNotes = JSON.parse(body).data;
        const newNotes = lead.getNotesPostData(currentNotes);
        const tasks = []
        for (const newNote of newNotes) {
          tasks.push(createAddNoteFn(existingLead.id, newNote));
        }
        async.parallel(tasks, (err, results) => {
          return done(err);
        });
      });
    });
  });
}

function saveNewLead(lead, done) {
  // console.log('DEBUG: saveNewLead', lead.name);
  const postData = lead.getLeadPostData();
  const options = {
    uri: `https://${closeIoApiKey}:X@app.close.io/api/v1/lead/`,
    body: JSON.stringify(postData)
  };
  request.post(options, (error, response, body) => {
    if (error) return done(error);
    const existingLead = JSON.parse(body);
    if (existingLead.errors || existingLead['field-errors']) {
      console.error(`New lead POST error for ${lead.name}`);
      console.error(body);
      // console.error(JSON.stringify(postData, null, 2));
      return done();
    }

    // Add notes
    const newNotes = lead.getNotesPostData();
    const tasks = []
    for (const newNote of newNotes) {
      tasks.push(createAddNoteFn(existingLead.id, newNote));
    }
    async.parallel(tasks, (err, results) => {
      return done(err);
    });
  });
}


function createUpdateLeadFn(lead) {
  return (done) => {
    // console.log('DEBUG: updateLead', lead.name);
    const url = `https://${closeIoApiKey}:X@app.close.io/api/v1/lead/?query=name:${encodeURIComponent(lead.name)}`;
    request.get(url, (error, response, body) => {
      if (error) return done(error);
      const data = JSON.parse(body);
      if (data.total_results === 0) {
        return saveNewLead(lead, done);
      }
      if (data.total_results > 1) {
        // console.error(`${data.total_results} leads found for ${lead.name}`);
        return done();
      }
      return updateExistingLead(lead, data.data[0], done);
    });
  };
}

function createAddContactFn(postData) {
  return (done) => {
    // console.log('DEBUG: addContact', postData.lead_id);
    const options = {
      uri: `https://${closeIoApiKey}:X@app.close.io/api/v1/activity/Contact/`,
      body: JSON.stringify(postData)
    };
    request.post(options, (error, response, body) => {
      if (error) return done(error);
      const result = JSON.parse(body);
      if (result.errors || result['field-errors']) {
        console.error(`New Contact POST error for ${leadId}`);
        console.error(body);
      }
      return done();
    });
  };
}

function createAddNoteFn(leadId, newNote) {
  return (done) => {
    // console.log('DEBUG: addNote', leadId);
    const notePostData = {
      note: newNote,
      lead_id: leadId
    };
    const options = {
      uri: `https://${closeIoApiKey}:X@app.close.io/api/v1/activity/note/`,
      body: JSON.stringify(notePostData)
    };
    request.post(options, (error, response, body) => {
      if (error) return done(error);
      const result = JSON.parse(body);
      if (result.errors || result['field-errors']) {
        console.error(`New note POST error for ${leadId}`);
        console.error(body);
        // console.error(notePostData);
      }
      return done();
    });
  };
}

function updateLeads(leads, done) {
  const tasks = []
  for (const name in leads) {
    if (leadsToSkip.indexOf(name) >= 0) continue;
    tasks.push(createUpdateLeadFn(leads[name]));
  }
  async.parallel(tasks, (err, results) => {
    return done(err);
  });
}

function log(str) {
  console.log(new Date().toISOString() + " " + str);
}
