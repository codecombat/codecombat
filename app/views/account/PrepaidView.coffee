RootView = require 'views/core/RootView'
template = require 'templates/account/prepaid-view'

module.exports = class PrepaidView extends RootView
  id: 'prepaid-view'
  template: template