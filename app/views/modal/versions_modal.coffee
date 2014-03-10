ModalView = require 'views/kinds/ModalView'
template = require 'templates/modal/versions'
tableTemplate = require 'templates/kinds/table'

class VersionsViewCollection extends Backbone.Collection
  url: ""
  model: null

  initialize: (@url, @levelID, @model) ->
    @url = url + levelID + '/versions'
    @model = model

module.exports = class VersionsModalView extends ModalView
  template: template
  startsLoading: true

  # needs to be overwritten by child
  id: ""
  url: ""
  page: ""

  constructor: (options, @ID, @model) ->
    super options
    @view = new model(_id: @ID)
    @view.fetch()
    @view.once('sync', @onViewSync)

  onViewSync: =>
    @collection = new VersionsViewCollection(@url, @view.attributes.original, @model)
    @collection.fetch()
    @collection.on('sync', @onVersionFetched)

  onVersionFetched: =>
    @startsLoading = false
    @render()

  getRenderData: (context={}) ->
    context = super(context)
    context.page = @page
    context.dataList = (m.attributes for m in @collection.models) if @collection
    console.debug context
    context
