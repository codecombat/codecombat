require('app/styles/editor/standards/edit.sass')
RootView = require 'views/core/RootView'
template = require 'app/templates/editor/standards/edit'
StandardsCorrelation = require 'models/StandardsCorrelation'
ConfirmModal = require 'views/core/ConfirmModal'
PatchesView = require 'views/editor/PatchesView'
errors = require 'core/errors'
nodes = require 'views/editor/level/treema_nodes'

require 'lib/game-libraries'
require('lib/setupTreema')
treemaExt = require 'core/treema-ext'

Concepts = require 'collections/Concepts'
schemas = require 'app/schemas/schemas'
concepts = []

module.exports = class StandardsCorrelationEditView extends RootView
  id: 'editor-standards-edit-view'
  template: template

  events:
    'click #save-button': 'onClickSaveButton'
    'click #i18n-button': 'onPopulateI18N'

  constructor: (options, @standardsID) ->
    super options
    @standards = new StandardsCorrelation(_id: @standardsID)
    @standards.saveBackups = true
    @supermodel.loadModel @standards

  onLoaded: ->
    super()
    @concepts = new Concepts([])

    @listenTo @concepts, 'sync', =>
      concepts = @concepts.models
      schemas.concept.enum = _.map concepts, (c) -> c.get('key')
      @onConceptsLoaded()
    
    @concepts.fetch
      data: { skip: 0, limit: 1000 }

  onConceptsLoaded: () ->
    @buildTreema()
    @listenTo @standards, 'change', =>
      @standards.updateI18NCoverage()
      @treema.set('/', @standards.attributes)

  buildTreema: ->
    return if @treema? or (not @standards.loaded)
    data = $.extend(true, {}, @standards.attributes)
    options =
      data: data
      filePath: "db/standards/#{@standards.get('_id')}"
      schema: StandardsCorrelation.schema
      readOnly: me.get('anonymous')
      supermodel: @supermodel
      nodeClasses:
        'concepts-list': nodes.conceptNodes(concepts).ConceptsListNode
        'concept': nodes.conceptNodes(concepts).ConceptNode
    @treema = @$el.find('#standards-treema').treema(options)
    @treema.build()
    @treema.childrenTreemas.rewards?.open(3)

  afterRender: ->
    super()
    return unless @supermodel.finished()
    @showReadOnly() if me.get('anonymous')
    @patchesView = @insertSubView(new PatchesView(@standards), @$el.find('.patches-view'))
    @patchesView.load()

  onPopulateI18N: ->
    @standards.populateI18N()

  onClickSaveButton: (e) ->
    @treema.endExistingEdits()
    for key, value of @treema.data
      @standards.set(key, value)
    @standards.updateI18NCoverage()

    res = @standards.save()

    res.error (collection, response, options) =>
      console.error response

    res.success =>
      url = "/editor/standards/#{@standards.get('slug') or @standards.id}"
      document.location.href = url