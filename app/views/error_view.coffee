RootView = require 'views/kinds/RootView'
template = require 'templates/error'

module.exports = class ErrorView extends RootView
  id: 'error-view'
  template: template
