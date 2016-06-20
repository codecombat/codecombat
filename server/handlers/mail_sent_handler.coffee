MailSent = require './../models/MailSent'
Handler = require '../commons/Handler'

class MailSentHandler extends Handler
  modelClass: MailSent
  editableProperties: ['mailTask','user','sent']
  jsonSchema: require '../../app/schemas/models/mail_sent'

  hasAccess: (req) ->
    req.user?.isAdmin()

module.exports = new MailSentHandler()
