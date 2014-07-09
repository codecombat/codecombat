ModalView = require 'views/kinds/ModalView'
template = require 'templates/modal/versions'
tableTemplate = require 'templates/kinds/table'
DeltaView = require 'views/editor/delta'
PatchModal = require 'views/editor/patch_modal'
nameLoader = require 'lib/NameLoader'
CocoCollection = require 'collections/CocoCollection'

class VersionsViewCollection extends CocoCollection
  url: ''
  model: null

  initialize: (@url, @levelID, @model) ->
    super()
    @url = url + levelID + '/versions'
    @model = model

module.exports = class VersionsModalView extends ModalView
  template: template
  startsLoading: true
  plain: true
  modalWidthPercent: 80

  # needs to be overwritten by child
  id: ''
  url: ''
  page: ''

  events:
    'change input.select': 'onSelectionChanged'

  constructor: (options, @ID, @model) ->
    super options
    @original = new model(_id: @ID)
    @original = @supermodel.loadModel(@original, 'document').model
    @listenToOnce(@original, 'sync', @onViewSync)

  onViewSync: ->
    @versions = new VersionsViewCollection(@url, @original.attributes.original, @model)
    @versions = @supermodel.loadCollection(@versions, 'versions').model
    @listenTo(@versions, 'sync', @onVersionsFetched)

  onVersionsFetched: ->
    ids = (p.get('creator') for p in @versions.models)
    jqxhrOptions = nameLoader.loadNames ids
    @supermodel.addRequestResource('user_names', jqxhrOptions).load() if jqxhrOptions

  onSelectionChanged: ->
    rows = @$el.find 'input.select:checked'
    deltaEl = @$el.find '.delta-view'
    @removeSubView(@deltaView) if @deltaView
    @deltaView = null
    if rows.length isnt 2 then return

    laterVersion = new @model(_id: $(rows[0]).val())
    earlierVersion = new @model(_id: $(rows[1]).val())
    @deltaView = new DeltaView({model: earlierVersion, comparisonModel: laterVersion, skipPaths: PatchModal.DOC_SKIP_PATHS})
    @insertSubView(@deltaView, deltaEl)

  getRenderData: (context={}) ->
    context = super(context)
    context.page = @page
    if @versions
      context.dataList = (m.attributes for m in @versions.models)
      for version in context.dataList
        version.creator = nameLoader.getName(version.creator)
    context
