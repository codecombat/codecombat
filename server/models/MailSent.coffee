mongoose = require 'mongoose'
plugins = require '../plugins/plugins'
jsonschema = require '../../app/schemas/models/mail_sent'

MailSent = new mongoose.Schema({
  sent:
    type: Date
    'default': Date.now
}, {strict: false})

MailSent.index({user: 1}, {name: 'User'})

module.exports = MailSent = mongoose.model('mail.sent', MailSent)
