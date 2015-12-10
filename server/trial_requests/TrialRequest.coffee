log = require 'winston'
mongoose = require 'mongoose'
config = require '../../server_config'
hipchat = require '../hipchat'
sendwithus = require '../sendwithus'
Prepaid = require '../prepaids/Prepaid'
jsonSchema = require '../../app/schemas/models/trial_request.schema'

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

    # Special HoC trial: Add 500 course headcount with end date
    endDate = new Date()
    endDate.setUTCMonth(endDate.getUTCMonth() + 2)
    prepaid = new Prepaid
      creator: @get('applicant')
      type: 'course'
      maxRedeemers: 500
      properties:
        endDate: endDate
        trialRequestID: @get('_id')
    prepaid.save (err) =>
      if err
        log.error "Trial request prepaid creation error: #{err}"
      next()

TrialRequestSchema.post 'save', (doc) ->
  if doc.get('status') is 'approved'
    endDate = new Date()
    endDate.setUTCMonth(endDate.getUTCMonth() + 2)
    emailParams =
      recipient:
        address: doc.get('properties')?.email
      email_id: sendwithus.templates.teacher_free_trial_hoc
      email_data:
        endDate: endDate.toDateString()
    sendwithus.api.send emailParams, (err, result) =>
      log.error "sendwithus trial request approved error: #{err}, result: #{result}" if err

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
