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

  # Add subscription
  Prepaid.generateNewCode (code) =>
    unless code
      log.error "Trial request pre save prepaid gen new code failure"
      return next()
    prepaid = new Prepaid
      creator: @get('reviewer')
      type: 'subscription'
      maxRedeemers: 1
      code: code
      properties:
        couponID: 'free'
    prepaid.save (err) =>
      if err
        log.error "Trial request prepaid creation error: #{err}"
        return next()
      @set('prepaidCode', code)

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
  if doc.get('status') is 'submitted'
    msg = "<a href=\"http://codecombat.com/admin/trial-requests\">Trial Request</a> submitted by #{doc.get('properties').email}"
    hipchat.sendHipChatMessage msg, ['tower']
  else if doc.get('status') is 'approved'
    ppc = doc.get('prepaidCode')
    unless ppc
      log.error 'Trial request post save no ppc'
      return
    emailParams =
      recipient:
        address: doc.get('properties')?.email
      email_id: sendwithus.templates.setup_free_sub_email
      email_data:
        url: "https://codecombat.com/account/subscription?_ppc=#{ppc}";
    sendwithus.api.send emailParams, (err, result) =>
      log.error "sendwithus trial request approved error: #{err}, result: #{result}" if err

TrialRequestSchema.statics.privateProperties = []
TrialRequestSchema.statics.editableProperties = [
  'prepaidCode'
  'properties'
  'reviewDate'
  'reviewer'
  'status'
  'type'
]

TrialRequestSchema.statics.jsonSchema = jsonSchema
module.exports = TrialRequest = mongoose.model 'trial.request', TrialRequestSchema, 'trial.requests'
