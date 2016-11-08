// Copy ZenProspect contacts with email replies into Close.io leads

'use strict';
if (process.argv.length !== 4) {
  console.log("Usage: node <script> <Close.io general API key> <ZenProspect auth token>");
  process.exit();
}

// NOTE: last_activity_date_range is the contacted at date, UTC

// TODO: Only looking at contacts created in last 30 days.  How do we catch replies for contacts older than 30 days?

const closeIoApiKey = process.argv[2];
const zpAuthToken = process.argv[3];

const scriptStartTime = new Date();

const async = require('async');
const request = require('request');

const zpPageSize = 100;
let zpMinActivityDate = new Date();
zpMinActivityDate.setUTCDate(zpMinActivityDate.getUTCDate() - 30);
zpMinActivityDate = zpMinActivityDate.toISOString().substring(0, 10);

const closeParallelLimit = 100;

getZPContacts((err, emailContactMap) => {
  if (err) {
    console.log(err);
    return;
  }
  const tasks = [];
  for (const email in emailContactMap) {
    const contact = emailContactMap[email];
    tasks.push(createUpsertCloseLeadFn(contact));
  }
  async.parallelLimit(tasks, closeParallelLimit, (err, results) => {
    if (err) console.log(err);
    log("Script runtime: " + (new Date() - scriptStartTime));
  });
});

function createCloseLead(zpContact, done) {
  if (!(zpContact.school_name || zpContact.district)) {
    log('WARNING: ZP contact has no school or district name! Using organization name instead.', zpContact)
  }
  const postData = {
    name: zpContact.organization,
    status: 'Contacted',
    contacts: [
      {
        name: zpContact.name,
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
  if (zpContact.title) {
    postData.contacts[0].title = zpContact.title;
  }
  if (zpContact.district) {
    postData.custom['demo_nces_district'] = zpContact.district;
    postData.custom['demo_nces_name'] = zpContact.school_name;
  }
  if (zpContact.nces_district_id) {
    postData.custom['demo_nces_district_id'] = zpContact.nces_district_id;
  }
  if (zpContact.nces_school_id) {
    postData.custom['demo_nces_id'] = zpContact.nces_school_id;
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
    'custom.lastUpdated': new Date()
  };
  const currentCustom = existingLead.custom || {};
  if (!currentCustom['Lead Origin']) {
    putData['custom.Lead Origin'] = 'outbound campaign';
  }
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
  // New contact lead matching algorithm:
  // 1. New contact email exists
  // 2. New contact NCES school id exists
  // 3. New contact NCES district id and no NCES school id
  // 4. New contact school name and no NCES data
  // 5. New contact district name and no NCES data
  return (done) => {
    // console.log(`DEBUG: createUpsertCloseLeadFn ${zpContact.organization} ${zpContact.email}`);
    let query = `email:${zpContact.email}`;
    let url = `https://${closeIoApiKey}:X@app.close.io/api/v1/lead/?query=${encodeURIComponent(query)}`;
    request.get(url, (error, response, body) => {
      if (error) return done(error);
      const data = JSON.parse(body);
      if (data.total_results != 0) return done();

      query = `name:"${zpContact.organization}"`;
      if (zpContact.nces_school_id) {
        query = `custom.demo_nces_id:"${zpContact.nces_school_id}"`;
      }
      else if (zpContact.nces_district_id) {
        query = `custom.demo_nces_district_id:"${zpContact.nces_district_id}" custom.demo_nces_id:"" custom.demo_nces_name:""`;
      }
      url = `https://${closeIoApiKey}:X@app.close.io/api/v1/lead/?query=${encodeURIComponent(query)}`;
      request.get(url, (error, response, body) => {
        if (error) return done(error);
        const data = JSON.parse(body);
        if (data.total_results === 0) {
          console.log(`DEBUG: Creating lead for ${zpContact.organization} ${zpContact.email} nces_district_id=${zpContact.nces_district_id} nces_school_id=${zpContact.nces_school_id}`);
          return createCloseLead(zpContact, done);
        }
        else if (data.total_results > 1) {
          console.error(`ERROR: ${data.total_results} leads found with info from Zen Prospect: email=${zpContact.email}, organization=${zpContact.organization}, school_name=${zpContact.school_name}, district=${zpContact.district}, nces_district_id=${zpContact.nces_district_id}, nces_school_id=${zpContact.nces_school_id}, nces_district_id=${zpContact.nces_district_id}. Final query: ${query}`);
          return done()
        }
        else {
          const existingLead = data.data[0];
          console.log(`DEBUG: Adding to ${existingLead.id} ${zpContact.organization} ${zpContact.email} nces_district_id=${zpContact.nces_district_id} nces_school_id=${zpContact.nces_school_id}`);
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
      const newContact = {
        organization: contact.organization_name,
        name: contact.name,
        title: contact.title,
        email: contact.email,
        phone: contact.phone,
        data: contact
      };
      // console.log("contact email:",contact.email,"contact custom fields:", contact.custom_fields);
      if (contact.custom_fields) {
        if (contact.custom_fields.district) {
          newContact.district = contact.custom_fields.district;
          newContact.organization = contact.custom_fields.district;
          // console.log(`DEBUG: found contact with district name ${newContact.email} ${contact.custom_fields.district}`);
        }
        if (contact.custom_fields.school_name) {
          newContact.school_name = contact.custom_fields.school_name;
          newContact.organization = contact.custom_fields.school_name;
          // console.log(`DEBUG: found contact with school name ${newContact.email} ${contact.custom_fields.school_name}`);
        }
        if (contact.custom_fields.nces_district_id) {
          newContact.nces_district_id = contact.custom_fields.nces_district_id;
          // console.log(`DEBUG: found contact with district id ${newContact.email} ${newContact.nces_district_id}`);
        }
        if (contact.custom_fields.nces_school_id) {
          newContact.nces_school_id = contact.custom_fields.nces_school_id;
          // console.log(`DEBUG: found contact with school id ${newContact.email} ${newContact.nces_school_id}`);
        }
      }
      contacts.push(newContact);
    }
    return done(null, data.pipeline_total);
  });
}

function createGetZPAutoResponderContactsPage(contacts, page) {
  return (done) => {
    // console.log(`DEBUG: Fetching autoresponder page ${page} ${zpPageSize}...`);
    let searchQuery = `codecombat_special_auth_token=${zpAuthToken}&page=${page}&per_page=${zpPageSize}&last_activity_date_range[min]=${zpMinActivityDate}&contact_email_autoresponder=true`;
    getZPContactsPage(contacts, searchQuery, done);
  };
}

function createGetZPRepliedContactsPage(contacts, page) {
  return (done) => {
    // console.log(`DEBUG: Fetching email reply page ${page} ${zpPageSize}...`);
    let searchQuery = `codecombat_special_auth_token=${zpAuthToken}&page=${page}&per_page=${zpPageSize}&last_activity_date_range[min]=${zpMinActivityDate}&contact_email_replied=true`;
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
          if (!contact.organization || !contact.name || !contact.email) {
            console.log(`DEBUG: missing data for zp contact ${contact.email}: {organization: ${contact.organization}, school_name: ${contact.school_name}, district: ${contact.district}, name: ${contact.name}, email: ${contact.email}}`);
            // console.log(JSON.stringify(contact, null, 2));
          }
          else if (!emailContactMap[contact.email]) {
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
