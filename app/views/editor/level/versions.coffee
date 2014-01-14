View = require 'views/kinds/RootView'
template = require 'templates/editor/level/versions'
tableTemplate = require 'templates/editor/level/table'
Level = require 'models/Level'

class LevelVersionsCollection extends Backbone.Collection
  url: '/db/level/'
  model: Level
  initialize: (@levelID) -> @url += levelID + '/versions'

module.exports = class LevelVersionsView extends View
  id: "editor-level-versions-view"
  template: template
  startsLoading: true

  constructor: (options, @levelID) ->
    super options
    @level = new Level(_id: @levelID)
    @level.fetch()
    @level.once('sync', @onLevelSync)

  onLevelSync: =>
    @collection = new LevelVersionsCollection(@level.attributes.original)
    @collection.fetch()
    @collection.on('sync', @onVersionFetched)

  onVersionFetched: =>
    @startsLoading = false
    @render()

  getRenderData: (context={}) =>
    context = super(context)
    context.levels = (m.attributes for m in @collection.models) if @collection
    context
