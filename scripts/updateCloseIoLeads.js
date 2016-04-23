// Upsert new lead data into Close.io

'use strict';
if (process.argv.length !== 7) {
  log("Usage: node <script> <Close.io general API key> <Close.io mail API key1> <Close.io mail API key2> <Intercom 'App ID:API key'> <mongo connection Url>");
  process.exit();
}

// TODO: Test multiple contacts
// TODO: Support multiple emails for the same contact (i.e diff trial and coco emails)
// TODO: Update notes with new data (e.g. coco user or intercom url)
// TODO: Find/fix case-sensitive bugs
// TODO: Use generators and promises
// TODO: Reduce response data via _fields param

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
const leadsToSkip = ['6 sınıflar', 'fdsafd', 'ashtasht', 'matt+20160404teacher3 school', 'sdfdsf', 'ddddd', 'dsfadsaf', "Nolan's School of Wonders"];

const demoRequestEmailTemplates = ['tmpl_s7BZiydyCHOMMeXAcqRZzqn0fOtk0yOFlXSZ412MSGm', 'tmpl_cGb6m4ssDvqjvYd8UaG6cacvtSXkZY3vj9b9lSmdQrf'];
const createTeacherEmailTemplates = ['tmpl_i5bQ2dOlMdZTvZil21bhTx44JYoojPbFkciJ0F560mn', 'tmpl_CEZ9PuE1y4PRvlYiKB5kRbZAQcTIucxDvSeqvtQW57G'];
const emailDelayMinutes = 27;

const scriptStartTime = new Date();
const closeIoApiKey = process.argv[2];
const closeIoMailApiKeys = [process.argv[3], process.argv[4]]; // Automatic mails sent as API owners
const intercomAppIdApiKey = process.argv[5];
const intercomAppId = intercomAppIdApiKey.split(':')[0];
const intercomApiKey = intercomAppIdApiKey.split(':')[1];
const mongoConnUrl = process.argv[6];
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
    if (trial.properties.firstName && trial.properties.lastName) {
      this.contacts[email.toLowerCase()].name = `${trial.properties.firstName} ${trial.properties.lastName}`;
    }
    else if (trial.properties.name) {
      this.contacts[email.toLowerCase()].name = trial.properties.name;
    }
    this.contacts[email.toLowerCase()].trial = trial;
  }
  addUser(email, user) {
    this.contacts[email.toLowerCase()].user = user;
  }
  getLeadPostData() {
    const postData = {
      display_name: this.name,
      name: this.name,
      status: 'Auto Attempted',
      contacts: this.getContactsPostData(),
      custom: {
        lastUpdated: new Date(),
        'Lead Origin': this.getLeadOrigin()
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
    if (!currentCustom['Lead Origin']) {
      putData['custom.Lead Origin'] = this.getLeadOrigin();
    }

    for (const email in this.contacts) {
      const props = this.contacts[email].trial.properties;
      if (props) {
        for (const prop in props) {
          if (commonTrialProperties.indexOf(prop) >= 0 && currentCustom[`demo_${prop}`] !== props[prop] && currentCustom[`demo_${prop}`].indexOf(props[prop]) < 0) {
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
  getLeadOrigin() {
    for (const email in this.contacts) {
      const props = this.contacts[email].trial.properties;
      switch (props.siteOrigin) {
        case 'create teacher':
          return 'Create Teacher';
        case 'convert teacher':
          return 'Convert Teacher';
      }
    }
    return 'Demo Request';
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
      try {
        const user = JSON.parse(body);
        lead.addIntercomUser(email, user);
      }
      catch (err) {
        console.log(err);
        console.log(body);
      }
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
      tasks.push(createAddContactFn(newContact, lead, existingLead));
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
      if (err) return done(err);

      // Send emails to new contacts
      const tasks = [];
      for (const contact of existingLead.contacts) {
        for (const email of contact.emails) {
          if (['create teacher', 'convert teacher'].indexOf(lead.contacts[email.email].trial.properties.siteOrigin) >= 0) {
            tasks.push(createSendEmailFn(email.email, existingLead.id, contact.id, getRandomEmailTemplate(createTeacherEmailTemplates)));
          }
          else {
            tasks.push(createSendEmailFn(email.email, existingLead.id, contact.id, getRandomEmailTemplate(demoRequestEmailTemplates)));
          }
        }
      }
      async.parallel(tasks, (err, results) => {
        return done(err);
      });
    });
  });
}

function createFindExistingLeadFn(email, name, existingLeads) {
  return (done) => {
    // console.log('DEBUG: findEmailLead', email);
    const query = `recipient:"${email}"`;
    const url = `https://${closeIoApiKey}:X@app.close.io/api/v1/lead/?query=${encodeURIComponent(query)}`;
    request.get(url, (error, response, body) => {
      if (error) return done(error);
      try {
        const data = JSON.parse(body);
        if (data.total_results > 0) {
          if (!existingLeads[name]) existingLeads[name] = [];
          for (const lead of data.data) {
            existingLeads[name].push(lead);
          }
        }
        return done();
      } catch (error) {
        // console.log(url);
        // console.log(error);
        // console.log(body);
        return done();
      }
    });
  };
}

function createUpdateLeadFn(lead, existingLeads) {
  return (done) => {
    // console.log('DEBUG: updateLead', lead.name);
    const query = `name:"${lead.name}"`;
    const url = `https://${closeIoApiKey}:X@app.close.io/api/v1/lead/?query=${encodeURIComponent(query)}`;
    request.get(url, (error, response, body) => {
      if (error) return done(error);
      try {
        const data = JSON.parse(body);
        if (data.total_results === 0) {
          if (existingLeads[lead.name.toLowerCase()]) {
            if (existingLeads[lead.name.toLowerCase()].length === 1) {
              console.log(`DEBUG: Using lead from email lookup: ${lead.name}`);
              return updateExistingLead(lead, existingLeads[lead.name.toLowerCase()][0], done);
            }
            console.error(`ERROR: ${existingLeads[lead.name.toLowerCase()].length} email leads found for ${lead.name}`);
            return done();
          }
          return saveNewLead(lead, done);
        }
        if (data.total_results > 1) {
          console.error(`ERROR: ${data.total_results} leads found for ${lead.name}`);
          return done();
        }
        return updateExistingLead(lead, data.data[0], done);
      } catch (error) {
        // console.log(url);
        // console.log(error);
        // console.log(body);
        return done();
      }
    });
  };
}

function createAddContactFn(postData, internalLead, externalLead) {
  return (done) => {
    // console.log('DEBUG: addContact', postData.lead_id);
    const options = {
      uri: `https://${closeIoApiKey}:X@app.close.io/api/v1/contact/`,
      body: JSON.stringify(postData)
    };
    request.post(options, (error, response, body) => {
      if (error) return done(error);
      const newContact = JSON.parse(body);
      if (newContact.errors || newContact['field-errors']) {
        console.error(`New Contact POST error for ${postData.lead_id}`);
        console.error(body);
        return done();
      }

      // Send emails to new contact
      const email = postData.emails[0].email;
      if (['create teacher', 'convert teacher'].indexOf(internalLead.contacts[email].trial.properties.siteOrigin) >= 0) {
        return sendMail(email, externalLead.id, newContact.id, getRandomEmailTemplate(createTeacherEmailTemplates), done);
      }
      else {
        return sendMail(email, externalLead.id, newContact.id, getRandomEmailTemplate(demoRequestEmailTemplates), done);
      }
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

function getRandomEmailTemplate(templates) {
  if (templates.length < 0) return '';
  return templates[Math.floor(Math.random() * templates.length)];
}

function isSameEmailTemplateType(template1, template2) {
  if (createTeacherEmailTemplates.indexOf(template1) >= 0 && createTeacherEmailTemplates.indexOf(template2) >= 0) {
    return true;
  }
  if (demoRequestEmailTemplates.indexOf(template1) >= 0 && demoRequestEmailTemplates.indexOf(template2) >= 0) {
    return true;
  }
  return false;
}

function getRandomEmailApiKey() {
  if (closeIoMailApiKeys.length < 0) return;
  return closeIoMailApiKeys[Math.floor(Math.random() * closeIoMailApiKeys.length)];
}

function createSendEmailFn(email, leadId, contactId, template) {
  return (done) => {
    return sendMail(email, leadId, contactId, template, done);
  };
}

function sendMail(toEmail, leadId, contactId, template, done) {
  // console.log('DEBUG: sendMail', toEmail, leadId, contactId, template);

  // Check for previously sent email
  const url = `https://${closeIoApiKey}:X@app.close.io/api/v1/activity/email/?lead_id=${leadId}`;
  request.get(url, (error, response, body) => {
    if (error) return done(error);
    try {
      const data = JSON.parse(body);
      for (const emailData of data.data) {
        if (!isSameEmailTemplateType(emailData.template_id, template)) continue;
        for (const email of emailData.to) {
          if (email.toLowerCase() === toEmail.toLowerCase()) {
            console.error("ERROR: sending duplicate email:", toEmail, leadId, contactId, template, emailData.contact_id);
            return done();
          }
        }
      }
    }
    catch (err) {
      console.log(err);
      console.log(body);
      return done();
    }

    // Send mail
    const dateScheduled = new Date();
    dateScheduled.setUTCMinutes(dateScheduled.getUTCMinutes() + emailDelayMinutes);
    const postData = {
      to: [toEmail],
      contact_id: contactId,
      lead_id: leadId,
      template_id: template,
      status: 'scheduled',
      date_scheduled: dateScheduled
    };
    const options = {
      uri: `https://${getRandomEmailApiKey()}:X@app.close.io/api/v1/activity/email/`,
      body: JSON.stringify(postData)
    };
    request.post(options, (error, response, body) => {
      if (error) return done(error);
      const result = JSON.parse(body);
      if (result.errors || result['field-errors']) {
        const errorMessage = `Send email POST error for ${toEmail} ${leadId} ${contactId}`;
        console.error(errorMessage);
        console.error(body);
        // console.error(postData);
        return done(errorMessage);
      }
      return done();
    });
  });
}

function updateLeads(leads, done) {
  // Lookup existing leads via email to protect against direct lead name querying later
  // Querying via lead name is unreliable
  const existingLeads = {};
  const tasks = [];
  for (const name in leads) {
    if (leadsToSkip.indexOf(name) >= 0) continue;
    for (const email in leads[name].contacts) {
      tasks.push(createFindExistingLeadFn(email.toLowerCase(), name.toLowerCase(), existingLeads));
    }
  }
  async.parallel(tasks, (err, results) => {
    const tasks = [];
    for (const name in leads) {
      if (leadsToSkip.indexOf(name) >= 0) continue;
      tasks.push(createUpdateLeadFn(leads[name], existingLeads));
    }
    async.parallel(tasks, (err, results) => {
      return done(err);
    });
  });
}

function log(str) {
  console.log(new Date().toISOString() + " " + str);
}
