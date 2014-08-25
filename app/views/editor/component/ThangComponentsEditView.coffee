CocoView = require 'views/kinds/CocoView'
template = require 'templates/editor/component/thang-components-edit-view'

Level = require 'models/Level'
LevelComponent = require 'models/LevelComponent'
LevelSystem = require 'models/LevelSystem'
ComponentsCollection = require 'collections/ComponentsCollection'
ThangComponentConfigView = require './ThangComponentConfigView'
AddThangComponentsModal = require './AddThangComponentsModal'
nodes = require '../level/treema_nodes'

ThangType = require 'models/ThangType'
CocoCollection = require 'collections/CocoCollection'

class ItemThangTypeSearchCollection extends CocoCollection
  url: '/db/thang.type?view=items&project=original,name,version,slug,kind,components'
  model: ThangType

module.exports = class ThangComponentsEditView extends CocoView
  id: 'thang-components-edit-view'
  template: template

  events:
    'click #add-components-button': 'onAddComponentsButtonClicked'

  constructor: (options) ->
    super options
    @components = options.components or []
    @components = $.extend true, [], @components # just to be sure
    @lastComponentLength = @components.length
    @world = options.world
    @level = options.level
    @loadComponents(@components)
    # Need to grab the ThangTypes so that we can autocomplete items in inventory based on them.
    @itemThangTypes = @supermodel.loadCollection(new ItemThangTypeSearchCollection(), 'thangs').model

  loadComponents: (components) ->
    for componentRef in components
      levelComponent = new LevelComponent(componentRef)
      url = "/db/level.component/#{componentRef.original}/version/#{componentRef.majorVersion}"
      levelComponent.setURL(url)
      resource = @supermodel.loadModel levelComponent, 'component'
      continue unless resource.isLoading
      @listenToOnce resource, 'loaded', ->
        return if @handlingChange
        @handlingChange = true
        @onComponentsAdded()
        @handlingChange = false

  afterRender: ->
    super()
    return unless @supermodel.finished()
    @buildComponentsTreema()
    @addThangComponentConfigViews()

  buildComponentsTreema: ->
    treemaOptions =
      supermodel: @supermodel
      schema: Level.schema.properties.thangs.items.properties.components
      data: $.extend true, [], @components
      callbacks: {select: @onSelectComponent, change: @onComponentsTreemaChanged}
      noSortable: true
      nodeClasses:
        'thang-components-array': ThangComponentsArrayNode
        'point2d': nodes.WorldPointNode
        'viewport': nodes.WorldViewportNode
        'bounds': nodes.WorldBoundsNode
        'radians': nodes.RadiansNode
        'team': nodes.TeamNode
        'superteam': nodes.SuperteamNode
        'meters': nodes.MetersNode
        'kilograms': nodes.KilogramsNode
        'seconds': nodes.SecondsNode
        'speed': nodes.SpeedNode
        'acceleration': nodes.AccelerationNode
        'item-thang-type': nodes.ItemThangTypeNode

    @componentsTreema = @$el.find('#thang-components-column .treema').treema treemaOptions
    @componentsTreema.build()

  onComponentsTreemaChanged: =>
    return if @handlingChange
    @handlingChange = true
    componentMap = {}
    for component in @components
      componentMap[component.original] = component

    newComponentsList = []
    for component in @componentsTreema.data
      newComponentsList.push(componentMap[component.original] or component)
    @components = newComponentsList

    # update the components list here
    @onComponentsChanged()
    @handlingChange = false

  onComponentsChanged: =>
    # happens whenever the list of components changed, one way or another
    # * if the treema gets changed
    # * if components are added externally, like by a modal
    # * if a dependency loads and is added to the list

    if @components.length < @lastComponentLength
      @onComponentsRemoved()
    else
      @onComponentsAdded()

  onComponentsRemoved: ->
    componentMap = {}
    for component in @components
      componentMap[component.original] = component

    # Deleting components missing dependencies.
    while true
      removedSomething = false
      for componentRef in _.values(componentMap)
        componentModel = @supermodel.getModelByOriginalAndMajorVersion(
          LevelComponent, componentRef.original, componentRef.majorVersion)
        for dependency in componentModel.get('dependencies') or []
          if not componentMap[dependency.original]
            delete componentMap[componentRef.original]
            component = @supermodel.getModelByOriginal(
              LevelComponent, componentRef.original)
            noty {
              text: "Removed dependent component: #{component.get('name')}"
              layout: 'topCenter'
              timeout: 5000
              type: 'information'
            }
            removedSomething = true
        break if removedSomething
      break unless removedSomething

    @components = _.values(componentMap)

    # Delete individual component config views that are no longer included.
    for subview in _.values(@subviews)
      continue unless subview instanceof ThangComponentConfigView
      if not componentMap[subview.component.get('original')]
        @removeSubView(subview)

    @updateComponentsList()
    @reportChanges()

  updateComponentsList: ->
    @componentsTreema?.set('/', $.extend(true, [], @components))

  onComponentsAdded: ->
    return unless @componentsTreema
    componentMap = {}
    for component in @components
      componentMap[component.original] = component

    # Go through the map, adding missing dependencies.
    while true
      addedSomething = false
      for componentRef in _.values(componentMap)
        componentModel = @supermodel.getModelByOriginalAndMajorVersion(
          LevelComponent, componentRef.original, componentRef.majorVersion)
        for dependency in componentModel?.get('dependencies') or []
          if not componentMap[dependency.original]
            component = @supermodel.getModelByOriginalAndMajorVersion(
              LevelComponent, dependency.original, dependency.majorVersion)
            if not component
              @loadComponents([dependency])
              # will run onComponentsAdded once more when the model loads
            else
              addedSomething = true
              noty {
                text: "Added dependency: #{component.get('name')}"
                layout: 'topCenter'
                timeout: 5000
                type: 'information'
              }
              componentMap[dependency.original] = dependency
              @components.push dependency
      break unless addedSomething


    # Sort the component list, reorder the component config views
    @updateComponentsList()
    @addThangComponentConfigViews()
    @checkForMissingSystems()
    @reportChanges()

  addThangComponentConfigViews: ->
    # Detach all component config views temporarily.
    componentConfigViews = {}
    for subview in _.values(@subviews)
      continue unless subview instanceof ThangComponentConfigView
      componentConfigViews[subview.component.get('original')] = subview
      subview.$el.detach()

    # Put back config views into the DOM based on the component list ordering,
    # adding and registering new ones as needed.
    configsEl = @$el.find('#thang-component-configs')
    for componentRef in @componentsTreema.data
      subview = componentConfigViews[componentRef.original]
      if not subview
        subview = @makeThangComponentConfigView(componentRef)
        continue unless subview
        @registerSubView(subview)
      configsEl.append(subview.$el)

  makeThangComponentConfigView: (thangComponent) ->
    component = @supermodel.getModelByOriginal(LevelComponent, thangComponent.original)
    return unless component
    config = thangComponent.config ? {}
    configView = new ThangComponentConfigView({
      supermodel: @supermodel
      level: @level
      world: @world
      config: config
      component: component
    })
    configView.render()
    @listenTo configView, 'changed', @onConfigChanged
    configView

  onConfigChanged: (e) ->
    for thangComponent in @components
      if thangComponent.original is e.component.get('original')
        thangComponent.config = e.config
    @reportChanges()

  onSelectComponent: (e, nodes) =>
    @componentsTreema.$el.find('.dependent').removeClass('dependent')
    return unless nodes.length is 1

    # find dependent components
    dependents = {}
    dependents[nodes[0].data.original] = true
    componentsToCheck = [nodes[0].data.original]
    while componentsToCheck.length
      componentOriginal = componentsToCheck.pop()
      for otherComponentRef in @components
        continue if otherComponentRef.original is componentOriginal
        continue if dependents[otherComponentRef.original]
        otherComponent = @supermodel.getModelByOriginal(LevelComponent, otherComponentRef.original)
        for dependency in otherComponent.get('dependencies')
          if dependents[dependency.original]
            dependents[otherComponentRef.original] = true
            componentsToCheck.push otherComponentRef.original

    # highlight them
    for child in _.values(@componentsTreema.childrenTreemas)
      if dependents[child.data.original]
        child.$el.addClass('dependent')

    # scroll to the config
    for subview in _.values(@subviews)
      continue unless subview instanceof ThangComponentConfigView
      if subview.component.get('original') is nodes[0].data.original
        subview.$el[0].scrollIntoView()
        break

  onComponentConfigChanged: (data) =>
    @updatingFromConfig = true
    @selectedRow.set '/config', data if data and @configView.changed and @configView.editing
    @updatingFromConfig = false

  onChangeExtantComponents: =>
    @buildAddComponentTreema()
    @reportChanges()

  checkForMissingSystems: ->
    return unless @level
    extantSystems =
      (@supermodel.getModelByOriginalAndMajorVersion LevelSystem, sn.original, sn.majorVersion).attributes.name.toLowerCase() for idx, sn of @level.get('systems')

    componentModels = (@supermodel.getModelByOriginal(LevelComponent, c.original) for c in @components)
    componentSystems = (c.get('system') for c in componentModels when c)

    for system in componentSystems
      if system not in extantSystems
        s = "Component requires system <strong>#{system}</strong> which is currently not included in this level."
        noty({
          text: s,
          layout: 'bottomLeft',
          type: 'warning'
        })

  reportChanges: ->
    @lastComponentLength = @components.length
    @trigger 'components-changed', $.extend(true, [], @components)

  undo: -> @componentsTreema.undo()

  redo: -> @componentsTreema.redo()

  onAddComponentsButtonClicked: ->
    modal = new AddThangComponentsModal({skipOriginals: (c.original for c in @components)})
    @openModalView modal
    @listenToOnce modal, 'hidden', ->
      componentsToAdd = modal.getSelectedComponents()
      sparseComponents = ({original: c.get('original'), majorVersion: c.get('version').major} for c in componentsToAdd)
      @loadComponents(sparseComponents)
      @components = @components.concat(sparseComponents)
      @onComponentsChanged()


class ThangComponentsArrayNode extends TreemaArrayNode
  valueClass: 'treema-thang-components-array'
  sort: true

  sortFunction: (a, b) =>
    a = @settings.supermodel.getModelByOriginalAndMajorVersion(LevelComponent, a.original, a.majorVersion)
    b = @settings.supermodel.getModelByOriginalAndMajorVersion(LevelComponent, b.original, b.majorVersion)
    return 0 if not (a or b)
    return 1 if not b
    return -1 if not a
    return 1 if a.attributes.system > b.attributes.system
    return -1 if a.attributes.system < b.attributes.system
    return 1 if a.name > b.name
    return -1 if a.name < b.name
    return 0
