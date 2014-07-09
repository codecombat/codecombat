c = require './../schemas'
#This will represent transactional emails which have been sent

MailTaskSchema = c.object {
  title: 'Mail task'
  description: 'Mail tasks to call at certain intervals'
}
_.extend MailTaskSchema.properties,
  url: 
    title: 'URL'
    description: 'The associated URL of the mailtask to call'
    type: 'string'
  frequency:
    title: 'Frequency'
    description: 'The number of seconds the servers should check whether or not to send the email'
    type: 'integer'

c.extendBasicProperties MailTaskSchema, 'mail.task'

module.exports = MailTaskSchema
  