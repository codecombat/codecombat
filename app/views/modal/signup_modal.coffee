View = require 'views/kinds/ModalView'
template = require 'templates/modal/signup'
{createUser, me} = require('lib/auth')
forms = require('lib/forms')
User = require 'models/User'

filterKeyboardEvents = (allowedEvents, func) ->
  return (splat...) ->
    e = splat[0]
    return unless e.keyCode in allowedEvents or not e.keyCode
    return func(splat...)

module.exports = class SignupModalView extends View
  id: "signup-modal"
  template: template

  events:
    "click #signup-confirm-age": "checkAge"
    "click #signup-button": "createAccount"
    "keydown input": "createAccount"

  subscriptions:
    'server-error': 'onServerError'
    'logging-in-with-facebook': 'onLoggingInWithFacebook'

  onServerError: (e) -> # TODO: work error handling into a separate forms system
    @disableModalInProgress(@$el)

  constructor: (options) ->
    @createAccount = filterKeyboardEvents([13], @createAccount) # TODO: part of forms
    super options
    window.tracker?.trackEvent 'Started Signup'

  onLoggingInWithFacebook: (e) ->
    modal = $('.modal:visible', @$el)
    @enableModalInProgress(modal) # TODO: part of forms

  checkAge: (e) ->
    $("#signup-button", @$el).prop 'disabled', not $(e.target).prop('checked')

  getRenderData: ->
    c = super()
    c.showRequiredError = @options.showRequiredError
    c

  createAccount: (e) =>
    forms.clearFormAlerts(@$el)
    userObject = forms.formToObject @$el
    delete userObject.subscribe
    delete userObject["confirm-age"]
    for key, val of me.attributes when key in ["preferredLanguage", "testGroupNumber", "dateCreated", "wizardColor1", "name", "music", "volume", "emails"]
      userObject[key] ?= val
    subscribe = @$el.find('#signup-subscribe').prop('checked')
    userObject.emails ?= {}
    userObject.emails.generalNews ?= {}
    userObject.emails.generalNews.enabled = subscribe
    res = tv4.validateMultiple userObject, User.schema
    return forms.applyErrorsToForm(@$el, res.errors) unless res.valid
    window.tracker?.trackEvent 'Finished Signup'
    @enableModalInProgress(@$el)
    createUser userObject, null, window.nextLevelURL

  afterInsert: ->
    super()
    application.router.renderLoginButtons()
