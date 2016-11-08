// Upsert new lead data into Close.io

'use strict';
if (process.argv.length !== 10) {
  log("Usage: node <script> <Close.io general API key> <Close.io mail API key1> <Close.io mail API key2> <Close.io mail API key3> <Close.io mail API key4> <Close.io EU mail API key> <Intercom 'App ID:API key'> <mongo connection Url>");
  process.exit();
}

// TODO: Test multiple contacts
// TODO: Support multiple emails for the same contact (i.e diff trial and coco emails)
// TODO: Update notes with new data (e.g. coco user or intercom url)
// TODO: Reduce response data via _fields param
// TODO: Assumes 1:1 contact:email relationship (Close.io supports multiple emails for a single contact)
// TODO: Cleanup country/status lookup code
// TODO: automation states should be driven at contact-level
// TODO: unclear when we stop execution for an error vs. print it and continue

// Save as custom fields instead of user-specific lead notes (also saving nces_ props)
const commonTrialProperties = ['organization', 'district', 'city', 'state', 'country'];

// Old properties which are deprecated or moved
const customFieldsToRemove = [
  'coco_name', 'coco_firstName', 'coco_lastName', 'coco_gender', 'coco_numClassrooms', 'coco_numStudents', 'coco_role', 'coco_schoolName', 'coco_stats', 'coco_lastLevel',
  'email', 'intercom_url', 'name',
  'trial_created', 'trial_educationLevel', 'trial_phoneNumber', 'trial_email', 'trial_location', 'trial_name', 'trial_numStudents', 'trial_role', 'trial_userID', 'userID', 'trial_organization', 'trial_city', 'trial_state', 'trial_country',
  'demo_request_organization', 'demo_request_city', 'demo_request_state', 'demo_request_country'
];

const createTeacherEmailTemplatesAuto1 = ['tmpl_i5bQ2dOlMdZTvZil21bhTx44JYoojPbFkciJ0F560mn', 'tmpl_CEZ9PuE1y4PRvlYiKB5kRbZAQcTIucxDvSeqvtQW57G'];
const demoRequestEmailTemplatesAuto1 = [
  'tmpl_cGb6m4ssDvqjvYd8UaG6cacvtSXkZY3vj9b9lSmdQrf', // (Auto1) Demo Request Short
  'tmpl_2hV6OdOXtsObLQK9qlRdpf0C9QKbER06T17ksGYOoUE', // (Auto1) Demo Request With Questions
  'tmpl_Q0tweZ5H4xs2E489KwdYj3HET9PpzkQ7jgDQb9hOMTR', // (Auto1) Demo Request Without Questions
];
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

const closeParallelLimit = 10;
const intercomParallelLimit = 100;

const scriptStartTime = new Date();
const closeIoApiKey = process.argv[2]; // Matt
// Automatic mails sent as API owners, first key assumed to be primary and gets 50% of the leads
// Names in comments are for reference, but Source of Truth is updateSalesLeads.sh on the analytics server
const closeIoMailApiKeys = [
  {
    apiKey: process.argv[3], // Lisa
    weight: .8
  },
  {
    apiKey: process.argv[4], // Elliot
    weight: .1
  },
  {
    apiKey: process.argv[5], // Nolan
    weight: .05
  },
  {
    apiKey: process.argv[6], // Sean
    weight: .05
  },
];
const closeIoEuMailApiKey = process.argv[7]; // Jurian
const intercomAppIdApiKey = process.argv[8];
const intercomAppId = intercomAppIdApiKey.split(':')[0];
const intercomApiKey = intercomAppIdApiKey.split(':')[1];
const mongoConnUrl = process.argv[9];
const MongoClient = require('mongodb').MongoClient;
const async = require('async');
const countryData = require('country-data');
const countryList = require('country-list')();
const parseDomain = require('parse-domain');
const request = require('request');

const earliestDate = new Date();
earliestDate.setUTCDate(earliestDate.getUTCDate() - 10);

const apiKeyEmailMap = {};
const emailApiKeyMap = {};
const userApiKeyMap = {};

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
  findCocoContacts((err, contacts) => {
    if (err) return done(err);
    log(`Num contacts ${Object.keys(contacts).length}`);

    // log('DEBUG: Adding Intercom data..');
    addIntercomData(contacts, (err) => {
      if (err) return done(err);

      updateCloseApiKeyMaps((err) => {
        if (err) return done(err);

        // log('DEBUG: Updating contacts..');
        updateCloseLeads(contacts, (err) => {
          return done(err);
        });
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
    const domain = parseDomain(email);
    if (!domain) continue;
    const tld = domain.tld;
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

function findCocoContacts(done) {
  MongoClient.connect(mongoConnUrl, (err, db) => {
    if (err) return done(err);

    // Recent trial requests
    const query = {$and: [{created: {$gte: earliestDate}}, {type: 'course'}]};
    db.collection('trial.requests').find(query).toArray((err, trialRequests) => {
      if (err) {
        db.close();
        return done(err);
      }
      const contacts = {};
      for (const trialRequest of trialRequests) {
        if (!trialRequest.properties || !trialRequest.properties.email) continue;
        const email = trialRequest.properties.email.toLowerCase();
        if (contacts[email]) {
          console.log(`ERROR: found additional course trial requests for email ${email}, skipping.`);
          continue;
        }
        contacts[email] = new CocoContact(email, trialRequest);
      }

      // Users for trial requests
      const query = {$and: [
        {emailLower: {$in: Object.keys(contacts)}},
        {anonymous: false}
      ]};
      db.collection('users').find(query).toArray((err, users) => {
        if (err) {
          db.close();
          return done(err);
        }
        const userIDs = [];
        const userContactMap = {};
        const userEmailMap = {};
        for (const user of users) {
          const email = user.emailLower;
          contacts[email].addUser(user);
          userIDs.push(user._id);
          userContactMap[user._id.valueOf()] = contacts[email];
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
            userContactMap[classroom.ownerID.valueOf()].addClassroom(classroom);
          }
          db.close();
          return done(null, contacts);
        });
      });
    });
  });
}

function createAddIntercomDataFn(contact) {
  return (done) => {
    const options = {
      url: `https://api.intercom.io/users?email=${encodeURIComponent(contact.email)}`,
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
        contact.addIntercomUser(user);
      }
      catch (err) {
        console.log(err);
        console.log(body);
      }
      return done();
    });
  };
}

function addIntercomData(contacts, done) {
  const tasks = []
  for (const email in contacts) {
    tasks.push(createAddIntercomDataFn(contacts[email]));
  }
  async.parallelLimit(tasks, intercomParallelLimit, done);
}

class CocoContact {
  constructor(email, trialRequest) {
    this.email = email;
    this.name = email;
    this.trialRequest = trialRequest;
    if (this.trialRequest.properties.firstName && this.trialRequest.properties.lastName) {
      this.name = `${this.trialRequest.properties.firstName} ${this.trialRequest.properties.lastName}`;
    }
    else if (this.trialRequest.properties.name) {
      this.name = this.trialRequest.properties.name;
    }
    this.leadName = trialRequest.properties.nces_name || trialRequest.properties.organization
      || trialRequest.properties.school || trialRequest.properties.district
      || trialRequest.properties.nces_district || email;
  }
  addClassroom(classroom) {
    this.numClassrooms = this.numClassrooms ? this.numClassrooms + 1 : 1;
    if (classroom.members && classroom.members.length) {
      this.numStudents = this.numStudents ? this.numStudents + classroom.members.length : classroom.members.length;
    }
  }
  addIntercomUser(user) {
    if (user && user.id) {
      this.intercomUrl = `https://app.intercom.io/a/apps/${intercomAppId}/users/${user.id}/`;
      if (user.last_request_at) {
        this.intercomLastSeen = new Date(parseInt(user.last_request_at) * 1000);
      }
      if (user.session_count) {
        this.intercomSessionCount = parseInt(user.session_count);
      }
    }
  }
  addUser(user) {
    this.user = user;
  }
  getInitialLeadStatus() {
    const props = this.trialRequest.properties;
    if (props && props['country']) {
      const status = getInitialLeadStatusViaCountry(props['country'], [this.trialRequest]);
      if (status) return status;
    }
    return getInitialLeadStatusViaEmails([this.email], [this.trialRequest]);
  }
  getLeadPostData() {
    const postData = {
      display_name: this.leadName,
      name: this.leadName,
      status: this.getInitialLeadStatus(),
      contacts: [this.getContactPostData()],
      custom: {
        lastUpdated: new Date(),
        'Lead Origin': this.getLeadOrigin()
      }
    };
    const emailApiKey = getEmailApiKey(postData.status);
    if (apiKeyEmailMap[emailApiKey]) postData.custom['auto_sales_email'] = apiKeyEmailMap[emailApiKey];
    const props = this.trialRequest.properties;
    if (props) {
      for (const prop in props) {
        if (commonTrialProperties.indexOf(prop) >= 0 || /nces_/ig.test(prop)) {
          postData.custom[`demo_${prop}`] = props[prop];
        }
      }
    }
    if (this.intercomLastSeen && (this.intercomLastSeen > (postData.custom['intercom_lastSeen'] || 0))) {
      postData.custom['intercom_lastSeen'] = this.intercomLastSeen;
    }
    if (this.intercomSessionCount && (this.intercomSessionCount > (postData.custom['intercom_sessionCount'] || 0))) {
      postData.custom['intercom_sessionCount'] = this.intercomSessionCount;
    }
    return postData;
  }
  getLeadPutData(closeLead, resetStatus) {
    // console.log('DEBUG: getLeadPutData', closeLead.id, 'resetStatus: ', !!resetStatus);
    const putData = resetStatus ? {
      status: this.getInitialLeadStatus() // So new contacts get auto2 emails
    } : {};
    if (resetStatus) {
      log(`Resetting status of ${closeLead.id} to "${putData.status}"`)
    }
    const currentCustom = closeLead.custom || {};
    if (!currentCustom['Lead Origin']) {
      putData['custom.Lead Origin'] = this.getLeadOrigin();
    }
    const props = this.trialRequest.properties;
    if (props) {
      for (const prop in props) {
        if (!currentCustom[`demo_${prop}`] && (commonTrialProperties.indexOf(prop) >= 0 || /nces_/ig.test(prop))) {
          putData[`custom.demo_${prop}`] = props[prop];
        }
      }
    }
    if (this.intercomLastSeen && (this.intercomLastSeen > (currentCustom['intercom_lastSeen'] || 0))) {
      putData['custom.intercom_lastSeen'] = this.intercomLastSeen;
    }
    if (this.intercomSessionCount && (this.intercomSessionCount > (currentCustom['intercom_sessionCount'] || 0))) {
      putData['custom.intercom_sessionCount'] = this.intercomSessionCount;
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
    const props = this.trialRequest.properties;
    switch (props.siteOrigin) {
      case 'create teacher':
        return 'Create Teacher';
      case 'convert teacher':
        return 'Convert Teacher';
    }
    return 'Demo Request';
  }
  getContactPostData(existingLead) {
    const data = {
      emails: [{email: this.email}],
      name: this.name
    }
    if (existingLead) {
      data.lead_id = existingLead.id;
    }
    const props = this.trialRequest.properties;
    if (props.nces_phone) {
      data.phones = [{phone: props.nces_phone}];
    }
    else if (props.phoneNumber) {
      data.phones = [{phone: props.phoneNumber}];
    }
    if (props.role) {
      data.title = props.role;
    }
    else if (this.user && this.user.role) {
      data.title = this.user.role;
    }
    return data;
  }
  getNotePostData(currentNotes) {
    // Post activity notes for each contact
    for (const note of currentNotes || []) {
      if (note.note.indexOf(this.email) >= 0) {
        return [];
      }
    }
    let noteData = "";
    if (this.trialRequest.properties) {
      const props = this.trialRequest.properties;
      if (props.name) {
        noteData += `${props.name}\n`;
      }
      if (props.email) {
        noteData += `demo_email: ${props.email.toLowerCase()}\n`;
      }
      if (this.trialRequest.created) {
        noteData += `demo_request: ${this.trialRequest.created}\n`;
      }
      if (props.educationLevel) {
        noteData += `demo_educationLevel: ${props.educationLevel.join(', ')}\n`;
      }
      for (const prop in props) {
        if (['email', 'educationLevel', 'created'].indexOf(prop) >= 0) continue;
        noteData += `demo_${prop}: ${props[prop]}\n`;
      }
    }
    if (this.intercomUrl) noteData += `intercom_url: ${this.intercomUrl}\n`;
    if (this.intercomLastSeen) noteData += `intercom_lastSeen: ${this.intercomLastSeen}\n`;
    if (this.intercomSessionCount) noteData += `intercom_sessionCount: ${this.intercomSessionCount}\n`;
    if (this.user) {
      const user = this.user
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
    if (this.numClassrooms) {
      noteData += `coco_numClassrooms: ${this.numClassrooms}\n`
    }
    if (this.numStudents) {
      noteData += `coco_numStudents: ${this.numStudents}\n`
    }
    return noteData;
  }
}

// ** Upsert Close.io methods

function updateCloseLead(cocoContact, closeLead, done) {
  // console.log('DEBUG: updateCloseLead', cocoContact.email, closeLead.id);

  // Check for existing contact
  let contactIsNew = true;
  const existingContacts = closeLead.contacts || [];
  for (const contact of existingContacts) {
    const emails = contact.emails || [];
    for (const email of emails) {
      if (email.email.toLowerCase() === cocoContact.email) {
        console.log(`DEBUG: contact ${cocoContact.email} already exists on ${closeLead.id}`);
        contactIsNew = false;
      }
    }
  }

  const putData = cocoContact.getLeadPutData(closeLead, contactIsNew);
  const options = {
    uri: `https://${closeIoApiKey}:X@app.close.io/api/v1/lead/${closeLead.id}/`,
    body: JSON.stringify(putData)
  };

  request.put(options, (error, response, body) => {
    if (error) return done(error);
    const result = JSON.parse(body);
    if (result.errors || result['field-errors']) {
      console.error(`Update existing lead PUT error for ${cocoContact.leadName}`);
      return done();
    }

    if (!contactIsNew) {
      return done();
    }

    // Add Close contact
    addContact(cocoContact, closeLead, (err, results) => {
      if (err) return done(err);

      // Add Close note
      const url = `https://${closeIoApiKey}:X@app.close.io/api/v1/activity/note/?lead_id=${closeLead.id}`;
      request.get(url, (error, response, body) => {
        if (error) return done(error);
        const currentNotes = JSON.parse(body).data;
        addNote(cocoContact, closeLead, currentNotes, done);
      });
    });
  });
}

function saveNewCloseLead(cocoContact, done) {
  const postData = cocoContact.getLeadPostData();
  // console.log(`DEBUG: saveNewCloseLead ${cocoContact.email} ${postData.status}`);
  const options = {
    uri: `https://${closeIoApiKey}:X@app.close.io/api/v1/lead/`,
    body: JSON.stringify(postData)
  };
  request.post(options, (error, response, body) => {
    if (error) return done(error);
    const newCloseLead = JSON.parse(body);
    if (newCloseLead.errors || newCloseLead['field-errors']) {
      console.error(`New lead POST error for ${cocoContact.email}`);
      console.error(`New lead postData: `, JSON.stringify(postData));
      console.error(newCloseLead.errors || newCloseLead['field-errors']);
      return done();
    }

    // Add contact note
    addNote(cocoContact, newCloseLead, null, (err, results) => {
      if (err) return done(err);

      // Send email to new contact
      let newContact = null;
      for (const contact of newCloseLead.contacts) {
        for (const email of contact.emails) {
          if (email.email === cocoContact.email) {
            newContact = contact;
            break;
          }
        }
        if (newContact) break;
      }
      if (!newContact) {
        console.error(`ERROR: Could not find contact ${cocoContact.email} in new lead ${newCloseLead.id}`);
        return done();
      }
      const countryCode = getCountryCode(cocoContact.trialRequest.properties.country, [cocoContact.email]);
      const emailTemplate = getEmailTemplate(cocoContact.trialRequest.properties.siteOrigin, postData.status, countryCode);
      sendMail(cocoContact.email, newCloseLead, newContact.id, emailTemplate, emailDelayMinutes, done);
    });
  });
}

function createFindExistingLeadFn(email, existingLeads) {
  return (done) => {
    // console.log('DEBUG: findEmailLead', email);
    const query = `email_address:"${email}"`;
    const url = `https://${closeIoApiKey}:X@app.close.io/api/v1/lead/?query=${encodeURIComponent(query)}`;
    request.get(url, (error, response, body) => {
      if (error) return done(error);
      try {
        const data = JSON.parse(body);
        if (data.total_results > 0) {
          if (!existingLeads[email]) existingLeads[email] = [];
          for (const lead of data.data) {
            existingLeads[email].push(lead);
          }
        }
        return done();
      } catch (error) {
        console.log(`ERROR: failed to parse email lead search for ${email}`);
        console.log(error);
        return done(error);
      }
    });
  };
}

function createUpdateCloseLeadFn(cocoContact, existingLeads) {
  // New contact lead matching algorithm:
  // 1. New contact email exists
  // 2. New contact NCES school id exists
  // 3. New contact NCES district id and no NCES school id
  // 4. New contact school name and no NCES data
  // 5. New contact district name and no NCES data
  return (done) => {
    // console.log('DEBUG: createUpdateCloseLeadFn', cocoContact.email);

    if (existingLeads[cocoContact.email]) {
      if (existingLeads[cocoContact.email].length === 1) {
        // console.log(`DEBUG: Using lead from email lookup: ${cocoContact.email}`);
        return updateCloseLead(cocoContact, existingLeads[cocoContact.email][0], done);
      }
      console.error(`ERROR: ${existingLeads[cocoContact.email].length} email leads found for ${cocoContact.email}`);
      return done();
    }

    let nces_district_id = null, nces_school_id = null;
    if (cocoContact.trialRequest.properties.nces_district_id) {
      nces_district_id = cocoContact.trialRequest.properties.nces_district_id;
    }
    if (cocoContact.trialRequest.properties.nces_id) {
      nces_school_id = cocoContact.trialRequest.properties.nces_id;
    }
    // console.log(`DEBUG: updateCloseLead district ${nces_district_id} school ${nces_school_id}`);

    let query = `name:"${cocoContact.leadName}"`;
    if (nces_school_id) {
      query = `custom.demo_nces_id:"${nces_school_id}"`;
    }
    else if (nces_district_id) {
      query = `custom.demo_nces_district_id:"${nces_district_id}" custom.demo_nces_id:"" custom.demo_nces_name:""`;
    }
    const url = `https://${closeIoApiKey}:X@app.close.io/api/v1/lead/?query=${encodeURIComponent(query)}`;
    request.get(url, (error, response, body) => {
      if (error) return done(error);
      try {
        const data = JSON.parse(body);
        if (data.total_results > 1) {
          console.error(`ERROR: ${data.total_results} leads found with info from demo request: email=${cocoContact.email}, leadName=${cocoContact.leadName}, nces_district_id=${nces_district_id}, nces_school_id=${nces_school_id}. Final query: ${query}`);
          return done();
        }
        if (data.total_results === 1) {
          return updateCloseLead(cocoContact, data.data[0], done);
        }
        return saveNewCloseLead(cocoContact, done);
      } catch (error) {
        console.log(`ERROR: createUpdateCloseLeadFn ${cocoContact.email}`);
        console.log(error);
        return done();
      }
    });
  };
}

function addContact(cocoContact, closeLead, done) {
  // console.log('DEBUG: addContact', closeLead.id, cocoContact.email);
  const postData = cocoContact.getContactPostData(closeLead);
  const options = {
    uri: `https://${closeIoApiKey}:X@app.close.io/api/v1/contact/`,
    body: JSON.stringify(postData)
  };
  request.post(options, (error, response, body) => {
    if (error) return done(error);
    const newContact = JSON.parse(body);
    if (newContact.errors || newContact['field-errors']) {
      console.error(`New Contact POST error for ${postData.lead_id}`);
      console.error(`Contact post data: `, JSON.stringify(postData));
      return done();
    }

    const countryCode = getCountryCode(cocoContact.trialRequest.properties.country, [cocoContact.email]);
    const emailTemplate = getEmailTemplate(cocoContact.trialRequest.properties.siteOrigin, closeLead.status_label, countryCode);
    sendMail(cocoContact.email, closeLead, newContact.id, emailTemplate, emailDelayMinutes, done);
  });
}

function addNote(cocoContact, closeLead, currentNotes, done) {
  // console.log('DEBUG: addNote', cocoContact.email, closeLead.id);
  const newNote = cocoContact.getNotePostData(currentNotes);
  const notePostData = {
    note: newNote,
    lead_id: closeLead.id
  };
  const options = {
    uri: `https://${closeIoApiKey}:X@app.close.io/api/v1/activity/note/`,
    body: JSON.stringify(notePostData)
  };
  request.post(options, (error, response, body) => {
    if (error) return done(error);
    const result = JSON.parse(body);
    if (result.errors || result['field-errors']) {
      console.error(`New note POST error for ${closeLead.id}`);
      console.error('Note contents: ', JSON.stringify(notePostData));
      console.error(result.errors || result['field-errors']);
    }
    return done();
  });
}

function sendMail(toEmail, closeLead, contactId, template, delayMinutes, done) {
  // console.log('DEBUG: sendMail', toEmail, leadId, contactId, template, delayMinutes);

  // Sales contact email precedence: previous email to contact, previous email to lead, lead custom field, lead status default
  let emailApiKey = null;
  let emailDiffContactApiKey = null;

  // Check for previously sent email
  const url = `https://${closeIoApiKey}:X@app.close.io/api/v1/activity/email/?lead_id=${closeLead.id}`;
  request.get(url, (error, response, body) => {
    if (error) return done(error);
    try {
      const data = JSON.parse(body);
      for (const emailData of data.data) {

        // Check for previous email to this contact
        if (!emailApiKey && userApiKeyMap[emailData.user_id]) {
          for (const email of emailData.to) {
            if (email.toLowerCase() === toEmail.toLowerCase()) {
              emailApiKey = userApiKeyMap[emailData.user_id];
              break;
            }
          }
        }

        // Save previous lead email to this lead
        if (!emailDiffContactApiKey && !emailApiKey && userApiKeyMap[emailData.user_id]) {
          emailDiffContactApiKey = userApiKeyMap[emailData.user_id];
        }

        // Never send this email template to this contact again
        if (isSameEmailTemplateType(emailData.template_id, template)) {
          for (const email of emailData.to) {
            if (email.toLowerCase() === toEmail.toLowerCase()) {
              console.error("ERROR: sending duplicate email:", toEmail, closeLead.id, contactId, template, emailData.contact_id);
              return done();
            }
          }
        }
      }
    }
    catch (err) {
      console.error(`ERROR: parsing previous email sent GET for ${toEmail} ${closeLead.id}`);
      console.log(err);
      return done();
    }

    if (!emailApiKey && emailDiffContactApiKey) emailApiKey = emailDiffContactApiKey;
    if (!emailApiKey) {
      if (closeLead.custom && closeLead.custom['auto_sales_email'] && emailApiKeyMap[closeLead.custom['auto_sales_email']]) {
        emailApiKey = emailApiKeyMap[closeLead.custom['auto_sales_email']];
      }
      else {
        emailApiKey = getEmailApiKey(closeLead.status_label);
      }
    }

    // Send mail
    const dateScheduled = new Date();
    dateScheduled.setUTCMinutes(dateScheduled.getUTCMinutes() + delayMinutes);
    const postData = {
      to: [toEmail],
      contact_id: contactId,
      lead_id: closeLead.id,
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
        const errorMessage = `Send email POST error for ${toEmail} ${closeLead.id} ${contactId}`;
        console.error(errorMessage);
        return done(errorMessage);
      }
      return done();
    });
  });
}

function updateCloseLeads(cocoContacts, done) {
  // Lookup existing leads via email to protect against direct lead name querying later
  // Querying via lead name is unreliable
  const existingLeads = {};
  const tasks = [];
  for (const email in cocoContacts) {
    tasks.push(createFindExistingLeadFn(email, existingLeads));
  }
  async.parallelLimit(tasks, closeParallelLimit, (err, results) => {
    if (err) return done(err);
    const tasks = [];
    for (const email in cocoContacts) {
      tasks.push(createUpdateCloseLeadFn(cocoContacts[email], existingLeads));
    }
    async.series(tasks, done);
  });
}

function updateCloseApiKeyMaps(done) {
  let createGetUserFn = (apiKey) => {
    return (done) => {
      const url = `https://${apiKey}:X@app.close.io/api/v1/me/?_fields=id,email`;
      request.get(url, (error, response, body) => {
        if (error) return done();
        const results = JSON.parse(body);
        apiKeyEmailMap[apiKey] = results.email;
        emailApiKeyMap[results.email] = apiKey;
        userApiKeyMap[results.id] = apiKey;
        return done();
      });
    };
  }
  const tasks = [createGetUserFn(closeIoEuMailApiKey)];
  for (const closeIoMailApiKey of closeIoMailApiKeys) {
    tasks.push(createGetUserFn(closeIoMailApiKey.apiKey));
  }
  async.parallelLimit(tasks, closeParallelLimit, done);
}
