// Upsert new lead data into Close.io

'use strict';
if (process.argv.length !== 9) {
  log("Usage: node <script> <Close.io general API key> <Close.io mail API key1> <Close.io mail API key2> <Close.io mail API key3> <Close.io EU mail API key> <Intercom 'App ID:API key'> <mongo connection Url>");
  process.exit();
}

// TODO: Test multiple contacts
// TODO: Support multiple emails for the same contact (i.e diff trial and coco emails)
// TODO: Update notes with new data (e.g. coco user or intercom url)
// TODO: Find/fix case-sensitive bugs
// TODO: Use generators and promises
// TODO: Reduce response data via _fields param
// TODO: Assumes 1:1 contact:email relationship (Close.io supports multiple emails for a single contact)
// TODO: Cleanup country/status lookup code

// Save as custom fields instead of user-specific lead notes (also saving nces_ props)
const commonTrialProperties = ['organization', 'city', 'state', 'country'];

// Old properties which are deprecated or moved
const customFieldsToRemove = [
  'coco_name', 'coco_firstName', 'coco_lastName', 'coco_gender', 'coco_numClassrooms', 'coco_numStudents', 'coco_role', 'coco_schoolName', 'coco_stats', 'coco_lastLevel',
  'email', 'intercom_url', 'name',
  'trial_created', 'trial_educationLevel', 'trial_phoneNumber', 'trial_email', 'trial_location', 'trial_name', 'trial_numStudents', 'trial_role', 'trial_userID', 'userID', 'trial_organization', 'trial_city', 'trial_state', 'trial_country',
  'demo_request_organization', 'demo_request_city', 'demo_request_state', 'demo_request_country'
];

// Skip these problematic leads
const leadsToSkip = ['6 sınıflar', 'fdsafd', 'ashtasht', 'matt+20160404teacher3 school', 'sdfdsf', 'ddddd', 'dsfadsaf', "Nolan's School of Wonders", 'asdfsadf'];

const createTeacherEmailTemplatesAuto1 = ['tmpl_i5bQ2dOlMdZTvZil21bhTx44JYoojPbFkciJ0F560mn', 'tmpl_CEZ9PuE1y4PRvlYiKB5kRbZAQcTIucxDvSeqvtQW57G'];
const demoRequestEmailTemplatesAuto1 = ['tmpl_s7BZiydyCHOMMeXAcqRZzqn0fOtk0yOFlXSZ412MSGm', 'tmpl_cGb6m4ssDvqjvYd8UaG6cacvtSXkZY3vj9b9lSmdQrf'];
const createTeacherInternationalEmailTemplateAuto1 = 'tmpl_8vsXwcr6dWefMnAEfPEcdHaxqSfUKUY8UKq6WfReGqG';
const demoRequestInternationalEmailTemplateAuto1 = 'tmpl_nnH1p3II7G7NJYiPOIHphuj4XUaDptrZk1mGQb2d9Xa';
const createTeacherNlEmailTemplatesAuto1 = ['tmpl_yf9tAPasz8KV7L414GhWWIclU8ewclh3Z8lCx2mCoIU', 'tmpl_OgPCV2p59uq0daVuUPF6r1rcQkxJbViyZ1ZMtW45jY8'];
const demoRequestNlEmailTemplatesAuto1 = ['tmpl_XGKyZm6gcbqZ5jirt7A54Vu8p68cLxAsKZtb9QBABUE', 'tmpl_xcfgQjUHPa6LLsbPWuPvEUElFXHmIpLa4IZEybJ0b0u'];

// Prioritized Close.io lead status match list
const closeIoInitialLeadStatuses = [
  {status: 'Inbound UK Auto Attempt 1', regex: /^uk$|\.uk$/},
  {status: 'Inbound Canada Auto Attempt 1', regex: /^ca$|\.ca$/},
  {status: 'Inbound AU Auto Attempt 1', regex: /^au$|\.au$/},
  {status: 'Inbound NZ Auto Attempt 1', regex: /^nz$|\.nz$/},
  {status: 'New US Schools Auto Attempt 1', regex: /^us$|\.us$|\.gov$|k12|sd/},
  {status: 'Inbound International Auto Attempt 1', regex: /^[A-Za-z]{2}$|\.[A-Za-z]{2}$/},
  {status: 'Auto Attempt 1', regex: /^[A-Za-z]*$/}
];
const defaultLeadStatus = 'Auto Attempt 1';
const defaultInternationalLeadStatus = 'Inbound International Auto Attempt 1';
const defaultEuLeadStatus = 'Inbound EU Auto Attempt 1';

const usSchoolStatuses = ['Auto Attempt 1', 'New US Schools Auto Attempt 1', 'New US Schools Auto Attempt 1 Low'];

const emailDelayMinutes = 27;

const scriptStartTime = new Date();
const closeIoApiKey = process.argv[2];
// Automatic mails sent as API owners, first key assumed to be primary and gets 50% of the leads
const closeIoMailApiKeys = [
  {
    apiKey: process.argv[3],
    weight: .7
  },
  {
    apiKey: process.argv[4],
    weight: .25
  },
  {
    apiKey: process.argv[5],
    weight: .05
  },
];
const closeIoEuMailApiKey = process.argv[6];
const intercomAppIdApiKey = process.argv[7];
const intercomAppId = intercomAppIdApiKey.split(':')[0];
const intercomApiKey = intercomAppIdApiKey.split(':')[1];
const mongoConnUrl = process.argv[8];
const MongoClient = require('mongodb').MongoClient;
const async = require('async');
const countryData = require('country-data');
const countryList = require('country-list')();
const parseDomain = require('parse-domain');
const request = require('request');

const earliestDate = new Date();
earliestDate.setUTCDate(earliestDate.getUTCDate() - 10);

// ** Main program

async.series([
  upsertLeads
],
(err, results) => {
  if (err) console.error(err);
  log("Script runtime: " + (new Date() - scriptStartTime));
}
);

function upsertLeads(done) {
  // log('DEBUG: Finding leads..');
  findCocoLeads((err, leads) => {
    if (err) return done(err);
    log(`Num leads ${Object.keys(leads).length}`);

    // log('DEBUG: Adding Intercom data..');
    addIntercomData(leads, (err) => {
      if (err) return done(err);

      // log('DEBUG: Updating leads..');
      updateLeads(leads, (err) => {
        return done(err);
      });
    });
  });
}

// ** Utilities

function getCountryCode(country, emails) {
  // console.log(`DEBUG: getCountryCode ${country} ${emails.length}`);
  if (country) {
    if (country.indexOf('Nederland') >= 0) return 'NL';
    let countryCode = countryList.getCode(country);
    if (countryCode) return countryCode;
  }
  for (const email of emails) {
    const tld = parseDomain(email).tld;
    if (tld) {
      const matches = /^[A-Za-z]*\.?([A-Za-z]{2})$/ig.exec(tld);
      if (matches && matches.length === 2) {
        return matches[1].toUpperCase();
      }
    }
  }
}

function getInitialLeadStatusViaCountry(country, trialRequests) {
  // console.log(`DEBUG: getInitialLeadStatusViaCountry ${country} ${trialRequests.length}`);
  if (/^u\.s\.?(\.a)?\.?$|^us$|usa|america|united states/ig.test(country)) {
    const status = 'New US Schools Auto Attempt 1'
    return isLowValueUsLead(status, trialRequests) ? `${status} Low` : status;
  }
  const highValueLead = isHighValueLead(trialRequests);
  if (/^england$|^uk$|^united kingdom$/ig.test(country) && highValueLead) {
    return 'Inbound UK Auto Attempt 1';
  }
  if (/^ca$|^canada$/ig.test(country)) {
    return 'Inbound Canada Auto Attempt 1';
  }
  if (/^au$|^australia$/ig.test(country)) {
    return 'Inbound AU Auto Attempt 1';
  }
  if (/^nz$|^new zealand$/ig.test(country)) {
    return 'Inbound AU Auto Attempt 1';
  }
  if (/bolivia|iran|korea|macedonia|taiwan|tanzania|^venezuela$/ig.test(country)) {
    return defaultInternationalLeadStatus;
  }
  const countryCode = countryList.getCode(country);
  if (countryCode) {
    if (countryCode === 'NL' || countryCode === 'BE') {
      return defaultEuLeadStatus;
    }
    if (isEuCountryCode(countryCode)) {
      return highValueLead ? 'Inbound EU Auto Attempt 1 High' : defaultEuLeadStatus;
    }
    return defaultInternationalLeadStatus;
  }
  return null;
}

function getInitialLeadStatusViaEmails(emails, trialRequests) {
  // console.log(`DEBUG: getInitialLeadStatusViaEmails ${emails.length} ${trialRequests.length}`);
  let currentStatus = null;
  let currentRank = closeIoInitialLeadStatuses.length;
  for (const email of emails) {
    let tld = parseDomain(email).tld;
    tld = tld ? tld.toLowerCase() : '';
    for (let rank = 0; rank < currentRank; rank++) {
      if (closeIoInitialLeadStatuses[rank].regex.test(tld)) {
        currentStatus = closeIoInitialLeadStatuses[rank].status;
        currentRank = rank;
      }
    }
  }
  if (!currentStatus || [defaultLeadStatus, defaultInternationalLeadStatus].indexOf(currentStatus) >= 0) {
    // Look for a better EU match
    const countryCode = getCountryCode(null, emails);
    if (countryCode === 'NL' || countryCode === 'BE') {
      return defaultEuLeadStatus;
    }
    if (isEuCountryCode(countryCode)) {
      return isHighValueLead(trialRequests) ? 'Inbound EU Auto Attempt 1 High' : defaultEuLeadStatus;
    }
  }
  currentStatus = currentStatus ? currentStatus : defaultLeadStatus;
  return isLowValueUsLead(currentStatus, trialRequests) ? `${currentStatus} Low` : currentStatus;
}

function isEuCountryCode(countryCode) {
  if (countryData.regions.northernEurope.countries.indexOf(countryCode) >= 0) {
    return true;
  }
  if (countryData.regions.southernEurope.countries.indexOf(countryCode) >= 0) {
    return true;
  }
  if (countryData.regions.easternEurope.countries.indexOf(countryCode) >= 0) {
    return true;
  }
  if (countryData.regions.westernEurope.countries.indexOf(countryCode) >= 0) {
    return true;
  }
  return false;
}

function isLowValueUsLead(status, trialRequests) {
  if (isUSSchoolStatus(status)) {
    for (const trialRequest of trialRequests) {
      if (parseInt(trialRequest.properties.nces_district_students) < 5000) {
        return true;
      }
      else if (parseInt(trialRequest.properties.nces_district_students) >= 5000) {
        return false;
      }
    }
    for (const trialRequest of trialRequests) {
      // Must match these values: https://github.com/codecombat/codecombat/blob/master/app/templates/teachers/request-quote-view.jade#L159
      if (['1-500', '500-1,000'].indexOf(trialRequest.properties.numStudentsTotal) >= 0) {
        return true;
      }
    }
  }
  return false;
}

function isHighValueLead(trialRequests) {
  for (const trialRequest of trialRequests) {
    // Must match these values: https://github.com/codecombat/codecombat/blob/master/app/templates/teachers/request-quote-view.jade#L159
    if (['5,000-10,000', '10,000+'].indexOf(trialRequest.properties.numStudentsTotal) >= 0) {
      return true;
    }
  }
  return false;
}

function isUSSchoolStatus(status) {
  return usSchoolStatuses.indexOf(status) >= 0;
}

function getEmailApiKey(leadStatus) {
  if (leadStatus === defaultEuLeadStatus) return closeIoEuMailApiKey;
  if (closeIoMailApiKeys.length < 0) return;
  const weightedList = [];
  for (let closeIoMailApiKey of closeIoMailApiKeys) {
    const multiples = closeIoMailApiKey.weight * 100;
    for (let i = 0; i < multiples; i++) {
      weightedList.push(closeIoMailApiKey.apiKey);
    }
  }
  return weightedList[Math.floor(Math.random() * weightedList.length)];
}

function getRandomEmailTemplate(templates) {
  if (templates.length < 0) return '';
  return templates[Math.floor(Math.random() * templates.length)];
}

function getEmailTemplate(siteOrigin, leadStatus, countryCode) {
  // console.log(`DEBUG: getEmailTemplate ${siteOrigin} ${leadStatus} ${countryCode}`);
  if (isUSSchoolStatus(leadStatus)) {
    if (['create teacher', 'convert teacher'].indexOf(siteOrigin) >= 0) {
      return getRandomEmailTemplate(createTeacherEmailTemplatesAuto1);
    }
    return getRandomEmailTemplate(demoRequestEmailTemplatesAuto1);
  }
  if (leadStatus === defaultEuLeadStatus && (countryCode === 'NL' || countryCode === 'BE')) {
    if (['create teacher', 'convert teacher'].indexOf(siteOrigin) >= 0) {
      return getRandomEmailTemplate(createTeacherNlEmailTemplatesAuto1);
    }
    return getRandomEmailTemplate(demoRequestNlEmailTemplatesAuto1);
  }
  if (['create teacher', 'convert teacher'].indexOf(siteOrigin) >= 0) {
    return createTeacherInternationalEmailTemplateAuto1;
  }
  return demoRequestInternationalEmailTemplateAuto1;
}

function isSameEmailTemplateType(template1, template2) {
  if (template1 == template2) {
    return true;
  }
  if (createTeacherEmailTemplatesAuto1.indexOf(template1) >= 0 && createTeacherEmailTemplatesAuto1.indexOf(template2) >= 0) {
    return true;
  }
  if (demoRequestEmailTemplatesAuto1.indexOf(template1) >= 0 && demoRequestEmailTemplatesAuto1.indexOf(template2) >= 0) {
    return true;
  }
  return false;
}

function log(str) {
  console.log(new Date().toISOString() + " " + str);
}

// ** Coco data collection methods and class

function findCocoLeads(done) {
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
        if (!leads[name]) leads[name] = new CocoLead(name);
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

function createAddIntercomDataFn(cocoLead, email) {
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
        cocoLead.addIntercomUser(email, user);
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

class CocoLead {
  constructor(name) {
    this.contacts = {};
    this.custom = {};
    this.name = name;
    this.trialRequests = [];
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
      if (user.last_request_at) {
        this.contacts[email.toLowerCase()].intercomLastSeen = new Date(parseInt(user.last_request_at) * 1000);
      }
      if (user.session_count) {
        this.contacts[email.toLowerCase()].intercomSessionCount = parseInt(user.session_count);
      }
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
    this.trialRequests.push(trial);
  }
  addUser(email, user) {
    this.contacts[email.toLowerCase()].user = user;
  }
  getInitialLeadStatus() {
    for (const email in this.contacts) {
      const props = this.contacts[email].trial.properties;
      if (props && props['country']) {
        const status = getInitialLeadStatusViaCountry(props['country'], this.trialRequests);
        if (status) return status;
      }
    }
    return getInitialLeadStatusViaEmails(Object.keys(this.contacts), this.trialRequests);
  }
  getLeadPostData() {
    const postData = {
      display_name: this.name,
      name: this.name,
      status: this.getInitialLeadStatus(),
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
          if (commonTrialProperties.indexOf(prop) >= 0 || /nces_/ig.test(prop)) {
            postData.custom[`demo_${prop}`] = props[prop];
          }
        }
      }
      if (this.contacts[email].intercomLastSeen && (this.contacts[email].intercomLastSeen > (postData.custom['intercom_lastSeen'] || 0))) {
        postData.custom['intercom_lastSeen'] = this.contacts[email].intercomLastSeen;
      }
      if (this.contacts[email].intercomSessionCount && (this.contacts[email].intercomSessionCount > (postData.custom['intercom_sessionCount'] || 0))) {
        postData.custom['intercom_sessionCount'] = this.contacts[email].intercomSessionCount;
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
        let haveNcesData = false;
        for (const prop in props) {
          if (/nces_/ig.test(prop)) {
            haveNcesData = true;
            putData[`custom.demo_${prop}`] = props[prop];
          }
        }
        for (const prop in props) {
          // Always overwrite common props if we have NCES data, because other fields more likely to be accurate
          if (commonTrialProperties.indexOf(prop) >= 0 && (haveNcesData || !currentCustom[`demo_${prop}`] || currentCustom[`demo_${prop}`] !== props[prop] && currentCustom[`demo_${prop}`].indexOf(props[prop]) < 0)) {
            putData[`custom.demo_${prop}`] = props[prop];
          }
        }
      }
      if (this.contacts[email].intercomLastSeen && (this.contacts[email].intercomLastSeen > (currentCustom['intercom_lastSeen'] || 0))) {
        putData['custom.intercom_lastSeen'] = this.contacts[email].intercomLastSeen;
      }
      if (this.contacts[email].intercomSessionCount && (this.contacts[email].intercomSessionCount > (currentCustom['intercom_sessionCount'] || 0))) {
        putData['custom.intercom_sessionCount'] = this.contacts[email].intercomSessionCount;
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
        if (contact.intercomLastSeen) noteData += `intercom_lastSeen: ${contact.intercomLastSeen}\n`;
        if (contact.intercomSessionCount) noteData += `intercom_sessionCount: ${contact.intercomSessionCount}\n`;
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

// ** Upsert Close.io methods

function updateExistingLead(lead, existingLead, userApiKeyMap, done) {
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
      tasks.push(createAddContactFn(newContact, lead, existingLead, userApiKeyMap));
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
  const postData = lead.getLeadPostData();
  // console.log(`DEBUG: saveNewLead ${lead.name} ${postData.status}`);
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
          const countryCode = getCountryCode(lead.contacts[email.email].trial.properties.country, [email.email]);
          const emailTemplate = getEmailTemplate(lead.contacts[email.email].trial.properties.siteOrigin, postData.status, countryCode);
          tasks.push(createSendEmailFn(email.email, existingLead.id, contact.id, emailTemplate, postData.status));
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
        console.log(error);
        // console.log(body);
        return done(error);
      }
    });
  };
}

function createUpdateLeadFn(lead, existingLeads, userApiKeyMap) {
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
              // console.log(`DEBUG: Using lead from email lookup: ${lead.name}`);
              return updateExistingLead(lead, existingLeads[lead.name.toLowerCase()][0], userApiKeyMap, done);
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
        return updateExistingLead(lead, data.data[0], userApiKeyMap, done);
      } catch (error) {
        // console.log(url);
        console.log(`ERROR: updateLead ${error}`);
        // console.log(body);
        return done();
      }
    });
  };
}

function createAddContactFn(postData, internalLead, closeIoLead, userApiKeyMap) {
  return (done) => {
    // console.log('DEBUG: addContact', postData.lead_id);

    // Create new contact
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

      // Find previous internal user for new contact correspondence
      const url = `https://${closeIoApiKey}:X@app.close.io/api/v1/activity/email/?lead_id=${closeIoLead.id}`;
      request.get(url, (error, response, body) => {
        if (error) return done(error);
        const data = JSON.parse(body);
        let emailApiKey = data.data && data.data.length > 0 ? userApiKeyMap[data.data[0].user_id] : getEmailApiKey(closeIoLead.status_label);
        if (!emailApiKey) emailApiKey = getEmailApiKey(closeIoLead.status_label);

        // Send email to new contact
        const email = postData.emails[0].email;
        const countryCode = getCountryCode(internalLead.contacts[email].trial.properties.country, [email]);
        const emailTemplate = getEmailTemplate(internalLead.contacts[email].trial.properties.siteOrigin, closeIoLead.status_label);
        sendMail(email, closeIoLead.id, newContact.id, emailTemplate, emailApiKey, emailDelayMinutes, done);
      });
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

function createSendEmailFn(email, leadId, contactId, template, leadStatus) {
  return (done) => {
    return sendMail(email, leadId, contactId, template, getEmailApiKey(leadStatus), emailDelayMinutes, done);
  };
}

function sendMail(toEmail, leadId, contactId, template, emailApiKey, delayMinutes, done) {
  // console.log('DEBUG: sendMail', toEmail, leadId, contactId, template, emailApiKey, delayMinutes);

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
    dateScheduled.setUTCMinutes(dateScheduled.getUTCMinutes() + delayMinutes);
    const postData = {
      to: [toEmail],
      contact_id: contactId,
      lead_id: leadId,
      template_id: template,
      status: 'scheduled',
      date_scheduled: dateScheduled
    };
    const options = {
      uri: `https://${emailApiKey}:X@app.close.io/api/v1/activity/email/`,
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
  const userApiKeyMap = {};
  let createGetUserFn = (apiKey) => {
    return (done) => {
      const url = `https://${apiKey}:X@app.close.io/api/v1/me/`;
      request.get(url, (error, response, body) => {
        if (error) return done();
        const results = JSON.parse(body);
        userApiKeyMap[results.id] = apiKey;
        return done();
      });
    };
  }
  const tasks = [];
  for (const closeIoMailApiKey of closeIoMailApiKeys) {
    tasks.push(createGetUserFn(closeIoMailApiKey.apiKey));
  }
  async.parallel(tasks, (err, results) => {
    if (err) console.log(err);
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
    async.series(tasks, (err, results) => {
      if (err) return done(err);
      const tasks = [];
      for (const name in leads) {
        if (leadsToSkip.indexOf(name) >= 0) continue;
        tasks.push(createUpdateLeadFn(leads[name], existingLeads, userApiKeyMap));
      }
      async.series(tasks, (err, results) => {
        return done(err);
      });
    });
  });
}
