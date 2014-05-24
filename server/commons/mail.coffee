config = require '../../server_config'

module.exports.MAILCHIMP_LIST_ID = 'e9851239eb'
module.exports.MAILCHIMP_GROUP_ID = '4529'

# these two need to be parallel
module.exports.MAILCHIMP_GROUPS = ['Announcements', 'Adventurers', 'Artisans', 'Archmages', 'Scribes', 'Diplomats', 'Ambassadors']
module.exports.NEWS_GROUPS = ['generalNews', 'adventurerNews', 'artisanNews', 'archmageNews', 'scribeNews', 'diplomatNews', 'ambassadorNews']

nodemailer = require 'nodemailer'
module.exports.transport = nodemailer.createTransport "SMTP",
  service: config.mail.service
  user: config.mail.username
  pass: config.mail.password
  authMethod: "LOGIN"
