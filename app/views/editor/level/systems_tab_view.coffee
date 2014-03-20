View = require 'views/kinds/CocoView'
template = require 'templates/editor/level/systems_tab'
Level = require 'models/Level'
LevelSystem = require 'models/LevelSystem'
LevelSystemEditView = require './system/edit'
LevelSystemNewView = require './system/new'
LevelSystemAddView = require './system/add'
{ThangTypeNode} = require './treema_nodes'

module.exports = class SystemsTabView extends View
  id: "editor-level-systems-tab-view"
  template: template
  className: 'tab-pane'
  startsLoading: true

  subscriptions:
    'level-system-added': 'onLevelSystemAdded'
    'edit-level-system': 'editLevelSystem'
    'level-system-edited': 'onLevelSystemEdited'
    'level-system-editing-ended': 'onLevelSystemEditingEnded'
    'level-loaded': 'onLevelLoaded'

  events:
    'click #add-system-button': 'addLevelSystem'
    'click #create-new-system-button': 'createNewLevelSystem'

  constructor: (options) ->
    super options
    @toLoad = 0
    for system in @buildDefaultSystems()
      url = "/db/level.system/#{system.original}/version/#{system.majorVersion}"
      ls = new LevelSystem()
      ls.saveBackups = true
      do (url) -> ls.url = -> url
      continue if @supermodel.getModelByURL ls.url
      ls.fetch()
      ls.on 'sync', @onSystemLoaded
      ++@toLoad
    @onDefaultSystemsLoaded() unless @toLoad

  onSystemLoaded: (ls) =>
    @supermodel.addModel ls
    --@toLoad
    @onDefaultSystemsLoaded() unless @toLoad

  onDefaultSystemsLoaded: ->
    @startsLoading = false
    @render()  # do it again but without the loading screen
    @onLevelLoaded level: @level if @level

  onLevelLoaded: (e) ->
    @level = e.level
    return if @startsLoading
    @buildSystemsTreema()

  buildSystemsTreema: ->
    systems = $.extend(true, [], @level.get('systems') ? [])
    unless systems.length
      systems = @buildDefaultSystems()
      insertedDefaults = true

    systemModels = @supermodel.getModels LevelSystem
    systemModelMap = {}
    systemModelMap[sys.get('original')] = sys.get('name') for sys in systemModels
    systems = _.sortBy systems, (sys) -> systemModelMap[sys.original]
    
    treemaOptions =
      # TODO: somehow get rid of the + button, or repurpose it to open the LevelSystemAddView instead
      supermodel: @supermodel
      schema: Level.schema.get('properties').systems
      data: systems
      readOnly: true unless me.isAdmin() or @level.hasWriteAccess(me)
      callbacks:
        change: @onSystemsChanged
        select: @onSystemSelected
      nodeClasses:
        'level-system': LevelSystemNode
        'level-system-configuration': LevelSystemConfigurationNode
        'thang-type': ThangTypeNode  # Not until we actually want CocoSprite IndieSprites
    @systemsTreema = @$el.find('#systems-treema').treema treemaOptions
    @systemsTreema.build()
    @systemsTreema.open()
    @onSystemsChanged() if insertedDefaults

  onSystemsChanged: (e) =>
    @level.set 'systems', @systemsTreema.data

  onSystemSelected: (e, selected) =>
    selected = if selected.length > 1 then selected[0].getLastSelectedTreema() else selected[0]
    unless selected
      @removeSubView @levelSystemEditView if @levelSystemEditView
      @levelSystemEditView = null
      return
    until selected.data.original
      selected = selected.parent
    @editLevelSystem original: selected.data.original, majorVersion: selected.data.majorVersion

  onLevelSystemAdded: (e) ->
    @systemsTreema.insert '/', e.system

  addLevelSystem: (e) ->
    @openModalView new LevelSystemAddView supermodel: @supermodel, extantSystems: _.cloneDeep @systemsTreema.data
    Backbone.Mediator.publish 'level:view-switched', e

  createNewLevelSystem: (e) ->
    @openModalView new LevelSystemNewView supermodel: @supermodel
    Backbone.Mediator.publish 'level:view-switched', e

  editLevelSystem: (e) ->
    @levelSystemEditView = @insertSubView new LevelSystemEditView(original: e.original, majorVersion: e.majorVersion, supermodel: @supermodel)

  onLevelSystemEdited: (e) ->
    Backbone.Mediator.publish 'level-systems-changed', systemsData: @systemsTreema.data

  onLevelSystemEditingEnded: (e) ->
    @removeSubView @levelSystemEditView
    @levelSystemEditView = null

  buildDefaultSystems: ->
    [
      {original: "528112c00268d018e3000008", majorVersion: 0}  # Event
      {original: "5280f83b8ae1581b66000001", majorVersion: 0, config: {lifespan: 60}}  # Existence
      {original: "5281146f0268d018e3000014", majorVersion: 0}  # Programming
      {original: "528110f30268d018e3000001", majorVersion: 0}  # AI
      {original: "52810ffa33e01a6e86000012", majorVersion: 0}  # Action
      {original: "528114b20268d018e3000017", majorVersion: 0}  # Targeting
      {original: "528105f833e01a6e86000007", majorVersion: 0}  # Collision
      {original: "528113240268d018e300000c", majorVersion: 0, config: {gravity: 9.81}}  # Movement
      {original: "528112530268d018e3000007", majorVersion: 0}  # Combat
      {original: "52810f4933e01a6e8600000c", majorVersion: 0}  # Hearing
      {original: "528115040268d018e300001b", majorVersion: 0}  # Vision
      {original: "5280dc4d251616c907000001", majorVersion: 0}  # Inventory
      {original: "528111b30268d018e3000004", majorVersion: 0}  # Alliance
      {original: "528114e60268d018e300001a", majorVersion: 0}  # UI
      {original: "528114040268d018e3000011", majorVersion: 0}  # Physics
    ]

class LevelSystemNode extends TreemaObjectNode
  valueClass: 'treema-level-system'
  constructor: ->
    super(arguments...)
    @grabDBComponent()
    @collection = @system?.attributes?.configSchema?.properties?

  grabDBComponent: ->
    @system = @settings.supermodel.getModelByOriginalAndMajorVersion LevelSystem, @data.original, @data.majorVersion
    #@system = _.find @settings.supermodel.getModels(LevelSystem), (m) =>
    #  m.get('original') is @data.original and m.get('version').major is @data.majorVersion
    console.error "Couldn't find system for", @data.original, @data.majorVersion, "from models", @settings.supermodel.models unless @system

  getChildSchema: (key) ->
    return @system.attributes.configSchema if key is 'config'
    return super(key)

  buildValueForDisplay: (valEl) ->
    return super valEl unless @data.original and @system
    name = "#{@system.get('name')} v#{@system.get('version').major}"
    @buildValueForDisplaySimply valEl, "#{name}"

  onEnterPressed: ->
    Backbone.Mediator.publish 'edit-level-system', original: @data.original, majorVersion: @data.majorVersion

  open: ->
    super()
    cTreema = @childrenTreemas.config
    if cTreema? and (cTreema.getChildren().length or cTreema.canAddChild())
      cTreema.open()
# No easy way to flatten the config object, so for now just keep it longer than it needs to be

class LevelSystemConfigurationNode extends TreemaObjectNode
  valueClass: 'treema-level-system-configuration'
  buildValueForDisplay: (valEl) ->
    return
