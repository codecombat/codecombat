require('app/styles/teachers/teacher-trial-requests.sass')
RootView = require 'views/core/RootView'
forms = require 'core/forms'
TrialRequest = require 'models/TrialRequest'
TrialRequests = require 'collections/TrialRequests'
AuthModal = require 'views/core/AuthModal'
errors = require 'core/errors'
ConfirmModal = require 'views/core/ConfirmModal'
User = require 'models/User'
algolia = require 'core/services/algolia'
State = require 'models/State'
parseFullName = require('parse-full-name').parseFullName

SIGNUP_REDIRECT = '/teachers'
DISTRICT_NCES_KEYS = ['district', 'district_id', 'district_schools', 'district_students', 'phone']
SCHOOL_NCES_KEYS = DISTRICT_NCES_KEYS.concat(['id', 'name', 'students'])

module.exports = class RequestQuoteView extends RootView
  id: 'request-quote-view'
  template: require 'templates/teachers/request-quote-view'
  logoutRedirectURL: null

  events:
    'change #request-form': 'onChangeRequestForm'
    'submit #request-form': 'onSubmitRequestForm'
    'change input[name="city"]': 'invalidateNCES'
    'change input[name="state"]': 'invalidateNCES'
    'change input[name="district"]': 'invalidateNCES'
    'change input[name="country"]': 'invalidateNCES'
    'click #email-exists-login-link': 'onClickEmailExistsLoginLink'
    'submit #signup-form': 'onSubmitSignupForm'
    'click #logout-link': -> me.logout()
    'click #gplus-signup-btn': 'onClickGPlusSignupButton'
    'click #facebook-signup-btn': 'onClickFacebookSignupButton'
    'change input[name="email"]': 'onChangeEmail'
    'change input[name="name"]': 'onChangeName'
    'click #submit-request-btn': 'onClickRequestButton'

  getTitle: -> $.i18n.t('new_home.request_quote')

  initialize: ->
    @trialRequest = new TrialRequest()
    @trialRequests = new TrialRequests()
    @trialRequests.fetchOwn()
    @supermodel.trackCollection(@trialRequests)
    @formChanged = false
    window.tracker?.trackEvent 'Teachers Request Demo Loaded', category: 'Teachers', ['Mixpanel']
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

  onLeaveMessage: ->
    if @formChanged
      return 'Your request has not been submitted! If you continue, your changes will be lost.'

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
      forms.objectToForm(@$('#request-form'), properties)

    $("#organization-control").algolia_autocomplete({hint: false}, [
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
      @$('input[name="district"]').val suggestion.district
      @$('input[name="city"]').val suggestion.city
      @$('input[name="state"]').val suggestion.state
      @$('input[name="country"]').val 'USA'
      for key in SCHOOL_NCES_KEYS
        @$('input[name="nces_' + key + '"]').val suggestion[key]
      @onChangeRequestForm()

    $("#district-control").algolia_autocomplete({hint: false}, [
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
      @$('input[name="organization"]').val '' # TODO: does not persist on tabbing: back to school, back to district
      @$('input[name="city"]').val suggestion.city
      @$('input[name="state"]').val suggestion.state
      @$('input[name="country"]').val 'USA'
      for key in DISTRICT_NCES_KEYS
        @$('input[name="nces_' + key + '"]').val suggestion[key]
      @onChangeRequestForm()

  onChangeRequestForm: ->
    unless @formChanged
      window.tracker?.trackEvent 'Teachers Request Demo Form Started', category: 'Teachers', ['Mixpanel']
    @formChanged = true

  onClickRequestButton: (e) ->
    eventAction = $(e.target).data('event-action')
    if eventAction
      window.tracker?.trackEvent(eventAction, category: 'Teachers')

  onSubmitRequestForm: (e) ->
    e.preventDefault()
    form = @$('#request-form')
    attrs = forms.formToObject(form)
    trialRequestAttrs = _.cloneDeep(attrs)

    # Don't save n/a district entries, but do validate required district client-side
    trialRequestAttrs = _.omit(trialRequestAttrs, 'district') if trialRequestAttrs.district?.replace(/\s/ig, '').match(/n\/a/ig)

    forms.clearFormAlerts(form)
    requestFormSchema = if me.isAnonymous() then requestFormSchemaAnonymous else requestFormSchemaLoggedIn
    result = tv4.validateMultiple(trialRequestAttrs, requestFormSchemaAnonymous)
    error = false
    if not result.valid
      forms.applyErrorsToForm(form, result.errors)
      error = true
    if not error and not forms.validateEmail(trialRequestAttrs.email)
      forms.setErrorToProperty(form, 'email', 'invalid email')
      error = true

    unless attrs.district
      forms.setErrorToProperty(form, 'district', $.i18n.t('common.required_field'))
      error = true

    trialRequestAttrs['siteOrigin'] = 'demo request'

    try
      parsedName = parseFullName(trialRequestAttrs['fullName'], 'all', -1, true)
      if parsedName.first and parsedName.last
        trialRequestAttrs['firstName'] = parsedName.first
        trialRequestAttrs['lastName'] = parsedName.last
    catch e
      # TODO handle_error_ozaria

    if not trialRequestAttrs['firstName'] or not trialRequestAttrs['lastName']
      error = true
      forms.clearFormAlerts($('#full-name'))
      forms.setErrorToProperty(form, 'fullName', $.i18n.t('teachers_quote.full_name_required'))

    if error
      forms.scrollToFirstError()
      return

    @trialRequest = new TrialRequest({
      type: 'course'
      properties: trialRequestAttrs
    })
    if me.get('role') is 'student' and not me.isAnonymous()
      modal = new ConfirmModal({
        title: ''
        body: "<p>#{$.i18n.t('teachers_quote.conversion_warning')}</p><p>#{$.i18n.t('teachers_quote.learn_more_modal')}</p>"
        confirm: $.i18n.t('common.continue')
        decline: $.i18n.t('common.cancel')
      })
      @openModalView(modal)
      modal.once('confirm', (->
        modal.hide()
        @saveTrialRequest()
      ), @)
    else
      @saveTrialRequest()

  saveTrialRequest: ->
    @trialRequest.notyErrors = false
    @$('#submit-request-btn').text('Sending').attr('disabled', true)
    @trialRequest.save()
    @trialRequest.on 'sync', @onTrialRequestSubmit, @
    @trialRequest.on 'error', @onTrialRequestError, @

  onTrialRequestError: (model, jqxhr) ->
    @$('#submit-request-btn').text('Submit').attr('disabled', false)
    if jqxhr.status is 409
      userExists = $.i18n.t('teachers_quote.email_exists')
      logIn = $.i18n.t('login.log_in')
      @$('#email-form-group')
        .addClass('has-error')
        .append($("<div class='help-block error-help-block'>#{userExists} <a id='email-exists-login-link'>#{logIn}</a>"))
      forms.scrollToFirstError()
    else
      errors.showNotyNetworkError(arguments...)

  onClickEmailExistsLoginLink: ->
    @openModalView(new AuthModal({ initialValues: @state.get('authModalInitialValues') }))

  onTrialRequestSubmit: ->
    window.tracker?.trackEvent 'Teachers Request Demo Form Submitted', category: 'Teachers', ['Mixpanel']
    @formChanged = false
    trialRequestProperties = @trialRequest.get('properties')
    me.setRole trialRequestProperties.role.toLowerCase(), true
    defaultName = [trialRequestProperties.firstName, trialRequestProperties.lastName].join(' ')
    @$('input[name="name"]').val(defaultName)
    @$('#request-form, #form-submit-success').toggleClass('hide')
    @scrollToTop(0)
    $('#flying-focus').css({top: 0, left: 0}) # Hack copied from Router.coffee#187. Ideally we'd swap out the view and have view-swapping logic handle this

  onClickGPlusSignupButton: ->
    btn = @$('#gplus-signup-btn')
    btn.attr('disabled', true)
    application.gplusHandler.loadAPI({
      context: @
      success: ->
        btn.attr('disabled', false)
        application.gplusHandler.connect({
          context: @
          success: ->
            btn.find('.sign-in-blurb').text($.i18n.t('signup.creating'))
            btn.attr('disabled', true)
            application.gplusHandler.loadPerson({
              context: @
              success: (gplusAttrs) ->
                me.set(gplusAttrs)
                me.save(null, {
                  url: "/db/user?gplusID=#{gplusAttrs.gplusID}&gplusAccessToken=#{application.gplusHandler.token()}"
                  type: 'PUT'
                  success: ->
                    window.tracker?.trackEvent 'Teachers Request Demo Create Account Google', category: 'Teachers', ['Mixpanel']
                    application.router.navigate(SIGNUP_REDIRECT)
                    window.location.reload()
                  error: errors.showNotyNetworkError
                })
            })
        })
    })

  onClickFacebookSignupButton: ->
    btn = @$('#facebook-signup-btn')
    btn.attr('disabled', true)
    application.facebookHandler.loadAPI({
      context: @
      success: ->
        btn.attr('disabled', false)
        application.facebookHandler.connect({
          context: @
          success: ->
            btn.find('.sign-in-blurb').text($.i18n.t('signup.creating'))
            btn.attr('disabled', true)
            application.facebookHandler.loadPerson({
              context: @
              success: (facebookAttrs) ->
                me.set(facebookAttrs)
                me.save(null, {
                  url: "/db/user?facebookID=#{facebookAttrs.facebookID}&facebookAccessToken=#{application.facebookHandler.token()}"
                  type: 'PUT'
                  success: ->
                    window.tracker?.trackEvent 'Teachers Request Demo Create Account Facebook', category: 'Teachers', ['Mixpanel']
                    application.router.navigate(SIGNUP_REDIRECT)
                    window.location.reload()
                  error: errors.showNotyNetworkError
                })
            })
        })
    })


  onSubmitSignupForm: (e) ->
    e.preventDefault()
    form = @$('#signup-form')
    attrs = forms.formToObject(form)

    forms.clearFormAlerts(form)
    result = tv4.validateMultiple(attrs, signupFormSchema)
    error = false
    if not result.valid
      forms.applyErrorsToForm(form, result.errors)
      error = true
    if attrs.password1 isnt attrs.password2
      forms.setErrorToProperty(form, 'password1', 'Passwords do not match')
      error = true
    return if error

    me.set({
      password: attrs.password1
      name: attrs.name
      email: @trialRequest.get('properties').email
    })
    if me.inEU()
      emails = _.assign({}, me.get('emails'))
      emails.generalNews ?= {}
      emails.generalNews.enabled = false
      me.set('emails', emails)
      me.set('unsubscribedFromMarketingEmails', true)
    me.save(null, {
      success: ->
        window.tracker?.trackEvent 'Teachers Request Demo Create Account', category: 'Teachers', ['Mixpanel']
        application.router.navigate(SIGNUP_REDIRECT)
        window.location.reload()
      error: errors.showNotyNetworkError
    })

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

requestFormSchemaAnonymous = {
  type: 'object'
  required: [
    'fullName', 'email', 'role', 'numStudents', 'numStudentsTotal', 'city', 'state',
    'country', 'organization', 'phoneNumber'
  ]
  properties:
    fullName: { type: 'string' }
    email: { type: 'string', format: 'email' }
    phoneNumber: { type: 'string' }
    role: { type: 'string' }
    organization: { type: 'string' }
    district: { type: 'string' }
    city: { type: 'string' }
    state: { type: 'string' }
    country: { type: 'string' }
    numStudents: { type: 'string' }
    numStudentsTotal: { type: 'string' }
}

for key in SCHOOL_NCES_KEYS
  requestFormSchemaAnonymous['nces_' + key] = type: 'string'

# same form, but add username input
requestFormSchemaLoggedIn = _.cloneDeep(requestFormSchemaAnonymous)
requestFormSchemaLoggedIn.required.push('name')

signupFormSchema = {
  type: 'object'
  required: ['name', 'password1', 'password2']
  properties:
    name: { type: 'string' }
    password1: { type: 'string' }
    password2: { type: 'string' }
}
