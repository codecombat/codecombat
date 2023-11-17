RootView = require 'views/core/RootView'
template = require 'app/templates/base'

module.exports = class BaseView extends RootView
  id: 'base-view'
  template: template
  usesSocialMedia: true
