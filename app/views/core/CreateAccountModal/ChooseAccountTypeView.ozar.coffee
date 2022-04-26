require('app/styles/modal/create-account-modal/choose-account-type-view.sass')
CocoView = require 'views/core/CocoView'
template = require 'app/templates/core/create-account-modal/choose-account-type-view'

module.exports = class ChooseAccountTypeView extends CocoView
  id: 'choose-account-type-view'
  template: template

  events:
    'click .teacher-path-button': -> @trigger 'choose-path', 'teacher'
    'input .class-code-input': 'onInputClassCode'
    'submit form.choose-account-type': 'onSubmitStudent'

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
