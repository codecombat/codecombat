ContributeClassView = require 'views/contribute/contribute_class_view'
template = require 'templates/contribute/diplomat'
{me} = require 'lib/auth'

module.exports = class DiplomatView extends ContributeClassView
  id: 'diplomat-view'
  template: template
  contributorClassName: 'diplomat'
