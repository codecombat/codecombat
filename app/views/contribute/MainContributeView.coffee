require('app/styles/contribute/contribute.sass')
ContributeClassView = require 'views/contribute/ContributeClassView'
template = require 'app/templates/contribute/contribute'

module.exports = class MainContributeView extends ContributeClassView
  id: 'contribute-view'
  template: template

  events:
    'change input[type="checkbox"]': 'onCheckboxChanged'
