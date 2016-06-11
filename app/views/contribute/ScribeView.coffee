ContributeClassView = require './ContributeClassView'
template = require 'templates/contribute/scribe'
{me} = require 'core/auth'

module.exports = class ScribeView extends ContributeClassView
  id: 'scribe-view'
  template: template

  initialize: ->
    @contributorClassName = 'scribe'

  contributors: [
    {name: 'Ryan Faidley'}
    {name: 'Mischa Lewis-Norelle', github: 'mlewisno'}
    {name: 'Tavio'}
    {name: 'Ronnie Cheng', github: 'rhc2104'}
    {name: 'engstrom'}
    {name: 'Dman19993'}
    {name: 'mattinsler'}
  ]
