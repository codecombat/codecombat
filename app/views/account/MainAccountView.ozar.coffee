require('app/styles/account/main-account-view.sass')
RootView = require 'views/core/RootView'
template = require 'templates/account/main-account-view'

module.exports = class MainAccountView extends RootView
  id: 'main-account-view'
  template: template

  events:
    'click .logout-btn': 'logoutAccount'

  getMeta: ->
    title: $.i18n.t 'account.title'
