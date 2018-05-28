User = require '../models/User'
co = require 'co'
delighted = require '../delighted'
config = require '../../server_config'
request = require 'request'
intercom = require '../lib/intercom'
log = require 'winston'

unsubscribeEmailFromMarketingEmails = co.wrap (email) ->
  log.info "Completely unsubscribing email: #{email}"
  # set user to be unsubscribed forever if user exists
  user = yield User.findByEmail(email)
  if user
    user.set('unsubscribedFromMarketingEmails', true)
    emails = _.cloneDeep(user.get('emails') or {}) # necessary for saves to work
    emails.generalNews ?= {}
    emails.anyNotes ?= {}
    consentHistory = _.cloneDeep(user.get('consentHistory') or [])
    for key, val of emails
      continue if key is 'anyNotes'
      if val.enabled
        consentHistory.push
          action: 'forbid'
          date: new Date()
          type: 'email'
          emailHash: User.hashEmail(user.get('email'))
          description: key
      val.enabled = false
    user.set('consentHistory', consentHistory)
    user.set('emails', emails)
    user.set 'mailChimp', undefined
    # unsubscribe user from MailChimp
    yield user.save() # middleware takes care of unsubscribing MailChimp

  updateConsentHistory = co.wrap (description) ->
    yield user.update {$push: {'consentHistory':
      action: 'forbid'
      date: new Date()
      type: 'email'
      emailHash: User.hashEmail(user.get('email'))
      description: description
    }}

  # unsubscribe user from delighted
  delighted.unsubscribeEmail({ person_email: email })
  yield updateConsentHistory('delighted')

  # unsubscribe user from ZP
  searchUrl = "https://www.zenprospect.com/api/v1/contacts/search?api_key=#{config.zenProspect.apiKey}&q_keywords=#{email}"
  contactUrl = "https://www.zenprospect.com/api/v1/contacts?api_key=#{config.zenProspect.apiKey}"
  DO_NOT_CONTACT = '57290b9c7ff0bb3b3ef2bebb'
  [res] = yield request.getAsync({ url:searchUrl, json: true })
  if res.statusCode is 200
    if res.body.contacts.length is 0
      # post a contact with status "do not contact" to prevent reaching out
      json = { email, contact_stage_id: DO_NOT_CONTACT } # contact stage: do not contact
      [res] = yield request.postAsync({ url:contactUrl, json })
    else
      # update any existing contacts "to do not contact"
      for contact in res.body.contacts
        if contact.contact_stage_id isnt DO_NOT_CONTACT
          url = "https://www.zenprospect.com/api/v1/contacts/#{contact.id}?api_key=#{config.zenProspect.apiKey}"
          json = {contact_stage_id: DO_NOT_CONTACT}
          [res] = yield request.putAsync({ url, json })
    yield updateConsentHistory('zenprospect')

  # unsubscribe user from Intercom
  tries = 0
  while tries < 10
    try
      yield intercom.users.find({email}) # throws error if 404
      # if an error hasn't been thrown, then update the user
      res = yield intercom.users.update({email, unsubscribed_from_emails: true})
      yield updateConsentHistory('intercom')
      break
    catch e
      if e.statusCode is 429
        # sleep, try again
        yield new Promise((accept) -> setTimeout(accept, 1000))
        continue
      # otherwise, no user found
      break

module.exports = {
  unsubscribeEmailFromMarketingEmails
}
