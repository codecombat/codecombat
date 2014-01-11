SaveVersionModal = require 'views/modal/save_version_modal'
template = require 'templates/editor/level/save'
forms = require 'lib/forms'
LevelComponent = require 'models/LevelComponent'
LevelSystem = require 'models/LevelSystem'

module.exports = class LevelSaveView extends SaveVersionModal
  template: template
  instant: false
  modalWidthPercent: 60

  events:
    'click #save-version-button': 'commitLevel'
    'submit form': 'commitLevel'

  constructor: (options) ->
    super options
    @level = options.level
    @originalLevelAttributes = options.originalLevelAttributes
    @levelNeedsSave = not _.isEqual @level.attributes, @originalLevelAttributes

  getRenderData: (context={}) =>
    context = super(context)
    context.level = @level
    context.levelNeedsSave = @levelNeedsSave
    context.modifiedComponents = _.filter @supermodel.getModels(LevelComponent), @shouldSaveEntity
    context.modifiedSystems = _.filter @supermodel.getModels(LevelSystem), @shouldSaveEntity
    context

  shouldSaveEntity: (m) ->
    return true if m.hasLocalChanges()
    return true if (m.get('version').major is 0 and m.get('version').minor is 0) or not m.isPublished() and not m.collection
    # Sometimes we have two versions: one in a search collection and one with a URL. We only save changes to the latter.
    false

  commitLevel: ->
    modelsToSave = []
    @showLoading()
    for form in @$el.find('form')
      # Level form is first, then LevelComponents' forms, then LevelSystems' forms
      fields = {}
      for field in $(form).serializeArray()
        fields[field.name] = if field.value is "on" then true else field.value
      isLevelForm = $(form).attr('id') is 'save-level-form'
      if isLevelForm
        model = @level
      else
        [kind, klass] = if $(form).hasClass 'component-form' then ['component', LevelComponent] else ['system', LevelSystem]
        model = @supermodel.getModelByOriginalAndMajorVersion klass, fields["#{kind}-original"], parseInt(fields["#{kind}-parent-major-version"], 10)
        console.log "Couldn't find model for", kind, fields, "from", @supermodel.models unless model
      newModel = if fields.major then model.cloneNewMajorVersion() else model.cloneNewMinorVersion()
      newModel.set 'commitMessage', fields['commit-message']
      modelsToSave.push newModel
      if isLevelForm
        @level = newModel
        if fields['publish'] and not @level.isPublished()
          @level.publish()
      else if @level.isPublished() and not newModel.isPublished()
        newModel.publish()  # Publish any LevelComponents that weren't published yet

      res = newModel.save()
      do (newModel, form) =>
        res.error =>
          @hideLoading()
          console.log "Got errors:", JSON.parse(res.responseText)
          forms.applyErrorsToForm($(form), JSON.parse(res.responseText))
        res.success =>
          @hide()
          modelsToSave = _.without modelsToSave, newModel
          unless modelsToSave.length
            url = "/editor/level/#{@level.get('slug') or @level.id}"
            document.location.href = url
