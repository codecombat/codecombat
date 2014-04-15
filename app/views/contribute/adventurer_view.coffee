ContributeClassView = require 'views/contribute/contribute_class_view'
template = require 'templates/contribute/adventurer'
{me} = require('lib/auth')

module.exports = class AdventurerView extends ContributeClassView
  id: "adventurer-view"
  template: template
  contributorClassName: 'adventurer'
