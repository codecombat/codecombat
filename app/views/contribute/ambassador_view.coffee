ContributeClassView = require 'views/contribute/contribute_class_view'
template = require 'templates/contribute/ambassador'
{me} = require 'lib/auth'

module.exports = class AmbassadorView extends ContributeClassView
  id: 'ambassador-view'
  template: template
  contributorClassName: 'ambassador'
