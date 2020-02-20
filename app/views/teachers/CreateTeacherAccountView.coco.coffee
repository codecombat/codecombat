require('app/styles/teachers/teacher-trial-requests.sass')
RootView = require 'views/core/RootView'
forms = require 'core/forms'
TrialRequest = require 'models/TrialRequest'
TrialRequests = require 'collections/TrialRequests'
AuthModal = require 'views/core/AuthModal'
errors = require 'core/errors'
User = require 'models/User'
algolia = require 'core/services/algolia'
State = require 'models/State'
loadSegment = require('core/services/segment')


SIGNUP_REDIRECT = '/teachers/classes'
DISTRICT_NCES_KEYS = ['district', 'district_id', 'district_schools', 'district_students', 'phone']
SCHOOL_NCES_KEYS = DISTRICT_NCES_KEYS.concat(['id', 'name', 'students'])

module.exports = class CreateTeacherAccountView extends RootView
  id: 'create-teacher-account-view'
  template: require 'templates/teachers/create-teacher-account-view'

  events:
    'click .login-link': 'onClickLoginLink'
    'change form#signup-form': 'onChangeForm'
    'submit form#signup-form': 'onSubmitForm'
    'click #gplus-signup-btn': 'onClickGPlusSignupButton'
    'click #facebook-signup-btn': 'onClickFacebookSignupButton'
    'change input[name="city"]': 'invalidateNCES'
    'change input[name="state"]': 'invalidateNCES'
    'change input[name="district"]': 'invalidateNCES'
    'change input[name="country"]': 'invalidateNCES'
    'change input[name="email"]': 'onChangeEmail'
    'change input[name="name"]': 'onChangeName'

  initialize: ->
    @trialRequest = new TrialRequest()
    @trialRequests = new TrialRequests()
    @trialRequests.fetchOwn()
    @supermodel.trackCollection(@trialRequests)
    window.tracker?.trackEvent 'Teachers Create Account Loaded', category: 'Teachers', ['Mixpanel']
    @state = new State {
      suggestedNameText: '...'
      checkEmailState: 'standby' # 'checking', 'exists', 'available'
      checkEmailValue: null
      checkEmailPromise: null
      checkNameState: 'standby' # same
      checkNameValue: null
      checkNamePromise: null
      authModalInitialValues: {}
    }
    @listenTo @state, 'change:checkEmailState', -> @renderSelectors('.email-check')
    @listenTo @state, 'change:checkNameState', -> @renderSelectors('.name-check')
    @listenTo @state, 'change:error', -> @renderSelectors('.error-area')
    loadSegment() unless @segmentLoaded

  onLeaveMessage: ->
    if @formChanged
      return 'Your account has not been created! If you continue, your changes will be lost.'

  onLoaded: ->
    if @trialRequests.size()
      @trialRequest = @trialRequests.first()
      @state.set({
        authModalInitialValues: {
          email: @trialRequest?.get('properties')?.email
        }
      })
    super()

  invalidateNCES: ->
    for key in SCHOOL_NCES_KEYS
      @$('input[name="nces_' + key + '"]').val ''

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

    @$("#organization-control").algolia_autocomplete({hint: false}, [
      source: (query, callback) ->
        algolia.schoolsIndex.search(query, { hitsPerPage: 5, aroundLatLngViaIP: false }).then (answer) ->
          callback answer.hits
        , ->
          callback []
      displayKey: 'name',
      templates:
        suggestion: (suggestion) ->
          hr = suggestion._highlightResult
          "<div class='school'> #{hr.name.value} </div>" +
            "<div class='district'>#{hr.district.value}, " +
              "<span>#{hr.city?.value}, #{hr.state.value}</span></div>"
    ]).on 'autocomplete:selected', (event, suggestion, dataset) =>
      # Tell Algolioa about the change but don't open the suggestion dropdown
      @$('input[name="district"]').val(suggestion.district).trigger('input').trigger('blur')
      @$('input[name="city"]').val suggestion.city
      @$('input[name="state"]').val suggestion.state
      @$('input[name="country"]').val 'USA'
      for key in SCHOOL_NCES_KEYS
        @$('input[name="nces_' + key + '"]').val suggestion[key]
      @onChangeForm()

    @$("#district-control").algolia_autocomplete({hint: false}, [
      source: (query, callback) ->
        algolia.schoolsIndex.search(query, { hitsPerPage: 5, aroundLatLngViaIP: false }).then (answer) ->
          callback answer.hits
        , ->
          callback []
      displayKey: 'district',
      templates:
        suggestion: (suggestion) ->
          hr = suggestion._highlightResult
          "<div class='district'>#{hr.district.value}, " +
            "<span>#{hr.city?.value}, #{hr.state.value}</span></div>"
    ]).on 'autocomplete:selected', (event, suggestion, dataset) =>
      @$('input[name="organization"]').val('').trigger('input').trigger('blur')
      @$('input[name="city"]').val suggestion.city
      @$('input[name="state"]').val suggestion.state
      @$('input[name="country"]').val 'USA'
      for key in DISTRICT_NCES_KEYS
        @$('input[name="nces_' + key + '"]').val suggestion[key]
      @onChangeForm()

  onClickLoginLink: ->
    @openModalView(new AuthModal({ initialValues: @state.get('authModalInitialValues') }))

  onChangeForm: ->
    unless @formChanged
      window.tracker?.trackEvent 'Teachers Create Account Form Started', category: 'Teachers', ['Mixpanel']
    @formChanged = true

  onSubmitForm: (e) ->
    e.preventDefault()

    # Creating Trial Request first, validate user attributes but do not use them
    form = @$('form')
    allAttrs = forms.formToObject(form)
    trialRequestAttrs = _.omit(allAttrs, 'name', 'password1', 'password2')

    # Don't save n/a district entries, but do validate required district client-side
    trialRequestAttrs = _.omit(trialRequestAttrs, 'district') if trialRequestAttrs.district?.replace(/\s/ig, '').match(/n\/a/ig)

    if @$('#other-education-level-checkbox').is(':checked')
      val = @$('#other-education-level-input').val()
      trialRequestAttrs.educationLevel.push(val) if val

    forms.clearFormAlerts(form)
    tv4.addFormat({
      'phoneNumber': (phoneNumber) ->
        if forms.validatePhoneNumber(phoneNumber)
          return null
        else
          return {code: tv4.errorCodes.FORMAT_CUSTOM, message: 'Please enter a valid phone number, including area code.'}
    })

    result = tv4.validateMultiple(trialRequestAttrs, formSchema)
    error = false
    if not result.valid
      forms.applyErrorsToForm(form, result.errors)
      error = true
    if not error and not forms.validateEmail(trialRequestAttrs.email)
      forms.setErrorToProperty(form, 'email', 'invalid email')
      error = true
    if not error and forms.validateEmail(allAttrs.name)
      forms.setErrorToProperty(form, 'name', 'username may not be an email')
      error = true
    if not _.size(trialRequestAttrs.educationLevel)
      forms.setErrorToProperty(form, 'educationLevel', 'include at least one')
      error = true
    if not allAttrs.name
      forms.setErrorToProperty(form, 'name', $.i18n.t('common.required_field'))
      error = true
    unless allAttrs.district
      forms.setErrorToProperty(form, 'district', $.i18n.t('common.required_field'))
      error = true
    unless @gplusAttrs or @facebookAttrs
      if not allAttrs.password1
        forms.setErrorToProperty(form, 'password1', $.i18n.t('common.required_field'))
        error = true
      else if not allAttrs.password2
        forms.setErrorToProperty(form, 'password2', $.i18n.t('common.required_field'))
        error = true
      else if allAttrs.password1 isnt allAttrs.password2
        forms.setErrorToProperty(form, 'password1', 'Password fields are not equivalent')
        error = true
    if error
      forms.scrollToFirstError()
      return
    trialRequestAttrs['siteOrigin'] = 'create teacher'
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

  onTrialRequestSubmit: ->
    window.tracker?.trackEvent 'Teachers Create Account Submitted', category: 'Teachers', ['Mixpanel']
    @formChanged = false
    
    Promise.resolve()
    .then =>
      attrs = _.pick(forms.formToObject(@$('form')), 'role', 'firstName', 'lastName')
      attrs.role = attrs.role.toLowerCase()
      me.set(attrs)
      me.set(_.omit(@gplusAttrs, 'gplusID', 'email')) if @gplusAttrs
      me.set(_.omit(@facebookAttrs, 'facebookID', 'email')) if @facebookAttrs
      if me.inEU()
        emails = _.assign({}, me.get('emails'))
        emails.generalNews ?= {}
        emails.generalNews.enabled = false
        me.set('emails', emails)
        me.set('unsubscribedFromMarketingEmails', true)
      jqxhr = me.save()
      if not jqxhr
        throw new Error('Could not save user')
      @trigger 'update-settings'
      return jqxhr
      
    .then =>
      { name, email } = forms.formToObject(@$('form'))
      if @gplusAttrs
        { email, gplusID } = @gplusAttrs
        { name } = forms.formToObject(@$el)
        jqxhr = me.signupWithGPlus(name, email, @gplusAttrs.gplusID)
      else if @facebookAttrs
        { email, facebookID } = @facebookAttrs
        { name } = forms.formToObject(@$el)
        jqxhr = me.signupWithFacebook(name, email, facebookID)
      else
        { name, email, password1 } = forms.formToObject(@$el)
        jqxhr = me.signupWithPassword(name, email, password1)
      @trigger 'signup'
      return jqxhr

    .then =>
      trialRequestIntercomData = _.pick @trialRequest.attributes.properties, ["siteOrigin", "marketingReferrer", "referrer", "notes", "numStudentsTotal", "numStudents", "purchaserRole", "role", "phoneNumber", "country", "state", "city", "district", "organization", "nces_students", "nces_name", "nces_id", "nces_phone", "nces_district_students", "nces_district_schools", "nces_district_id", "nces_district"]
      trialRequestIntercomData.educationLevel_elementary = _.contains @trialRequest.attributes.properties.educationLevel, "Elementary"
      trialRequestIntercomData.educationLevel_middle = _.contains @trialRequest.attributes.properties.educationLevel, "Middle"
      trialRequestIntercomData.educationLevel_high = _.contains @trialRequest.attributes.properties.educationLevel, "High"
      trialRequestIntercomData.educationLevel_college = _.contains @trialRequest.attributes.properties.educationLevel, "College+"
      application.tracker.updateTrialRequestData trialRequestIntercomData
      
    .then =>
      application.router.navigate(SIGNUP_REDIRECT, { trigger: true })
      application.router.reload()
      
    .then =>
      @trigger 'on-trial-request-submit-complete'



    .catch (e) =>
      if e instanceof Error
        noty {
          text: e.message
          layout: 'topCenter'
          type: 'error'
          timeout: 5000
          killer: false,
          dismissQueue: true
        }
      else
        errors.showNotyNetworkError(arguments...)
      @$('#create-account-btn').text('Submit').attr('disabled', false)
    

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
                        application.router.navigate('/teachers/update-account', {trigger: true})
                      error: errors.showNotyNetworkError
                    })
                })
            })
        })
    })

  onGPlusConnected: ->
    @formChanged = true
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
                        application.router.navigate('/teachers/update-account', {trigger: true})
                      error: errors.showNotyNetworkError
                    })
                })
            })
        })
    })

  onFacebookConnected: ->
    @formChanged = true
    forms.objectToForm(@$('form'), @facebookAttrs)
    for field in ['email', 'firstName', 'lastName']
      input = @$("input[name='#{field}']")
      if input.val()
        input.attr('disabled', true)
    @$('input[type="password"]').attr('disabled', true)
    @$('#facebook-logged-in-row, #social-network-signups').toggleClass('hide')

  updateAuthModalInitialValues: (values) ->
    @state.set {
      authModalInitialValues: _.merge @state.get('authModalInitialValues'), values
    }, { silent: true }

  onChangeName: (e) ->
    @updateAuthModalInitialValues { name: @$(e.currentTarget).val() }
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
      return Promise.resolve()

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
      .catch (error) =>
        @state.set('checkNameState', 'standby')
        throw error
      )
    })

    return @state.get('checkNamePromise')

  onChangeEmail: (e) ->
    @updateAuthModalInitialValues { email: @$(e.currentTarget).val() }
    @checkEmail()
    
  checkEmail: ->
    email = @$('[name="email"]').val()
    
    if not _.isEmpty(email) and email is @state.get('checkEmailValue')
      return @state.get('checkEmailPromise')

    if not (email and forms.validateEmail(email))
      @state.set({
        checkEmailState: 'standby'
        checkEmailValue: email
        checkEmailPromise: null
      })
      return Promise.resolve()
      
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
    

formSchema = {
  type: 'object'
  required: ['firstName', 'lastName', 'email', 'role', 'numStudents', 'numStudentsTotal', 'city', 'state', 'country']
  properties:
    password1: { type: 'string' }
    password2: { type: 'string' }
    firstName: { type: 'string' }
    lastName: { type: 'string' }
    name: { type: 'string', minLength: 1 }
    email: { type: 'string', format: 'email' }
    phoneNumber: { type: 'string', format: 'phoneNumber' }
    role: { type: 'string' }
    organization: { type: 'string' }
    district: { type: 'string' }
    city: { type: 'string' }
    state: { type: 'string' }
    country: { type: 'string' }
    numStudents: { type: 'string' }
    numStudentsTotal: { type: 'string' }
    educationLevel: {
      type: 'array'
      items: { type: 'string' }
    }
    notes: { type: 'string' }
}

for key in SCHOOL_NCES_KEYS
  formSchema['nces_' + key] = type: 'string'
