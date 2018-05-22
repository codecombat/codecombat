require('app/styles/privacy.sass')
RootView = require 'views/core/RootView'
template = require 'templates/privacy'

module.exports = class PrivacyView extends RootView
  id: 'privacy-view'
  template: template
