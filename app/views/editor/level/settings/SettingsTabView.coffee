CocoView = require 'views/core/CocoView'
template = require 'templates/editor/level/settings_tab'
Level = require 'models/Level'
ThangType = require 'models/ThangType'
Surface = require 'lib/surface/Surface'
nodes = require './../treema_nodes'
{me} = require 'core/auth'
require 'vendor/treema'
concepts = require 'schemas/concepts'

module.exports = class SettingsTabView extends CocoView
  id: 'editor-level-settings-tab-view'
  className: 'tab-pane'
  template: template

  # not thangs or scripts or the backend stuff
  editableSettings: [
    'name', 'description', 'documentation', 'nextLevel', 'victory', 'i18n', 'goals',
    'type', 'kind', 'terrain', 'banner', 'loadingTip', 'requiresSubscription', 'adventurer', 'adminOnly',
    'helpVideos', 'replayable', 'scoreTypes', 'concepts', 'picoCTFProblem', 'practice', 'practiceThresholdMinutes'
    'primerLanguage', 'shareable', 'studentPlayInstructions', 'requiredCode', 'suspectCode',
    'requiredGear', 'restrictedGear', 'requiredProperties', 'restrictedProperties', 'recommendedHealth', 'allowedHeroes'
  ]

  subscriptions:
    'editor:level-loaded': 'onLevelLoaded'
    'editor:thangs-edited': 'onThangsEdited'
    'editor:random-terrain-generated': 'onRandomTerrainGenerated'

  constructor: (options) ->
    super options

  onLoaded: ->
  onLevelLoaded: (e) ->
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
        concept: ConceptNode
      solutions: @level.getSolutions()

    @settingsTreema = @$el.find('#settings-treema').treema treemaOptions
    @settingsTreema.build()
    @settingsTreema.open()
    @lastTerrain = data.terrain

  getThangIDs: ->
    (t.id for t in @level.get('thangs') ? [])

  onSettingsChanged: (e) =>
    $('.level-title').text @settingsTreema.data.name
    for key in @editableSettings
      @level.set key, @settingsTreema.data[key]
    if (terrain = @settingsTreema.data.terrain) isnt @lastTerrain
      @lastTerrain = terrain
      Backbone.Mediator.publish 'editor:terrain-changed', terrain: terrain
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

class ConceptNode extends TreemaNode.nodeMap.string
  buildValueForDisplay: (valEl, data) ->
    super valEl, data
    return console.error "Couldn't find concept #{@data}" unless concept = _.find concepts, concept: @data
    description = "#{concept.name} -- #{concept.description}"
    description = description + " (Deprecated)" if concept.deprecated
    description = "AUTO | " + description if concept.automatic
    @$el.find('.treema-row').css('float', 'left')
    @$el.find('.treema-description').remove()
    @$el.append($("<span class='treema-description'>#{description}</span>").show())
