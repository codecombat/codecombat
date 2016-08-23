I18NEditModelView = require './I18NEditModelView'
Course = require 'models/Course'
deltasLib = require 'core/deltas'
Patch = require 'models/Patch'
Patches = require 'collections/Patches'
PatchModal = require 'views/editor/PatchModal'

# TODO: Apply these changes to all i18n views if it proves to be more reliable

module.exports = class I18NEditCourseView extends I18NEditModelView
  id: "i18n-edit-course-view"
  modelClass: Course
  
  events:
    'click .open-patch-link': 'onClickOpenPatchLink'
  
  constructor: ->
    super(arguments...)
    @model.saveBackups = false
    @madeChanges = false
    @patches = new Patches()
    @patches.comparator = '_id'
    @supermodel.trackRequest(@patches.fetchMineFor(@model))
    
  onLoaded: ->
    super(arguments...)
    @originalModel = @model.clone()

  buildTranslationList: ->
    lang = @selectedLanguage

    # name, description
    if i18n = @model.get('i18n')
      if name = @model.get('name')
        @wrapRow 'Course short name', ['name'], name, i18n[lang]?.name, []
      if description = @model.get('description')
        @wrapRow 'Course description', ['description'], description, i18n[lang]?.description, []

  onTranslationChanged: ->
    super(arguments...)
    @madeChanges = true

  onClickOpenPatchLink: (e) ->
    patchID = $(e.currentTarget).data('patch-id')
    patch = @patches.get(patchID)
    modal = new PatchModal(patch, @model)
    @openModalView(modal)

  onLeaveMessage: ->
    if @madeChanges
      return 'You have unsaved changes!'

  onLanguageSelectChanged: ->
    if @madeChanges
      return unless confirm('You have unsaved changes!')
    super(arguments...)
    @madeChanges = false
    @model.set(@originalModel.clone().attributes)

  onSubmitPatch: (e) ->

    delta = @model.getDelta()
    flattened = deltasLib.flattenDelta(delta)
    
    patch = new Patch({
      delta
      target: {
        'collection': _.string.underscored @model.constructor.className
        'id': @model.id
      }
      commitMessage: "Diplomat submission for lang #{@selectedLanguage}: #{flattened.length} change(s)."
    })
    errors = patch.validate()
    button = $(e.target)
    button.attr('disabled', 'disabled')
    return button.text('Failed to Submit Changes') if errors
    res = patch.save(null, {
      url: "/db/course/#{@model.id}/patch"
    })
    return button.text('Failed to Submit Changes') unless res
    button.text('Submitting...')
    Promise.resolve(res)
      .then =>
        @savedBefore = true
        @madeChanges = false
        @patches.add(patch)
        @renderSelectors('#patches-col')
        button.text('Submit Changes')
      .catch =>
        button.text('Error Submitting Changes')
      
