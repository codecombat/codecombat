ContributeClassView = require 'views/contribute/contribute_class_view'
template = require 'templates/contribute/contribute'
SignupModalView = require 'views/modal/signup_modal'

module.exports = class ContributeView extends ContributeClassView
  id: "contribute-view"
  template: template

  events:
    'change input[type="checkbox"]': 'onCheckboxChanged'