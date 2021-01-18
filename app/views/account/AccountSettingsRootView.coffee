require('app/styles/account/account-settings-view.sass')
RootView = require 'views/core/RootView'
template = require 'templates/account/account-settings-root-view'
AccountSettingsView = require './AccountSettingsView'
CreateAccountModal = require 'views/core/CreateAccountModal'

module.exports = class AccountSettingsRootView extends RootView
  id: "account-settings-root-view"
  template: template

  getMeta: ->
    title: $.i18n.t 'account.settings_title'

  shortcuts:
    'enter': -> @

  afterRender: ->
    super()
    @accountSettingsView = new AccountSettingsView()
    @insertSubView(@accountSettingsView)

  afterInsert: ->
    @openModalView new CreateAccountModal() if me.get('anonymous')
