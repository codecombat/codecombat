View = require 'views/kinds/CocoView'
add_thangs_template = require 'templates/editor/level/add_thangs'
ThangType = require 'models/ThangType'
CocoCollection = require 'models/CocoCollection'

class ThangTypeSearchCollection extends CocoCollection
  url: '/db/thang.type/search?project=true'
  model: ThangType

  addTerm: (term) ->
    @url += "&term=#{term}" if term

module.exports = class AddThangsView extends View
  id: "add-thangs-column"
  className: 'add-thangs-palette thangs-column'
  template: add_thangs_template
  startsLoading: false

  events:
    'keyup input#thang-search': 'runSearch'

  constructor: (options) ->
    super options
    @world = options.world
    @thangTypes = @supermodel.getCollection new ThangTypeSearchCollection()  # should load depended-on Components, too
    @thangTypes.once 'sync', @onThangTypesLoaded
    @thangTypes.fetch()

  onThangTypesLoaded: =>
    return if @destroyed
    @render()  # do it again but without the loading screen

  getRenderData: (context={}) ->
    context = super(context)
    if @searchModels
      models = @searchModels
    else
      models = @supermodel.getModels(ThangType)

    thangTypes = (thangType.attributes for thangType in models)
    thangTypes = _.uniq thangTypes, false, 'original'
    thangTypes = _.reject thangTypes, kind: 'Mark'
    groupMap = {}
    for thangType in thangTypes
      groupMap[thangType.kind] ?= []
      groupMap[thangType.kind].push thangType

    groups = []
    for groupName in Object.keys(groupMap).sort()
      someThangTypes = groupMap[groupName]
      someThangTypes = _.sortBy someThangTypes, 'name'
      group =
        name: groupName
        thangs: someThangTypes
      groups.push group

    context.thangTypes = thangTypes
    context.groups = groups
    context

  afterRender: ->
    return if @startsLoading
    super()

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
    @$el.find('input#thang-search').val("")
    @runSearch