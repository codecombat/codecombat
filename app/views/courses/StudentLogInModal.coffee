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
    'click #create-new-account-link': 'onClickCreateNewAccountLink'

  onSubmitForm: (e) ->
    e.preventDefault()
    @login()

  onClickLogInButton: ->
    @login()

  login: ->
    # TODO: doesn't track failed login
    window.tracker?.trackEvent 'Finished Login', category: 'Courses', label: 'Courses Student Login'
    data = forms.formToObject @$el
    @enableModalInProgress(@$el)
    auth.loginUser data, (jqxhr) =>
      error = jqxhr.responseJSON[0]
      message = _.filter([error.property, error.message]).join(' ')
      if message is 'Missing credentials'
        message = 'Enter both username and password'
        # TODO: Make the server return better error message
      message = _.string.capitalize(message)
      @disableModalInProgress(@$el)
      @$('#errors-alert').text(message).removeClass('hide')

  onClickCreateNewAccountLink: ->
    @trigger 'want-to-create-account'
    @hide?()

  afterInsert: ->
    super()
    _.delay (=> @$('input:visible:first').focus()), 500
