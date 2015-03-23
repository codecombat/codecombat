ModalView = require 'views/core/ModalView'
template = require 'templates/editor/fork-modal'
forms = require 'core/forms'

module.exports = class ForkModal extends ModalView
  id: 'fork-modal'
  template: template
  instant: false

  events:
    'click #fork-model-confirm-button': 'forkModel'
    'submit form': 'forkModel'

  constructor: (options) ->
    super options
    @editorPath = options.editorPath  # like 'level' or 'thang'
    @model = options.model
    @modelClass = @model.constructor

  forkModel: (e) ->
    e.preventDefault()
    @showLoading()
    forms.clearFormAlerts(@$el)
    newModel = new @modelClass($.extend(true, {}, @model.attributes))
    newModel.unset '_id'
    newModel.unset 'version'
    newModel.unset 'creator'
    newModel.unset 'created'
    newModel.unset 'original'
    newModel.unset 'parent'
    newModel.unset 'i18n'
    newModel.unset 'i18nCoverage'
    newModel.set 'commitMessage', "Forked from #{@model.get('name')}"
    newModel.set 'name', @$el.find('#fork-model-name').val()
    if @model.schema().properties.permissions
      newModel.set 'permissions', [access: 'owner', target: me.id]
    newPathPrefix = "editor/#{@editorPath}/"
    res = newModel.save(null, {type: 'POST'})  # Override PUT so we can trigger postFirstVersion logic
    return unless res
    res.error =>
      @hideLoading()
      forms.applyErrorsToForm(@$el.find('form'), JSON.parse(res.responseText))
    res.success =>
      @hide()
      application.router.navigate(newPathPrefix + newModel.get('slug'), {trigger: true})
