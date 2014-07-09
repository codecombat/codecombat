mongoose = require 'mongoose'
plugins = require '../../plugins/plugins'
jsonschema = require '../../../app/schemas/models/mail_task'

MailTaskSchema = new mongoose.Schema({}, {strict: false})

module.exports = MailTask = mongoose.model('mail.task', MailTaskSchema)
