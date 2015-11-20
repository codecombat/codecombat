ModalView = require 'views/core/ModalView'
template = require 'templates/courses/student-log-in-modal'
auth = require 'core/auth'
forms = require 'core/forms'
User = require 'models/User'

module.exports = class StudentSignInModal extends ModalView
  id: 'student-log-in-modal'
  template: template
  
  initialize: ->
    @formValues = {}

  events:
    'click #log-in-btn': 'onClickLogInButton'
    
  onClickLogInButton: ->
    forms.clearFormAlerts(@$el)
    userObject = forms.formToObject @$el
    res = tv4.validateMultiple userObject, User.schema
    return forms.applyErrorsToForm(@$el, res.errors) unless res.valid
    @enableModalInProgress(@$el) # TODO: part of forms
    loginUser userObject, null, window.nextURL
