// Copy sales leads from HelpScout to Close.io based on HelpScout tags

// TODO: handle leads with multiple email addresses
// TODO: some feedback email threads get broken up in Close.io

var CloseIo = function  (apiKey, mailboxEmail) {
  this.apiKey = apiKey;
  this.mailboxEmail = mailboxEmail;
}
CloseIo.prototype.createLead = function (conversation, done) {
  console.log('Close.Io - Creating lead for', conversation.customer.email);
  var data = {
    contacts: [{
      emails: [{
        email: conversation.customer.email,
        type: 'office'
      }],
      name: conversation.customer.firstName + ' ' + conversation.customer.lastName
    }]
  };
  var options = {
    uri: 'https://' + this.apiKey+ ':X@app.close.io/api/v1/lead/',
    body: JSON.stringify(data)
  };
  request.post(options, function (error, response, body) {
    if (error) {
      return done(error);
    }
    return done(null, JSON.parse(body));
  });
}
CloseIo.prototype.getActivities = function (leadID, done) {
  // console.log('Close.Io - Retrieving activities for lead', leadID);
  request.get('https://' + this.apiKey + ':X@app.close.io/api/v1/activity/email/?lead_id=' + leadID, function(error, response, body) {
    if (error) {
      return done(error);
    }
    return done(null, JSON.parse(body));
  });
}
CloseIo.prototype.getLead = function (conversation, done) {
  // console.log('Close.Io - Retrieving contact', conversation.customer.email);
  var uri = 'https://' + this.apiKey + ':X@app.close.io/api/v1/lead/?query=email_address:' + conversation.customer.email;
  request.get(uri, (function(error, response, body) {
    if (error) return done(error);
    var leads = JSON.parse(body);
    if (leads.data.length === 1) {
      return done(null, leads.data[0]);
    }
    else if (leads.data.length > 1) {
      return done('ERROR: too many leads returned for ' + conversation.customer.email + ' ' + leads.data.length);
    }
    this.createLead(conversation, (function(error, lead) {
      if (error) return done(error);
      return done(null, lead);
    }).bind(this));
  }).bind(this));
}
CloseIo.prototype.updateActivity = function (activities, lead, conversation, conversationThread, done) {
  // console.log('Close.Io - Updating email thread', conversation.subject);
  var data = {
    body_html: conversationThread.body,
    contact_id: lead.contacts[0].id,
    date_created: conversationThread.createdAt,
    lead_id: lead.id,
    sender: conversationThread.createdBy.email,
    _type: 'Email'
  }
  if (conversation.subject) {
    data.subject = conversation.subject;
    if (data.subject.substring(0, 4) === 'Re: ') {
      data.subject = data.subject.substring(4);
    }
  }
  if (conversationThread.createdBy.email === this.mailboxEmail) {
    data.status = 'sent';
    data.to = [conversationThread.customer.email];
  }
  else {
    data.status = 'inbox';
    data.to = [this.mailboxEmail];
  }
  for (var i = 0; i < activities.data.length; i++) {
    if (activities.data[i].body_html === data.body_html
      && new Date(activities.data[i].date_created).getTime() == new Date(data.date_created).getTime()) {
      // console.log('Close.Io - Found existing email', data.subject, data.date_created);
      return done();
    }
  }
  var options = {
    uri: 'https://' + this.apiKey + ':X@app.close.io/api/v1/activity/email/',
    body: JSON.stringify(data)
  };
  request.post(options, function (error, response, body) {
    if (error) {
      return done(error);
    }
    return done();
  });
}
CloseIo.prototype.updateLead = function (conversation, done) {
  console.log('Close.Io - Updating lead', conversation.customer.email);
  this.getLead(conversation, (function(error, lead) {
    if (error) return done(error);
    this.updateLeadEmails(lead, conversation, (function(error) {
      if (error) {
        console.log(error);
        return;
      }
    }).bind(this));
  }).bind(this));
}
CloseIo.prototype.updateLeadEmails = function (lead, conversation, done) {
  console.log('Close.Io - Updating lead emails', lead.display_name, conversation.subject);
  if (conversation.type !== 'email') return done();
  this.getActivities(lead.id, (function(error, activities) {
      if (error) return done(error);
      for (var i = 0; i < conversation.threads.length; i++) {
        if (conversation.threads[i].type !== 'message') continue;
        if (conversation.threads[i].state !== 'published') continue;
        if (!conversation.threads[i].body || conversation.threads[i].body.length === 0) continue;
        this.updateActivity(activities, lead, conversation, conversation.threads[i], done);
      }
    }).bind(this));
}

var HelpScout = function  (apiKey, mailboxEmails, searchTag) {
  this.apiKey = apiKey;
  this.mailboxEmails = mailboxEmails;
  this.searchTag = searchTag;
}
HelpScout.prototype.getConversation = function (conversationId, done) {
  // console.log('HelpScout - Retrieving conversation', conversationId);
  request.get('https://' + this.apiKey + ':X@api.helpscout.net/v1/conversations/' + conversationId + '.json', function (error, response, body) {
    if (error) return done(error);
    var conversation = JSON.parse(body);
    return done(null, conversation.item);
  });
}
HelpScout.prototype.getConversations = function (mailboxId, done) {
  // console.log('HelpScout - Retrieving conversations for mailbox', mailboxId);
  var results = [];
  var fetchPage = (function (page) {
    // console.error("HelpScout - Fetching conversations page", page);
    var uri = 'https://' + this.apiKey + ':X@api.helpscout.net/v1/mailboxes/' + mailboxId + '/conversations.json'
    uri += '?page=' + page + '&tag=' + this.searchTag;
    request.get(uri, function (error, response, body) {
      if (error) return done(error);
      var conversations = JSON.parse(body);
      results = results.concat(conversations.items);
      if (conversations.page < conversations.pages) {
        return fetchPage(page + 1);
      }
      return done(null, results);
    });
  }).bind(this);
  fetchPage(1);
}
HelpScout.prototype.getMailboxes = function (done) {
  // console.log('HelpScout - Retrieving mailboxes');
  var results = [];
  request.get('https://' + this.apiKey + ':X@api.helpscout.net/v1/mailboxes.json', (function (error, response, body) {
    if (error) return done(error);
    var mailboxes = JSON.parse(body);
    for (var i = 0 ; i < mailboxes.items.length; i++) {
      if (this.mailboxEmails.indexOf(mailboxes.items[i].email) >= 0) {
        results.push(mailboxes.items[i]);
      }
    }
    return done(null, results);
  }).bind(this));
}

// Main program

if (process.argv.length !== 4) {
  log("Usage: node <script> <HelpScout API key> <Close.io API key>");
  process.exit();
}

var request = require('request');
var helpScout = new HelpScout(process.argv[2], ['support@codecombat.com', 'team@codecombat.com'], 'make the sale');
var closeIo = new CloseIo(process.argv[3], 'matt@codecombat.com');

helpScout.getMailboxes(function (error, mailboxes) {
  if (error) {
    console.log(error);
    return;
  }
  for (var i = 0; i < mailboxes.length; i++) {
    var mailbox = mailboxes[i];
    helpScout.getConversations(mailbox.id, function(error, conversations) {
      if (error) {
        console.log(error);
        return;
      }
      console.log(mailbox.email, 'mailbox has', conversations.length, 'conversations');
      for (var i = 0; i < conversations.length; i++) {
        if (conversations[i].type !== 'email') continue;

        if (i > 8) {
          console.log('TODO: process all the conversations');
          break;
        }

        helpScout.getConversation(conversations[i].id, function(error, conversation) {
          if (error) {
            console.log(error);
            return;
          }
          closeIo.updateLead(conversation, function(error, lead) {
            if (error) {
              console.log(error);
              return;
            }
          });
        });
      }
    });
  }
});
