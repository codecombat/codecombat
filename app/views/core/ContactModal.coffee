ModalView = require 'views/core/ModalView'
template = require 'templates/core/contact'

forms = require 'core/forms'
{sendContactMessage} = require 'core/contact'

contactSchema =
  additionalProperties: false
  required: ['email', 'message']
  properties:
    email:
      type: 'string'
      maxLength: 100
      minLength: 1
      format: 'email'

    message:
      type: 'string'
      minLength: 1

module.exports = class ContactModal extends ModalView
  id: 'contact-modal'
  template: template
  closeButton: true

  events:
    'click #contact-submit-button': 'contact'

  contact: ->
    @playSound 'menu-button-click'
    forms.clearFormAlerts @$el
    contactMessage = forms.formToObject @$el
    res = tv4.validateMultiple contactMessage, contactSchema
    return forms.applyErrorsToForm @$el, res.errors unless res.valid
    @populateBrowserData contactMessage
    contactMessage = _.merge contactMessage, @options
    contactMessage.country = me.get('country')
    window.tracker?.trackEvent 'Sent Feedback', message: contactMessage
    sendContactMessage contactMessage, @$el
    $.post "/db/user/#{me.id}/track/contact_codecombat"

  populateBrowserData: (context) ->
    if $.browser
      context.browser = "#{$.browser.platform} #{$.browser.name} #{$.browser.versionNumber}"
    context.screenSize = "#{screen?.width ? $(window).width()} x #{screen?.height ? $(window).height()}"
    context.screenshotURL = @screenshotURL

  updateScreenshot: ->
    return unless @screenshotURL
    screenshotEl = @$el.find('#contact-screenshot').removeClass('secret')
    screenshotEl.find('a').prop('href', @screenshotURL.replace("http://codecombat.com/", "/"))
    screenshotEl.find('img').prop('src', @screenshotURL.replace("http://codecombat.com/", "/"))
