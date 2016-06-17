ModalView = require 'views/core/ModalView'
template = require 'templates/core/create-account-modal/segment-check-view'
forms = require 'core/forms'
Classroom = require 'models/Classroom'
State = require 'models/State'

module.exports = class SegmentCheckView extends ModalView
  id: 'segment-check-view'
  template: template

  events:
    'click .back-to-account-type': -> @trigger 'nav-back'
    'input .class-code-input': (e) ->
      classCode = $(e.currentTarget).val()
      @checkClassCode(classCode)
      @sharedState.set { classCode }, { silent: true }
    'input .birthday-form-group': ->
      { birthdayYear, birthdayMonth, birthdayDay } = forms.formToObject(@$('form'))
      birthday = new Date Date.UTC(birthdayYear, birthdayMonth - 1, birthdayDay)
      @sharedState.set { birthdayYear, birthdayMonth, birthdayDay, birthday }, { silent: true }
      unless isNaN(birthday.getTime())
        forms.clearFormAlerts(@$el)
    'submit form.segment-check': (e) ->
      e.preventDefault()
      if @sharedState.get('path') is 'student'
        @trigger 'nav-forward' if @state.get('segmentCheckValid')
      else if @sharedState.get('path') is 'individual'
        if isNaN(@sharedState.get('birthday').getTime())
          forms.setErrorToProperty @$el, 'birthdayDay', 'Required'
        else
          age = (new Date().getTime() - @sharedState.get('birthday').getTime()) / 365.4 / 24 / 60 / 60 / 1000
          if age > 13
            @trigger 'nav-forward'
          else
            @trigger 'nav-forward', 'coppa-deny'

  initialize: ({ @sharedState } = {}) ->
    @state = new State()
    @classroom = new Classroom()
    @listenTo @state, 'all', -> @render()

  checkClassCode: _.debounce((classCode) ->
    @classroom.fetchByCode(classCode)
    @classroom.once 'sync', => @state.set { classCodeValid: true, segmentCheckValid: true }
    @classroom.once 'error', => @state.set { classCodeValid: false, segmentCheckValid: false }
  , 1000)
