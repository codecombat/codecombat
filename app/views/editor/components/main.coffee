CocoView = require 'views/kinds/CocoView'
template = require 'templates/editor/components/main'

Level = require 'models/Level'
LevelComponent = require 'models/LevelComponent'
LevelSystem = require 'models/LevelSystem'
ComponentsCollection = require 'collections/ComponentsCollection'
ComponentConfigView = require './config'

module.exports = class ThangComponentEditView extends CocoView
  id: 'thang-components-edit-view'
  template: template

  constructor: (options) ->
    super options
    @components = options.components or []
    @world = options.world
    @level = options.level
    @callback = options.callback
    @componentCollection = @supermodel.loadCollection(new ComponentsCollection(), 'components').model

  afterRender: ->
    super()
    return unless @supermodel.finished()
    @buildExtantComponentTreema()
    @buildAddComponentTreema()

  buildExtantComponentTreema: ->
    level = new Level()
    treemaOptions =
      supermodel: @supermodel
      schema: level.schema().properties.thangs.items.properties.components
      data: _.cloneDeep @components
      callbacks: {select: @onSelectExtantComponent, change: @onChangeExtantComponents}
      noSortable: true
      nodeClasses:
        'thang-components-array': ThangComponentsArrayNode
        'thang-component': ThangComponentNode

    @extantComponentsTreema = @$el.find('#extant-components-column .treema').treema treemaOptions
    @extantComponentsTreema.build()

  buildAddComponentTreema: ->
    return unless @componentCollection and @extantComponentsTreema
    extantComponents = @extantComponentsTreema.data
    componentsUsedCount = extantComponents.length
    return if @lastComponentsUsedCount is componentsUsedCount
    @lastComponentsUsedCount = componentsUsedCount
    components = (m.attributes for m in @componentCollection.models)
    _.remove components, (comp) =>
      _.find extantComponents, {original: comp.original}  # already have this one added
    components = _.sortBy components, (comp) -> comp.system + '.' + comp.name

    treemaOptions =
      supermodel: @supermodel
      schema: {type: 'array', items: LevelComponent.schema}
      data: ($.extend(true, {}, c) for c in components)
      callbacks: {select: @onSelectAddableComponent, enter: @onAddComponentEnterPressed}
      readOnly: true
      noSortable: true
      nodeClasses:
        'array': ComponentArrayNode
        'object': ComponentNode
    # I have no idea why it's not building in the Thang Editor unless I defer
    _.defer (=>
      @addComponentsTreema = @$el.find('#add-component-column .treema').treema treemaOptions
      @addComponentsTreema.build()
      @hideLoading()
    ), 500

  onSelectAddableComponent: (e, selected) =>
    @extantComponentsTreema.deselectAll()
    @onComponentSelected(selected, false)

  onSelectExtantComponent: (e, selected) =>
    return if @updatingFromConfig
    @addComponentsTreema.deselectAll()
    @onComponentSelected(selected, true)

  onComponentSelected: (selected, extant=true) ->
    return if @alreadySaving # handle infinite loops
    @alreadySaving = true
    @closeExistingView()
    @alreadySaving = false

    return unless selected.length

    # select dependencies.
    node = selected[0]
    original = node.data.original

    toRemoveTreema = []
    dependent_class = 'treema-dependent'
    try
      for index, child of @extantComponentsTreema.childrenTreemas
        $(child.$el).removeClass(dependent_class)

      for index, child of @extantComponentsTreema.childrenTreemas
        if child.data.original == original # Here we assume that the treemas are sorted by their dependency.
          break

        dep_originals = (d.original for d in child.component.attributes.dependencies)
        for dep_original in dep_originals
          if original == dep_original
            toRemoveTreema.push child

      for dep_treema in toRemoveTreema
        dep_treema.toggleSelect()
        $(dep_treema.$el).addClass(dependent_class)

    catch error
      console.error error

    return unless selected.length
    row = selected[0]
    @selectedRow = row
    component = row.component?.attributes or row.data
    config = if extant then row.data?.config else {}
    @configView = new ComponentConfigView({
      supermodel: @supermodel
      level: @level
      world: @world
      config: config
      component: component
      editing: extant
      callback: @onComponentConfigChanged
    })
    @insertSubView @configView

  closeExistingView: ->
    return unless @configView
    data = @configView.data()
    @selectedRow.set '/config', data if data and @configView.changed and @configView.editing
    @removeSubView @configView
    @configView = null

  onComponentConfigChanged: (data) =>
    @updatingFromConfig = true
    @selectedRow.set '/config', data if data and @configView.changed and @configView.editing
    @updatingFromConfig = false

  onChangeExtantComponents: =>
    @buildAddComponentTreema()
    @reportChanges()

  onAddComponentEnterPressed: (node) =>
    if extantSystems
      extantSystems =
        (@supermodel.getModelByOriginalAndMajorVersion LevelSystem, sn.original, sn.majorVersion).attributes.name.toLowerCase() for idx, sn of @level.get('systems')
      requireSystem = node.data.system.toLowerCase()

      if requireSystem not in extantSystems
        warn_element = 'Component <b>' + node.data.name + '</b> requires system <b>' + requireSystem + '</b> which is currently not specified in this level.'
        noty({
          text: warn_element,
          layout: 'bottomLeft',
          type: 'warning'
        })

    currentSelection = @addComponentsTreema?.getLastSelectedTreema()?.data._id

    id = node.data._id
    comp = _.find @componentCollection.models, id: id
    unless comp
      return console.error 'Couldn\'t find component for id', id, 'out of', @components.models
    # Add all dependencies, recursively, unless we already have them
    toAdd = comp.getDependencies(@componentCollection.models)
    _.remove toAdd, (c1) =>
      _.find @extantComponentsTreema.data, (c2) ->
        c2.original is c1.get('original')
    for c in toAdd.concat [comp]
      @extantComponentsTreema.insert '/', {
        original: c.get('original') ? id
        majorVersion: c.get('version').major ? 0
      }

    return unless currentSelection
    # reselect what was selected before the addComponentsTreema was rebuilt
    for index, treema of @addComponentsTreema.childrenTreemas
      if treema.data._id is currentSelection
        treema.select()
        return

  reportChanges: ->
    @callback?($.extend(true, [], @extantComponentsTreema.data))

class ThangComponentsArrayNode extends TreemaArrayNode
  valueClass: 'treema-thang-components-array'
  editable: false
  sort: true
  canAddChild: -> false

  sortFunction: (a, b) =>
    a = @settings.supermodel.getModelByOriginalAndMajorVersion(LevelComponent, a.original, a.majorVersion)
    b = @settings.supermodel.getModelByOriginalAndMajorVersion(LevelComponent, b.original, b.majorVersion)
    return 1 if a.attributes.system > b.attributes.system
    return -1 if a.attributes.system < b.attributes.system
    return 1 if a.name > b.name
    return -1 if a.name < b.name
    return 0

class ThangComponentNode extends TreemaObjectNode
  valueClass: 'treema-thang-component'
  collection: false

  constructor: ->
    super(arguments...)
    @grabDBComponent()

  grabDBComponent: ->
    @component = @settings.supermodel.getModelByOriginalAndMajorVersion LevelComponent, @data.original, @data.majorVersion
    console.error 'Couldn\'t find comp for', @data.original, @data.majorVersion, 'from models', @settings.supermodel.models unless @component

  buildValueForDisplay: (valEl) ->
    return super valEl unless @data.original and @component
    s = @component.get('system') + '.' + @component.get('name')
    @buildValueForDisplaySimply valEl, s

class ComponentArrayNode extends TreemaArrayNode
  editable: false
  sort: true
  canAddChild: -> false

  sortFunction: (a, b) =>
    return 1 if a.system > b.system
    return -1 if a.system < b.system
    return 1 if a.name > b.name
    return -1 if a.name < b.name
    return 0

class ComponentNode extends TreemaObjectNode
  valueClass: 'treema-component'
  collection: false

  buildValueForDisplay: (valEl) ->
    s = @data.system + '.' + @data.name
    @buildValueForDisplaySimply valEl, s

  onEnterPressed: (args...) ->
    super(args...)
    @callbacks.enter?(@)
