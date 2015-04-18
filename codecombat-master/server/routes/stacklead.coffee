config = require '../../server_config'
request = require 'request'
log = require 'winston'

module.exports.setup = (app) ->
  app.post '/stacklead', (req, res) ->
    return res.end() unless req.user
    email = req.body.email or req.user.get 'email'
    sendStackLead email, req.user
    return res.end()

module.exports.sendStackLead = sendStackLead = (email, user) ->
  return unless key = config.mail.stackleadAPIKey
  form = email: email, api_key: key
  if user
    form.first_name = firstName if firstName = user.get('firstName')
    form.last_name = lastName if lastName = user.get('lastName')
    if profile = user.get 'jobProfile'
      form.name = name if name = profile.name
      form.location = location if location = profile.city
      form.location = location if location = profile.city
      for link in (profile.links ? [])
        form.linkedin = link.link if /linkedin/.test link.link
        form.twitter = link.link if /twitter/.test link.link
      form.company = company if company = profile.work?[0]?.employer
    if linkedIn = user.get('signedEmployerAgreement')?.data
      form.first_name = data.firstName if data.firstName
      form.last_name = data.lastName if data.lastName
      form.linkedin = data.publicProfileUrl if data.publicProfileUrl
      data.company = company if company = data.positions?.values?[0]?.company?.name
  request.post {uri: 'https://stacklead.com/api/leads', form: form}, (err, res, body) ->
    return log.error 'Error sending StackLead request:', err or body if err or /error/.test body
