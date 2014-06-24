View = require 'views/kinds/RootView'
template = require 'templates/not_found'

module.exports = class NotFoundView extends View
  id: 'not-found-view'
  template: template
