SaveVersionModal = require 'views/modal/save_version_modal'
template = require 'templates/editor/level/save'
forms = require 'lib/forms'
LevelComponent = require 'models/LevelComponent'
LevelSystem = require 'models/LevelSystem'
DeltaView = require 'views/editor/delta'

module.exports = class LevelSaveView extends SaveVersionModal
  template: template
  instant: false
  modalWidthPercent: 60
  plain: true

  events:
    'click #save-version-button': 'commitLevel'
    'submit form': 'commitLevel'

  constructor: (options) ->
    super options
    @level = options.level

  getRenderData: (context={}) ->
    context = super(context)
    context.level = @level
    context.levelNeedsSave = @level.hasLocalChanges()
    context.modifiedComponents = _.filter @supermodel.getModels(LevelComponent), @shouldSaveEntity
    context.modifiedSystems = _.filter @supermodel.getModels(LevelSystem), @shouldSaveEntity
    context.hasChanges = (context.levelNeedsSave or context.modifiedComponents.length or context.modifiedSystems.length)
    @lastContext = context
    context

  afterRender: ->
    super(false)
    changeEls = @$el.find('.changes-stub')
    models = if @lastContext.levelNeedsSave then [@level] else []
    models = models.concat @lastContext.modifiedComponents
    models = models.concat @lastContext.modifiedSystems
    models = (m for m in models when m.hasWriteAccess())
    for changeEl, i in changeEls
      model = models[i]
      try
        deltaView = new DeltaView({model:model})
        @insertSubView(deltaView, $(changeEl))
      catch e
        console.error "Couldn't create delta view:", e

  shouldSaveEntity: (m) ->
    return false unless m.hasWriteAccess()
    return true if m.hasLocalChanges()
    return true if (m.get('version').major is 0 and m.get('version').minor is 0) or not m.isPublished() and not m.collection
    # Sometimes we have two versions: one in a search collection and one with a URL. We only save changes to the latter.
    false

  commitLevel: ->
    modelsToSave = []
    formsToSave = []
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
      formsToSave.push form
    
    for model in modelsToSave
      if errors = model.getValidationErrors()
        messages = ("\t #{error.dataPath}: #{error.message}" for error in errors)
        messages = messages.join('<br />')
        @$el.find('#errors-wrapper .errors').html(messages)
        @$el.find('#errors-wrapper').removeClass('hide')
        return

    @showLoading()
    tuples = _.zip(modelsToSave, formsToSave)
    for [newModel, form] in tuples
      res = newModel.save()
      do (newModel, form) =>
        res.error =>
          @hideLoading()
          console.log "Got errors:", JSON.parse(res.responseText)
          forms.applyErrorsToForm($(form), JSON.parse(res.responseText))
        res.success =>
          modelsToSave = _.without modelsToSave, newModel
          unless modelsToSave.length
            url = "/editor/level/#{@level.get('slug') or @level.id}"
            document.location.href = url
            @hide()  # This will destroy everything, so do it last
