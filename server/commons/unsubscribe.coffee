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
    for key of emails
      continue if key is 'anyNotes'
      emails[key].enabled = false

    user.set('emails', emails)
    user.set 'mailChimp', undefined
    # unsubscribe user from MailChimp
    yield user.save() # middleware takes care of unsubscribing MailChimp

  # unsubscribe user from delighted
  delighted.unsubscribeEmail({ person_email: email })

  # unsubscribe user from ZP
  searchUrl = "https://www.zenprospect.com/api/v1/contacts/search?api_key=#{config.zenProspect.apiKey}&q_keywords=#{email}"
  [res] = yield request.getAsync({ url:searchUrl, json: true })
  if res.statusCode is 200 and res.body.contacts.length is 0
    postContactUrl = "https://www.zenprospect.com/api/v1/contacts?api_key=#{config.zenProspect.apiKey}"
    json = { email, contact_stage_id: '57290b9c7ff0bb3b3ef2bebb' } # contact stage: do not contact
    [res] = yield request.postAsync({ url:postContactUrl, json })
  
  # unsubscribe user from Intercom
  tries = 0
  while tries < 10
    try
      yield intercom.users.find({email}) # throws error if 404
      # if an error hasn't been thrown, then update the user
      res = yield intercom.users.update({email, unsubscribed_from_emails: true})
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
