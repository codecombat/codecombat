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
          forms.clearFormAlerts(@$el)
          forms.setErrorToProperty @$el, 'birthdayDay', 'Required'
        else
          age = (new Date().getTime() - @sharedState.get('birthday').getTime()) / 365.4 / 24 / 60 / 60 / 1000
          if age > 13
            @trigger 'nav-forward'
          else
            @trigger 'nav-forward', 'coppa-deny'
    'click .individual-path-button': ->
      @trigger 'choose-path', 'individual'

  initialize: ({ @sharedState } = {}) ->
    @state = new State()
    @classroom = new Classroom()
    @listenTo @state, 'all', -> @renderSelectors('.render')
  #
  # checkClassCode: _.debounce((classCode) ->
  #   @classroom.fetchByCode(classCode)
  #   # @classroom.once 'sync', => @state.set { classCodeValid: true, segmentCheckValid: true }
  #   # @classroom.once 'error', => @state.set { classCodeValid: false, segmentCheckValid: false }
  #
  #   forms.clearFormAlerts(@$('form'))
  #   res = tv4.validate(classCode, UserSchema.)
  # , 1000)
  
  checkClassCode: _.debounce (classCode) ->
    @classroom.clear()
    console.log 'Checking classCode: ', classCode
    return forms.clearFormAlerts(@$el) if classCode is ''
    
    new Promise(@classroom.fetchByCode(classCode).then)
      .then =>
        console.log @classroom.get('name')
        @state.set { classCodeValid: true, segmentCheckValid: true }
      .catch =>
        console.log @classroom.get('name')
        @state.set { classCodeValid: false, segmentCheckValid: false }
  , 1000
      
    # jqxhr = User.getUnconflictedName name, (newName) =>
    #   forms.clearFormAlerts(@$el)
    #   if name is newName
    #     @suggestedName = undefined
    #     return true
    #   else
    #     console.log "Suggesting name: #{newName}"
    #     @suggestedName = newName
    #     forms.setErrorToProperty @$el, 'name', "Username already taken!<br>Try #{newName}?"
    #     return false
    # jqxhr.then (val) -> return val
