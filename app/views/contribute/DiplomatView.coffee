ContributeClassView = require './ContributeClassView'
template = require 'templates/contribute/diplomat'
{me} = require 'lib/auth'

module.exports = class DiplomatView extends ContributeClassView
  id: 'diplomat-view'
  template: template
  contributorClassName: 'diplomat'
