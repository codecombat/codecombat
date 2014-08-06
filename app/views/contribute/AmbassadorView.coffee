ContributeClassView = require './ContributeClassView'
template = require 'templates/contribute/ambassador'
{me} = require 'lib/auth'

module.exports = class AmbassadorView extends ContributeClassView
  id: 'ambassador-view'
  template: template
  contributorClassName: 'ambassador'
