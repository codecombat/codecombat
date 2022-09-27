require('app/styles/modal/create-account-modal/choose-account-type-view.sass')
CocoView = require 'views/core/CocoView'
template = require 'app/templates/core/create-account-modal/choose-account-type-view'
utils = require 'core/utils'

module.exports = class ChooseAccountTypeView extends CocoView
  id: 'choose-account-type-view'
  template: template

  events:
    'click .teacher-path-button': -> @trigger 'choose-path', 'teacher'
    'click .student-path-button': -> @trigger 'choose-path', 'student'
    'click .individual-path-button': -> @trigger 'choose-path', 'individual'
    'input .class-code-input': 'onInputClassCode'
    'submit form.choose-account-type': 'onSubmitStudent'
    'click .parent-path-button': ->
      if location.pathname is '/parents'
        @trigger 'choose-path', 'individual'
      else
        application.router.navigate('/parents', {trigger: true})

  afterRender: ->
    if me.showChinaHomeVersion()
      @trigger 'choose-path', 'individual'

  initialize: ({ @signupState }) ->

  getClassCode: -> @$('.class-code-input').val() or @signupState.get('classCode')

  onInputClassCode: ->
    classCode = @getClassCode()
    @signupState.set { classCode }, { silent: true }

  onSubmitStudent: (e) ->
    e.preventDefault()

    @onInputClassCode()
    @trigger 'choose-path', 'student'
    return false
