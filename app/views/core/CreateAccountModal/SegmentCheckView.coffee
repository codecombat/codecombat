CocoView = require 'views/core/CocoView'
template = require 'templates/core/create-account-modal/segment-check-view'
forms = require 'core/forms'
Classroom = require 'models/Classroom'
State = require 'models/State'

module.exports = class SegmentCheckView extends CocoView
  id: 'segment-check-view'
  template: template

  events:
    'click .back-to-account-type': -> @trigger 'nav-back'
    'input .class-code-input': 'onInputClassCode'
    'input .birthday-form-group': 'onInputBirthday'
    'submit form.segment-check': 'onSubmitSegmentCheck'
    'click .individual-path-button': ->
      @trigger 'choose-path', 'individual'
      
  onInputClassCode: (e) ->
    classCode = $(e.currentTarget).val()
    @checkClassCodeDebounced(classCode)
    @sharedState.set { classCode }, { silent: true }

  onInputBirthday: ->
    { birthdayYear, birthdayMonth, birthdayDay } = forms.formToObject(@$('form'))
    birthday = new Date Date.UTC(birthdayYear, birthdayMonth - 1, birthdayDay)
    @sharedState.set { birthdayYear, birthdayMonth, birthdayDay, birthday }, { silent: true }
    unless isNaN(birthday.getTime())
      forms.clearFormAlerts(@$el)
    
  onSubmitSegmentCheck: (e) ->
    e.preventDefault()
    if @sharedState.get('path') is 'student'
      @trigger 'nav-forward' if @state.get('segmentCheckValid')
    else if @sharedState.get('path') is 'individual'
      if isNaN(@sharedState.get('birthday').getTime())
        forms.clearFormAlerts(@$el)
        forms.setErrorToProperty @$el, 'birthdayDay', 'Required'
      else
        age = (new Date().getTime() - @sharedState.get('birthday').getTime()) / 365.4 / 24 / 60 / 60 / 1000
        if age > 13
          @trigger 'nav-forward'
        else
          @trigger 'nav-forward', 'coppa-deny'

  initialize: ({ @sharedState } = {}) ->
    @checkClassCodeDebounced = _.debounce @checkClassCode, 1000
    @state = new State()
    @classroom = new Classroom()
    if @sharedState.get('classCode')
      @checkClassCode(@sharedState.get('classCode'))
    @listenTo @state, 'all', -> @renderSelectors('.render')
  
  checkClassCode: (classCode) ->
    @classroom.clear()
    return forms.clearFormAlerts(@$el) if classCode is ''
    
    new Promise(@classroom.fetchByCode(classCode).then)
      .then =>
        @state.set { classCodeValid: true, segmentCheckValid: true }
      .catch =>
        @state.set { classCodeValid: false, segmentCheckValid: false }
  
