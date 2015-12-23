ModalView = require 'views/core/ModalView'
template = require 'templates/play/modal/play-account-modal'
AccountSettingsView = require 'views/account/AccountSettingsView'

module.exports = class PlayAccountModal extends ModalView
  className: 'modal fade play-modal'
  template: template
  plain: true
  id: 'play-account-modal'

  events:
    'click #save-button': -> @accountSettingsView.save()

  constructor: (options) ->
    super options

  afterRender: ->
    super()
    return unless @supermodel.finished()
    @playSound 'game-menu-open'
    @accountSettingsView = new AccountSettingsView()
    @insertSubView(@accountSettingsView)
    @listenTo @accountSettingsView, 'input-changed', @onInputChanged
    @listenTo @accountSettingsView, 'save-user-began', @onUserSaveBegan
    @listenTo @accountSettingsView, 'save-user-success', @hide
    @listenTo @accountSettingsView, 'save-user-error', @onUserSaveError

  onHidden: ->
    super()
    @playSound 'game-menu-close'

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

  onUserSaveError: ->
    @$el.find('#save-button')
      .text($.i18n.t('account_settings.error_saving', defaultValue: 'Error Saving'))
      .removeClass('btn-success')
      .addClass('btn-danger', 500)
