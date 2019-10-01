require('app/styles/editor/level/add-thangs-view.sass')
CocoView = require 'views/core/CocoView'
add_thangs_template = require 'templates/editor/level/add-thangs-view'
ThangType = require 'models/ThangType'
CocoCollection = require 'collections/CocoCollection'

PAGE_SIZE = 1000

class ThangTypeSearchCollection extends CocoCollection
  url: '/db/thang.type?project=original,name,version,description,slug,kind,rasterIcon'
  model: ThangType

  addTerm: (term) ->
    @url += "&term=#{term}" if term

module.exports = class AddThangsView extends CocoView
  id: 'add-thangs-view'
  className: 'add-thangs-palette'
  template: add_thangs_template

  events:
    'keyup input#thang-search': 'runSearch'

  constructor: (options) ->
    super options
    @world = options.world

    @thangTypes = new Backbone.Collection()
    thangTypeCollection = new ThangTypeSearchCollection([])
    thangTypeCollection.fetch({data: {limit: PAGE_SIZE}})
    thangTypeCollection.skip = 0
    # should load depended-on Components, too
    @supermodel.loadCollection(thangTypeCollection, 'thangs')
    @listenTo thangTypeCollection, 'sync', @onThangCollectionSynced

  onThangCollectionSynced: (collection) ->
    getMore = collection.models.length is PAGE_SIZE
    @thangTypes.add(collection.models)
    @render()
    if getMore
      collection.skip += PAGE_SIZE
      collection.fetch({data: {skip: collection.skip, limit: PAGE_SIZE}})
      @supermodel.loadCollection(collection, 'thangs')


  getRenderData: (context={}) ->
    context = super(context)
    if @searchModels
      models = @searchModels
    else
      models = @supermodel.getModels(ThangType)

    thangTypes = _.uniq models, false, (thangType) -> thangType.get('original')
    thangTypes = _.reject thangTypes, (thangType) -> thangType.get('kind') in ['Mark', 'Item', undefined]
    groupMap = {}
    for thangType in thangTypes
      kind = thangType.get('kind')
      groupMap[kind] ?= []
      groupMap[kind].push thangType

    groups = []
    for groupName in Object.keys(groupMap).sort()
      someThangTypes = groupMap[groupName]
      someThangTypes = _.sortBy someThangTypes, (thangType) -> thangType.get('name')
      group =
        name: groupName
        thangs: someThangTypes
      groups.push group

    groups = _.sortBy groups, (group) ->
      index = ['Wall', 'Floor', 'Unit', 'Doodad', 'Misc'].indexOf group.name
      if index is -1 then 9001 else index

    context.thangTypes = thangTypes
    context.groups = groups
    context

  afterRender: ->
    super()
    @buildAddThangPopovers()

  buildAddThangPopovers: ->
    @$el.find('#thangs-list .add-thang-palette-icon').addClass('has-tooltip').tooltip(container: 'body', animation: false)

  runSearch: (e) =>
    if e?.which is 27
      @onEscapePressed()
    term = @$el.find('input#thang-search').val()
    return unless term isnt @lastSearch

    @searchModels = @thangTypes.filter (model) ->
      return true unless term
      regExp = new RegExp term, 'i'
      return model.get('name').match regExp
    @render()
    @$el.find('input#thang-search').focus().val(term)
    @lastSearch = term

  onEscapePressed: ->
    @$el.find('input#thang-search').val('')
    @runSearch()
