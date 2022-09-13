require('app/styles/modal/create-account-modal/segment-check-view.sass')
CocoView = require 'views/core/CocoView'
template = require 'app/templates/core/create-account-modal/segment-check-view'
forms = require 'core/forms'
Classroom = require 'models/Classroom'
State = require 'models/State'
utils = require 'core/utils'

module.exports = class SegmentCheckView extends CocoView
  id: 'segment-check-view'
  template: template

  events:
    'click .back-to-account-type': 'onBackToAccountType'
    'input .class-code-input': 'onInputClassCode'
    'change .birthday-form-group': 'onInputBirthday'
    'submit form.segment-check': 'onSubmitSegmentCheck'
    'click .individual-path-button': -> @trigger 'choose-path', 'individual'

  initialize: ({ @signupState } = {}) ->
    @fetchAndApplyClassCodeDebounced = _.debounce @fetchAndApplyClassCode, 1000
    @fetchClassByCode = _.memoize(@fetchClassByCode)
    @state = new State()
    if @signupState.get('classCode')
      @fetchAndApplyClassCode()
    @listenTo @state, 'all', _.debounce(->
      @renderSelectors('.render')
      @trigger 'special-render'
    )

  getClassCode: -> @$('.class-code-input').val() or @signupState.get('classCode')

  onBackToAccountType: ->
    @state.set { doneFetching: false }
    @trigger 'nav-back'

  onInputClassCode: ->
    # TODO: This may do nothing, because the glyph icons we use are not alerts
    forms.clearFormAlerts(@$el)
    # TODO: Ideally, when this is in Vue, we can run the check on each key press
    # and let them know we are searching for the class code, without having to 
    # reset focus and mess with the input
    @signupState.set { classCode: @getClassCode() }, { silent: true }
    @fetchAndApplyClassCodeDebounced()

  afterRender: () ->
    super()
    @onInputClassCode()

  fetchAndApplyClassCode: ->
    return if @destroyed
    classCode = @getClassCode()

    if not classCode
      return

    @fetchClassByCode(classCode)
    .then (classroom) =>
      return if @destroyed or @getClassCode() isnt classCode
      if classroom
        firstName = classroom.owner.get('firstName')
        lastName = classroom.owner.get('lastName')
        ownerName = if firstName || lastName then "#{firstName} #{lastName}" else classroom.owner.get('name')
        @state.set {
          ownerName
          classroomName: classroom.get('name')
          doneFetching: true
          classCodeValid: true
          segmentCheckValid: true
        }
      else
        @state.set { doneFetching: true, classCodeValid: false, segmentCheckValid: false }
    .catch (error) ->
      throw error

  onInputBirthday: ->
    { birthdayYear, birthdayMonth, birthdayDay } = forms.formToObject(@$('form'))
    birthday = new Date Date.UTC(birthdayYear, birthdayMonth - 1, birthdayDay)
    @signupState.set { birthdayYear, birthdayMonth, birthdayDay, birthday }, { silent: true }
    unless _.isNaN(birthday.getTime())
      forms.clearFormAlerts(@$el)

  onSubmitSegmentCheck: (e) ->
    e.preventDefault()

    if @signupState.get('path') is 'student'
      @$('.class-code-input').attr('disabled', true)

      @fetchClassByCode(@getClassCode())
      .then (classroom) =>
        return if @destroyed
        if classroom
          @signupState.set { classroom }
          screen = if me.get('country') and me.inEU() then 'eu-confirmation' else 'basic-info'
          @trigger 'nav-forward', screen
        else
          @$('.class-code-input').attr('disabled', false)
          @classroom = new Classroom()
          @state.set { classCodeValid: false, segmentCheckValid: false }
      .catch (error) ->
        throw error

    else if @signupState.get('path') is 'individual'
      if _.isNaN(@signupState.get('birthday').getTime())
        forms.clearFormAlerts(@$el)
        requiredMessage = _.string.titleize $.i18n.t('common.required_field')
        forms.setErrorToProperty @$el, 'birthdayDay', requiredMessage
      else
        age = (new Date().getTime() - @signupState.get('birthday').getTime()) / 365.4 / 24 / 60 / 60 / 1000
        if age > utils.ageOfConsent(me.get('country'), 13)
          screen = if me.get('country') and me.inEU() then 'eu-confirmation' else 'basic-info'
          @trigger 'nav-forward', screen
          window.tracker?.trackEvent 'CreateAccountModal Individual SegmentCheckView Submit', category: 'Individuals'
        else
          @trigger 'nav-forward', 'coppa-deny'
          window.tracker?.trackEvent 'CreateAccountModal Individual SegmentCheckView Coppa Deny', category: 'Individuals'

  fetchClassByCode: (classCode) ->
    if not classCode
      return Promise.resolve()

    new Promise((resolve, reject) ->
      new Classroom().fetchByCode(classCode, {
        success: resolve
        error: (classroom, jqxhr) ->
          if jqxhr.status is 404
            resolve()
          else
            reject(jqxhr.responseJSON)
      })
    )
