config = require '../../server_config'

module.exports.MAILCHIMP_LIST_ID = 'e9851239eb'
module.exports.MAILCHIMP_GROUP_ID = '4529'
module.exports.MAILCHIMP_GROUP_MAP =
  announcement: 'Announcements'
  tester: 'Adventurers'
  level_creator: 'Artisans'
  developer: 'Archmages'
  article_editor: 'Scribes'
  translator: 'Diplomats'
  support: 'Ambassadors'

nodemailer = require 'nodemailer'
module.exports.transport = nodemailer.createTransport "SMTP",
  service: config.mail.service
  user: config.mail.username
  pass: config.mail.password
  authMethod: "LOGIN"
