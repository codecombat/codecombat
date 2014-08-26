ModalView = require 'views/kinds/ModalView'
template = require 'templates/modal/auth'
{loginUser, createUser, me} = require 'lib/auth'
forms = require 'lib/forms'
User = require 'models/User'
application  = require 'application'

module.exports = class AuthModal extends ModalView
  id: 'auth-modal'
  template: template
  mode: 'login' # or 'signup'

  events:
    # login buttons
    'click #switch-to-signup-button': 'onSignupInstead'
    'click #signup-confirm-age': 'checkAge'
    'click #github-login-button': 'onGitHubLoginClicked'
    'submit': 'onSubmitForm' # handles both submit buttons
    'keyup #name': 'onNameChange'

  subscriptions:
    'server-error': 'onServerError'
    'logging-in-with-facebook': 'onLoggingInWithFacebook'

  constructor: (options) ->
    @onNameChange = _.debounce @checkNameExists, 500
    super options

  getRenderData: ->
    c = super()
    c.showRequiredError = @options.showRequiredError
    c.title = {0: 'short', 1: 'long'}[me.get('testGroupNumber') % 2]
    c.descriptionOn = {0: 'yes', 1: 'no'}[Math.floor(me.get('testGroupNumber')/2) % 2]
    if @mode is 'signup'
      application.tracker.identify authModalTitle: c.title
      application.tracker.trackEvent 'Started Signup', authModalTitle: c.title, descriptionOn: c.descriptionOn
    c.mode = @mode
    c.formValues = @previousFormInputs or {}
    c.onEmployersPage = Backbone.history.fragment is "employers"
    c.me = me
    c
    
  afterInsert: ->
    super()
    _.delay application.router.renderLoginButtons, 500

  onSignupInstead: (e) ->
    @mode = 'signup'
    @previousFormInputs = forms.formToObject @$el
    @render()
    _.delay application.router.renderLoginButtons, 500

  onSubmitForm: (e) ->
    e.preventDefault()
    if @mode is 'login' then @loginAccount() else @createAccount()
    false

  checkAge: (e) ->
    $('#signup-button', @$el).prop 'disabled', not $(e.target).prop('checked')

  loginAccount: ->
    forms.clearFormAlerts(@$el)
    userObject = forms.formToObject @$el
    res = tv4.validateMultiple userObject, User.schema
    return forms.applyErrorsToForm(@$el, res.errors) unless res.valid
    @enableModalInProgress(@$el) # TODO: part of forms
    loginUser(userObject)

  createAccount: ->
    forms.clearFormAlerts(@$el)
    userObject = forms.formToObject @$el
    delete userObject.subscribe
    delete userObject['confirm-age']
    delete userObject.name if userObject.name is ''
    userObject.name = @suggestedName if @suggestedName
    for key, val of me.attributes when key in ['preferredLanguage', 'testGroupNumber', 'dateCreated', 'wizardColor1', 'name', 'music', 'volume', 'emails']
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

  onLoggingInWithFacebook: (e) ->
    modal = $('.modal:visible', @$el)
    @enableModalInProgress(modal) # TODO: part of forms

  onServerError: (e) -> # TODO: work error handling into a separate forms system
    @disableModalInProgress(@$el)

  checkNameExists: =>
    name = $('#name', @$el).val()
    return forms.clearFormAlerts(@$el) if name is ''
    User.getUnconflictedName name, (newName) =>
      forms.clearFormAlerts(@$el)
      if name is newName
        @suggestedName = undefined
      else
        @suggestedName = newName
        forms.setErrorToProperty @$el, 'name', "That name is taken! How about #{newName}?", true

  onGitHubLoginClicked: ->
    Backbone.Mediator.publish 'github-login'
