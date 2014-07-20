ContributeClassView = require './ContributeClassView'
template = require 'templates/contribute/adventurer'
{me} = require 'lib/auth'

module.exports = class AdventurerView extends ContributeClassView
  id: 'adventurer-view'
  template: template
  contributorClassName: 'adventurer'
