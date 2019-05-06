require('app/styles/modal/auth-modal.sass')
ModalView = require 'views/core/ModalView'
template = require 'templates/core/auth-modal'
forms = require 'core/forms'
User = require 'models/User'
errors = require 'core/errors'
RecoverModal = require 'views/core/RecoverModal'
storage = require 'core/storage'

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
    'click [data-toggle="coco-modal"][data-target="core/RecoverModal"]': 'openRecoverModal'

  # Initialization

  initialize: (options={}) ->
    @previousFormInputs = options.initialValues or {}
    @previousFormInputs.emailOrUsername ?= @previousFormInputs.email or @previousFormInputs.username

    if me.useSocialSignOn()
      # TODO: Switch to promises and state, rather than using defer to hackily enable buttons after render
      application.gplusHandler.loadAPI({ success: => _.defer => @$('#gplus-login-btn').attr('disabled', false) })
      application.facebookHandler.loadAPI({ success: => _.defer => @$('#facebook-login-btn').attr('disabled', false) })
    @subModalContinue = options.subModalContinue

  afterRender: ->
    super()
    @playSound 'game-menu-open'

  afterInsert: ->
    super()
    _.delay (=> $('input:visible:first', @$el).focus()), 500

  onSignupInstead: (e) ->
    CreateAccountModal = require('./CreateAccountModal')
    modal = new CreateAccountModal({initialValues: forms.formToObject @$el, @subModalContinue})
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
    .then(=>
      if window.nextURL then window.location.href = window.nextURL else loginNavigate(@subModalContinue)
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
                  success: => loginNavigate(@subModalContinue)
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
                  success: => loginNavigate(@subModalContinue)
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

  openRecoverModal: (e) ->
    e.stopPropagation()
    @openModalView new RecoverModal()

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

loginNavigate = (subModalContinue) ->
  if not me.isAdmin()
    if me.isStudent()
      application.router.navigate('/students', { trigger: true })
    else if me.isTeacher()
      if me.isSchoolAdmin()
        application.router.navigate('/school-administrator', { trigger: true })
      else
        application.router.navigate('/teachers/classes', { trigger: true })
  else if subModalContinue
    storage.save('sub-modal-continue', subModalContinue)

  window.location.reload()
