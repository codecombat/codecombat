ModalView = require 'views/core/ModalView'
template = require 'templates/core/auth'
{loginUser, createUser, me} = require 'core/auth'
forms = require 'core/forms'
User = require 'models/User'
application  = require 'core/application'
errors = require 'core/errors'

module.exports = class AuthModal extends ModalView
  id: 'auth-modal'
  template: template

  events:
    # login buttons
    'click #switch-to-signup-btn': 'onSignupInstead'
    'click #github-login-button': 'onGitHubLoginClicked'
    'submit form': 'onSubmitForm' # handles both submit buttons
    'keyup #name': 'onNameChange'
    'click #gplus-login-btn': 'onClickGPlusLogin'
    'click #facebook-login-btn': 'onClickFacebookLoginButton'
    'click #close-modal': 'hide'

  subscriptions:
    'errors:server-error': 'onServerError'
    'auth:facebook-api-loaded': 'onFacebookAPILoaded'


  # Initialization
    
  initialize: (options={}) ->
    @previousFormInputs = options.initialValues or {}
    @listenTo application.gplusHandler, 'logged-into-google', @onGPlusHandlerLoggedIntoGoogle
    @listenTo application.gplusHandler, 'person-loaded', @onGPlusPersonLoaded
    @listenTo application.gplusHandler, 'render-login-buttons', @onGPlusRenderLoginButtons
    @listenTo application.facebookHandler, 'logged-into-facebook', @onFacebookHandlerLoggedIntoFacebook
    @listenTo application.facebookHandler, 'person-loaded', @onFacebookPersonLoaded

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
    @playSound 'game-menu-open'
    @$('#facebook-login-btn').attr('disabled', true) if not window.FB?

  afterInsert: ->
    super()
    _.delay (=> application.router.renderLoginButtons()), 500
    _.delay (=> $('input:visible:first', @$el).focus()), 500

  onGPlusRenderLoginButtons: ->
    @$('#gplus-login-btn').attr('disabled', false)

  onFacebookAPILoaded: ->
    @$('#facebook-login-btn').attr('disabled', false)

  onSignupInstead: (e) ->
    CreateAccountModal = require('./CreateAccountModal')
    modal = new CreateAccountModal({initialValues: forms.formToObject @$el})
    currentView.openModalView(modal)

  onSubmitForm: (e) ->
    @playSound 'menu-button-click'
    e.preventDefault()
    forms.clearFormAlerts(@$el)
    userObject = forms.formToObject @$el
    res = tv4.validateMultiple userObject, User.schema
    return forms.applyErrorsToForm(@$el, res.errors) unless res.valid
    @enableModalInProgress(@$el) # TODO: part of forms
    loginUser userObject, null, window.nextURL

  onServerError: (e) -> # TODO: work error handling into a separate forms system
    @disableModalInProgress(@$el)
    
    
  # Google Plus

  onClickGPlusLogin: ->
    @clickedGPlusLogin = true

  onGPlusHandlerLoggedIntoGoogle: ->
    return unless @clickedGPlusLogin
    application.gplusHandler.loadPerson()
    btn = @$('#gplus-login-btn')
    btn.find('.sign-in-blurb').text($.i18n.t('login.logging_in'))
    btn.attr('disabled', true)

  onGPlusPersonLoaded: (gplusAttrs) ->
    existingUser = new User()
    existingUser.fetchGPlusUser(gplusAttrs.gplusID, {
      success: =>
        me.loginGPlusUser(gplusAttrs.gplusID, {
          success: -> window.location.reload()
          error: @onGPlusLoginError
        })
      error: @onGPlusLoginError
    })
    
  onGPlusLoginError: =>
    btn = @$('#gplus-login-btn')
    btn.find('.sign-in-blurb').text($.i18n.t('login.sign_in_with_gplus'))
    btn.attr('disabled', false)
    errors.showNotyNetworkError(arguments...)
    
    
  # Facebook

  onClickFacebookLoginButton: ->
    @clickedFacebookLogin = true
    if application.facebookHandler.loggedIn
      @onFacebookHandlerLoggedIntoFacebook()
    else
      application.facebookHandler.loginThroughFacebook()

  onFacebookHandlerLoggedIntoFacebook: ->
    return unless @clickedFacebookLogin
    application.facebookHandler.loadPerson()
    btn = @$('#facebook-login-btn')
    btn.find('.sign-in-blurb').text($.i18n.t('login.logging_in'))
    btn.attr('disabled', true)

  onFacebookPersonLoaded: (facebookAttrs) ->
    existingUser = new User()
    existingUser.fetchFacebookUser(facebookAttrs.facebookID, {
      success: =>
        me.loginFacebookUser(facebookAttrs.facebookID, {
          success: -> window.location.reload()
          error: @onFacebookLoginError
        })
      error: @onFacebookLoginError
    })

  onFacebookLoginError: =>
    btn = @$('#facebook-login-btn')
    btn.find('.sign-in-blurb').text($.i18n.t('login.sign_in_with_facebook'))
    btn.attr('disabled', false)
    errors.showNotyNetworkError(arguments...)


  onHidden: ->
    super()
    @playSound 'game-menu-close'
