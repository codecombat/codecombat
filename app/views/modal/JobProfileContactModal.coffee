ContactModal = require 'views/modal/ContactModal'
template = require 'templates/modal/job_profile_contact'

forms = require 'lib/forms'
{sendContactMessage} = require 'lib/contact'

contactSchema =
  additionalProperties: false
  required: ['email', 'message']
  properties:
    email:
      type: 'string'
      maxLength: 100
      minLength: 1
      format: 'email'

    subject:
      type: 'string'
      minLength: 1

    message:
      type: 'string'
      minLength: 1

    recipientID:
      type: 'string'
      minLength: 1

module.exports = class JobProfileContactModal extends ContactModal
  id: 'job-profile-contact-modal'
  template: template

  contact: ->
    forms.clearFormAlerts @$el
    contactMessage = forms.formToObject @$el
    contactMessage.recipientID = @options.recipientID
    res = tv4.validateMultiple contactMessage, contactSchema
    return forms.applyErrorsToForm @$el, res.errors unless res.valid
    contactMessage.message += "\n\n\n\n[For reference, the recipient's CodeCombat username is  #{@options.recipientUserName}!]"
    window.tracker?.trackEvent 'Sent Job Profile Message', message: contactMessage
    sendContactMessage contactMessage, @$el
    $.post "/db/user/#{me.id}/track/contact_candidate"
    $.post "/db/user/#{@options.recipientID}/track/contacted_by_employer" unless me.isAdmin()
