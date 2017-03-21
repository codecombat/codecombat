log = require 'winston'
mongoose = require 'mongoose'
config = require '../../server_config'
sendwithus = require '../sendwithus'
Prepaid = require './Prepaid'
jsonSchema = require '../../app/schemas/models/trial_request.schema'
Classroom = require './Classroom'
User = require './User'

TrialRequestSchema = new mongoose.Schema {}, {strict: false, minimize: false, read:config.mongo.readpref}

TrialRequestSchema.post 'save', (doc) ->
  # Subscribe to teacher news group
  User.findById doc.get('applicant'), (err, user) =>
    if err
      log.error "Trial request user find error: #{err}"
      return
    emails = _.cloneDeep(user.get('emails') ? {})
    emails.teacherNews ?= {}
    emails.teacherNews.enabled = true
    user.update {$set: {emails: emails}}, {}, (err) =>
      if err
        log.error "Trial request user update error: #{err}"
        return

TrialRequestSchema.statics.privateProperties = []
TrialRequestSchema.statics.editableProperties = [
  'created'
  'prepaidCode'
  'properties'
  'reviewDate'
  'reviewer'
  'status'
  'type'
]

TrialRequestSchema.statics.jsonSchema = jsonSchema
module.exports = TrialRequest = mongoose.model 'trial.request', TrialRequestSchema, 'trial.requests'
