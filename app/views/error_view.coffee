View = require 'views/kinds/RootView'
template = require 'templates/error'

module.exports = class ErrorView extends View
  id: 'error-view'
  template: template
