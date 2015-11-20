ModalView = require 'views/core/ModalView'
template = require 'templates/courses/student-log-in-modal'
auth = require 'core/auth'
forms = require 'core/forms'
User = require 'models/User'

module.exports = class StudentSignInModal extends ModalView
  id: 'student-log-in-modal'
  template: template
  
  events:
    'click #log-in-btn': 'onClickLogInButton'
    'submit form': 'onSubmitForm'

  onSubmitForm: (e) ->
    e.preventDefault()
    @login()
    
  onClickLogInButton: ->
    @login()

  login: ->
    data = forms.formToObject @$el
    @enableModalInProgress(@$el)
    auth.loginUser data, (jqxhr) =>
      error = jqxhr.responseJSON[0]
      message = _.filter([error.property, error.message]).join(' ')
      @disableModalInProgress(@$el)
      @$('#errors-alert').text(message).removeClass('hide')
      