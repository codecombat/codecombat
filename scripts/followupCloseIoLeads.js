// Follow up on Close.io leads

'use strict';
if (process.argv.length !== 7) {
  log("Usage: node <script> <Close.io general API key> <Close.io mail API key1> <Close.io mail API key2> <Close.io mail API key3>");
  process.exit();
}

// TODO: Assumes 1:1 contact:email relationship (Close.io supports multiple emails for a single contact)
// TODO: Duplicate lead lookups when checking per-email (e.g. existing tasks)
// TODO: 2nd follow up email activity does not handle paged activity results
// TODO: sendMail copied from updateCloseIoLeads.js
// TODO: template values copied from updateCloseIoLeads.js
// TODO: status change is not related to specific lead contacts, e.g. lead_7fQAZKtX7tPYe352JpaUULVaVA99Ppq4HlsHXrRkpA9
// TODO: update status after adding a call task

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

const scriptStartTime = new Date();
const closeIoApiKey = process.argv[2];
const closeIoMailApiKeys = [process.argv[3], process.argv[4], process.argv[5], process.argv[6]]; // Automatic mails sent as API owners
const async = require('async');
const request = require('request');

const earliestDate = new Date();
earliestDate.setUTCDate(earliestDate.getUTCDate() - 10);

// ** Main program

async.series([
  sendSecondFollowupMails,
  addCallTasks
// TODO: Cancel call tasks
],
(err, results) => {
  if (err) console.error(err);
  log("Script runtime: " + (new Date() - scriptStartTime));
});

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
  console.log(new Date().toISOString() + " " + str);
}

// ** Close.io methods

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
            console.log("ERROR: sending duplicate email:", toEmail, leadId, contactId, template, emailData.contact_id);
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

function updateLeadStatus(lead, status, done) {
  // console.log(`DEBUG: updateLeadStatus ${lead.id} ${status}`);
  const putData = {status: status};
  const options = {
    uri: `https://${closeIoApiKey}:X@app.close.io/api/v1/lead/${lead.id}/`,
    body: JSON.stringify(putData)
  };
  request.put(options, (error, response, body) => {
    if (error) return done(error);
    try {
      const result = JSON.parse(body);
      if (result.errors || result['field-errors']) {
        console.log(`Update existing lead status PUT error for ${lead.id}`);
        console.log(body);
        return done(result.errors || result['field-errors']);
      }
      return done();
    }
    catch (err) {
      console.log(body);
      return done(err);
    }
  });
}

function createSendFollowupMailFn(userApiKeyMap, latestDate, lead, contactEmails) {
  // Find first auto mail
  // Find activity since first auto mail
  // Send send auto mail of same template type (create or demo) from same user who sent first email
  // Update status to Auto Attempt 2 or New US Schools Auto Attempt 2
  return (done) => {
    // console.log("DEBUG: sendFollowupMail", lead.id);

    // Skip leads with tasks
    const url = `https://${closeIoApiKey}:X@app.close.io/api/v1/task/?lead_id=${lead.id}`;
    request.get(url, (error, response, body) => {
      if (error) {
        console.log(error);
        return done();
      }
      try {
        const results = JSON.parse(body);
        if (results.total_results > 0) {
          // console.log(`${lead.id} has ${results.total_results} tasks`);
          return done();
        }
      }
      catch (err) {
        return done(err);
      }

      // Find all lead activities
      const url = `https://${closeIoApiKey}:X@app.close.io/api/v1/activity/?lead_id=${lead.id}`;
      request.get(url, (error, response, body) => {
        if (error) {
          console.log(error);
          return done();
        }
        try {
          const results = JSON.parse(body);
          if (results.has_more) {
            console.log(`ERROR: ${lead.id} has more activities than returned!`);
            return done();
          }

          // Find first auto mail
          let firstMailActivity;
          for (const activity of results.data) {
            if (activity._type === 'Email' && contactEmails.indexOf(activity.to[0].toLowerCase() >= 0)) {
              if (isTemplateAuto1(activity.template_id)) {
                if (firstMailActivity) {
                  console.log(`ERROR: ${lead.id} sent multiple auto1 emails!?`);
                  return done();
                }
                firstMailActivity = activity;
              }
            }
          }

          if (!firstMailActivity) {
            console.log(`ERROR: No first auto mail sent for ${lead.id}`);
            return done();
          }
          if (new Date(firstMailActivity.date_created) > latestDate) {
            // console.log(`First auto mail too recent ${firstMailActivity.date_created} ${lead.id}`);
            return done();
          }

          // Find activity since first auto mail, that's not email to a different contact's email
          let recentActivity;
          for (const activity of results.data) {
            if (activity.id === firstMailActivity.id) continue;
            if (new Date(firstMailActivity.date_created) > new Date(activity.date_created)) continue;
            if (activity._type === 'Email' && contactEmails.indexOf(activity.to[0].toLowerCase() < 0)) continue;
            recentActivity = activity;
            break;
          }

          if (!recentActivity) {
            let template = getRandomEmailTemplateAuto2(firstMailActivity.template_id);
            if (!template) {
              console.log(`ERROR: no auto2 template selected for ${lead.id} ${firstMailActivity.template_id}`);
              return done();
            }
            // console.log(`TODO: ${firstMailActivity.to[0]} ${lead.id} ${firstMailActivity.contact_id} ${template} ${userApiKeyMap[firstMailActivity.user_id]}`);
            sendMail(firstMailActivity.to[0], lead.id, firstMailActivity.contact_id, template, userApiKeyMap[firstMailActivity.user_id], 0, (err) => {
              if (err) return done(err);

              // TODO: some sort of callback problem that stops the series here

              // TODO: manage this status mapping better
              if (lead.status_label === "Auto Attempt 1") {
                return updateLeadStatus(lead, "Auto Attempt 2", done);
              }
              else if (lead.status_label === "New US Schools Auto Attempt 1") {
                return updateLeadStatus(lead, "New US Schools Auto Attempt 2", done);
              }
              else if (lead.status_label === "Inbound AU Auto Attempt 1") {
                return updateLeadStatus(lead, "Inbound AU Auto Attempt 2", done);
              }
              else if (lead.status_label === "Inbound Canada Auto Attempt 1") {
                return updateLeadStatus(lead, "Inbound Canada Auto Attempt 2", done);
              }
              else if (lead.status_label === "Inbound NZ Auto Attempt 1") {
                return updateLeadStatus(lead, "Inbound NZ Auto Attempt 2", done);
              }
              else if (lead.status_label === "Inbound UK Auto Attempt 1") {
                return updateLeadStatus(lead, "Inbound UK Auto Attempt 2", done);
              }
              else {
                console.log(`ERROR: unknown lead status ${lead.id} ${lead.status_label}`)
                return done();
              }
            });
          }
          else {
            // console.log(`Found recent activity after auto1 mail for ${lead.id}`);
            // console.log(firstMailActivity.template_id, recentActivity);
            return done();
          }
        }
        catch (err) {
          console.log(err);
          console.log(body);
          return done();
        }
      });
    });
  };
}

function sendSecondFollowupMails(done) {
  // Find all leads with auto 1 status, created since earliestDate
  // console.log("DEBUG: sendSecondFollowupMails");
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
  for (const apiKey of closeIoMailApiKeys) {
    tasks.push(createGetUserFn(apiKey));
  }
  async.parallel(tasks, (err, results) => {
    if (err) console.log(err);
    const latestDate = new Date();
    latestDate.setUTCDate(latestDate.getUTCDate() - 3);
    // TODO: manage this status list better
    const query = `date_created > ${earliestDate.toISOString().substring(0, 19)} (lead_status:"Auto Attempt 1" or lead_status:"New US Schools Auto Attempt 1" or lead_status:"Inbound Canada Auto Attempt 1" or lead_status:"Inbound AU Auto Attempt 1" or lead_status:"Inbound NZ Auto Attempt 1" or lead_status:"Inbound UK Auto Attempt 1")`;
    const limit = 100;
    const nextPage = (skip) => {
      let has_more = false;
      const url = `https://${closeIoApiKey}:X@app.close.io/api/v1/lead/?_skip=${skip}&_limit=${limit}&query=${encodeURIComponent(query)}/`;
      request.get(url, (error, response, body) => {
        if (error) return done(error);
        try {
          const results = JSON.parse(body);
          if (skip === 0) {
            console.log(`sendSecondFollowupMails total num leads ${results.total_results} has_more=${results.has_more}`);
          }
          has_more = results.has_more;
          const tasks = [];
          for (const lead of results.data) {
            // console.log(`DEBUG: ${lead.id}\t${lead.status_label}\t${lead.name}`);
            // if (lead.id !== 'lead_W9qq3oZHIAhUCHZkfj4MRcjQoBbgckV6r9HurMszye5') continue;
            const existingContacts = lead.contacts || [];
            for (const contact of existingContacts) {
              if (contact.emails && contact.emails.length > 0) {
                const contactEmails = contact.emails.map((e) => {return e.email.toLowerCase();});
                tasks.push(createSendFollowupMailFn(userApiKeyMap, latestDate, lead, contactEmails));
              }
              else {
                console.log(`ERROR: lead ${lead.id} contact ${contact.id} has no email`);
              }
            }
          }
          async.series(tasks, (err, results) => {
            if (err) return done(err);
            if (has_more) {
              return nextPage(skip + limit);
            }
            return done(err);
          });
        }
        catch (err) {
          return done(err);
        }
      });
    };
    nextPage(0);
  });
}

function createAddCallTaskFn(userApiKeyMap, latestDate, lead, email) {
  // Check for activity since second auto mail and status update
  // Add call task
  const auto1Statuses = ["Auto Attempt 1", "New US Schools Auto Attempt 1", "Inbound Canada Auto Attempt 1", "Inbound AU Auto Attempt 1", "Inbound NZ Auto Attempt 1", "Inbound UK Auto Attempt 1"];
  const auto2Statuses = ["Auto Attempt 2", "New US Schools Auto Attempt 2", "Inbound Canada Auto Attempt 2", "Inbound AU Auto Attempt 2", "Inbound NZ Auto Attempt 2", "Inbound UK Auto Attempt 2"];
  return (done) => {
    // console.log("DEBUG: addCallTask", lead.id);

    // Skip leads with tasks
    const url = `https://${closeIoApiKey}:X@app.close.io/api/v1/task/?lead_id=${lead.id}`;
    request.get(url, (error, response, body) => {
      if (error) {
        console.log(error);
        return done();
      }
      try {
        const results = JSON.parse(body);
        if (results.total_results > 0) {
          // console.log(`DEBUG: ${lead.id} has ${results.total_results} tasks`);
          return done();
        }
      }
      catch (err) {
        return done(err);
      }

      // Find all lead activities
      const url = `https://${closeIoApiKey}:X@app.close.io/api/v1/activity/?lead_id=${lead.id}`;
      request.get(url, (error, response, body) => {
        if (error) {
          console.log(error);
          return done();
        }
        try {
          const results = JSON.parse(body);
          if (results.has_more) {
            console.log(`ERROR: ${lead.id} has more activities than returned!`);
            return done();
          }

          // Find second auto mail and status change
          let secondMailActivity;
          let statusUpdateActivity;
          for (const activity of results.data) {
            if (activity._type === 'Email' && activity.to[0] === email) {
              if (isTemplateAuto2(activity.template_id)) {
                if (secondMailActivity) {
                    console.log(`ERROR: ${lead.id} sent multiple auto2 emails!?`);
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
            // console.log(`DEBUG: No auto2 mail sent for ${lead.id} ${email}`);
            return done();
          }
          if (!statusUpdateActivity) {
            console.log(`ERROR: No status update for ${lead.id} ${email}`);
            return done();
          }
          if (new Date(secondMailActivity.date_created) > latestDate) {
            // console.log(`DEBUG: Second auto mail too recent ${secondMailActivity.date_created} ${lead.id}`);
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
              && activity.note.indexOf('demo_email') >= 0 && activity.note.indexOf(email) < 0) {
              // console.log(`DEBUG: Skipping ${lead.id} ${email} auto import note for different contact`);
              // console.log(activity.note);
              continue;
            }
            recentActivity = activity;
            break;
          }

          // Create call task
          if (!recentActivity) {
            console.log(`DEBUG: adding call task for ${lead.id} ${email}`);
            const postData = {
              _type: "lead",
              lead_id: lead.id,
              assigned_to: secondMailActivity.user_id,
              text: `Call ${email}`,
              is_complete: false
            };
            const options = {
              uri: `https://${closeIoApiKey}:X@app.close.io/api/v1/task/`,
              body: JSON.stringify(postData)
            };
            request.post(options, (error, response, body) => {
              if (error) return done(error);
              const result = JSON.parse(body);
              if (result.errors || result['field-errors']) {
                const errorMessage = `Create call task POST error for ${email} ${lead.id}`;
                console.error(errorMessage);
                // console.error(body);
                // console.error(postData);
                return done(errorMessage);
              }
              return done();
            });
          }
          else {
            // console.log(`DEBUG: Found recent activity after auto2 mail for ${lead.id} ${email}`);
            // console.log(recentActivity);
            return done();
          }
        }
        catch (err) {
          console.log(err);
          // console.log(body);
          return done();
        }
      });
    });
  };
}

function addCallTasks(done) {
  // Find all leads with auto 2 status, created since earliestDate
  // TODO: Very similar function to sendSecondFollowupMails
  // console.log("DEBUG: addCallTasks");
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
  for (const apiKey of closeIoMailApiKeys) {
    tasks.push(createGetUserFn(apiKey));
  }
  async.parallel(tasks, (err, results) => {
    if (err) console.log(err);
    const latestDate = new Date();
    latestDate.setUTCDate(latestDate.getUTCDate() - 3);
    const query = `date_created > ${earliestDate.toISOString().substring(0, 19)} (lead_status:"Auto Attempt 2" or lead_status:"New US Schools Auto Attempt 2" or lead_status:"Inbound Canada Auto Attempt 2" or lead_status:"Inbound AU Auto Attempt 2" or lead_status:"Inbound NZ Auto Attempt 2" or lead_status:"Inbound UK Auto Attempt 2")`;
    const limit = 100;
    const nextPage = (skip) => {
      let has_more = false;
      const url = `https://${closeIoApiKey}:X@app.close.io/api/v1/lead/?_skip=${skip}&_limit=${limit}&query=${encodeURIComponent(query)}/`;
      request.get(url, (error, response, body) => {
        if (error) return done(error);
        try {
          const results = JSON.parse(body);
          if (skip === 0) {
            console.log(`addCallTasks total num leads ${results.total_results} has_more=${results.has_more}`);
          }
          has_more = results.has_more;
          const tasks = [];
          for (const lead of results.data) {
            // console.log(`${lead.id}\t${lead.status_label}\t${lead.name}`);
            // if (lead.id !== 'lead_foo') continue;
            const existingContacts = lead.contacts || [];
            for (const contact of existingContacts) {
              if (contact.emails && contact.emails.length > 0) {
                if (contact.phones && contact.phones.length > 0) {
                  tasks.push(createAddCallTaskFn(userApiKeyMap, latestDate, lead, contact.emails[0].email.toLowerCase()));
                }
              }
              else {
                console.log(`ERROR: lead ${lead.id} contact ${contact.id} has no email`);
              }
            }
            // if (tasks.length > 1) break;
          }
          async.series(tasks, (err, results) => {
            if (err) return done(err);
            if (has_more) {
              return nextPage(skip + limit);
            }
            return done(err);
          });
        }
        catch (err) {
          return done(err);
        }
      });
    };
    nextPage(0);
  });
}
