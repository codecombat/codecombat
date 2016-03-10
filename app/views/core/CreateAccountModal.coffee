ModalView = require 'views/core/ModalView'
template = require 'templates/core/create-account-modal'
{loginUser, createUser, me} = require 'core/auth'
forms = require 'core/forms'
User = require 'models/User'
application  = require 'core/application'
Classroom = require 'models/Classroom'
errors = require 'core/errors'

# TODO: Avoid using G+ render buttons to login, login directly instead.
# Form object is split in two in template to avoid having rendered buttons triggered on form submit.

module.exports = class CreateAccountModal extends ModalView
  id: 'create-account-modal'
  template: template

  events:
    'submit form': 'onSubmitForm'
    'keyup #name': 'onNameChange'
    'click #gplus-signup-btn': 'onClickGPlusSignupButton'
    'click #gplus-login-btn': 'onClickGPlusLoginButton'
    'click #facebook-signup-btn': 'onClickFacebookSignupButton'
    'click #facebook-login-btn': 'onClickFacebookLoginButton'
    'click #close-modal': 'hide'
    'click #switch-to-login-btn': 'onClickSwitchToLoginButton'
    
  subscriptions:
    'auth:facebook-api-loaded': 'onFacebookAPILoaded'
    
    
  # Initialization

  initialize: (options={}) ->
    @onNameChange = _.debounce(_.bind(@checkNameExists, @), 500)
    @previousFormInputs = options.initialValues or {}
    @listenTo application.gplusHandler, 'logged-into-google', @onGPlusHandlerLoggedIntoGoogle
    @listenTo application.gplusHandler, 'person-loaded', @onGPlusPersonLoaded
    @listenTo application.gplusHandler, 'render-login-buttons', @onGPlusRenderLoginButtons
    @listenTo application.facebookHandler, 'logged-into-facebook', @onFacebookHandlerLoggedIntoFacebook
    @listenTo application.facebookHandler, 'person-loaded', @onFacebookPersonLoaded

  afterRender: ->
    super()
    @playSound 'game-menu-open'
    @$('#facebook-signup-btn').attr('disabled', true) if not window.FB?

  afterInsert: ->
    super()
    _.delay (-> application.router.renderLoginButtons()), 500
    _.delay (=> $('input:visible:first', @$el).focus()), 500

  onGPlusRenderLoginButtons: ->
    @$('#gplus-signup-btn').attr('disabled', false)

  onFacebookAPILoaded: ->
    @$('#facebook-signup-btn').attr('disabled', false)

    
  # User creation

  onSubmitForm: (e) ->
    e.preventDefault()
    @playSound 'menu-button-click'

    forms.clearFormAlerts(@$el)
    attrs = forms.formToObject @$el
    attrs.name = @suggestedName if @suggestedName
    _.defaults attrs, me.pick([
      'preferredLanguage', 'testGroupNumber', 'dateCreated', 'wizardColor1',
      'name', 'music', 'volume', 'emails', 'schoolName'
    ])
    attrs.emails ?= {}
    attrs.emails.generalNews ?= {}
    attrs.emails.generalNews.enabled = @$el.find('#subscribe').prop('checked')
    @classCode = attrs.classCode
    delete attrs.classCode
    _.assign attrs, @gplusAttrs if @gplusAttrs
    _.assign attrs, @facebookAttrs if @facebookAttrs
    res = tv4.validateMultiple attrs, User.schema
    error = false
    if not res.valid
      forms.applyErrorsToForm(@$el, res.errors)
      error = true
    if not _.any([attrs.password, @gplusAttrs, @facebookAttrs])
      forms.setErrorToProperty @$el, 'password', 'Required'
      error = true
    if not forms.validateEmail(attrs.email)
      forms.setErrorToProperty @$el, 'email', 'Please enter a valid email address'
      error = true
    return if error
    
    @$('#signup-button').text($.i18n.t('signup.creating')).attr('disabled', true)
    @newUser = new User(attrs)
    if @classCode
      @signupClassroomPrecheck()
    else
      @createUser()

  signupClassroomPrecheck: ->
    classroom = new Classroom()
    classroom.fetch({ data: { code: @classCode } })
    classroom.once 'sync', @createUser, @
    classroom.once 'error', @onClassroomFetchError, @

  onClassroomFetchError: ->
    @$('#signup-button').text($.i18n.t('signup.sign_up')).attr('disabled', false)
    forms.setErrorToProperty(@$el, 'classCode', "#{@classCode} is not a valid code. Please verify the code is typed correctly.")
    @$('#class-code-input').val('')
      
  createUser: ->
    options = {}
    window.tracker?.identify()
    if @gplusAttrs
      @newUser.set('_id', me.id)
      options.url = "/db/user?gplusID=#{@gplusAttrs.gplusID}&gplusAccessToken=#{application.gplusHandler.accessToken.access_token}"
      options.type = 'PUT'
    if @facebookAttrs
      @newUser.set('_id', me.id)
      options.url = "/db/user?facebookID=#{@facebookAttrs.facebookID}&facebookAccessToken=#{application.facebookHandler.authResponse.accessToken}"
      options.type = 'PUT'
    @newUser.save(null, options)
    @newUser.once 'sync', @onUserCreated, @
    @newUser.once 'error', @onUserSaveError, @

  onUserSaveError: (user, jqxhr) ->
    @$('#signup-button').text($.i18n.t('signup.sign_up')).attr('disabled', false)
    if _.isObject(jqxhr.responseJSON) and jqxhr.responseJSON.property
      error = jqxhr.responseJSON
      if jqxhr.status is 409 and error.property is 'name'
        @newUser.unset 'name'
        return @createUser()
      return forms.applyErrorsToForm(@$el, [jqxhr.responseJSON])
    errors.showNotyNetworkError(jqxhr)

  onUserCreated: ->
    Backbone.Mediator.publish "auth:signed-up", {}
    if @gplusAttrs
      window.tracker?.trackEvent 'Google Login', category: "Signup", label: 'GPlus'
      window.tracker?.trackEvent 'Finished Signup', category: "Signup", label: 'GPlus'
    else if @facebookAttrs
      window.tracker?.trackEvent 'Facebook Login', category: "Signup", label: 'Facebook'
      window.tracker?.trackEvent 'Finished Signup', category: "Signup", label: 'Facebook'
    else
      window.tracker?.trackEvent 'Finished Signup', category: "Signup", label: 'CodeCombat'
    if @classCode
      url = "/courses?_cc="+@classCode
      application.router.navigate(url)
    window.location.reload()
    
  
  # Google Plus

  onClickGPlusSignupButton: ->
    @clickedGPlusLogin = true

  onGPlusHandlerLoggedIntoGoogle: ->
    return unless @clickedGPlusLogin
    application.gplusHandler.loadPerson()
    btn = @$('#gplus-signup-btn')
    btn.find('.sign-in-blurb').text($.i18n.t('signup.creating'))
    btn.attr('disabled', true)

  onGPlusPersonLoaded: (@gplusAttrs) ->
    existingUser = new User()
    existingUser.fetchGPlusUser(@gplusAttrs.gplusID, {
      context: @
      complete: ->
        @$('#email-password-row').remove()
      success: =>
        @$('#gplus-account-exists-row').removeClass('hide')
      error: (user, jqxhr) =>
        if jqxhr.status is 404
          @$('#gplus-logged-in-row').toggleClass('hide')
        else
          errors.showNotyNetworkError(jqxhr)
    })

  onClickGPlusLoginButton: ->
    me.loginGPlusUser(@gplusAttrs.gplusID, {
      context: @
      success: -> window.location.reload()
      error: ->
        @$('#gplus-login-btn').text($.i18n.t('login.log_in')).attr('disabled', false)
        errors.showNotyNetworkError(arguments...)
    })
    @$('#gplus-login-btn').text($.i18n.t('login.logging_in')).attr('disabled', true)


    
  # Facebook

  onClickFacebookSignupButton: ->
    @clickedFacebookLogin = true
    if application.facebookHandler.loggedIn
      @onFacebookHandlerLoggedIntoFacebook()
    else
      application.facebookHandler.loginThroughFacebook()

  onFacebookHandlerLoggedIntoFacebook: ->
    return unless @clickedFacebookLogin
    application.facebookHandler.loadPerson()
    btn = @$('#facebook-signup-btn')
    btn.find('.sign-in-blurb').text($.i18n.t('signup.creating'))
    btn.attr('disabled', true)
    
  onFacebookPersonLoaded: (@facebookAttrs) ->
    existingUser = new User()
    existingUser.fetchFacebookUser(@facebookAttrs.facebookID, {
      success: =>
        @$('#email-password-row').remove()
        @$('#facebook-account-exists-row').removeClass('hide')
      error: (model, jqxhr) =>
        @$('#email-password-row').remove()
        if jqxhr.status is 404
          @$('#facebook-logged-in-row').toggleClass('hide')
        else
          errors.showNotyNetworkError(jqxhr)
    })

  onClickFacebookLoginButton: ->
    me.loginFacebookUser(@facebookAttrs.facebookID, {
      context: @
      success: -> window.location.reload()
      error: =>
        @$('#facebook-login-btn').text($.i18n.t('login.log_in')).attr('disabled', false)
        errors.showNotyNetworkError(jqxhr)
    })
    @$('#facebook-login-btn').text($.i18n.t('login.logging_in')).attr('disabled', true)

  
  # Misc
  
  onHidden: ->
    super()
    @playSound 'game-menu-close'

  checkNameExists: ->
    name = $('#name', @$el).val()
    return forms.clearFormAlerts(@$el) if name is ''
    User.getUnconflictedName name, (newName) =>
      forms.clearFormAlerts(@$el)
      if name is newName
        @suggestedName = undefined
      else
        @suggestedName = newName
        forms.setErrorToProperty @$el, 'name', "That name is taken! How about #{newName}?"

  onClickSwitchToLoginButton: ->
    AuthModal = require('./AuthModal')
    modal = new AuthModal({initialValues: forms.formToObject @$el})
    currentView.openModalView(modal)
