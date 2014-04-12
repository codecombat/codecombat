View = require 'views/kinds/ModalView'
template = require 'templates/modal/employer_signup_modal'

module.exports = class EmployerSignupView extends View
  id: "employer-signup"
  template: template
  closeButton: true
