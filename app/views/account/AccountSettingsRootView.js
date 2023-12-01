// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let AccountSettingsRootView
require('app/styles/account/account-settings-view.sass')
const RootView = require('views/core/RootView')
const template = require('app/templates/account/account-settings-root-view')
const AccountSettingsView = require('./AccountSettingsView')
const CreateAccountModal = require('views/core/CreateAccountModal')

module.exports = (AccountSettingsRootView = (function () {
  AccountSettingsRootView = class AccountSettingsRootView extends RootView {
    static initClass () {
      this.prototype.id = 'account-settings-root-view'
      this.prototype.template = template

      this.prototype.shortcuts =
        { 'enter' () { return this } }
    }

    getMeta () {
      return { title: $.i18n.t('account.settings_title') }
    }

    afterRender () {
      super.afterRender()
      this.accountSettingsView = new AccountSettingsView()
      return this.insertSubView(this.accountSettingsView)
    }

    afterInsert () {
      super.afterInsert()
      if (me.get('anonymous')) { return this.openModalView(new CreateAccountModal()) }
    }
  }
  AccountSettingsRootView.initClass()
  return AccountSettingsRootView
})())
