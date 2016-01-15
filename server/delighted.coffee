config = require '../server_config'
request = require 'request'
log = require 'winston'

DELIGHTED_EMAIL_DELAY = 1 * 86400  # in seconds

module.exports.addDelightedUser = addDelightedUser = (user) ->
  return unless key = config.mail.delightedAPIKey
  #return unless user.isEmailSubscriptionEnabled 'generalNews'  # Doesn't work? Just returns undefined...
  return if user.get('emails')?.generalNews?.enabled is false  # Workaround.
  name = user.get('name')
  if first = user.get('firstName') and last = user.get('lastName')
    name = first + ' ' + last
  form =
    email: user.get('email')
    name: name
    delay: DELIGHTED_EMAIL_DELAY
    properties:
      id: user.id
      locale: user.get('preferredLanguage')
      testGroupNumber: user.get('testGroupNumber')
      gender: user.get('gender')
      lastLevel: user.get('lastLevel')
  request.post {uri: "https://#{key}:@api.delightedapp.com/v1/people.json", form: form}, (err, res, body) ->
    return log.error 'Error sending Delighted request:', err or body if err or /error/i.test body
    #log.info "Got DelightedApp response: #{body}"
