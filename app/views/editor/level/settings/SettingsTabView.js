require('app/styles/editor/level/settings_tab.sass')
CocoView = require 'views/core/CocoView'
template = require 'app/templates/editor/level/settings_tab'
Level = require 'models/Level'
ThangType = require 'models/ThangType'
Surface = require 'lib/surface/Surface'
nodes = require './../treema_nodes'
{me} = require 'core/auth'
require 'lib/setupTreema'
Concepts = require 'collections/Concepts'
schemas = require 'app/schemas/schemas'
concepts = []
utils = require 'core/utils'


module.exports = class SettingsTabView extends CocoView
  id: 'editor-level-settings-tab-view'
  className: 'tab-pane'
  template: template

  subscriptions:
    'editor:level-loaded': 'onLevelLoaded'
    'editor:thangs-edited': 'onThangsEdited'
    'editor:random-terrain-generated': 'onRandomTerrainGenerated'

  # Not thangs or scripts or the backend stuff. Most properties will be added from the schema inEditor field.
  editableSettings: ['name']

  constructor: (options) ->
    super options
    @editableSettings = @editableSettings.concat _.keys(_.pick(Level.schema.properties, (value, key) => value.inEditor is true or value.inEditor is utils.getProduct()))

  onLoaded: ->

  onLevelLoaded: (e) ->
    @concepts = new Concepts([])

    @listenTo @concepts, 'sync', =>
      concepts = @concepts.models
      schemas.concept.enum = _.map concepts, (c) -> c.get('key')
      @onConceptsLoaded(e)
    
    @concepts.fetch
      data: { skip: 0, limit: 1000 }  

  onConceptsLoaded: (e) ->
    @level = e.level
    data = _.pick @level.attributes, (value, key) => key in @editableSettings
    schema = _.cloneDeep Level.schema
    schema.properties = _.pick schema.properties, (value, key) => key in @editableSettings
    schema.required = _.intersection schema.required, @editableSettings
    schema.default = _.pick schema.default, (value, key) => key in @editableSettings
    @thangIDs = @getThangIDs()
    treemaOptions =
      filePath: "db/level/#{@level.get('original')}"
      supermodel: @supermodel
      schema: schema
      data: data
      readOnly: me.get('anonymous')
      callbacks: {change: @onSettingsChanged}
      thangIDs: @thangIDs
      nodeClasses:
        object: SettingsNode
        thang: nodes.ThangNode
        'solution-gear': SolutionGearNode
        'solution-stats': SolutionStatsNode
        concept:  nodes.conceptNodes(concepts).ConceptNode
        'concepts-list':  nodes.conceptNodes(concepts).ConceptsListNode
        'clans-list': ClansListNode
      solutions: @level.getSolutions()

    @settingsTreema = @$el.find('#settings-treema').treema treemaOptions
    @settingsTreema.build()
    @settingsTreema.open()
    @lastTerrain = data.terrain
    @lastType = data.type

  getThangIDs: ->
    (t.id for t in @level.get('thangs') ? [])

  onSettingsChanged: (e) =>
    $('.level-title').text @settingsTreema.data.name
    for key in @editableSettings
      @level.set key, @settingsTreema.data[key]
    if (terrain = @settingsTreema.data.terrain) isnt @lastTerrain
      @lastTerrain = terrain
      Backbone.Mediator.publish 'editor:terrain-changed', terrain: terrain
    if (type = @settingsTreema.data.type) isnt @lastType
      @onTypeChanged type
    for goal, index in @settingsTreema.data.goals ? []
      continue if goal.id
      goalIndex = index
      goalID = "goal-#{goalIndex}"
      goalID = "goal-#{++goalIndex}" while _.find @settingsTreema.get("goals"), id: goalID
      @settingsTreema.disableTracking()
      @settingsTreema.set "/goals/#{index}/id", goalID
      @settingsTreema.set "/goals/#{index}/name", _.string.humanize goalID
      @settingsTreema.enableTracking()

  onThangsEdited: (e) ->
    # Update in-place so existing Treema nodes refer to the same array.
    @thangIDs?.splice(0, @thangIDs.length, @getThangIDs()...)
    @settingsTreema.solutions = @level.getSolutions()  # Remove if slow

  onRandomTerrainGenerated: (e) ->
    @settingsTreema.set '/terrain', e.terrain

  onTypeChanged: (type) ->
    @lastType = type
    if type is 'ladder' and @settingsTreema.get('/mirrorMatch') isnt false
      @settingsTreema.set '/mirrorMatch', false
      noty {
        text: "Type updated to 'ladder', so mirrorMatch has been updated to false."
        layout: 'topCenter'
        timeout: 5000
        type: 'information'
      }

  destroy: ->
    @settingsTreema?.destroy()
    super()


class SettingsNode extends TreemaObjectNode
  nodeDescription: 'Settings'

class SolutionGearNode extends TreemaArrayNode
  select: ->
    super()
    return unless solution = _.find @getRoot().solutions, succeeds: true, language: 'javascript'
    propertiesUsed = []
    for match in (solution.source ? '').match /hero\.([a-z][A-Za-z0-9]*)/g
      prop = match.split('.')[1]
      propertiesUsed.push prop unless prop in propertiesUsed
    return unless propertiesUsed.length
    if _.isEqual @data, propertiesUsed
      @$el.find('.treema-description').html('Solution uses exactly these required properties.')
      return
    description = 'Solution used properties: ' + ["<code>#{prop}</code>" for prop in propertiesUsed].join(' ')
    button = $('<button class="btn btn-sm">Use</button>')
    $(button).on 'click', =>
      @set '', propertiesUsed
      _.defer =>
        @open()
        @select()
    @$el.find('.treema-description').html(description).append(button)

class SolutionStatsNode extends TreemaNode.nodeMap.number
  select: ->
    super()
    return unless solution = _.find @getRoot().solutions, succeeds: true, language: 'javascript'
    ThangType.calculateStatsForHeroConfig solution.heroConfig, (stats) =>
      stats[key] = val.toFixed(2) for key, val of stats when parseInt(val) isnt val
      description = "Solution had stats: <code>#{JSON.stringify(stats)}</code>"
      button = $('<button class="btn btn-sm">Use health</button>')
      $(button).on 'click', =>
        @set '', stats.health
        _.defer =>
          @open()
          @select()
      @$el.find('.treema-description').html(description).append(button)

class ClansListNode extends TreemaNode.nodeMap.array
  nodeDescription: 'ClansList'
