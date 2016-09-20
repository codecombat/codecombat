// Send exported leads

// NOTE: using activity email body text instead of html because it didn't escape well into a new email

// TODO: custom.auto_status update after sending isn't that flexible/specific

'use strict';
if (process.argv.length !== 6) {
  log("Usage: node <script> <Close.io general API key> <lead search query> <recipient email> <sendwithus API key>");
  process.exit();
}

const scriptStartTime = new Date();
const closeIoApiKey = process.argv[2];
const searchQuery = process.argv[3];
const recipientEmail = process.argv[4];
const swuAPIKey = process.argv[5];
const email_template = 'tem_85UvKDCCNPXsFckERTig6Y';

const async = require('async');
const request = require('request');
const sendwithus = require('sendwithus')(swuAPIKey);

const url = `https://${closeIoApiKey}:X@app.close.io/api/v1/lead/?query=${encodeURIComponent(searchQuery)}`;
request.get(url, (error, response, body) => {
  if (error) {
    console.log(error);
    return;
  }
  const results = JSON.parse(body);
  log(`DEBUG: ${(results.data || []).length} leads found for ${searchQuery}`);
  const tasks = [];
  for (const lead of results.data || []) {
    tasks.push(createSendExportFn(lead));
  }
  async.parallel(tasks, (error, results) => {
    if (error) console.log(error);
    log("Script runtime: " + (new Date() - scriptStartTime));
  });
});

function createSendExportFn(lead) {
  return (done) => {
    log(`DEBUG: exporting ${lead.id}`);
    // Get activities
    const url = `https://${closeIoApiKey}:X@app.close.io/api/v1/activity/?lead_id=${lead.id}`;
    request.get(url, (error, response, body) => {
      if (error) return done(error);
      const results = JSON.parse(body);
      let email_body = lead2Html(lead);;
      email_body += "<h2>Activities</h2>";
      for (let activity of results.data) {
        email_body += activity2Html(activity);
      }

      // Send exported lead
      sendwithus.send({
        email_id: email_template,
        recipient: {
          address: recipientEmail
        },
        sender: {
          address: 'team@codecombat.com',
          name: 'CodeCombat Team'
        },
        email_data: {
          subject: `New Lead: ${lead.name}`,
          contentHTML: email_body
        }
      }, function(error, response) {
        if (error) return done(error);

        // Flag lead automation status to finished
        const putData = {'custom.auto_status': 'export_sent'};
        const options = {
          uri: `https://${closeIoApiKey}:X@app.close.io/api/v1/lead/${lead.id}/`,
          body: JSON.stringify(putData)
        };
        request.put(options, (error, response, body) => {
          if (error) return done(error);
          const result = JSON.parse(body);
          if (result.errors || result['field-errors']) {
            return done(`Update existing lead PUT error for ${lead.id}`);
          }
          return done();
        });
      });
    });
  };
}

function lead2Html(lead) {
  let html = '';
  html += `<h1>${lead.display_name || lead.name}</h1>`;
  if (lead.date_updated) html += `<div>Updated: ${lead.date_updated}</div>`;
  if (lead.url) html += `<div>${lead.url}</div>`;
  if (lead.description) html += `<p>${lead.description}</p>`;
  html += "<h2>Contacts</h2>";
  for (const contact of lead.contacts) {
    html += `<h3>${contact.name}</h3>`;
    html += `<div>${contact.title}</div>`;
    for (const email of contact.emails) {
      html += `<div>${email.email}</div>`;
    }
    for (const phone of contact.phones) {
      html += `<div>${phone.phone_formatted || phone.phone}</div>`;
    }
  } 
  if (lead.custom) {
    html += "<h2>Custom data</h2>";
    for (let key in lead.custom) {
      html += `<div>${key}: ${lead.custom[key]}</div>`;
    }
  }
  return html;
}

function activity2Html(activity) {
  let html = "";
  if (activity._type === 'Note' && activity.note) {
    html += `<h3>${activity._type}</h3>`;
    if (activity.date_updated) html += `<div>Updated: ${activity.date_updated}</div>`;
    if (activity.user_name) html += `<div>Author: ${activity.user_name}</div>`;
    const lines = activity.note.split('\n');
    html += "<p>";
    for (const line of lines) {
      html += `<div>${line}</div>`;
    }
    html += "</p>";
  }
  return html;
}

// ** Utilities

function log(str) {
  console.log(new Date().toISOString() + " " + str);
}
