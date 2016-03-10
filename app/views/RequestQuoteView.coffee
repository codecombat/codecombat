RootView = require 'views/core/RootView'
forms = require 'core/forms'
TrialRequest = require 'models/TrialRequest'
TrialRequests = require 'collections/TrialRequests'
AuthModal = require 'views/core/AuthModal'
CreateAccountModal = require 'views/core/CreateAccountModal'
storage = require 'core/storage'

formSchema = {
  type: 'object'
  required: ['name', 'email', 'organization', 'role', 'numStudents']
  properties:
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

module.exports = class RequestQuoteView extends RootView
  id: 'request-quote-view'
  template: require 'templates/request-quote-view'

  events:
    'change form': 'onChangeForm'
    'submit form': 'onSubmitForm'
    'click #login-btn': 'onClickLoginButton'
    'click #signup-btn': 'onClickSignupButton'
    'click #email-exists-login-link': 'onClickEmailExistsLoginLink'

  initialize: ->
    @trialRequest = new TrialRequest()
    @trialRequests = new TrialRequests()
    @trialRequests.fetchOwn()
    @supermodel.loadCollection(@trialRequests)

  onLoaded: ->
    if @trialRequests.size()
      @trialRequest = @trialRequests.first()
    if @trialRequest and @trialRequest.get('status') isnt 'submitted' and @trialRequest.get('status') isnt 'approved'
      window.tracker?.trackEvent 'View Trial Request', category: 'Teachers', label: 'View Trial Request', ['Mixpanel']
    super()
    
  afterRender: ->
    super()
    obj = storage.load('request-quote-form')
    if obj
      @$('#other-education-level-checkbox').attr('checked', obj.otherChecked)
      @$('#other-education-level-input').val(obj.otherInput)
      forms.objectToForm(@$('form'), obj)

  onChangeForm: ->
    obj = forms.formToObject(@$('form'))
    obj.otherChecked = @$('#other-education-level-checkbox').is(':checked')
    obj.otherInput = @$('#other-education-level-input').val()
    storage.save('request-quote-form', obj, 10)

  onSubmitForm: (e) ->
    e.preventDefault()
    form = @$('form')
    attrs = forms.formToObject(form)
    
    # custom other input logic (also used in form local storage save/restore)
    if @$('#other-education-level-checkbox').is(':checked')
      attrs.educationLevel.push(@$('#other-education-level-input').val())
      
    forms.clearFormAlerts(form)
    result = tv4.validateMultiple(attrs, formSchema)
    error = true
    if not result.valid
      forms.applyErrorsToForm(form, result.errors)
    else if not /^.+@.+\..+$/.test(attrs.email)
      forms.setErrorToProperty(form, 'email', 'Invalid email.')
    else if not _.size(attrs.educationLevel)
      return forms.setErrorToProperty(form, 'educationLevel', 'Check at least one.')
    else
      error = false
    if error
      forms.scrollToFirstError()
      return
    @trialRequest = new TrialRequest({
      type: 'course'
      properties: attrs
    })
    @trialRequest.notyErrors = false
    @$('#submit-request-btn').text('Sending').attr('disabled', true)
    @trialRequest.save()
    @trialRequest.on 'sync', @onTrialRequestSubmit, @
    @trialRequest.on 'error', @onTrialRequestError, @
    me.setRole attrs.role.toLowerCase(), true

  onTrialRequestError: (model, jqxhr) ->
    if jqxhr.status is 409
      userExists = $.i18n.t('teachers_quote.email_exists')
      logIn = $.i18n.t('login.log_in')
      @$('#email-form-group')
        .addClass('has-error')
        .append($("<div class='help-block error-help-block'>#{userExists} <a id='email-exists-login-link'>#{logIn}</a>"))
    @$('#submit-request-btn').text('Submit').attr('disabled', false)
    forms.scrollToFirstError()

  onClickEmailExistsLoginLink: ->
    modal = new AuthModal({ initialValues: { email: @trialRequest.get('properties')?.email } })
    @openModalView(modal)

  onTrialRequestSubmit: ->
    @$('form, #form-submit-success').toggleClass('hide')
    window.tracker?.trackEvent 'Submit Trial Request', category: 'Teachers', label: 'Trial Request', ['Mixpanel']

  onClickLoginButton: ->
    modal = new AuthModal({ initialValues: { email: @trialRequest.get('properties')?.email } })
    @openModalView(modal)
    window.nextURL = '/courses/teachers' unless @trialRequest.isNew()

  onClickSignupButton: ->
    props = @trialRequest.get('properties') or {}
    me.set('name', props.name)
    modal = new CreateAccountModal({
      initialValues: {
        email: props.email
        schoolName: props.organization
      }
    })
    @openModalView(modal)
    window.nextURL = '/courses/teachers' unless @trialRequest.isNew()
