// Follow up on Close.io leads

'use strict';
if (process.argv.length !== 6) {
  log("Usage: node <script> <Close.io general API key> <Close.io mail API key1> <Close.io mail API key2> <mongo connection Url>");
  process.exit();
}

// TODO: Assumes 1:1 contact:email relationship (Close.io supports multiple emails for a single contact)
// TODO: Duplicate lead lookups when checking per-email (e.g. existing tasks)
// TODO: 2nd follow up email activity does not handle paged activity results
// TODO: sendMail copied from updateCloseIoLeads.js
// TODO: template values copied from updateCloseIoLeads.js

const createTeacherEmailTemplatesAuto1 = ['tmpl_i5bQ2dOlMdZTvZil21bhTx44JYoojPbFkciJ0F560mn', 'tmpl_CEZ9PuE1y4PRvlYiKB5kRbZAQcTIucxDvSeqvtQW57G'];
const demoRequestEmailTemplatesAuto1 = ['tmpl_s7BZiydyCHOMMeXAcqRZzqn0fOtk0yOFlXSZ412MSGm', 'tmpl_cGb6m4ssDvqjvYd8UaG6cacvtSXkZY3vj9b9lSmdQrf'];
const createTeacherEmailTemplatesAuto2 = ['tmpl_pGPtKa07ioISupdSc1MAzNC57K40XoA4k0PI1igi8Ec', 'tmpl_AYAcviU8NQGLbMGKSp3EmcBLha0gQw4cHSOR55Fmoha'];
const demoRequestEmailTemplatesAuto2 = ['tmpl_HJ5zebh1SqC1QydDto05VPUMu4F7i5M35Llq7bzgfTw', 'tmpl_dmnK7IVpkyYfPYAl1rChhm9lClH5lJ9pQAZoPr7cvLt'];

const scriptStartTime = new Date();
const closeIoApiKey = process.argv[2];
const closeIoMailApiKeys = [process.argv[3], process.argv[4]]; // Automatic mails sent as API owners
const mongoConnUrl = process.argv[5];
const MongoClient = require('mongodb').MongoClient;
const async = require('async');
const request = require('request');

const earliestDate = new Date();
earliestDate.setUTCDate(earliestDate.getUTCDate() - 10);

// ** Main program

async.series([
  sendSecondFollowupMails
],
(err, results) => {
  if (err) console.error(err);
  log("Script runtime: " + (new Date() - scriptStartTime));
}
);

// ** Utilities

function getRandomEmailApiKey() {
  if (closeIoMailApiKeys.length < 0) return;
  return closeIoMailApiKeys[Math.floor(Math.random() * closeIoMailApiKeys.length)];
}

function getRandomEmailTemplate(templates) {
  if (templates.length < 0) return '';
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

function isDemoRequestTemplateAuto1(template) {
  return demoRequestEmailTemplatesAuto1.indexOf(template) >= 0;
}

function isCreateTeacherTemplateAuto1(template) {
  return createTeacherEmailTemplatesAuto1.indexOf(template) >= 0;
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
  // console.log("DEBUG: updateLeadStatus", lead.id, status);
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

function createSendFollowupMailFn(userApiKeyMap, latestDate, lead, email) {
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
          let sentFirstCreateTeacherEmail = false;
          let sentFirstDemoRequestEmail = false;
          let firstMailActivity;
          for (const activity of results.data) {
            if (activity._type === 'Email' && activity.to[0] === email) {
              if (isCreateTeacherTemplateAuto1(activity.template_id)) {
                if (sentFirstCreateTeacherEmail || sentFirstDemoRequestEmail) {
                  console.log(`ERROR: ${lead.id} sent multiple auto1 emails!? ${sentFirstCreateTeacherEmail} ${sentFirstDemoRequestEmail}`);
                  return done();
                }
                sentFirstCreateTeacherEmail = true;
                firstMailActivity = activity;
              }
              else if (isDemoRequestTemplateAuto1(activity.template_id)) {
                if (sentFirstCreateTeacherEmail || sentFirstDemoRequestEmail) {
                  console.log(`ERROR: ${lead.id} sent multiple auto1 emails!? ${sentFirstCreateTeacherEmail} ${sentFirstDemoRequestEmail}`);
                  return done();
                }
                sentFirstDemoRequestEmail = true;
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

          if (sentFirstCreateTeacherEmail && sentFirstDemoRequestEmail) {
            console.log(`ERROR: ${lead.id} sent multiple auto1 emails!? ${sentFirstCreateTeacherEmail} ${sentFirstDemoRequestEmail}`);
            return done();
          }

          // Find activity since first auto mail, that's not email to a different contact's email
          let recentActivity;
          for (const activity of results.data) {
            if (activity.id === firstMailActivity.id) continue;
            if (new Date(firstMailActivity.date_created) > new Date(activity.date_created)) continue;
            if (activity._type === 'Email' && activity.to[0] !== email) continue;
            recentActivity = activity;
            break;
          }

          if (!recentActivity) {
            let template;
            if (sentFirstCreateTeacherEmail) {
              // console.log(`Create teacher auto 1 sent: ${lead.id} ${firstMailUserId} ${userApiKeyMap[firstMailUserId]}`);
              template = getRandomEmailTemplate(createTeacherEmailTemplatesAuto2);
            }
            else if (sentFirstDemoRequestEmail) {
              // console.log(`Demo request auto 1 sent: ${lead.id} ${firstMailUserId} ${userApiKeyMap[firstMailUserId]}`);
              template = getRandomEmailTemplate(demoRequestEmailTemplatesAuto2);
            }
            if (!template) {
              console.log(`ERROR: no template selected ${lead.id}`);
              return done();
            }
            // console.log(`TODO: ${firstMailActivity.to[0]} ${lead.id} ${firstMailActivity.contact_id} ${template} ${userApiKeyMap[firstMailActivity.user_id]}`);
            // console.log(`TODO: ${firstMailActivity.to[0]} ${lead.id}`);
            sendMail(firstMailActivity.to[0], lead.id, firstMailActivity.contact_id, template, userApiKeyMap[firstMailActivity.user_id], 0, (err) => {
              if (err) return done(err);

              // TODO: some sort of callback problem that stops the series here

              if (lead.status_label === "Auto Attempt 1") {
                return updateLeadStatus(lead, "Auto Attempt 2", done);
              }
              else if (lead.status_label === "New US Schools Auto Attempt 1") {
                return updateLeadStatus(lead, "New US Schools Auto Attempt 2", done);
              }
              else {
                console.log(`ERROR: unknown lead status ${lead.id} ${lead.status_label}`)
                return done();
              }
            });
          }
          else {
            // console.log(`Found recent activity after auto1 mail for ${lead.id}`);
            // console.log(firstMailActivity.template_id, recentActivity.template_id);
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
    const query = `date_created > ${earliestDate.toISOString().substring(0, 19)} (lead_status:"Auto Attempt 1" or lead_status:"New US Schools Auto Attempt 1")"`;
    const limit = 100;
    const nextPage = (skip) => {
      let has_more = false;
      const url = `https://${closeIoApiKey}:X@app.close.io/api/v1/lead/?_skip=${skip}&_limit=${limit}&query=${encodeURIComponent(query)}/`;
      request.get(url, (error, response, body) => {
        if (error) return done(error);
        try {
          const results = JSON.parse(body);
          console.log(`sendSecondFollowupMails total num leads ${results.total_results} has_more=${results.has_more}`);
          has_more = results.has_more;
          const tasks = [];
          for (const lead of results.data) {
            // console.log(`${lead.id}\t${lead.status_label}\t${lead.name}`);
            // if (lead.id !== 'lead_KYuI2HVOiUdJANvkOe1uLJBuuQVaaGSRveklhTWbHv2') continue;
            const existingContacts = lead.contacts || [];
            for (const contact of existingContacts) {
              if (contact.emails && contact.emails.length > 0) {
                tasks.push(createSendFollowupMailFn(userApiKeyMap, latestDate, lead, contact.emails[0].email.toLowerCase()));
              }
              else {
                console.log(`ERROR: lead ${lead.id} contact has non-1 emails`);
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
