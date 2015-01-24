RootView = require 'views/core/RootView'
template = require 'templates/legal'

module.exports = class LegalView extends RootView
  id: 'legal-view'
  template: template
