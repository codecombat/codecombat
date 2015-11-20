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
    userObject = forms.formToObject @$el
    res = tv4.validateMultiple userObject, User.schema
    return forms.applyErrorsToForm(@$el, res.errors) unless res.valid
    @enableModalInProgress(@$el)
    auth.loginUser userObject, (jqxhr) =>
      error = jqxhr.responseJSON[0]
      message = error.property + ' ' + error.message
      @disableModalInProgress(@$el)
      @$('#errors-alert').text(message).removeClass('hide')
      