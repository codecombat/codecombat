ModalView = require 'views/core/ModalView'
template = require 'templates/editor/modal/save-version-modal'
DeltaView = require 'views/editor/DeltaView'
Patch = require 'models/Patch'
forms = require 'core/forms'

module.exports = class SaveVersionModal extends ModalView
  id: 'save-version-modal'
  template: template
  plain: true
  modalWidthPercent: 60

  events:
    'click #save-version-button': 'saveChanges'
    'click #cla-link': 'onClickCLALink'
    'click #agreement-button': 'onAgreedToCLA'
    'click #submit-patch-button': 'submitPatch'
    'submit form': 'onSubmitForm'

  constructor: (options) ->
    super options
    @model = options.model or options.level
    @isPatch = not @model.hasWriteAccess()
    @hasChanges = @model.hasLocalChanges()

  afterRender: (insertDeltaView=true) ->
    super()
    @$el.find(if me.get('signedCLA') then '#accept-cla-wrapper' else '#save-version-button').hide()
    changeEl = @$el.find('.changes-stub')
    if insertDeltaView
      try
        deltaView = new DeltaView({model: @model})
        @insertSubView(deltaView, changeEl)
      catch e
        console.error 'Couldn\'t create delta view:', e, e.stack
    @$el.find('.commit-message input').attr('placeholder', $.i18n.t('general.commit_msg'))

  onSubmitForm: (e) ->
    e.preventDefault()
    if @isPatch then @submitPatch() else @saveChanges()

  saveChanges: ->
    @trigger 'save-new-version', {
      major: @$el.find('#major-version').prop('checked')
      commitMessage: @$el.find('#commit-message').val()
    }

  submitPatch: ->
    @savingPatchError = false
    forms.clearFormAlerts @$el
    patch = new Patch()
    patch.set 'delta', @model.getDelta()
    patch.set 'commitMessage', @$el.find('#commit-message').val()
    patch.set 'target', {
      'collection': _.string.underscored @model.constructor.className
      'id': @model.id
    }
    errors = patch.validate()
    forms.applyErrorsToForm(@$el, errors) if errors
    res = patch.save()
    return unless res
    @enableModalInProgress(@$el)

    res.error (jqxhr) =>
      @disableModalInProgress(@$el)
      @savingPatchError = jqxhr.responseJSON?.message or 'Unknown error.'
      @renderSelectors '.save-error-area'

    res.success =>
      @hide()

  onClickCLALink: ->
    window.open('/cla', 'cla', 'height=800,width=900')

  onAgreedToCLA: ->
    @$el.find('#agreement-button').text('Saving').prop('disabled', true)
    $.ajax({
      url: '/db/user/me/agreeToCLA'
      method: 'POST'
      success: @onAgreeSucceeded
      error: @onAgreeFailed
    })

  onAgreeSucceeded: =>
    @$el.find('#agreement-button').text('Thanks!')
    @$el.find('#save-version-button').show()

  onAgreeFailed: =>
    @$el.find('#agreement-button').text('Failed').prop('disabled', false)
