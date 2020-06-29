require('app/styles/account/account-settings-view.sass')
RootView = require 'views/core/RootView'
template = require 'templates/account/account-settings-root-view'
AccountSettingsView = require './AccountSettingsView'
CreateAccountModal = require 'views/core/CreateAccountModal'

module.exports = class AccountSettingsRootView extends RootView
  id: "account-settings-root-view"
  template: template

  events:
    'click #save-button': -> @accountSettingsView.save()

  getMeta: ->
    title: $.i18n.t 'account.settings_title'

  shortcuts:
    'enter': -> @

  afterRender: ->
    super()
    @accountSettingsView = new AccountSettingsView()
    @insertSubView(@accountSettingsView)
    @listenTo @accountSettingsView, 'input-changed', @onInputChanged
    @listenTo @accountSettingsView, 'save-user-began', @onUserSaveBegan
    @listenTo @accountSettingsView, 'save-user-success', @onUserSaveSuccess
    @listenTo @accountSettingsView, 'save-user-error', @onUserSaveError

  afterInsert: ->
    @openModalView new CreateAccountModal() if me.get('anonymous')

  onInputChanged: ->
    @$el.find('#save-button')
      .text($.i18n.t('common.save', defaultValue: 'Save'))
      .addClass 'btn-info'
      .removeClass 'disabled btn-danger'
      .removeAttr 'disabled'

  onUserSaveBegan: ->
    @$el.find('#save-button')
      .text($.i18n.t('common.saving', defaultValue: 'Saving...'))
      .removeClass('btn-danger')
      .addClass('btn-success').show()

  onUserSaveSuccess: ->
    @$el.find('#save-button')
      .text($.i18n.t('account_settings.saved', defaultValue: 'Changes Saved'))
      .removeClass('btn-success btn-info', 1000)
      .attr('disabled', 'true')

  onUserSaveError: ->
    @$el.find('#save-button')
      .text($.i18n.t('account_settings.error_saving', defaultValue: 'Error Saving'))
      .removeClass('btn-success')
      .addClass('btn-danger', 500)
