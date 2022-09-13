require('app/styles/not_found.sass')
RootView = require 'views/core/RootView'
template = require 'app/templates/core/not-found'

module.exports = class NotFoundView extends RootView
  id: 'not-found-view'
  template: template
