RootView = require 'views/core/RootView'
template = require 'templates/about'

module.exports = class AboutView extends RootView
  id: 'about-view'
  template: template

  logoutRedirectURL: false