CocoView = require 'views/core/CocoView'
template = require 'templates/editor/component/thang-components-edit-view'

Level = require 'models/Level'
LevelComponent = require 'models/LevelComponent'
LevelSystem = require 'models/LevelSystem'
LevelComponents = require 'collections/LevelComponents'
ThangComponentConfigView = require './ThangComponentConfigView'
AddThangComponentsModal = require './AddThangComponentsModal'
nodes = require '../level/treema_nodes'
require 'vendor/treema'

ThangType = require 'models/ThangType'
CocoCollection = require 'collections/CocoCollection'

LC = (componentName, config) -> original: LevelComponent[componentName + 'ID'], majorVersion: 0, config: config
DEFAULT_COMPONENTS =
  Unit: [LC('Equips'), LC('FindsPaths')]
  Hero: [LC('Equips'), LC('FindsPaths')]
  Floor: [
    LC('Exists', stateless: true)
    LC('Physical', width: 20, height: 17, depth: 2, shape: 'sheet', pos: {x: 10, y: 8.5, z: 1})
    LC('Land')
  ]
  Wall: [
    LC('Exists', stateless: true)
    LC('Physical', width: 4, height: 4, depth: 12, shape: 'box', pos: {x: 2, y: 2, z: 6})
    LC('Collides', collisionType: 'static', collisionCategory: 'obstacles', mass: 1000, fixedRotation: true, restitution: 1)
  ]
  Doodad: [
    LC('Exists', stateless: true)
    LC('Physical')
    LC('Collides', collisionType: 'static', fixedRotation: true)
  ]
  Misc: [LC('Exists'), LC('Physical')]
  Mark: []
  Item: [LC('Item')]
  Missile: [LC('Missile')]

module.exports = class ThangComponentsEditView extends CocoView
  id: 'thang-components-edit-view'
  template: template

  subscriptions:
    'editor:thang-type-kind-changed': 'onThangTypeKindChanged'

  events:
    'click #add-components-button': 'onAddComponentsButtonClicked'

  constructor: (options) ->
    super options
    @originalsLoaded = {}
    @components = options.components or []
    @components = $.extend true, [], @components # just to be sure
    @setThangType options.thangType
    @lastComponentLength = @components.length
    @world = options.world
    @level = options.level
    @loadComponents(@components)

  setThangType: (@thangType) ->
    return unless componentRefs = @thangType?.get('components')
    @loadComponents(componentRefs)

  loadComponents: (components) ->
    for componentRef in components
      # just to handle if ever somehow the same component is loaded twice, through bad data and alike
      continue if @originalsLoaded[componentRef.original]
      @originalsLoaded[componentRef.original] = componentRef.original

      levelComponent = new LevelComponent(componentRef)
      url = "/db/level.component/#{componentRef.original}/version/#{componentRef.majorVersion}"
      levelComponent.setURL(url)
      resource = @supermodel.loadModel levelComponent
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
    components = _.zipObject((c.original for c in @components), @components)
    defaultValue = undefined
    if thangTypeComponents = @thangType?.get('components', true)
      defaultValue = _.zipObject((c.original for c in thangTypeComponents), thangTypeComponents)

    treemaOptions =
      supermodel: @supermodel
      schema: {
        type: 'object'
        default: defaultValue
        additionalProperties: Level.schema.properties.thangs.items.properties.components.items
      },
      data: $.extend true, {}, components
      callbacks: {select: @onSelectComponent, change: @onComponentsTreemaChanged}
      nodeClasses:
        'object': ThangComponentsObjectNode

    @componentsTreema = @$el.find('#thang-components-column .treema').treema treemaOptions
    @componentsTreema.build()

  onComponentsTreemaChanged: =>
    return if @handlingChange
    @handlingChange = true
    componentMap = {}
    for component in @components
      componentMap[component.original] = component

    newComponentsList = []
    for component in _.values(@componentsTreema.data)
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
    @onComponentsAdded()

  onComponentsRemoved: ->
    componentMap = {}
    for component in @components
      componentMap[component.original] = component

    thangComponentMap = {}
    if thangTypeComponents = @thangType?.get('components')
      for thangTypeComponent in thangTypeComponents
        thangComponentMap[thangTypeComponent.original] = thangTypeComponent

    # Deleting components missing dependencies.
    while true
      removedSomething = false
      for componentRef in _.values(componentMap)
        componentModel = @supermodel.getModelByOriginalAndMajorVersion(
          LevelComponent, componentRef.original, componentRef.majorVersion)
        for dependency in componentModel.get('dependencies') or []
          unless (componentMap[dependency.original] or thangComponentMap[dependency.original])
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
      unless (componentMap[subview.component.get('original')] or thangComponentMap[subview.component.get('original')])
        @removeSubView(subview)

    @updateComponentsList()
    @reportChanges()

  updateComponentsList: ->
    # Before I was setting the data to the existing treema but then we had some
    # nasty sorting/callback bugs. This is less efficient, but it's also less bug prone.
    @buildComponentsTreema()

  onComponentsAdded: ->
    return unless @componentsTreema
    componentMap = {}
    for component in @components
      componentMap[component.original] = component

    if thangTypeComponents = @thangType?.get('components')
      for thangTypeComponent in thangTypeComponents
        componentMap[thangTypeComponent.original] = thangTypeComponent

    # Go through the map, adding missing dependencies.
    while true
      addedSomething = false
      for componentRef in _.values(componentMap)
        componentModel = @supermodel.getModelByOriginalAndMajorVersion(
          LevelComponent, componentRef.original, componentRef.majorVersion)
        if not componentModel?.loaded
          @loadComponents([componentRef])
          continue
        for dependency in componentModel?.get('dependencies') or []
          if not componentMap[dependency.original]
            component = @supermodel.getModelByOriginalAndMajorVersion(
              LevelComponent, dependency.original, dependency.majorVersion)
            if not component?.loaded
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

    componentRefs = _.merge {}, @componentsTreema.data
    if thangTypeComponents = @thangType?.get('components')
      thangComponentRefs = _.zipObject((c.original for c in thangTypeComponents), thangTypeComponents)
      for thangTypeComponent in thangTypeComponents
        if componentRef = componentRefs[thangTypeComponent.original]
          componentRef.additionalDefaults = thangTypeComponent.config
        else
          modifiedRef = _.merge {}, thangTypeComponent
          modifiedRef.additionalDefaults = modifiedRef.config
          delete modifiedRef.config
          componentRefs[thangTypeComponent.original] = modifiedRef

    for componentRef in _.values(componentRefs)
      subview = componentConfigViews[componentRef.original]
      if not subview
        subview = @makeThangComponentConfigView(componentRef)
        continue unless subview
        @registerSubView(subview)
      subview.setIsDefaultComponent(not @componentsTreema.data[componentRef.original])
      configsEl.append(subview.$el)

  makeThangComponentConfigView: (thangComponent) ->
    component = @supermodel.getModelByOriginal(LevelComponent, thangComponent.original)
    return unless component?.loaded
    config = thangComponent.config ? {}
    configView = new ThangComponentConfigView({
      supermodel: @supermodel
      level: @level
      world: @world
      config: config
      component: component
      additionalDefaults: thangComponent.additionalDefaults
    })
    configView.render()
    @listenTo configView, 'changed', @onConfigChanged
    configView

  onConfigChanged: (e) ->
    foundComponent = false
    for thangComponent in @components
      if thangComponent.original is e.component.get('original')
        thangComponent.config = e.config
        foundComponent = true
        break

    if not foundComponent
      @components.push({
        original: e.component.get('original')
        majorVersion: e.component.get('version').major
        config: e.config
      })

      for subview in _.values(@subviews)
        continue unless subview instanceof ThangComponentConfigView
        if subview.component.get('original') is e.component.get('original')
          _.defer -> subview.setIsDefaultComponent(false)
          break

    @updateComponentsList()
    @reportChanges()

  onSelectComponent: (e, nodes) =>
    @componentsTreema.$el.find('.dependent').removeClass('dependent')
    @$el.find('.selected-component').removeClass('selected-component')
    return unless nodes.length is 1

    # find dependent components
    dependents = {}
    dependents[nodes[0].getData().original] = true
    componentsToCheck = [nodes[0].getData().original]
    while componentsToCheck.length
      componentOriginal = componentsToCheck.pop()
      for otherComponentRef in @components
        continue if otherComponentRef.original is componentOriginal
        continue if dependents[otherComponentRef.original]
        otherComponent = @supermodel.getModelByOriginal(LevelComponent, otherComponentRef.original)
        for dependency in otherComponent.get('dependencies', true)
          if dependents[dependency.original]
            dependents[otherComponentRef.original] = true
            componentsToCheck.push otherComponentRef.original

    # highlight them
    for child in _.values(@componentsTreema.childrenTreemas)
      if dependents[child.getData().original]
        child.$el.addClass('dependent')

    # scroll to the config
    for subview in _.values(@subviews)
      continue unless subview instanceof ThangComponentConfigView
      if subview.component.get('original') is nodes[0].getData().original
        subview.$el[0].scrollIntoView()
        subview.$el.addClass('selected-component')
        break

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
      if system isnt 'misc' and system not in extantSystems
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

  onThangTypeKindChanged: (e) ->
    return unless defaultComponents = DEFAULT_COMPONENTS[e.kind]
    for component in defaultComponents when not _.find(@components, original: component.original)
      @components.push component
      @onComponentsAdded()

  destroy: ->
    @componentsTreema?.destroy()
    super()

class ThangComponentsObjectNode extends TreemaObjectNode
  addNewChild: -> @addNewChildForKey('') # HACK to get the object adding to act more like adding to an array

  getChildren: ->
    children = super(arguments...)
    children.sort(@sortFunction)

  sortFunction: (a, b) =>
    a = a.value ? a.defaultData
    b = b.value ? b.defaultData
    a = @settings.supermodel.getModelByOriginalAndMajorVersion(LevelComponent, a.original, a.majorVersion)
    b = @settings.supermodel.getModelByOriginalAndMajorVersion(LevelComponent, b.original, b.majorVersion)
    return 0 if not (a or b)
    return 1 if not b
    return -1 if not a
    return 1 if a.get('system') > b.get('system')
    return -1 if a.get('system') < b.get('system')
    return 1 if a.get('name') > b.get('name')
    return -1 if a.get('name') < b.get('name')
    return 0
