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
    'click #switch-to-signup-btn': 'onSignupInstead'
    'click #github-login-button': 'onGitHubLoginClicked'
    'submit form': 'onSubmitForm'
    'keyup #name': 'onNameChange'
    'click #gplus-login-btn': 'onClickGPlusLoginButton'
    'click #facebook-login-btn': 'onClickFacebookLoginButton'
    'click #close-modal': 'hide'


  # Initialization
    
  initialize: (options={}) ->
    @previousFormInputs = options.initialValues or {}

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

  afterInsert: ->
    super()
    _.delay (=> $('input:visible:first', @$el).focus()), 500

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

  onClickGPlusLoginButton: ->
    btn = @$('#gplus-login-btn')
    btn.attr('disabled', true)
    application.gplusHandler.loadAPI({
      context: @
      success: ->
        btn.attr('disabled', false)
        application.gplusHandler.connect({
          context: @
          success: ->
            btn.find('.sign-in-blurb').text($.i18n.t('login.logging_in'))
            btn.attr('disabled', true)
            application.gplusHandler.loadPerson({
              context: @
              success: (gplusAttrs) ->
                existingUser = new User()
                existingUser.fetchGPlusUser(gplusAttrs.gplusID, {
                  success: =>
                    me.loginGPlusUser(gplusAttrs.gplusID, {
                      success: -> window.location.reload()
                      error: @onGPlusLoginError
                    })
                  error: @onGPlusLoginError
                })
            })
        })
    })

  onGPlusLoginError: =>
    btn = @$('#gplus-login-btn')
    btn.find('.sign-in-blurb').text($.i18n.t('login.sign_in_with_gplus'))
    btn.attr('disabled', false)
    errors.showNotyNetworkError(arguments...) 
    
    
  # Facebook

  onClickFacebookLoginButton: ->
    btn = @$('#facebook-login-btn')
    btn.attr('disabled', true)
    application.facebookHandler.loadAPI({
      context: @
      success: ->
        btn.attr('disabled', false)
        application.facebookHandler.connect({
          context: @
          success: ->
            btn.find('.sign-in-blurb').text($.i18n.t('login.logging_in'))
            btn.attr('disabled', true)
            application.facebookHandler.loadPerson({
              context: @
              success: (facebookAttrs) ->
                existingUser = new User()
                existingUser.fetchFacebookUser(facebookAttrs.facebookID, {
                  success: =>
                    me.loginFacebookUser(facebookAttrs.facebookID, {
                      success: -> window.location.reload()
                      error: @onFacebookLoginError
                    })
                  error: @onFacebookLoginError
                })
            })
        })
    })
    
  onFacebookLoginError: =>
    btn = @$('#facebook-login-btn')
    btn.find('.sign-in-blurb').text($.i18n.t('login.sign_in_with_facebook'))
    btn.attr('disabled', false)
    errors.showNotyNetworkError(arguments...)


  onHidden: ->
    super()
    @playSound 'game-menu-close'
