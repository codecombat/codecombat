require('app/styles/teachers/teacher-trial-requests.sass')
RootView = require 'views/core/RootView'
forms = require 'core/forms'
TrialRequest = require 'models/TrialRequest'
TrialRequests = require 'collections/TrialRequests'
AuthModal = require 'views/core/AuthModal'
errors = require 'core/errors'
User = require 'models/User'
ConfirmModal = require 'views/core/ConfirmModal'
algolia = require 'core/services/algolia'

DISTRICT_NCES_KEYS = ['district', 'district_id', 'district_schools', 'district_students', 'phone']
SCHOOL_NCES_KEYS = DISTRICT_NCES_KEYS.concat(['id', 'name', 'students'])

module.exports = class ConvertToTeacherAccountView extends RootView
  id: 'convert-to-teacher-account-view'
  template: require 'templates/teachers/convert-to-teacher-account-view'
  logoutRedirectURL: null

  events:
    'change form': 'onChangeForm'
    'submit form': 'onSubmitForm'
    'click #logout-link': -> me.logout()
    'change input[name="city"]': 'invalidateNCES'
    'change input[name="state"]': 'invalidateNCES'
    'change input[name="district"]': 'invalidateNCES'
    'change input[name="country"]': 'invalidateNCES'

  initialize: ->
    if me.isAnonymous()
      application.router.navigate('/teachers/signup', {trigger: true, replace: true})
      return
    @trialRequest = new TrialRequest()
    @trialRequests = new TrialRequests()
    @trialRequests.fetchOwn()
    @supermodel.trackCollection(@trialRequests)
    window.tracker?.trackEvent 'Teachers Convert Account Loaded', category: 'Teachers', ['Mixpanel']

  onLeaveMessage: ->
    if @formChanged
      return 'Your account has not been updated! If you continue, your changes will be lost.'

  invalidateNCES: ->
    for key in SCHOOL_NCES_KEYS
      @$('input[name="nces_' + key + '"]').val ''

  onLoaded: ->
    if @trialRequests.size() and me.isTeacher()
      return application.router.navigate('/teachers', { trigger: true, replace: true })

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
      @onChangeForm()

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
      @onChangeForm()

  onChangeForm: ->
    unless @formChanged
      window.tracker?.trackEvent 'Teachers Convert Account Form Started', category: 'Teachers', ['Mixpanel']
    @formChanged = true

  onSubmitForm: (e) ->
    e.preventDefault()

    form = @$('form')
    attrs = forms.formToObject(form)
    trialRequestAttrs = _.cloneDeep(attrs)

    # Don't save n/a district entries, but do validate required district client-side
    trialRequestAttrs = _.omit(trialRequestAttrs, 'district') if trialRequestAttrs.district?.replace(/\s/ig, '').match(/^n\/?a$/ig)

    if @$('#other-education-level-checkbox').is(':checked')
      val = @$('#other-education-level-input').val()
      trialRequestAttrs.educationLevel.push(val) if val

    forms.clearFormAlerts(form)

    result = tv4.validateMultiple(trialRequestAttrs, formSchema)
    error = false
    if not result.valid
      forms.applyErrorsToForm(form, result.errors)
      error = true
    if not _.size(trialRequestAttrs.educationLevel)
      forms.setErrorToProperty(form, 'educationLevel', 'include at least one')
      error = true
    unless attrs.district
      forms.setErrorToProperty(form, 'district', $.i18n.t('common.required_field'))
      error = true
    if error
      forms.scrollToFirstError()
      return
    trialRequestAttrs['siteOrigin'] = 'convert teacher'
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
      modal.once 'confirm', @saveTrialRequest, @
    else
      @saveTrialRequest()

  saveTrialRequest: ->
    @trialRequest.notyErrors = false
    @$('#create-account-btn').text('Sending').attr('disabled', true)
    @trialRequest.save()
    @trialRequest.on 'sync', @onTrialRequestSubmit, @
    @trialRequest.on 'error', @onTrialRequestError, @

  onTrialRequestError: (model, jqxhr) ->
    @$('#submit-request-btn').text('Submit').attr('disabled', false)
    errors.showNotyNetworkError(arguments...)

  onTrialRequestSubmit: ->
    window.tracker?.trackEvent 'Teachers Convert Account Submitted', category: 'Teachers', ['Mixpanel']
    @formChanged = false
    me.setRole @trialRequest.get('properties').role.toLowerCase(), true
    me.unsubscribe()
    application.router.navigate('/teachers/classes', {trigger: true})

formSchema = {
  type: 'object'
  required: ['firstName', 'lastName', 'role', 'numStudents', 'city', 'state', 'country']
  properties:
    firstName: { type: 'string' }
    lastName: { type: 'string' }
    phoneNumber: { type: 'string' }
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
