require('app/styles/contribute/contribute.sass')
ContributeClassView = require 'views/contribute/ContributeClassView'
template = require 'templates/contribute/contribute'

module.exports = class MainContributeView extends ContributeClassView
  id: 'contribute-view'
  template: template

  events:
    'change input[type="checkbox"]': 'onCheckboxChanged'
