ContributeClassView = require './ContributeClassView'
template = require 'templates/contribute/ambassador'
{me} = require 'core/auth'

module.exports = class AmbassadorView extends ContributeClassView
  id: 'ambassador-view'
  template: template

  initialize: ->
    @contributorClassName = 'ambassador'
