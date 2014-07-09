MailTask = require './MailTask'
Handler = require '../../commons/Handler'

class MailTaskHandler extends Handler
  modelClass: MailTask
  editableProperties: ['url','frequency']
  jsonSchema: require '../../../app/schemas/models/mail_task'
  
  hasAccess: (req) ->
    req.user?.isAdmin()
    
module.exports = new MailTaskHandler()
