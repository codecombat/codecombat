closeIO = require '../lib/closeIO'
log = require 'winston'
mongoose = require 'mongoose'
config = require '../../server_config'
hipchat = require '../hipchat'
sendwithus = require '../sendwithus'
Prepaid = require '../prepaids/Prepaid'
jsonSchema = require '../../app/schemas/models/trial_request.schema'
Classroom = require '../classrooms/Classroom'
User = require '../users/User'

TrialRequestSchema = new mongoose.Schema {}, {strict: false, minimize: false, read:config.mongo.readpref}

TrialRequestSchema.pre 'save', (next) ->
  return next() unless @get('status') is 'approved'

  # Add 2 course headcount
  prepaid = new Prepaid
    creator: @get('applicant')
    type: 'course'
    maxRedeemers: 2
    properties:
      trialRequestID: @get('_id')
  prepaid.save (err) =>
    if err
      log.error "Trial request prepaid creation error: #{err}"
    next()

TrialRequestSchema.post 'save', (doc) ->
  if doc.get('status') is 'approved'
    unless trialProperties = doc.get('properties')
      log.error "Saving approved trial request #{doc.id} with no properties!"
      return

    User.findById doc.get('applicant'), (err, user) =>
      if err
        log.error "Trial request user find error: #{err}"
        return

      # Send trial approved email
      email = trialProperties.email ? user.get('emailLower')
      emailParams =
        recipient:
          address: email
        email_id: sendwithus.templates.teacher_request_demo
        email_data:
          account_exists: user?.get('anonymous') is false
          classes_exist: false
      if user?.get('anonymous') is false
        Classroom.findOne {ownerID: user.get('_id')}, (err, classroom) =>
          if err
            log.error "Trial request classroom find error: #{err}"
            return
          emailParams.email_data.classes_exist = classroom?
          sendwithus.api.send emailParams, (err, result) =>
            log.error "sendwithus trial request approved error: #{err}, result: #{result}" if err
      else
        sendwithus.api.send emailParams, (err, result) =>
          log.error "sendwithus trial request approved error: #{err}, result: #{result}" if err

      # Subscribe to teacher news group
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
