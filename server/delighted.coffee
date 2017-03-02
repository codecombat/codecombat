config = require '../server_config'
request = require 'request'
log = require 'winston'

DELIGHTED_EMAIL_DELAY = 10 * 86400  # in seconds

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

module.exports.maybeAddDelightedUser = addDelightedUser = (user, trialRequest) ->
  props = trialRequest.get('properties')
  return unless trialRequest.get('type') is 'course'
  return unless isTargetedCountry props.country
  name = props.firstName + ' ' + props.lastName
  form =
    email: props.email
    name: name
    delay: DELIGHTED_EMAIL_DELAY
    properties:
      id: trialRequest.get('applicant')
      locale: user.get('preferredLanguage')
      testGroupNumber: user.get('testGroupNumber')
      gender: user.get('gender')
      lastLevel: user.get('lastLevel')
      state: if props.nces_id and props.country is 'USA' then props.state else 'other'

  @postPeople(form)

module.exports.postPeople = (form) ->
  return unless key = config.mail.delightedAPIKey
  request.post {uri: "https://#{key}:@api.delightedapp.com/v1/people.json", form: form}, (err, res, body) ->
    return log.error 'Error sending Delighted request:', err or body if err or /error/i.test body
    #log.info "Got DelightedApp response: #{body}"
