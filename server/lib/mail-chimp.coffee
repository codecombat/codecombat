config = require '../../server_config'
MailChimp = require('mailchimp-api-v3')
api = new MailChimp(config.mail.mailChimpAPIKey or '00000000000000000000000000000000-us1')

if GLOBAL.testing
  api = {
    put: -> Promise.resolve()
    get: -> Promise.resolve({ status: 'subscribed' }) 
    delete: -> Promise.resolve()
  }
  

MAILCHIMP_LIST_ID = 'e9851239eb'
MAILCHIMP_GROUP_ID = '4529'

# Need mailChimpId when communicating TO MailChimp with the API, and mailChimpLabel 
# when receiving communication FROM MailChimp through the WebHook.
interests = [
  {
    "mailChimpLabel": "Announcements",
    "property": "generalNews",
    "mailChimpId": "363e59637c"
  },
  {
    "mailChimpLabel": "Adventurers",
    "property": "adventurerNews",
    "mailChimpId": "5ad1678251"
  },
  {
    "mailChimpLabel": "Artisans",
    "property": "artisanNews",
    "mailChimpId": "4f9b3f5895"
  },
  {
    "mailChimpLabel": "Archmages",
    "property": "archmageNews",
    "mailChimpId": "4f668727b3"
  },
  {
    "mailChimpLabel": "Scribes",
    "property": "scribeNews",
    "mailChimpId": "a8b435ed50"
  },
  {
    "mailChimpLabel": "Diplomats",
    "property": "diplomatNews",
    "mailChimpId": "878a6cd8c1"
  },
  {
    "mailChimpLabel": "Ambassadors",
    "property": "ambassadorNews",
    "mailChimpId": "eb02f46540"
  },
  {
    "mailChimpLabel": "Teachers",
    "property": "teacherNews",
    "mailChimpId": "f6b8104635"
  }
]

crypto = require 'crypto'

makeSubscriberUrl = (email) ->
  return '' unless email
  # http://developer.mailchimp.com/documentation/mailchimp/guides/manage-subscribers-with-the-mailchimp-api/
  subscriberHash = crypto.createHash('md5').update(email.toLowerCase()).digest('hex')
  return "/lists/#{MAILCHIMP_LIST_ID}/members/#{subscriberHash}"

module.exports = {
  api
  makeSubscriberUrl
  MAILCHIMP_LIST_ID
  MAILCHIMP_GROUP_ID
  interests
}
