ContributeClassView = require 'views/contribute/contribute_class_view'
template = require 'templates/contribute/scribe'
{me} = require('lib/auth')

module.exports = class ScribeView extends ContributeClassView
  id: "scribe-view"
  template: template
