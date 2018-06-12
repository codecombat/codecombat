config = require '../server_config'
request = require 'request'
log = require 'winston'
Prepaid = require './models/Prepaid'
Classroom = require './models/Classroom'
TrialRequest = require './models/TrialRequest'
co = require 'co'
delighted = require('delighted')(config.mail.delightedAPIKey)

ENGAGED_DELIGHTED_EMAIL_DELAY = 18 * 86400  # in seconds
PAID_DELIGHTED_EMAIL_DELAY = 7 * 86400

isTargetedCountry = (country) ->
  if /^u\.s\.?(\.a)?\.?$|^us$|usa|america|united states/ig.test(country)
    return true

  if /^england$|^uk$|^united kingdom$/ig.test(country)
    return true

  if /^ca$|^canada$/ig.test(country)
    return true

  if /^au$|^australia$/ig.test(country)
    return true
  
  return false

module.exports.maybeAddDelightedUser = addDelightedUser = (user, trialRequest, status='new') ->
  return if user.get('unsubscribedFromMarketingEmails')
  props = trialRequest.get('properties')
  return unless trialRequest.get('type') is 'course'
  return unless isTargetedCountry props.country
  name = props.firstName + ' ' + props.lastName
  form =
    email: props.email
    name: name
    delay: if status is 'engaged' then ENGAGED_DELIGHTED_EMAIL_DELAY else PAID_DELIGHTED_EMAIL_DELAY
    properties:
      id: trialRequest.get('applicant')
      locale: user.get('preferredLanguage')
      testGroupNumber: user.get('testGroupNumber')
      gender: user.get('gender')
      lastLevel: user.get('lastLevel')
      status: status
      state: if props.nces_id and props.country is 'USA' then props.state else 'other'

  module.exports.postPeople(form)

module.exports.postPeople = (form) ->
  console.log "Would post", JSON.stringify(form)
  return unless key = config.mail.delightedAPIKey
  request.post {uri: "https://#{key}:@api.delightedapp.com/v1/people.json", form: form}, (err, res, body) ->
    return log.error 'Error sending Delighted request:', err or body if err or /error/i.test body
    #log.info "Got DelightedApp response: #{body}"

module.exports.checkTriggerClassroomCreated = (user) ->
  # Check if the user has exactly one classrom, if so, queue the email
  co () ->
    return if user.get('unsubscribedFromMarketingEmails')
    count = yield Classroom.find(ownerID: user._id).count()
    return unless count is 1
    trialRequest = yield TrialRequest.findOne({applicant: user._id})
    return unless trialRequest?
    addDelightedUser user, trialRequest, 'engaged'

module.exports.checkTriggerPrepaidAdded = (user, type) ->
  # Check if the this is the first prepaid added to an account, if so, queue the email
  co () ->
    return if user.get('unsubscribedFromMarketingEmails')
    count = yield Prepaid.find(creator: user._id).count()
    return unless count is 1
    trialRequest = yield TrialRequest.findOne({applicant: user._id})
    return unless trialRequest?
    status = if type is 'starter_license' then 'paid starter' else 'paid full'
    addDelightedUser user, trialRequest, status

module.exports.unsubscribeEmail = (email) ->
  delighted.unsubscribe.create(email)
