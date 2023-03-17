require('app/styles/editor/concept/edit.sass')
RootView = require 'views/core/RootView'
template = require 'app/templates/editor/concept/edit'
Concept = require 'models/Concept'
ConfirmModal = require 'views/core/ConfirmModal'
PatchesView = require 'views/editor/PatchesView'
errors = require 'core/errors'

require 'lib/game-libraries'
require('lib/setupTreema')
treemaExt = require 'core/treema-ext'

module.exports = class ConceptEditView extends RootView
  id: 'editor-concept-edit-view'
  template: template

  events:
    'click #save-button': 'onClickSaveButton'
    'click #i18n-button': 'onPopulateI18N'

  constructor: (options, @conceptID) ->
    super options
    @concept = new Concept(_id: @conceptID)
    @concept.saveBackups = true
    @supermodel.loadModel @concept

  onLoaded: ->
    super()
    @buildTreema()
    @listenTo @concept, 'change', =>
      @concept.updateI18NCoverage()
      @treema.set('/', @concept.attributes)

  buildTreema: ->
    return if @treema? or (not @concept.loaded)
    data = $.extend(true, {}, @concept.attributes)
    options =
      data: data
      filePath: "db/concept/#{@concept.get('_id')}"
      schema: Concept.schema
      readOnly: me.get('anonymous')
      supermodel: @supermodel
      nodeClasses: { code: treemaExt.JavaScriptTreema }
    @treema = @$el.find('#concept-treema').treema(options)
    @treema.build()
    @treema.childrenTreemas.rewards?.open(3)

  afterRender: ->
    super()
    return unless @supermodel.finished()
    @showReadOnly() if me.get('anonymous')
    @patchesView = @insertSubView(new PatchesView(@concept), @$el.find('.patches-view'))
    @patchesView.load()

  onPopulateI18N: ->
    @concept.populateI18N()

  onClickSaveButton: (e) ->
    @treema.endExistingEdits()
    for key, value of @treema.data
      @concept.set(key, value)
    @concept.updateI18NCoverage()

    res = @concept.save()

    res.error (collection, response, options) =>
      console.error response

    res.success =>
      url = "/editor/concept/#{@concept.get('slug') or @concept.id}"
      document.location.href = url
