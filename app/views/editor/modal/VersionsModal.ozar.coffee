ModalView = require 'views/core/ModalView'
template = require 'templates/editor/modal/versions-modal'
DeltaView = require 'views/editor/DeltaView'
PatchModal = require 'views/editor/PatchModal'
nameLoader = require 'core/NameLoader'
CocoCollection = require 'collections/CocoCollection'
deltasLib = require 'core/deltas'

class VersionsViewCollection extends CocoCollection
  url: ''
  model: null

  initialize: (@url, @levelID, @model) ->
    super()
    @url = @url + @levelID + '/versions'

module.exports = class VersionsModal extends ModalView
  template: template
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
    @original = new @model(_id: @ID)
    @original = @supermodel.loadModel(@original).model
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
    @deltaView = new DeltaView({
      model: earlierVersion
      comparisonModel: laterVersion
      skipPaths: deltasLib.DOC_SKIP_PATHS
      loadModels: true
    })
    @insertSubView(@deltaView, deltaEl)

  getRenderData: (context={}) ->
    context = super(context)
    context.page = @page
    if @versions
      context.dataList = (m.attributes for m in @versions.models)
      for version in context.dataList
        version.creator = nameLoader.getName(version.creator)
    context
