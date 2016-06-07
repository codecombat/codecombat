ModalView = require 'views/core/ModalView'
template = require 'templates/core/auth-modal'
forms = require 'core/forms'
User = require 'models/User'
application  = require 'core/application'
errors = require 'core/errors'

module.exports = class AuthModal extends ModalView
  id: 'auth-modal'
  template: template

  events:
    'click #switch-to-signup-btn': 'onSignupInstead'
    'submit form': 'onSubmitForm'
    'keyup #name': 'onNameChange'
    'click #gplus-login-btn': 'onClickGPlusLoginButton'
    'click #facebook-login-btn': 'onClickFacebookLoginButton'
    'click #close-modal': 'hide'


  # Initialization
    
  initialize: (options={}) ->
    @previousFormInputs = options.initialValues or {}
    @previousFormInputs.emailOrUsername ?= @previousFormInputs.email or @previousFormInputs.username

    # TODO: Switch to promises and state, rather than using defer to hackily enable buttons after render
    application.gplusHandler.loadAPI({ success: => _.defer => @$('#gplus-login-btn').attr('disabled', false) })
    application.facebookHandler.loadAPI({ success: => _.defer => @$('#facebook-login-btn').attr('disabled', false) })

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
    @$('#unknown-error-alert').addClass('hide')
    userObject = forms.formToObject @$el
    res = tv4.validateMultiple userObject, formSchema
    return forms.applyErrorsToForm(@$el, res.errors) unless res.valid
    new Promise(me.loginPasswordUser(userObject.emailOrUsername, userObject.password).then)
    .then(->
      if window.nextURL then window.location.href = window.nextURL else window.location.reload()
    )
    .catch((jqxhr) =>
      showingError = false
      if jqxhr.status is 401
        errorID = jqxhr.responseJSON.errorID
        if errorID is 'not-found'
          forms.setErrorToProperty(@$el, 'emailOrUsername', $.i18n.t('loading_error.not_found'))
          showingError = true
        if errorID is 'wrong-password'
          forms.setErrorToProperty(@$el, 'password', $.i18n.t('account_settings.wrong_password'))
          showingError = true
      
      if not showingError
        @$('#unknown-error-alert').removeClass('hide')
    )
      
  
  # Google Plus

  onClickGPlusLoginButton: ->
    btn = @$('#gplus-login-btn')
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

  onGPlusLoginError: =>
    btn = @$('#gplus-login-btn')
    btn.find('.sign-in-blurb').text($.i18n.t('login.sign_in_with_gplus'))
    btn.attr('disabled', false)
    errors.showNotyNetworkError(arguments...)
    
    
  # Facebook

  onClickFacebookLoginButton: ->
    btn = @$('#facebook-login-btn')
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
    
  onFacebookLoginError: =>
    btn = @$('#facebook-login-btn')
    btn.find('.sign-in-blurb').text($.i18n.t('login.sign_in_with_facebook'))
    btn.attr('disabled', false)
    errors.showNotyNetworkError(arguments...)


  onHidden: ->
    super()
    @playSound 'game-menu-close'

formSchema = {
  type: 'object'
  properties: {
    emailOrUsername: {
      $or: [
        User.schema.properties.name
        User.schema.properties.email
      ]
    }
    password: User.schema.properties.password
  }
  required: ['emailOrUsername', 'password']
}
