ModalView = require 'views/core/ModalView'
template = require 'templates/core/auth'
{loginUser, createUser, me} = require 'core/auth'
forms = require 'core/forms'
User = require 'models/User'
application  = require 'core/application'

module.exports = class AuthModal extends ModalView
  id: 'auth-modal'
  template: template
  mode: 'signup' # or 'login'

  events:
    # login buttons
    'click #switch-to-signup-button': 'onSignupInstead'
    'click #switch-to-login-button': 'onLoginInstead'
    'click #github-login-button': 'onGitHubLoginClicked'
    'submit': 'onSubmitForm' # handles both submit buttons
    'keyup #name': 'onNameChange'
    'click #gplus-login-button': 'onClickGPlusLogin'
    'click #close-modal': 'hide'
    'click #facebook-login-btn': 'onClickFacebookLoginButton'

  subscriptions:
    'errors:server-error': 'onServerError'
    'auth:logging-in-with-facebook': 'onLoggingInWithFacebook'

  constructor: (options) ->
    options ?= {}
    @onNameChange = _.debounce @checkNameExists, 500
    super options
    @mode = options.mode if options.mode

  getRenderData: ->
    c = super()
    c.showRequiredError = @options.showRequiredError
    c.showSignupRationale = @options.showSignupRationale
    c.mode = @mode
    c.formValues = @previousFormInputs or {}
    c.me = me
    c

  afterRender: ->
    super()
    @$el.toggleClass('signup', @mode is 'signup').toggleClass('login', @mode is 'login')
    @playSound 'game-menu-open'

  afterInsert: ->
    super()
    _.delay (=> application.router.renderLoginButtons()), 500
    _.delay (=> $('input:visible:first', @$el).focus()), 500

  onSignupInstead: (e) ->
    @playSound 'menu-button-click'
    @mode = 'signup'
    @previousFormInputs = forms.formToObject @$el
    @render()
    _.delay application.router.renderLoginButtons, 500

  onLoginInstead: (e) ->
    @playSound 'menu-button-click'
    @mode = 'login'
    @previousFormInputs = forms.formToObject @$el
    @render()
    _.delay application.router.renderLoginButtons, 500

  onSubmitForm: (e) ->
    @playSound 'menu-button-click'
    e.preventDefault()
    if @mode is 'login' then @loginAccount() else @createAccount()
    false

  loginAccount: ->
    forms.clearFormAlerts(@$el)
    userObject = forms.formToObject @$el
    res = tv4.validateMultiple userObject, User.schema
    return forms.applyErrorsToForm(@$el, res.errors) unless res.valid
    @enableModalInProgress(@$el) # TODO: part of forms
    loginUser userObject, null, window.nextURL

  emailCheck: ->
    email = $('#email', @$el).val()
    filter = /^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,63}$/i  # https://news.ycombinator.com/item?id=5763990
    unless filter.test(email)
      forms.setErrorToProperty @$el, 'email', 'Please enter a valid email address', true
      return false
    return true

  createAccount: ->
    forms.clearFormAlerts(@$el)
    return unless @emailCheck()
    userObject = forms.formToObject @$el
    delete userObject.subscribe
    delete userObject.name if userObject.name is ''
    delete userObject.schoolName if userObject.schoolName is ''
    userObject.name = @suggestedName if @suggestedName
    for key, val of me.attributes when key in ['preferredLanguage', 'testGroupNumber', 'dateCreated', 'wizardColor1', 'name', 'music', 'volume', 'emails', 'schoolName']
      userObject[key] ?= val
    subscribe = @$el.find('#subscribe').prop('checked')
    userObject.emails ?= {}
    userObject.emails.generalNews ?= {}
    userObject.emails.generalNews.enabled = subscribe
    res = tv4.validateMultiple userObject, User.schema
    return forms.applyErrorsToForm(@$el, res.errors) unless res.valid
    Backbone.Mediator.publish "auth:signed-up", {}
    window.tracker?.trackEvent 'Finished Signup', label: 'CodeCombat'
    @enableModalInProgress(@$el)
    createUser userObject, null, window.nextURL

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
    @playSound 'menu-button-click'
    Backbone.Mediator.publish 'auth:log-in-with-github', {}

  gplusAuthSteps: [
    { i18n: 'login.authenticate_gplus', done: false }
    { i18n: 'login.load_profile', done: false }
    { i18n: 'login.finishing', done: false }
  ]

  onClickGPlusLogin: ->
    @playSound 'menu-button-click'
    step.done = false for step in @gplusAuthSteps
    handler = application.gplusHandler

    @listenToOnce handler, 'logged-in', ->
      @gplusAuthSteps[0].done = true
      @renderGPlusAuthChecklist()
      handler.loginCodeCombat()
      @listenToOnce handler, 'person-loaded', ->
        @gplusAuthSteps[1].done = true
        @renderGPlusAuthChecklist()

      @listenToOnce handler, 'logging-into-codecombat', ->
        @gplusAuthSteps[2].done = true
        @renderGPlusAuthChecklist()

  renderGPlusAuthChecklist: ->
    template = require 'templates/core/auth-modal-gplus-checklist'
    el = $(template({steps: @gplusAuthSteps}))
    el.i18n()
    @$el.find('.modal-body:visible').empty().append(el)
    @$el.find('.modal-footer').remove()

  onClickFacebookLoginButton: ->
    application.facebookHandler.loginThroughFacebook()

  onHidden: ->
    super()
    @playSound 'game-menu-close'
