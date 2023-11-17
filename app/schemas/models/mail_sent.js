// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
const c = require('./../schemas');
//This will represent transactional emails which have been sent

const MailSentSchema = c.object({
  title: 'Sent mail',
  description: 'Emails which have been sent through the system'
});
_.extend(MailSentSchema.properties, {
  mailTask: c.objectId({}),
  user: c.objectId({links: [{rel: 'extra', href: '/db/user/{($)}'}]}),
  sent: c.date({title: 'Sent', readOnly: true}),
  metadata: c.object({}, {})
});

c.extendBasicProperties(MailSentSchema, 'mail.sent');

module.exports = MailSentSchema;
  