CocoView = require 'views/core/CocoView'
AuthModal = require 'views/core/AuthModal'
template = require 'templates/core/create-account-modal/basic-info-view'
forms = require 'core/forms'
errors = require 'core/errors'
User = require 'models/User'
State = require 'models/State'

###
This view handles the primary form for user details — name, email, password, etc,
and the AJAX that actually creates the user.

It also handles facebook/g+ login, which if used, open one of two other screens:
sso-already-exists: If the facebook/g+ connection is already associated with a user, they're given a log in button
sso-confirm: If this is a new facebook/g+ connection, ask for a username, then allow creation of a user

The sso-confirm view *inherits from this view* in order to share its account-creation logic and events.
This means the selectors used in these events must work in both templates.

This view currently uses the old form API instead of stateful render.
It needs some work to make error UX and rendering better, but is functional.
###

module.exports = class BasicInfoView extends CocoView
  id: 'basic-info-view'
  template: template

  events:
    'change input[name="email"]': 'onChangeEmail'
    'change input[name="name"]': 'onChangeName'
    'click .back-button': 'onClickBackButton'
    'submit form': 'onSubmitForm'
    'click .use-suggested-name-link': 'onClickUseSuggestedNameLink'
    'click #facebook-signup-btn': 'onClickSsoSignupButton'
    'click #gplus-signup-btn': 'onClickSsoSignupButton'

  initialize: ({ @signupState } = {}) ->
    @state = new State {
      suggestedNameText: '...'
      checkEmailState: 'standby' # 'checking', 'exists', 'available'
      checkEmailValue: null
      checkEmailPromise: null
      checkNameState: 'standby' # same
      checkNameValue: null
      checkNamePromise: null
      error: ''
    }
    @listenTo @state, 'change:checkEmailState', -> @renderSelectors('.email-check')
    @listenTo @state, 'change:checkNameState', -> @renderSelectors('.name-check')
    @listenTo @state, 'change:error', -> @renderSelectors('.error-area')
    @listenTo @signupState, 'change:facebookEnabled', -> @renderSelectors('.auth-network-logins')
    @listenTo @signupState, 'change:gplusEnabled', -> @renderSelectors('.auth-network-logins')
    
  afterRender: ->
    super()
    if suggestedName = @state.get('suggestedName')
      @setNameError(suggestedName)

  onChangeEmail: ->
    @checkEmail()
    
  checkEmail: ->
    email = @$('[name="email"]').val()
    if email is @state.get('lastEmailValue')
      return @state.get('checkEmailPromise')
      
    if not email
      @state.set({
        checkEmailState: 'standby'
        checkEmailValue: email
        checkEmailPromise: null
      })
      return
      
    @state.set({
      checkEmailState: 'checking'
      checkEmailValue: email
      
      checkEmailPromise: (User.checkEmailExists(email)
      .then ({exists}) =>
        return unless email is @$('[name="email"]').val()
        if exists
          @state.set('checkEmailState', 'exists')
        else
          @state.set('checkEmailState', 'available')
      .catch (e) =>
        @state.set('checkEmailState', 'standby')
        throw e
      )
    })
    return @state.get('checkEmailPromise')

  onChangeName: ->
    @checkName()

  checkName: ->
    name = @$('input[name="name"]').val()

    if name is @state.get('checkNameValue')
      return @state.get('checkNamePromise')

    if not name
      @state.set({
        checkNameState: 'standby'
        checkNameValue: name
        checkNamePromise: null
      })
      return

    @state.set({
      checkNameState: 'checking'
      checkNameValue: name

      checkNamePromise: (User.checkNameConflicts(name)
      .then ({ suggestedName, conflicts }) =>
        return unless name is @$('input[name="name"]').val()
        if conflicts
          suggestedNameText = $.i18n.t('signup.name_taken').replace('{{suggestedName}}', suggestedName)
          @state.set({ checkNameState: 'exists', suggestedNameText })
        else
          @state.set { checkNameState: 'available' }
      .catch (error) ->
        @state.set('checkNameState', 'standby')
        throw error
      )
    })

    return @state.get('checkNamePromise') 

  checkBasicInfo: (data) ->
    # TODO: Move this to somewhere appropriate
    tv4.addFormat({
      'email': (email) ->
        if forms.validateEmail(email)
          return null
        else
          return {code: tv4.errorCodes.FORMAT_CUSTOM, message: "Please enter a valid email address."}
    })
    
    forms.clearFormAlerts(@$el)
    res = tv4.validateMultiple data, @formSchema()
    forms.applyErrorsToForm(@$('form'), res.errors) unless res.valid
    return res.valid
  
  formSchema: ->
    type: 'object'
    properties:
      email: User.schema.properties.email
      name: User.schema.properties.name
      password: User.schema.properties.password
    required: ['email', 'name', 'password'].concat (if @signupState.get('path') is 'student' then ['firstName', 'lastName'] else [])
  
  onClickBackButton: -> @trigger 'nav-back'
  
  onClickUseSuggestedNameLink: (e) ->
    @$('input[name="name"]').val(@state.get('suggestedName'))
    forms.clearFormAlerts(@$el.find('input[name="name"]').closest('.form-group').parent())

  onSubmitForm: (e) ->
    @state.unset('error')
    e.preventDefault()
    data = forms.formToObject(e.currentTarget)
    valid = @checkBasicInfo(data)
    return unless valid

    @displayFormSubmitting()
    AbortError = new Error()
    
    @checkEmail()
    .then @checkName()
    .then =>
      if not (@state.get('checkEmailState') is 'available' and @state.get('checkNameState') is 'available')
        throw AbortError
        
      # update User
      emails = _.assign({}, me.get('emails'))
      emails.generalNews ?= {}
      emails.generalNews.enabled = @$('#subscribe-input').is(':checked')
      me.set('emails', emails)
      
      unless _.isNaN(@signupState.get('birthday').getTime())
        me.set('birthday', @signupState.get('birthday')?.toISOString())

      me.set(_.omit(@signupState.get('ssoAttrs') or {}, 'email', 'facebookID', 'gplusID'))
      me.set('name', @$('input[name="name"]').val())
      jqxhr = me.save()
      if not jqxhr
        console.error(me.validationError)
        throw new Error('Could not save user')

      return new Promise(jqxhr.then)
    
    .then =>
      # Use signup method
      window.tracker?.identify()
      switch @signupState.get('ssoUsed')
        when 'gplus'
          { email, gplusID } = @signupState.get('ssoAttrs')
          jqxhr = me.signupWithGPlus(email, gplusID)
        when 'facebook'
          { email, facebookID } = @signupState.get('ssoAttrs')
          jqxhr = me.signupWithFacebook(email, facebookID)
        else
          { email, password } = forms.formToObject(@$el)
          jqxhr = me.signupWithPassword(email, password)

      return new Promise(jqxhr.then)
      
    .then =>
      @finishSignup()
        
    .catch (e) =>
      @displayFormStandingBy()
      if e is AbortError
        return
      else
        console.error 'caught!', e
        @state.set('error', e.responseJSON?.message or 'Unknown Error')
      
  finishSignup: ->
    if @signupState.get('classCode')
      location.href = "/courses?_cc=#{@signupState.get('classCode')}"
    else
      window.location.reload()

  displayFormSubmitting: ->
    @$('#create-account-btn').text($.i18n.t('signup.creating')).attr('disabled', true)
    @$('input').attr('disabled', true)
    
  displayFormStandingBy: ->
    @$('#create-account-btn').text($.i18n.t('signup.create_account')).attr('disabled', false)
    @$('input').attr('disabled', false)

#  createUser: ->
#    options = {}
#    window.tracker?.identify()
#    # TODO: Move to User functions which call specific endpoints for signup
#    if @signupState.get('ssoUsed') is 'gplus'
#      @newUser.set('_id', me.id)
#      options.url = "/db/user?gplusID=#{@signupState.get('ssoAttrs').gplusID}&gplusAccessToken=#{application.gplusHandler.accessToken.access_token}"
#      options.type = 'PUT'
#    if @signupState.get('ssoUsed') is 'facebook'
#      @newUser.set('_id', me.id)
#      options.url = "/db/user?facebookID=#{@signupState.get('ssoAttrs').facebookID}&facebookAccessToken=#{application.facebookHandler.authResponse.accessToken}"
#      options.type = 'PUT'
#    @newUser.save(null, options)
#    @newUser.once 'sync', @onUserCreated, @
#    @newUser.once 'error', @onUserSaveError, @
#  
#  onUserSaveError: (user, jqxhr) ->
#    # TODO: Do we need to enable/disable the submit button to prevent multiple users being created?
#    # Seems to work okay without that, but mongo had 2 copies of the user... temporarily. Very strange.
#    if _.isObject(jqxhr.responseJSON) and jqxhr.responseJSON.property
#      forms.applyErrorsToForm(@$el, [jqxhr.responseJSON])
#      @setNameError(@state.get('suggestedName'))
#    else
#      console.log "Error:", jqxhr.responseText
#      errors.showNotyNetworkError(jqxhr)
#  
#  onUserCreated: ->
#    # TODO: Move to User functions
#    Backbone.Mediator.publish "auth:signed-up", {}
#    if @signupState.get('gplusAttrs')
#      window.tracker?.trackEvent 'Google Login', category: "Signup", label: 'GPlus'
#      window.tracker?.trackEvent 'Finished Signup', category: "Signup", label: 'GPlus'
#    else if @signupState.get('facebookAttrs')
#      window.tracker?.trackEvent 'Facebook Login', category: "Signup", label: 'Facebook'
#      window.tracker?.trackEvent 'Finished Signup', category: "Signup", label: 'Facebook'
#    else
#      window.tracker?.trackEvent 'Finished Signup', category: "Signup", label: 'CodeCombat'
#    if @signupState.get('classCode')
#      url = "/courses?_cc="+@signupState.get('classCode')
#      location.href = url
#    else
#      window.location.reload()

  onClickSsoSignupButton: (e) ->
    e.preventDefault()
    ssoUsed = $(e.currentTarget).data('sso-used')
    if ssoUsed is 'facebook'
      handler = application.facebookHandler
      fetchSsoUser = 'fetchFacebookUser'
      idName = 'facebookID'
    else
      handler = application.gplusHandler
      fetchSsoUser = 'fetchGPlusUser'
      idName = 'gplusID'
    handler.connect({
      context: @
      success: ->
        handler.loadPerson({
          context: @
          success: (ssoAttrs) ->
            @signupState.set { ssoAttrs }
            { email } = ssoAttrs
            User.checkEmailExists(email).then ({exists}) =>
              @signupState.set {
                ssoUsed
                email: ssoAttrs.email
              }
              if exists
                @trigger 'sso-connect:already-in-use'
              else
                @trigger 'sso-connect:new-user'
        })
    })
