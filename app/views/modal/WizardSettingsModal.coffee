ModalView = require 'views/kinds/ModalView'
template = require 'templates/modal/wizard_settings'
WizardSprite = require 'lib/surface/WizardSprite'
ThangType = require 'models/ThangType'
{me} = require 'lib/auth'
forms = require 'lib/forms'
User = require 'models/User'

module.exports = class WizardSettingsModal extends ModalView
  id: 'wizard-settings-modal'
  template: template
  closesOnClickOutside: false

  events:
    'keyup #wizard-settings-name': -> @trigger 'nameChanged'
    'click #wizard-settings-done': 'onWizardSettingsDone'

  constructor: (options) ->
    @onNameChange = _.debounce(@checkNameExists, 500)
    @on 'nameChanged', @onNameChange
    super options

  afterRender: ->
    WizardSettingsView = require 'views/account/WizardSettingsView'
    view = new WizardSettingsView()
    @insertSubView view
    super()

  checkNameExists: =>
    forms.clearFormAlerts(@$el)
    name = $('#wizard-settings-name').val()
    User.getUnconflictedName name, (newName) =>
      forms.clearFormAlerts(@$el)
      if name isnt newName
        forms.setErrorToProperty @$el, 'name', 'This name is already taken so you won\'t be able to keep it.', true

  onWizardSettingsDone: ->
    me.set('name', $('#wizard-settings-name').val())
    forms.clearFormAlerts(@$el)
    res = me.validate()
    if res?
      forms.applyErrorsToForm(@$el, res)
      return

    res = me.patch()
    return unless res
    save = $('#save-button', @$el).text($.i18n.t('common.saving', defaultValue: 'Saving...'))
      .addClass('btn-info').show().removeClass('btn-danger')

    res.error =>
      errors = JSON.parse(res.responseText)
      console.warn 'Got errors saving user:', errors
      forms.applyErrorsToForm(@$el, errors)
      @disableModalInProgress(@$el)

    res.success (model, response, options) =>
      @hide()

    @enableModalInProgress(@$el)
