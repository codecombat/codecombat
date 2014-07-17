ContributeClassView = require 'views/contribute/contribute_class_view'
template = require 'templates/contribute/contribute'

module.exports = class ContributeView extends ContributeClassView
  id: 'contribute-view'
  template: template
  navPrefix: ''

  events:
    'change input[type="checkbox"]': 'onCheckboxChanged'
