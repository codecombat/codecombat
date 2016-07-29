config = require '../server_config'
request = require 'request'
log = require 'winston'

DELIGHTED_EMAIL_DELAY = 1 * 86400  # in seconds

module.exports.addDelightedUser = addDelightedUser = (user, trialRequest) ->
  props = trialRequest.get('properties')
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
