View = require 'views/kinds/RootView'
template = require 'templates/contribute/counselor'
{me} = require('lib/auth')

module.exports = class ArchmageView extends View
  id: "counselor-view"
  template: template
