ModalView = require 'views/kinds/ModalView'
template = require 'templates/modal/versions'
tableTemplate = require 'templates/kinds/table'
DeltaView = require 'views/editor/delta'
PatchModal = require 'views/editor/patch_modal'

class VersionsViewCollection extends Backbone.Collection
  url: ""
  model: null

  initialize: (@url, @levelID, @model) ->
    @url = url + levelID + '/versions'
    @model = model

module.exports = class VersionsModalView extends ModalView
  template: template
  startsLoading: true
  plain: true
  modalWidthPercent: 80

  # needs to be overwritten by child
  id: ""
  url: ""
  page: ""
  
  events:
    'change input.select': 'onSelectionChanged'

  constructor: (options, @ID, @model) ->
    super options
    @view = new model(_id: @ID)
    @view.fetch()
    @listenToOnce(@view, 'sync', @onViewSync)

  onViewSync: ->
    @collection = new VersionsViewCollection(@url, @view.attributes.original, @model)
    @collection.fetch()
    @listenTo(@collection, 'sync', @onVersionFetched)

  onVersionFetched: ->
    @startsLoading = false
    @render()

  onSelectionChanged: ->
    rows = @$el.find 'input.select:checked'
    deltaEl = @$el.find '.delta-view'
    @removeSubView(@deltaView) if @deltaView
    @deltaView = null
    if rows.length isnt 2 then return 
    
    laterVersion = new @model(_id:$(rows[0]).val())
    earlierVersion = new @model(_id:$(rows[1]).val())
    @deltaView = new DeltaView({model:earlierVersion, comparisonModel:laterVersion, skipPaths:PatchModal.DOC_SKIP_PATHS})
    @insertSubView(@deltaView, deltaEl)

  getRenderData: (context={}) ->
    context = super(context)
    context.page = @page
    context.dataList = (m.attributes for m in @collection.models) if @collection
    context
