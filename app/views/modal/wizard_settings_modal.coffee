View = require 'views/kinds/ModalView'
template = require 'templates/modal/wizard_settings'
WizardSprite = require 'lib/surface/WizardSprite'
ThangType = require 'models/ThangType'
{me} = require 'lib/auth'
forms = require('lib/forms')

module.exports = class WizardSettingsModal extends View
  id: "wizard-settings-modal"
  template: template
  closesOnClickOutside: false

  events:
    'change #wizard-settings-name': 'onNameChange'
    'click #wizard-settings-done': 'onWizardSettingsDone'

  afterRender: ->
    WizardSettingsView = require 'views/account/wizard_settings_view'
    view = new WizardSettingsView()
    @insertSubView view

  onNameChange: ->
    me.set('name', $('#wizard-settings-name').val())

  onWizardSettingsDone: ->
    forms.clearFormAlerts(@$el)
    res = me.validate()
    if res?
      forms.applyErrorsToForm(@$el, res)
      return

    res = me.save()
    return unless res
    save = $('#save-button', @$el).text($.i18n.t('common.saving', defaultValue: 'Saving...'))
    .addClass('btn-info').show().removeClass('btn-danger')

    res.error =>
      errors = JSON.parse(res.responseText)
      forms.applyErrorsToForm(@$el, errors)
      @disableModalInProgress(@$el)
    res.success (model, response, options) =>
      @hide()

    @enableModalInProgress(@$el)
    me.save()