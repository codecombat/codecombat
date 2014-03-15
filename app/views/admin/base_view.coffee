View = require 'views/kinds/RootView'
template = require 'templates/base'

module.exports = class BaseView extends View
  id: "base-view"
  template: template
