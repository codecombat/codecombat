View = require 'views/kinds/CocoView'
add_thangs_template = require 'templates/editor/level/add_thangs'
ThangType = require 'models/ThangType'
CocoCollection = require 'collections/CocoCollection'

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

    # should load depended-on Components, too
    @thangTypes = @supermodel.loadCollection(new ThangTypeSearchCollection(), 'thangs').model

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