RootView = require 'views/core/RootView'
forms = require 'core/forms'
TrialRequest = require 'models/TrialRequest'
TrialRequests = require 'collections/TrialRequests'
AuthModal = require 'views/core/AuthModal'
storage = require 'core/storage'
errors = require 'core/errors'
User = require 'models/User'

FORM_KEY = 'request-quote-form'
SIGNUP_REDIRECT = '/courses/teachers'

module.exports = class CreateTeacherAccountView extends RootView
  id: 'create-teacher-account-view'
  template: require 'templates/teachers/create-teacher-account-view'

  events:
    'click .login-link': 'onClickLoginLink'
    'change form': 'onChangeForm'
    'submit form': 'onSubmitForm'
    'click #gplus-signup-btn': 'onClickGPlusSignupButton'
    'click #facebook-signup-btn': 'onClickFacebookSignupButton'

  initialize: ->
    @trialRequest = new TrialRequest()
    @trialRequests = new TrialRequests()
    @trialRequests.fetchOwn()
    @supermodel.trackCollection(@trialRequests)

  onLoaded: ->
    if @trialRequests.size()
      @trialRequest = @trialRequests.first()
    if @trialRequest and @trialRequest.get('status') isnt 'submitted' and @trialRequest.get('status') isnt 'approved'
      window.tracker?.trackEvent 'View Trial Request', category: 'Teachers', label: 'View Trial Request', ['Mixpanel']
    super()
    
  afterRender: ->
    super()
    
    # apply existing trial request on form
    properties = @trialRequest.get('properties')
    if properties
      forms.objectToForm(@$('form'), properties)
      commonLevels = _.map @$('[name="educationLevel"]'), (el) -> $(el).val()
      submittedLevels = properties.educationLevel or []
      otherLevel = _.first(_.difference(submittedLevels, commonLevels)) or ''
      @$('#other-education-level-checkbox').attr('checked', !!otherLevel)
      @$('#other-education-level-input').val(otherLevel)
      
    # apply changes from local storage
    obj = storage.load(FORM_KEY)
    if obj
      @$('#other-education-level-checkbox').attr('checked', obj.otherChecked)
      @$('#other-education-level-input').val(obj.otherInput)
      forms.objectToForm(@$('form'), obj, { overwriteExisting: true })

  onClickLoginLink: ->
    modal = new AuthModal({ initialValues: { email: @trialRequest.get('properties')?.email } })
    @openModalView(modal)

  onChangeRequestForm: ->
    # Local storage is being used to store the contents of the form whenever it changes, 
    # and filling in the stored values if the page is reloaded or navigated away from and returned to.
    # save changes to local storage
    obj = forms.formToObject(@$('form'))
    obj.otherChecked = @$('#other-education-level-checkbox').is(':checked')
    obj.otherInput = @$('#other-education-level-input').val()
    storage.save(FORM_KEY, obj, 10)

  onSubmitForm: (e) ->
    e.preventDefault()
    
    # Creating Trial Request first, validate user attributes but do not use them
    form = @$('form')
    allAttrs = forms.formToObject(form)
    trialRequestAttrs = _.omit(allAttrs, 'name', 'password1', 'password2')
    
    if @$('#other-education-level-checkbox').is(':checked')
      val = @$('#other-education-level-input').val()
      trialRequestAttrs.educationLevel.push(val) if val
      
    forms.clearFormAlerts(form)
    
    result = tv4.validateMultiple(trialRequestAttrs, formSchema)
    error = false
    if not result.valid
      forms.applyErrorsToForm(form, result.errors)
      error = true
    if not forms.validateEmail(trialRequestAttrs.email)
      forms.setErrorToProperty(form, 'email', 'Invalid email.')
      error = true
    if not _.size(trialRequestAttrs.educationLevel)
      forms.setErrorToProperty(form, 'educationLevel', 'Include at least one.')
      error = true
    unless @gplusAttrs or @facebookAttrs
      if not allAttrs.password1
        forms.setErrorToProperty(form, 'password1', 'Required field')
        error = true
      else if not allAttrs.password2
        forms.setErrorToProperty(form, 'password2', 'Required field')
        error = true
      else if allAttrs.password1 isnt allAttrs.password2
        forms.setErrorToProperty(form, 'password1', 'Password fields are not equivalent')
        error = true
    if error
      forms.scrollToFirstError()
      return
    @trialRequest = new TrialRequest({
      type: 'course'
      properties: trialRequestAttrs
    })
    @trialRequest.notyErrors = false
    @$('#create-account-btn').text('Sending').attr('disabled', true)
    @trialRequest.save()
    @trialRequest.on 'sync', @onTrialRequestSubmit, @
    @trialRequest.on 'error', @onTrialRequestError, @

  onTrialRequestError: (model, jqxhr) ->
    @$('#create-account-btn').text('Submit').attr('disabled', false)
    if jqxhr.status is 409
      userExists = $.i18n.t('teachers_quote.email_exists')
      logIn = $.i18n.t('login.log_in')
      @$('#email-form-group')
        .addClass('has-error')
        .append($("<div class='help-block error-help-block'>#{userExists} <a class='login-link'>#{logIn}</a>"))
      forms.scrollToFirstError()
    else 
      errors.showNotyNetworkError(arguments...)

  onClickEmailExistsLoginLink: ->
    modal = new AuthModal({ initialValues: { email: @trialRequest.get('properties')?.email } })
    @openModalView(modal)

  onTrialRequestSubmit: ->
    storage.remove(FORM_KEY)
    attrs = _.pick(forms.formToObject(@$('form')), 'name', 'email', 'role')
    options = {}
    newUser = new User(attrs)
    if @gplusAttrs
      newUser.set('_id', me.id)
      options.url = "/db/user?gplusID=#{@gplusAttrs.gplusID}&gplusAccessToken=#{application.gplusHandler.accessToken.access_token}"
      options.type = 'PUT'
      newUser.set(@gplusAttrs)
    else if @facebookAttrs
      newUser.set('_id', me.id)
      options.url = "/db/user?facebookID=#{@facebookAttrs.facebookID}&facebookAccessToken=#{application.facebookHandler.authResponse.accessToken}"
      options.type = 'PUT'
      newUser.set(@facebookAttrs)
    else
      newUser.set('password', @$('input[name="password1"]').val())
    newUser.save(null, options)
    newUser.once 'sync', ->
      application.router.navigate(SIGNUP_REDIRECT, { trigger: true })
      application.router.reload()
    newUser.once 'error', errors.showNotyNetworkError

  # GPlus signup

  onClickGPlusSignupButton: ->
    btn = @$('#gplus-signup-btn')
    btn.attr('disabled', true)
    application.gplusHandler.loadAPI({
      success: =>
        btn.attr('disabled', false)
        application.gplusHandler.connect({
          success: =>
            btn.find('.sign-in-blurb').text($.i18n.t('signup.creating'))
            btn.attr('disabled', true)
            application.gplusHandler.loadPerson({
              success: (@gplusAttrs) =>
                existingUser = new User()
                existingUser.fetchGPlusUser(@gplusAttrs.gplusID, {
                  error: (user, jqxhr) =>
                    if jqxhr.status is 404
                      @onGPlusConnected()
                    else
                      errors.showNotyNetworkError(jqxhr)
                  success: =>
                    me.loginGPlusUser(@gplusAttrs.gplusID, {
                      success: ->
                        application.router.navigate('/teachers/convert')
                      error: errors.showNotyNetworkError
                    })
                })
            })
        })
    })

  onGPlusConnected: ->
    forms.objectToForm(@$('form'), @gplusAttrs)
    for field in ['email', 'firstName', 'lastName']
      input = @$("input[name='#{field}']")
      if input.val()
        input.attr('disabled', true)
    @$('input[type="password"]').attr('disabled', true)
    @$('#gplus-logged-in-row, #social-network-signups').toggleClass('hide')

  
  # Facebook signup

  onClickFacebookSignupButton: ->
    btn = @$('#facebook-signup-btn')
    btn.attr('disabled', true)
    application.facebookHandler.loadAPI({
      success: =>
        btn.attr('disabled', false)
        application.facebookHandler.connect({
          success: =>
            btn.find('.sign-in-blurb').text($.i18n.t('signup.creating'))
            btn.attr('disabled', true)
            application.facebookHandler.loadPerson({
              success: (@facebookAttrs) =>
                existingUser = new User()
                existingUser.fetchFacebookUser(@facebookAttrs.facebookID, {
                  error: (user, jqxhr) =>
                    if jqxhr.status is 404
                      @onFacebookConnected()
                    else
                      errors.showNotyNetworkError(jqxhr)
                  success: =>
                    me.loginFacebookUser(@facebookAttrs.facebookID, {
                      success: ->
                        application.router.navigate('/teachers/convert')
                      error: errors.showNotyNetworkError
                    })
                })
            })
        })
    })

  onFacebookConnected: ->
    forms.objectToForm(@$('form'), @facebookAttrs)
    for field in ['email', 'firstName', 'lastName']
      input = @$("input[name='#{field}']")
      if input.val()
        input.attr('disabled', true)
    @$('input[type="password"]').attr('disabled', true)
    @$('#facebook-logged-in-row, #social-network-signups').toggleClass('hide')



formSchema = {
  type: 'object'
  required: ['firstName', 'lastName', 'email', 'organization', 'role', 'numStudents']
  properties:
    password1: { type: 'string' }
    password2: { type: 'string' }
    firstName: { type: 'string' }
    lastName: { type: 'string' }
    name: { type: 'string', minLength: 1 }
    email: { type: 'string', format: 'email' }
    phoneNumber: { type: 'string' }
    role: { type: 'string' }
    organization: { type: 'string' }
    city: { type: 'string' }
    state: { type: 'string' }
    country: { type: 'string' }
    numStudents: { type: 'string' }
    educationLevel: {
      type: 'array'
      items: { type: 'string' }
    }
    notes: { type: 'string' }
}
