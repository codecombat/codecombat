// Copy ZenProspect contacts with email replies into Close.io leads

'use strict';
if (process.argv.length !== 4) {
  console.log("Usage: node <script> <Close.io general API key> <ZenProspect auth token>");
  process.exit();
}

const closeIoApiKey = process.argv[2];
const zpAuthToken = process.argv[3];

const scriptStartTime = new Date();

const async = require('async');
const request = require('request');

const zpPageSize = 100;

getZPContacts((err, emailContactMap) => {
  if (err) {
    console.log(err);
    return;
  }
  const tasks = [];
  for (const email in emailContactMap) {
    const contact = emailContactMap[email];
    // if (contact.organization !== 'Cabarrus County Schools') continue;
    tasks.push(createUpsertCloseLeadFn(contact));
  }
  async.parallel(tasks, (err, results) => {
    if (err) console.log(err);
    log("Script runtime: " + (new Date() - scriptStartTime));
  });
});

function createCloseLead(zpContact, done) {
  const postData = {
    name: zpContact.organization,
    status: 'Contacted',
    contacts: [
      {
        name: zpContact.name,
        title: zpContact.title,
        emails: [{email: zpContact.email}]
      }
    ],
    custom: {
      lastUpdated: new Date(),
      'Lead Origin': 'outbound campaign'
    }
  };
  if (zpContact.phone) {
    postData.contacts[0].phones = [{phone: zpContact.phone}];
  }
  const options = {
    uri: `https://${closeIoApiKey}:X@app.close.io/api/v1/lead/`,
    body: JSON.stringify(postData)
  };
  request.post(options, (error, response, body) => {
    if (error) return done(error);
    const newLead = JSON.parse(body);
    if (newLead.errors || newLead['field-errors']) {
      console.error(`New lead POST error for ${zpContact.name} ${zpContact.organization}`);
      return done(newLead.errors || newLead['field-errors']);
    }
    return done();
  });
}

function updateCloseLead(zpContact, existingLead, done) {
  // console.log(`DEBUG: updateCloseLead ${existingLead.id} ${zpContact.email}`);
  const putData = {
    status: 'Contacted',
    'custom.lastUpdated': new Date(),
    'custom.Lead Origin': 'outbound campaign'
  };
  const options = {
    uri: `https://${closeIoApiKey}:X@app.close.io/api/v1/lead/${existingLead.id}/`,
    body: JSON.stringify(putData)
  };
  request.put(options, (error, response, body) => {
    if (error) return done(error);
    const result = JSON.parse(body);
    if (result.errors || result['field-errors']) {
      return done(`Update existing lead PUT error for ${existingLead.id} ${zpContact.email} ${result.errors || result['field-errors']}`);
    }
    const postData = {
      lead_id: existingLead.id,
      name: zpContact.name,
      title: zpContact.title,
      emails: [{email: zpContact.email}]
    };
    if (zpContact.phone) {
      postData.phones = [{phone: zpContact.phone}];
    }
    const options = {
      uri: `https://${closeIoApiKey}:X@app.close.io/api/v1/contact/`,
      body: JSON.stringify(postData)
    };
    request.post(options, (error, response, body) => {
      if (error) return done(error);
      const result = JSON.parse(body);
      if (result.errors || result['field-errors']) {
        return done(`New Contact POST error for ${existingLead.id} ${zpContact.email} ${result.errors || result['field-errors']}`);
      }
      return done();
    });
  });
}

function createUpsertCloseLeadFn(zpContact) {
  return (done) => {
    // console.log(`DEBUG: createUpsertCloseLeadFn ${zpContact.organization} ${zpContact.email}`);
    const query = `email:${zpContact.email}`;
    const url = `https://${closeIoApiKey}:X@app.close.io/api/v1/lead/?query=${encodeURIComponent(query)}`;
    request.get(url, (error, response, body) => {
      if (error) return done(error);
      const data = JSON.parse(body);
      if (data.total_results != 0) return done();
      const query = `name:${zpContact.organization}`;
      const url = `https://${closeIoApiKey}:X@app.close.io/api/v1/lead/?query=${encodeURIComponent(query)}`;
      request.get(url, (error, response, body) => {
        if (error) return done(error);
        const data = JSON.parse(body);
        if (data.total_results === 0) {
          console.log(`DEBUG: Creating lead for ${zpContact.organization} ${zpContact.email}`);
          return createCloseLead(zpContact, done);
        }
        else {
          const existingLead = data.data[0];
          console.log(`DEBUG: Adding ${zpContact.organization} ${zpContact.email} to ${existingLead.id}`);
          return updateCloseLead(zpContact, existingLead, done);
        }
      });
    });
  };
}

function getZPContactsPage(contacts, searchQuery, done) {
  const options = {
    url: `https://www.zenprospect.com/api/v1/contacts/search?${searchQuery}`,
    headers: {
      'Accept': 'application/json'
    }
  };
  request.get(options, (err, response, body) => {
    if (err) return done(err);
    const data = JSON.parse(body);
    for (let contact of data.contacts) {
      contacts.push({
        organization: contact.organization_name,
        name: contact.name,
        title: contact.title,
        email: contact.email,
        phone: contact.phone,
        data: contact
      });
    }
    return done(null, data.pipeline_total);
  });
}

function createGetZPAutoResponderContactsPage(contacts, page) {
  return (done) => {
    // console.log(`DEBUG: Fetching autoresponder page ${page} ${zpPageSize}...`);
    let searchQuery = `codecombat_special_auth_token=${zpAuthToken}&page=${page}&per_page=${zpPageSize}&contact_email_autoresponder=true`;
    getZPContactsPage(contacts, searchQuery, done);
  };
}

function createGetZPRepliedContactsPage(contacts, page) {
  return (done) => {
    // console.log(`DEBUG: Fetching email reply page ${page} ${zpPageSize}...`);
    let searchQuery = `codecombat_special_auth_token=${zpAuthToken}&page=${page}&per_page=${zpPageSize}&contact_email_replied=true`;
    getZPContactsPage(contacts, searchQuery, done);
  };
}

function getZPContacts(done) {
  // Get first page to get total contact count for future parallized page fetches
  const contacts = [];
  createGetZPAutoResponderContactsPage(contacts, 0)((err, autoResponderTotal) => {
    if (err) return done(err);
    createGetZPRepliedContactsPage(contacts, 0)((err, repliedTotal) => {
      if (err) return done(err);

      const tasks = [];
      for (let i = 1; (i - 1) * zpPageSize < autoResponderTotal; i++) {
        tasks.push(createGetZPAutoResponderContactsPage(contacts, i));
      }
      for (let i = 1; (i - 1) * zpPageSize < repliedTotal; i++) {
        tasks.push(createGetZPRepliedContactsPage(contacts, i));
      }

      async.series(tasks, (err, results) => {
        if (err) return done(err);
        const emailContactMap = {};
        for (const contact of contacts) {
          if (!contact.organization || !contact.name || !contact.title || !contact.email) {
            console.log(JSON.stringify(contact, null, 2));
            return done(`DEBUG: missing data for zp contact:`);
          }
          if (!emailContactMap[contact.email]) {
            emailContactMap[contact.email] = contact;
          }
          // else {
          //   console.log(`DEBUG: already have contact ${contact.email}`);
          // }
        }
        log(`(${autoResponderTotal + repliedTotal}) ${autoResponderTotal} autoresponder ZP contacts ${repliedTotal} ZP contacts ${Object.keys(emailContactMap).length} contacts mapped`);
        return done(null, emailContactMap);
      });
    });
  });
}

function log(str) {
  console.log(new Date().toISOString() + " " + str);
}
