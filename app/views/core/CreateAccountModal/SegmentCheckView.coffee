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
    'change .birthday-form-group': 'onInputBirthday'
    'submit form.segment-check': 'onSubmitSegmentCheck'
    'click .individual-path-button': -> @trigger 'choose-path', 'individual'

  initialize: ({ @signupState } = {}) ->
    @checkClassCodeDebounced = _.debounce @checkClassCode, 1000
    @fetchClassByCode = _.memoize(@fetchClassByCode)
    @classroom = new Classroom()
    @state = new State()
    if @signupState.get('classCode')
      @checkClassCode(@signupState.get('classCode'))
    @listenTo @state, 'all', _.debounce(->
      @renderSelectors('.render')
      @trigger 'special-render'
    )
    
  getClassCode: -> @$('.class-code-input').val() or @signupState.get('classCode') 

  onInputClassCode: ->
    @classroom = new Classroom()
    forms.clearFormAlerts(@$el)
    classCode = @getClassCode()
    @signupState.set { classCode }, { silent: true }
    @checkClassCodeDebounced()
    
  checkClassCode: ->
    return if @destroyed
    classCode = @getClassCode()
    
    @fetchClassByCode(classCode)
    .then (classroom) =>
      return if @destroyed or @getClassCode() isnt classCode
      if classroom
        @classroom = classroom
        @state.set { classCodeValid: true, segmentCheckValid: true }
      else
        @classroom = new Classroom()
        @state.set { classCodeValid: false, segmentCheckValid: false }
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
          @trigger 'nav-forward'
        else
          @$('.class-code-input').attr('disabled', false)
          @classroom = new Classroom()
          @state.set { classCodeValid: false, segmentCheckValid: false }
      .catch (error) ->
        throw error
        
    else if @signupState.get('path') is 'individual'
      if _.isNaN(@signupState.get('birthday').getTime())
        forms.clearFormAlerts(@$el)
        forms.setErrorToProperty @$el, 'birthdayDay', 'Required'
      else
        age = (new Date().getTime() - @signupState.get('birthday').getTime()) / 365.4 / 24 / 60 / 60 / 1000
        if age > 13
          @trigger 'nav-forward'
        else
          @trigger 'nav-forward', 'coppa-deny'

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
  
