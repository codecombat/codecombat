CocoView = require 'views/core/CocoView'
template = require 'templates/editor/level/systems-tab-view'
Level = require 'models/Level'
LevelSystem = require 'models/LevelSystem'
LevelSystemEditView = require './LevelSystemEditView'
NewLevelSystemModal = require './NewLevelSystemModal'
AddLevelSystemModal = require './AddLevelSystemModal'
nodes = require '../treema_nodes'
require 'vendor/treema'

module.exports = class SystemsTabView extends CocoView
  id: 'systems-tab-view'
  template: template
  className: 'tab-pane'

  subscriptions:
    'editor:level-system-added': 'onLevelSystemAdded'
    'editor:edit-level-system': 'editLevelSystem'
    'editor:level-system-editing-ended': 'onLevelSystemEditingEnded'
    'editor:level-loaded': 'onLevelLoaded'
    'editor:terrain-changed': 'onTerrainChanged'

  events:
    'click #add-system-button': 'addLevelSystem'
    'click #create-new-system-button': 'createNewLevelSystem'
    'click #create-new-system': 'createNewLevelSystem'

  constructor: (options) ->
    super options
    for system in @buildDefaultSystems()
      url = "/db/level.system/#{system.original}/version/#{system.majorVersion}"
      ls = new LevelSystem().setURL(url)
      @supermodel.loadModel(ls)

  afterRender: ->
    @buildSystemsTreema()

  onLoaded: ->
    super()

  onLevelLoaded: (e) ->
    @level = e.level
    @buildSystemsTreema()

  buildSystemsTreema: ->
    return unless @level and @supermodel.finished()
    systems = $.extend(true, [], @level.get('systems') ? [])
    unless systems.length
      systems = @buildDefaultSystems()
      insertedDefaults = true
    systems = @getSortedByName systems
    thangs = if @level? then @level.get('thangs') else []
    thangIDs = _.filter(_.pluck(thangs, 'id'))
    teams = _.filter(_.pluck(thangs, 'team'))
    superteams = _.filter(_.pluck(thangs, 'superteam'))
    superteams = _.union(teams, superteams)
    treemaOptions =
      supermodel: @supermodel
      schema: Level.schema.properties.systems
      data: systems
      readOnly: me.get('anonymous')
      world: @options.world
      view: @
      thangIDs: thangIDs
      teams: teams
      superteams: superteams
      callbacks:
        change: @onSystemsChanged
        select: @onSystemSelected
      nodeClasses:
        'level-system': LevelSystemNode
        'level-system-configuration': LevelSystemConfigurationNode
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
        'thang-type': nodes.ThangTypeNode
        'item-thang-type': nodes.ItemThangTypeNode

    @systemsTreema = @$el.find('#systems-treema').treema treemaOptions
    @systemsTreema.build()
    @systemsTreema.open()
    @onSystemsChanged() if insertedDefaults

  onSystemsChanged: (e) =>
    systems = @getSortedByName @systemsTreema.data
    @level.set 'systems', systems

  getSortedByName: (systems) =>
    systemModels = @supermodel.getModels LevelSystem
    systemModelMap = {}
    systemModelMap[sys.get('original')] = sys.get('name') for sys in systemModels
    _.sortBy systems, (sys) -> systemModelMap[sys.original]

  onSystemSelected: (e, selected) =>
    selected = if selected.length > 1 then selected[0].getLastSelectedTreema() else selected[0]
    unless selected
      @removeSubView @levelSystemEditView if @levelSystemEditView
      @levelSystemEditView = null
      return
    until (data = selected.getData()) and data.original
      selected = selected.parent
    @editLevelSystem original: data.original, majorVersion: data.majorVersion

  onLevelSystemAdded: (e) ->
    @systemsTreema.insert '/', e.system

  addLevelSystem: (e) ->
    @openModalView new AddLevelSystemModal supermodel: @supermodel, extantSystems: _.cloneDeep @systemsTreema.data
    Backbone.Mediator.publish 'editor:view-switched', {}

  createNewLevelSystem: (e) ->
    @openModalView new NewLevelSystemModal supermodel: @supermodel
    Backbone.Mediator.publish 'editor:view-switched', {}

  editLevelSystem: (e) ->
    @levelSystemEditView = @insertSubView new LevelSystemEditView(original: e.original, majorVersion: e.majorVersion, supermodel: @supermodel)

  onLevelSystemEditingEnded: (e) ->
    @removeSubView @levelSystemEditView
    @levelSystemEditView = null

  onTerrainChanged: (e) ->
    defaultPathfinding = e.terrain in ['Dungeon', 'Indoor', 'Mountain', 'Glacier', 'Volcano']
    changed = false
    if AI = @systemsTreema.get 'original=528110f30268d018e3000001'
      unless AI.config?.findsPaths is defaultPathfinding
        AI.config ?= {}
        AI.config.findsPaths = defaultPathfinding
        @systemsTreema.set 'original=528110f30268d018e3000001', AI
        changed = true
    if Vision = @systemsTreema.get 'original=528115040268d018e300001b'
      unless Vision.config?.checksLineOfSight is defaultPathfinding
        Vision.config ?= {}
        Vision.config.checksLineOfSight = defaultPathfinding
        @systemsTreema.set 'original=528115040268d018e300001b', Vision
        changed = true
    if changed
      noty {
        text: "AI/Vision System defaulted pathfinding/line-of-sight to #{defaultPathfinding} for terrain #{e.terrain}."
        layout: 'topCenter'
        timeout: 5000
        type: 'information'
      }

  buildDefaultSystems: ->
    [
      {original: '528112c00268d018e3000008', majorVersion: 0}  # Event
      {original: '5280f83b8ae1581b66000001', majorVersion: 0}  # Existence
      {original: '5281146f0268d018e3000014', majorVersion: 0}  # Programming
      {original: '528110f30268d018e3000001', majorVersion: 0}  # AI
      {original: '52810ffa33e01a6e86000012', majorVersion: 0}  # Action
      {original: '528114b20268d018e3000017', majorVersion: 0}  # Targeting
      {original: '528105f833e01a6e86000007', majorVersion: 0}  # Collision
      {original: '528113240268d018e300000c', majorVersion: 0}  # Movement
      {original: '528112530268d018e3000007', majorVersion: 0}  # Combat
      {original: '52810f4933e01a6e8600000c', majorVersion: 0}  # Hearing
      {original: '528115040268d018e300001b', majorVersion: 0}  # Vision
      {original: '5280dc4d251616c907000001', majorVersion: 0}  # Inventory
      {original: '528111b30268d018e3000004', majorVersion: 0}  # Alliance
      {original: '528114e60268d018e300001a', majorVersion: 0}  # UI
      {original: '528114040268d018e3000011', majorVersion: 0}  # Physics
      {original: '52ae4f02a4dcd4415200000b', majorVersion: 0}  # Display
      {original: '52e953e81b2028d102000004', majorVersion: 0}  # Effect
      {original: '52f1354370fb890000000005', majorVersion: 0}  # Magic
    ]

  destroy: ->
    @systemsTreema?.destroy()
    super()

class LevelSystemNode extends TreemaObjectNode
  valueClass: 'treema-level-system'
  constructor: ->
    super(arguments...)
    @grabDBComponent()
    @collection = @system?.attributes?.configSchema?.properties?

  grabDBComponent: ->
    data = @getData()
    @system = @settings.supermodel.getModelByOriginalAndMajorVersion(LevelSystem, data.original, data.majorVersion)
    console.error 'Couldn\'t find system for', data.original, data.majorVersion, 'from models', @settings.supermodel.models unless @system

  getChildSchema: (key) ->
    return @system.attributes.configSchema if key is 'config'
    return super(key)

  buildValueForDisplay: (valEl, data) ->
    return super valEl unless data.original and @system
    name = @system.get 'name'
    name += " v#{@system.get('version').major}" if @system.get('version').major
    @buildValueForDisplaySimply valEl, name

  onEnterPressed: (e) ->
    super e
    data = @getData()
    Backbone.Mediator.publish 'editor:edit-level-system', original: data.original, majorVersion: data.majorVersion

  open: (depth) ->
    super depth
    cTreema = @childrenTreemas.config
    if cTreema? and (cTreema.getChildren().length or cTreema.canAddChild())
      cTreema.open()
# No easy way to flatten the config object, so for now just keep it longer than it needs to be

class LevelSystemConfigurationNode extends TreemaObjectNode
  valueClass: 'treema-level-system-configuration'
  buildValueForDisplay: -> return
