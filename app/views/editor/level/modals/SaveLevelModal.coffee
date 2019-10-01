SaveVersionModal = require 'views/editor/modal/SaveVersionModal'
template = require 'templates/editor/level/save-level-modal'
forms = require 'core/forms'
LevelComponent = require 'models/LevelComponent'
LevelSystem = require 'models/LevelSystem'
DeltaView = require 'views/editor/DeltaView'
PatchModal = require 'views/editor/PatchModal'
deltasLib = require 'core/deltas'
VerifierTest = require 'views/editor/verifier/VerifierTest'
SuperModel = require 'models/SuperModel'

module.exports = class SaveLevelModal extends SaveVersionModal
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
    @buildTime = options.buildTime
    @commitMessage = options.commitMessage ? ""

  getRenderData: (context={}) ->
    context = super(context)
    context.level = @level
    context.levelNeedsSave = @level.hasLocalChanges()
    context.modifiedComponents = _.filter @supermodel.getModels(LevelComponent), @shouldSaveEntity
    context.modifiedSystems = _.filter @supermodel.getModels(LevelSystem), @shouldSaveEntity
    context.commitMessage = @commitMessage
    @hasChanges = (context.levelNeedsSave or context.modifiedComponents.length or context.modifiedSystems.length)
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
        deltaView = new DeltaView({model: model, skipPaths: deltasLib.DOC_SKIP_PATHS})
        @insertSubView(deltaView, $(changeEl))
      catch e
        console.error 'Couldn\'t create delta view:', e
    @verify() if me.isAdmin()

  shouldSaveEntity: (m) ->
    return false unless m.hasWriteAccess()
    if m.get('system') is 'ai' and m.get('name') is 'Jitters' and m.type() is 'LevelComponent'
      # Trying to debug the occasional phantom all-Components-must-be-saved bug
      console.log "Should we save", m.get('system'), m.get('name'), m, "? localChanges:", m.hasLocalChanges(), "version:", m.get('version'), 'isPublished:', m.isPublished(), 'collection:', m.collection
      return false
    return true if m.hasLocalChanges()
    console.error "Trying to check major version of #{m.type()} #{m.get('name')}, but it doesn't have a version:", m unless m.get('version')
    return true if (m.get('version').major is 0 and m.get('version').minor is 0) or not m.isPublished() and not m.collection
    # Sometimes we have two versions: one in a search collection and one with a URL. We only save changes to the latter.
    false

  commitLevel: (e) ->
    e.preventDefault()
    @level.set 'buildTime', @buildTime
    modelsToSave = []
    formsToSave = []
    for form in @$el.find('form')
      # Level form is first, then LevelComponents' forms, then LevelSystems' forms
      fields = {}
      for field in $(form).serializeArray()
        fields[field.name] = if field.value is 'on' then true else field.value
      isLevelForm = $(form).attr('id') is 'save-level-form'
      if isLevelForm
        model = @level
      else
        [kind, klass] = if $(form).hasClass 'component-form' then ['component', LevelComponent] else ['system', LevelSystem]
        model = @supermodel.getModelByOriginalAndMajorVersion klass, fields["#{kind}-original"], parseInt(fields["#{kind}-parent-major-version"], 10)
        console.log 'Couldn\'t find model for', kind, fields, 'from', @supermodel.models unless model
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
      newModel.updateI18NCoverage() if newModel.get('i18nCoverage')
      res = newModel.save(null, {type: 'POST'})  # Override PUT so we can trigger postNewVersion logic
      do (newModel, form) =>
        res.error =>
          @hideLoading()
          console.log 'Got errors:', JSON.parse(res.responseText)
          forms.applyErrorsToForm($(form), JSON.parse(res.responseText))
        res.success =>
          modelsToSave = _.without modelsToSave, newModel
          oldModel = _.find @supermodel.models, (m) -> m.get('original') is newModel.get('original')
          oldModel.clearBackup()  # Otherwise looking at old versions is confusing.
          unless modelsToSave.length
            url = "/editor/level/#{@level.get('slug') or @level.id}"
            document.location.href = url
            @hide()  # This will destroy everything, so do it last

  verify: ->
    return @$('#verifier-stub').hide() unless (solutions = @level.getSolutions()) and solutions.length
    @running = @problems = @failed = @passedExceptFrames = @passed = 0
    @waiting = solutions.length
    @renderSelectors '#verifier-tests'
    for solution in solutions
      childSupermodel = new SuperModel()
      childSupermodel.models = _.clone @supermodel.models
      childSupermodel.collections = _.clone @supermodel.collections
      test = new VerifierTest @level.get('slug'), @onVerifierTestUpate, childSupermodel, solution.language, {devMode: true, solution}

  onVerifierTestUpate: (e) =>
    return if @destroyed
    if e.state is 'running'
      --@waiting
      ++@running
    else if e.state in ['complete', 'error', 'no-solution']
      --@running
      if e.state is 'complete'
        if e.test.isSuccessful true
          ++@passed
        else if e.test.isSuccessful false
          ++@passedExceptFrames
        else
          ++@failed
      else if e.state is 'no-solution'
        console.warn 'Solution problem for', e.test.language
        ++@problems
      else
        ++@problems
    @renderSelectors '#verifier-tests'
