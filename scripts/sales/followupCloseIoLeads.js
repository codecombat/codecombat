// Follow up on Close.io leads

'use strict';
const wrap = require('co').wrap;
const async = require('async');
const request = require('request');
const Promise = require('bluebird');
Promise.promisifyAll(request);

const runAsScript = (process.argv.length === 8);
if (!runAsScript) {
  log("Usage: node <script> <Close.io general API key> <Close.io mail API key1> <Close.io mail API key2> <Close.io mail API key3>");
}

// TODO: Assumes 1:1 contact:email relationship (Close.io supports multiple emails for a single contact)
// TODO: Duplicate lead lookups when checking per-email (e.g. existing tasks)
// TODO: 2nd follow up email activity does not handle paged activity results
// TODO: sendMail copied from updateCloseIoLeads.js
// TODO: template values copied from updateCloseIoLeads.js
// TODO: status change is not related to specific lead contacts, e.g. lead_7fQAZKtX7tPYe352JpaUULVaVA99Ppq4HlsHXrRkpA9
// TODO: update status after adding a call task
// TODO: automation states should be driven at contact-level
// TODO: unclear when we stop execution for an error vs. print it and continue

const createTeacherEmailTemplatesAuto1 = ['tmpl_i5bQ2dOlMdZTvZil21bhTx44JYoojPbFkciJ0F560mn', 'tmpl_CEZ9PuE1y4PRvlYiKB5kRbZAQcTIucxDvSeqvtQW57G'];
const demoRequestEmailTemplatesAuto1 = [
  'tmpl_s7BZiydyCHOMMeXAcqRZzqn0fOtk0yOFlXSZ412MSGm', // (Auto1) Demo Request Long
  'tmpl_cGb6m4ssDvqjvYd8UaG6cacvtSXkZY3vj9b9lSmdQrf', // (Auto1) Demo Request Short
  'tmpl_2hV6OdOXtsObLQK9qlRdpf0C9QKbER06T17ksGYOoUE', // (Auto1) Demo Request With Questions
  'tmpl_Q0tweZ5H4xs2E489KwdYj3HET9PpzkQ7jgDQb9hOMTR', // (Auto1) Demo Request Without Questions
];
const createTeacherInternationalEmailTemplateAuto1 = 'tmpl_8vsXwcr6dWefMnAEfPEcdHaxqSfUKUY8UKq6WfReGqG';
const demoRequestInternationalEmailTemplateAuto1 = 'tmpl_nnH1p3II7G7NJYiPOIHphuj4XUaDptrZk1mGQb2d9Xa';
const createTeacherEmailTemplatesAuto2 = ['tmpl_pGPtKa07ioISupdSc1MAzNC57K40XoA4k0PI1igi8Ec', 'tmpl_AYAcviU8NQGLbMGKSp3EmcBLha0gQw4cHSOR55Fmoha'];
const demoRequestEmailTemplatesAuto2 = [
  'tmpl_dmnK7IVpkyYfPYAl1rChhm9lClH5lJ9pQAZoPr7cvLt', // (Auto2) Demo Request Long
  'tmpl_HJ5zebh1SqC1QydDto05VPUMu4F7i5M35Llq7bzgfTw', // (Auto2) Demo Request Short
  'tmpl_oMH8Gqsh3dPl17FsBrz8dIF14sfTiySASDkmzyRlpWg', // (Auto2) Demo Request With Questions
  'tmpl_JuuQsQhWNpDMYmN9rwD5Kk7oBELVZI4fMmJNUQC7A8j', // (Auto2) Demo Request Without Questions
];
const createTeacherInternationalEmailTemplatesAuto2 = ['tmpl_a6Syzzy6ri9MErfXQySM5UfaF5iNIv1VCArYowAEICT', 'tmpl_jOqWLgT0G19Eqs7qZaAeNwtiull7UrSX4ZuvkYRM2gC'];
const demoRequestInternationalEmailTemplatesAuto2 = ['tmpl_wz4SnDZMjNmAhp3MIuZaSMmjJTy5IW75Rcy3MYGb6Ti', 'tmpl_5oJ0YQMZFqNi3DgW7hplD6JS2zHqkB4Gt7Fj1u19Nks'];

if(runAsScript){
  var scriptStartTime = new Date();
  var closeIoApiKey = process.argv[2];
}

// TODO: Generalize this for other keys?
// TODO:
function closeIoMailApiKeys() {
  return [process.argv[3], process.argv[4], process.argv[5], process.argv[6], process.argv[7]]; // Automatic mails sent as API owners
}
const earliestDate = new Date();
earliestDate.setUTCDate(earliestDate.getUTCDate() - 10);

// ** Main program

if (runAsScript){
  console.log("Running as a script!");
  process.on('unhandledRejection', (reason, promise)=>{
    console.trace()
    log(`WARNING: Promise rejection went unhandled: ${reason}`)
  })
  setTimeout(()=>{
    async.series([
      sendSecondFollowupMails,
      addCallTasks
    // TODO: Cancel call tasks
    ],
    (err, results) => {
      if (err) console.error(err);
      log("Script runtime: " + (new Date() - scriptStartTime));
    });
  }, 0)
}

// ** Utilities

function getRandomEmailTemplateAuto2(template) {
  if (createTeacherEmailTemplatesAuto1.indexOf(template) >= 0) {
    return getRandomEmailTemplate(createTeacherEmailTemplatesAuto2);
  }
  if (demoRequestEmailTemplatesAuto1.indexOf(template) >= 0) {
    return getRandomEmailTemplate(demoRequestEmailTemplatesAuto2);
  }
  if (createTeacherInternationalEmailTemplateAuto1 == template) {
    return getRandomEmailTemplate(createTeacherInternationalEmailTemplatesAuto2);
  }
  if (demoRequestInternationalEmailTemplateAuto1 === template) {
    return getRandomEmailTemplate(demoRequestInternationalEmailTemplatesAuto2);
  }
  return null;
}

function getRandomEmailTemplate(templates) {
  if (templates.length < 0) return null;
  return templates[Math.floor(Math.random() * templates.length)];
}

function isSameEmailTemplateType(template1, template2) {
  if (createTeacherEmailTemplatesAuto1.indexOf(template1) >= 0 && createTeacherEmailTemplatesAuto1.indexOf(template2) >= 0) {
    return true;
  }
  if (demoRequestEmailTemplatesAuto1.indexOf(template1) >= 0 && demoRequestEmailTemplatesAuto1.indexOf(template2) >= 0) {
    return true;
  }
  return false;
}

function isTemplateAuto1(template) {
  if (createTeacherEmailTemplatesAuto1.indexOf(template) >= 0) return true;
  if (demoRequestEmailTemplatesAuto1.indexOf(template) >= 0) return true;
  if (createTeacherInternationalEmailTemplateAuto1 == template) return true;
  if (demoRequestInternationalEmailTemplateAuto1 === template) return true;
  return false;
}

function isTemplateAuto2(template) {
  if (createTeacherEmailTemplatesAuto2.indexOf(template) >= 0) return true;
  if (demoRequestEmailTemplatesAuto2.indexOf(template) >= 0) return true;
  if (createTeacherInternationalEmailTemplatesAuto2.indexOf(template) >= 0) return true;
  if (demoRequestInternationalEmailTemplatesAuto2.indexOf(template) >= 0) return true;
  return false;
}

function log(str) {
  if (runAsScript) {
    console.log(new Date().toISOString() + " " + str);
  }
}

function contactHasEmailAddress(contact) {
  return Boolean(contact.emails && contact.emails.length > 0);
}

function contactHasPhoneNumbers(contact) {
  return Boolean(contact.phones && contact.phones.length > 0);
}

function lowercaseEmailsForContact(contact) {
  if (contactHasEmailAddress(contact)) {
    return contact.emails.map((e) => {return e.email.toLowerCase();});
  } else {
    return [];
  }
}

// ** Close.io network requests

const getJsonUrl = wrap(function*(url){
  const response = yield request.getAsync({url:url, json: true});
  if (response.statusCode >= 400) {
    throw(new Error(`getJonUrl got an error. {url: ${url}, response.statusCode: ${response.statusCode} response.body: ${response.body}`))
  }
  return response.body;
})

const postJsonUrl = wrap(function*(options){
  const response = yield request.postAsync(options);
  if (response.body.errors || response.body['field-errors']) {
    throw(`ERROR: Close.io API returned an error (POST).`, {
      errors: response.body.errors,
      'field-errors': response.body['field-errors'],
    });
  }
  return response.body;
})

const putJsonUrl = wrap(function*(options){
  const response = yield request.putAsync(options);
  if (response.body.errors || response.body['field-errors']) {
    throw(`ERROR: Close.io API returned an error (PUT). ` + JSON.stringify({
      errors: response.body.errors,
      'field-errors': response.body['field-errors'],
    }));
  }
  return response.body;
})

const getSomeLeads = wrap(function* (options) {
  const getParams = '?' + Object.keys(options).map((key) => {
    return `${key}=${encodeURIComponent(options[key])}`;
  }).join('&')
  const url = `https://${closeIoApiKey}:X@app.close.io/api/v1/lead/${getParams}`;
  return yield getJsonUrl(url);
})

const getTasksForLead = wrap(function* (lead) {
  const lead_id = lead.id || lead;
  const url = `https://${closeIoApiKey}:X@app.close.io/api/v1/task/?lead_id=${lead.id}`;
  return yield getJsonUrl(url);
})

const getEmailActivityForLead = wrap(function* (lead) {
  const lead_id = lead.id || lead;
  const url = `https://${closeIoApiKey}:X@app.close.io/api/v1/activity/email/?lead_id=${lead.id}`;
  const activity = yield getJsonUrl(url);
  if (!activity) {
    throw(`ERROR: ${lead.id} has no activity!`); // TODO: sanity check
  } else if (activity.has_more) {
    throw(`ERROR: ${lead.id} has more activities than returned!`); // TODO: sanity check
  } else {
    return activity;
  }
})

const getActivityForLead = wrap(function* (lead) {
  const lead_id = lead.id || lead;
  const url = `https://${closeIoApiKey}:X@app.close.io/api/v1/activity/?lead_id=${lead.id}`;
  const activity = yield getJsonUrl(url);
  if (activity.has_more) {
    throw(`ERROR: ${lead.id} has more activities than returned! Returning nothing instead.`);
  } else {
    return activity;
  }
})

const postEmailActivity = wrap(function* (postData, emailApiKey) {
  console.log(`POSTing email activity: ${JSON.stringify(postData)}`);
  const options = {
    uri: `https://${emailApiKey}:X@app.close.io/api/v1/activity/email/`,
    json: postData
  };
  return yield postJsonUrl(options);
})

const postTask = wrap(function* (postData) {
  const options = {
    uri: `https://${closeIoApiKey}:X@app.close.io/api/v1/task/`,
    json: postData
  };
  return yield postJsonUrl(options);
})

// ** Close.io logic

const sendMail = wrap(function* (toEmail, leadId, contactId, template, emailApiKey, delayMinutes) {
  // log('DEBUG: sendMail', toEmail, leadId, contactId, template, emailApiKey, delayMinutes);

  // Check for previously sent email
  const data = yield getEmailActivityForLead(leadId)
  if (!data) { return };
  for (const emailData of data.data) {
    if (!isSameEmailTemplateType(emailData.template_id, template)) continue;
    for (const email of emailData.to) {
      if (email.toLowerCase() === toEmail.toLowerCase()) {
        log("ERROR: sending duplicate email:", toEmail, leadId, contactId, template, emailData.contact_id);
        return; //TODO: Do this checking outside of here instead of pretending we sent an email
      }
    }
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
  try {
    log(`Sent email to ${toEmail} ${leadId} ${contactId}`);
    return yield postEmailActivity(postData, emailApiKey);
  } catch (error) {
    throw(`Send email POST error for ${toEmail} ${leadId} ${contactId}: `, error);
  }
})

const updateLeadStatus = wrap(function* (lead, status) {
  // log(`DEBUG: updateLeadStatus ${lead.id} ${status}`);
  const putData = {status: status};
  const options = {
    uri: `https://${closeIoApiKey}:X@app.close.io/api/v1/lead/${lead.id}/`,
    json: putData
  };
  try {
    log('Updating lead status: ' + JSON.stringify({ lead: lead.id, status }));
    return yield putJsonUrl(options);
  } catch (error) {
    throw(`Update existing lead status PUT error for ${lead.id}: ${error}`);
  }
})

const theyHaveNotResponded = wrap(function* (lead, contact) {
  const activities = yield module.exports.getActivityForLead(lead);
  if(!activities || !activities.data || !(activities.data.length > 0)) {
    log(`No activities found for lead ${lead.id} — shouldn't send them any more autos-emails`);
    return false;
  }
  activities.data.sort((a,b) => { return new Date(a.date_updated) < new Date(b.date_updated) });
  const emails = activities.data.filter((act) => { return act._type === 'Email' });
  const emailAddresses = module.exports.lowercaseEmailsForContact(contact);
  const they_have_replied = emails.some((emailData) => {
    return emailAddresses.some((emailAddress) => {
      return emailData.sender && emailData.sender.match(new RegExp(emailAddress, 'i'));
    });
  });
  // TODO: Stop auto-emails if we send them an email or call them.
  // const we_have_sent_manually = emails.some(function(email){ return ??? });
  if (they_have_replied) {
    log(`Email response found from ${emailAddresses} — shouldn't send them any more autos-emails.`);
  }
  return !they_have_replied
})

function createSendFollowupMailFn(userApiKeyMap, latestDate, lead, contactEmails) {
  // Find first auto mail
  // Find activities since first auto mail
  // Send send auto mail of same template type (create or demo) from same user who sent first email
  // Update status to Auto Attempt 2 or New US Schools Auto Attempt 2
  return wrap(function* (done) {
    log(`DEBUG: sendFollowupMail ${lead.id}, to one of ${contactEmails}`);

    // Skip leads with tasks
    const tasks = yield module.exports.getTasksForLead(lead);

    if (!tasks || tasks.total_results > 0) { return done() }

    // Find all lead activities
    const activities = yield module.exports.getActivityForLead(lead);//TODO: use better variable names
    const auto1Emails = activities.data.filter((activity) => {
      return activity._type === 'Email'
             && contactEmails.indexOf(activity.to[0].toLowerCase()) >= 0
             && module.exports.isTemplateAuto1(activity.template_id);
    })
    if (auto1Emails.length > 1) {
      log(`ERROR: ${lead.id} sent multiple auto1 emails!?`);
      return done();
    }
    const firstMailActivity = auto1Emails[0];

    if (!firstMailActivity) {
      log(`ERROR: No first auto mail sent for ${lead.id}`);
      return done();
    }
    if (new Date(firstMailActivity.date_created) > latestDate) {
      log(`DEBUG: First auto mail too recent ${firstMailActivity.date_created} ${lead.id}`);
      return done();
    }

    // Find activity since first auto mail, that's not email to a different contact's email
    const recentActivity = activities.data.find((activity) => {
      return activity.id !== firstMailActivity.id
             && activity._type === 'Email'
             && contactEmails.indexOf(activity.to[0].toLowerCase()) < 0
             && new Date(activity.date_created) >= new Date(firstMailActivity.date_created)
    })

    if (activities.data.find((activity) => { return module.exports.isTemplateAuto2(activity.template_id) })){
      log(`ERROR: ${lead.id} Already sent an auto2 email`);
      return done();
    }

    // TODO: Prefilter for this outside of this function
    if (!recentActivity) {
      let template = module.exports.getRandomEmailTemplateAuto2(firstMailActivity.template_id);
      if (!template) {
        log(`ERROR: no auto2 template selected for ${lead.id} ${firstMailActivity.template_id}`);
        return done();
      }
      // log(`TODO: ${firstMailActivity.to[0]} ${lead.id} ${firstMailActivity.contact_id} ${template} ${userApiKeyMap[firstMailActivity.user_id]}`);
      try {
        yield module.exports.sendMail(firstMailActivity.to[0], lead.id, firstMailActivity.contact_id, template, userApiKeyMap[firstMailActivity.user_id], 0);
      } catch (error) {
        return done(error);
      }

      // TODO: some sort of callback problem that stops the series here

      // TODO: manage this status mapping better
      const statusMap = {
        "Auto Attempt 1": "Auto Attempt 2",
        "New US Schools Auto Attempt 1": "New US Schools Auto Attempt 2",
        "Inbound AU Auto Attempt 1": "Inbound AU Auto Attempt 2",
        "Inbound Canada Auto Attempt 1": "Inbound Canada Auto Attempt 2",
        "Inbound NZ Auto Attempt 1": "Inbound NZ Auto Attempt 2",
        "Inbound UK Auto Attempt 1": "Inbound UK Auto Attempt 2",
      }
      const newStatus = statusMap[lead.status_label]
      if (newStatus) {
        return done(null, yield module.exports.updateLeadStatus(lead, newStatus));
      }
      else {
        log(`ERROR: unknown lead status ${lead.id} ${lead.status_label}`);
        return done();
      }
    }
    else {
      log(`DEBUG: Not sending mail; Found recent activity after auto1 mail for ${lead.id}`);
      // log(firstMailActivity.template_id, recentActivity);
      return done();
    }
  });
}

const getUserIdByApiKey = wrap(function* (apiKey) {
  const url = `https://${apiKey}:X@app.close.io/api/v1/me/`;
  const user = yield getJsonUrl(url);
  return user.id;
})

function sendSecondFollowupMails (done) {
  log("Sending second followup emails...");
  // Find all leads with auto 1 status, created since earliestDate
  // log("DEBUG: sendSecondFollowupMails");
  const userApiKeyMap = {};
  let createGetUserFn = (apiKey) => {
    return (done) => {
      module.exports.getUserIdByApiKey(apiKey).then((userId) => {
        userApiKeyMap[userId] = apiKey;
        done();
      }).catch((error)=>{
        log(`ERROR: Error looking up user by API key ${apiKey}: ${error}`);
      });
    }
  }
  const tasks = [];
  for (const apiKey of module.exports.closeIoMailApiKeys()) {
    tasks.push(createGetUserFn(apiKey));
  }
  async.parallel(tasks, (err, results) => {
    if (err) log(err);
    const latestDate = new Date();
    latestDate.setUTCDate(latestDate.getUTCDate() - 3);
    // TODO: manage this status list better
    const query = `date_created > ${earliestDate.toISOString().substring(0, 19)} (lead_status:"Auto Attempt 1" or lead_status:"New US Schools Auto Attempt 1" or lead_status:"Inbound Canada Auto Attempt 1" or lead_status:"Inbound AU Auto Attempt 1" or lead_status:"Inbound NZ Auto Attempt 1" or lead_status:"Inbound UK Auto Attempt 1")`;
    const limit = 100;
    const nextPage = wrap(function *(skip) {
      let has_more = false;
      const leadsResults = yield module.exports.getSomeLeads({ _skip: skip, _limit: limit, query: query });
      if (skip === 0) {
        log(`sendSecondFollowupMails total num leads ${leadsResults.total_results} has_more=${leadsResults.has_more}`);
      }
      has_more = leadsResults.has_more;
      const tasks = [];
      for (const lead of leadsResults.data) {
        // log(`DEBUG: ${lead.id}\t${lead.status_label}\t${lead.name}`);
        // if (lead.id !== 'lead_W9qq3oZHIAhUCHZkfj4MRcjQoBbgckV6r9HurMszye5') continue;
        for (const contact of (lead.contacts || [])) {
          if (module.exports.contactHasEmailAddress(contact)) {
            if (yield module.exports.theyHaveNotResponded(lead, contact)) {
              const contactEmails = lowercaseEmailsForContact(contact);
              tasks.push(module.exports.createSendFollowupMailFn(userApiKeyMap, latestDate, lead, contactEmails));
            }
            else {
              log(`Not sending auto-email to lead ${lead.id} contact ${contact.id} `);
            }
          }
          else {
            log(`ERROR: lead ${lead.id} contact ${contact.id} has no email`);
          }
        }
      }
      async.series(tasks, (err, results) => {
        if (err) return done(err);
        if (has_more) {
          return nextPage(skip + limit);
        }
        log('Finished sending followup emails!');
        return done(err);
      });
    });
    nextPage(0);
  });
}

function createAddCallTaskFn(userApiKeyMap, latestDate, lead, contact) {
  const contactEmails = module.exports.lowercaseEmailsForContact(contact);
  const contactPrimaryEmail = contactEmails[0];
  // Check for activity since second auto mail and status update
  // Add call task
  const auto1Statuses = ["Auto Attempt 1", "New US Schools Auto Attempt 1", "Inbound Canada Auto Attempt 1", "Inbound AU Auto Attempt 1", "Inbound NZ Auto Attempt 1", "Inbound UK Auto Attempt 1"];
  const auto2Statuses = ["Auto Attempt 2", "New US Schools Auto Attempt 2", "Inbound Canada Auto Attempt 2", "Inbound AU Auto Attempt 2", "Inbound NZ Auto Attempt 2", "Inbound UK Auto Attempt 2"];
  return wrap(function* (done) {
    log(`DEBUG: addCallTask ${lead.id}`);

    // Skip leads with tasks
    const tasks = yield module.exports.getTasksForLead(lead);
    if (!tasks || tasks.total_results > 0) {
      console.log(`ERROR: Found too many tasks (${tasks && tasks.total_results}) (or tasks request broke)`);
      return done();
    }

    // Find all lead activities
    const results = yield module.exports.getActivityForLead(lead);
    if (!results) {
      console.log(`ERROR: Activity request broke`);
      return done();
    };
    // Find second auto mail and status change
    let secondMailActivity;
    let statusUpdateActivity;
    for (const activity of results.data) {
      if (activity._type === 'Email' && contactEmails.indexOf(activity.to[0].toLowerCase()) >= 0) {
        if (module.exports.isTemplateAuto2(activity.template_id)) {
          if (secondMailActivity) {
            log(`ERROR: ${lead.id} sent multiple auto2 emails!?`);
            return done();
          }
          secondMailActivity = activity;
        }
      }
      else if (activity._type === 'LeadStatusChange' && auto1Statuses.indexOf(activity.old_status_label) >= 0
        && auto2Statuses.indexOf(activity.new_status_label) >= 0) {
          statusUpdateActivity = activity;
      }
    }

    if (!secondMailActivity) {
      log(`DEBUG: No auto2 mail sent for ${lead.id} ${contactPrimaryEmail}`);
      return done();
    }
    if (!statusUpdateActivity) {
      log(`ERROR: No status update for ${lead.id} ${contactPrimaryEmail}`);
      return done();
    }
    if (new Date(secondMailActivity.date_created) > latestDate) {
      log(`DEBUG: Second auto mail too recent ${secondMailActivity.date_created} ${lead.id}`);
      return done();
    }

    // Find activity since second auto mail and status update
    // Skip email to a different contact's email
    // Skip note about different contact
    let recentActivity;
    for (const activity of results.data) {
      if (activity.id === secondMailActivity.id) continue;
      if (activity.id === statusUpdateActivity.id) continue;
      if (new Date(secondMailActivity.date_created) > new Date(activity.date_created)) continue;
      if (new Date(statusUpdateActivity.date_created) > new Date(activity.date_created)) continue;
      if (activity._type === 'Note' && activity.note
        && activity.note.indexOf('demo_email') >= 0
        && contactEmails.every((email) => {return activity.note.indexOf(email) < 0})) {
        // log(`DEBUG: Skipping ${lead.id} ${contactPrimaryEmail} auto import note for different contact`);
        continue;
      }
      recentActivity = activity;
      break;
    }

    // TODO: Prefilter for this outside of this function
    // Create call task
    if (!recentActivity) {
      log(`DEBUG: adding call task for ${lead.id} ${contactPrimaryEmail}`);
      const postData = {
        _type: "lead",
        lead_id: lead.id,
        assigned_to: secondMailActivity.user_id,
        text: `Call ${contactPrimaryEmail}`,
        is_complete: false
      };

      try {
        return done(null, yield module.exports.postTask(postData));
      } catch (error) {
        return done(`Create call task POST error for ${contactPrimaryEmail} ${lead.id}`);
      }
    }
    else {
      log(`DEBUG: Found recent activity after auto2 mail for ${lead.id} ${contactPrimaryEmail}`);
      // log(recentActivity);
      return done();
    }
  })
}

function addCallTasks(done) {
  // Find all leads with auto 2 status, created since earliestDate
  // TODO: Very similar function to sendSecondFollowupMails
  // log("DEBUG: addCallTasks");
  const userApiKeyMap = {};
  let createGetUserFn = (apiKey) => {
    return (done) => {
      module.exports.getUserIdByApiKey(apiKey).then((userId) => {
        userApiKeyMap[userId] = apiKey;
        done()
      });
    };
  }
  const tasks = [];
  for (const apiKey of module.exports.closeIoMailApiKeys()) {
    tasks.push(createGetUserFn(apiKey));
  }
  async.parallel(tasks, (err, results) => {
    if (err) log(err);
    const latestDate = new Date();
    latestDate.setUTCDate(latestDate.getUTCDate() - 3);
    const query = `date_created > ${earliestDate.toISOString().substring(0, 19)} (lead_status:"Auto Attempt 2" or lead_status:"New US Schools Auto Attempt 2" or lead_status:"Inbound Canada Auto Attempt 2" or lead_status:"Inbound AU Auto Attempt 2" or lead_status:"Inbound NZ Auto Attempt 2" or lead_status:"Inbound UK Auto Attempt 2")`;
    const limit = 100;
    const nextPage = wrap(function* (skip) {
      let has_more = false;
      const leadsResults = yield module.exports.getSomeLeads({ _skip: skip, _limit: limit, query: query });
      if (!leadsResults || !leadsResults.data) { return done() }
      if (skip === 0) {
        log(`addCallTasks total num leads ${leadsResults.total_results} has_more=${leadsResults.has_more}`);
      }
      has_more = leadsResults.has_more;
      const tasks = [];
      for (const lead of leadsResults.data) {
        // log(`${lead.id}\t${lead.status_label}\t${lead.name}`);
        // if (lead.id !== 'lead_foo') continue;
        for (const contact of (lead.contacts || [])) {
          if (module.exports.contactHasEmailAddress(contact)) {
            if (module.exports.contactHasPhoneNumbers(contact)) {
              tasks.push(module.exports.createAddCallTaskFn(userApiKeyMap, latestDate, lead, contact));
            } else {
              log(`ERROR: lead ${lead.id} contact ${contact.id} has no phone number`)
            }
          }
          else {
            log(`ERROR: lead ${lead.id} contact ${contact.id} has no email`);
          }
        }
        // if (tasks.length > 1) break;
      }
      async.series(tasks, (err, results) => {
        if (err) return done(err);
        if (has_more) {
          return nextPage(skip + limit);
        } else {
          log('Finished adding call tasks!');
          return done(err);
        }
      });
    });
    nextPage(0);
  });
}

module.exports = {
  getRandomEmailTemplateAuto2: getRandomEmailTemplateAuto2,
  getRandomEmailTemplate: getRandomEmailTemplate,
  isSameEmailTemplateType: isSameEmailTemplateType,
  isTemplateAuto1: isTemplateAuto1,
  isTemplateAuto2: isTemplateAuto2,
  log: log,
  contactHasEmailAddress: contactHasEmailAddress,
  contactHasPhoneNumbers: contactHasPhoneNumbers,
  lowercaseEmailsForContact: lowercaseEmailsForContact,
  getJsonUrl: getJsonUrl,
  postJsonUrl: postJsonUrl,
  putJsonUrl: putJsonUrl,
  getUserIdByApiKey: getUserIdByApiKey,
  getSomeLeads: getSomeLeads,
  getTasksForLead: getTasksForLead,
  getEmailActivityForLead: getEmailActivityForLead,
  getActivityForLead: getActivityForLead,
  postEmailActivity: postEmailActivity,
  postTask: postTask,
  sendMail: sendMail,
  updateLeadStatus: updateLeadStatus,
  theyHaveNotResponded: theyHaveNotResponded,
  createSendFollowupMailFn: createSendFollowupMailFn,
  sendSecondFollowupMails: sendSecondFollowupMails,
  createAddCallTaskFn: createAddCallTaskFn,
  addCallTasks: addCallTasks,
  // For stubbing API keys in testing:
  closeIoMailApiKeys: closeIoMailApiKeys,
};
