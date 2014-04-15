ModalView = require 'views/kinds/ModalView'
template = require 'templates/modal/save_version'
DeltaView = require 'views/editor/delta'
Patch = require 'models/Patch'
forms = require 'lib/forms'

module.exports = class SaveVersionModal extends ModalView
  id: 'save-version-modal'
  template: template
  plain: true

  events:
    'click #save-version-button': 'onClickSaveButton'
    'click #cla-link': 'onClickCLALink'
    'click #agreement-button': 'onAgreedToCLA'
    'click #submit-patch-button': 'onClickPatchButton'

  constructor: (options) ->
    super options
    @model = options.model or options.level
    new Patch() # hack to get the schema to load, delete this later
    @isPatch = not @model.hasWriteAccess()

  getRenderData: ->
    c = super()
    c.isPatch = @isPatch
    c.hasChanges = @model.hasLocalChanges()
    c

  afterRender: ->
    super()
    @$el.find(if me.get('signedCLA') then '#accept-cla-wrapper' else '#save-version-button').hide()
    changeEl = @$el.find('.changes-stub')
    try
      deltaView = new DeltaView({model:@model})
      @insertSubView(deltaView, changeEl)
    catch e
      console.error "Couldn't create delta view:", e
    @$el.find('.commit-message input').attr('placeholder', $.i18n.t('general.commit_msg'))

  onClickSaveButton: ->
    Backbone.Mediator.publish 'save-new-version', {
      major: @$el.find('#major-version').prop('checked')
      commitMessage: @$el.find('#commit-message').val()
    }

  onClickPatchButton: ->
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

    res.error =>
      @disableModalInProgress(@$el)

    res.success =>
      @hide()

  onClickCLALink: ->
    window.open('/cla', 'cla', 'height=800,width=900')

  onAgreedToCLA: ->
    @$el.find('#agreement-button').text('Saving').prop('disabled', true)
    $.ajax({
      url: "/db/user/me/agreeToCLA"
      method: 'POST'
      success: @onAgreeSucceeded
      error: @onAgreeFailed
    })

  onAgreeSucceeded: =>
    @$el.find('#agreement-button').text('Thanks!')
    @$el.find('#save-version-button').show()

  onAgreeFailed: =>
    @$el.find('#agreement-button').text('Failed').prop('disabled', false)
