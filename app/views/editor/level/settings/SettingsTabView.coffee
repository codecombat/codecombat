CocoView = require 'views/core/CocoView'
template = require 'templates/editor/level/settings_tab'
Level = require 'models/Level'
Surface = require 'lib/surface/Surface'
nodes = require './../treema_nodes'
{me} = require 'core/auth'
require 'vendor/treema'

module.exports = class SettingsTabView extends CocoView
  id: 'editor-level-settings-tab-view'
  className: 'tab-pane'
  template: template

  # not thangs or scripts or the backend stuff
  editableSettings: [
    'name', 'description', 'documentation', 'nextLevel', 'background', 'victory', 'i18n', 'icon', 'goals',
    'type', 'terrain', 'showsGuide', 'banner', 'employerDescription', 'loadingTip', 'requiresSubscription',
    'helpVideos', 'replayable', 'scoreTypes', 'concepts', 'picoCTFProblem', 'practice', 'practiceThresholdMinutes'
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

    @settingsTreema = @$el.find('#settings-treema').treema treemaOptions
    @settingsTreema.build()
    @settingsTreema.open()
    @lastTerrain = data.terrain

  getThangIDs: ->
    (t.id for t in @level.get('thangs') ? [])

  onSettingsChanged: (e) =>
    $('.level-title').text @settingsTreema.data.name
    for key in @editableSettings
      continue if @settingsTreema.data[key] is undefined
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

  onRandomTerrainGenerated: (e) ->
    @settingsTreema.set '/terrain', e.terrain

  destroy: ->
    @settingsTreema?.destroy()
    super()


class SettingsNode extends TreemaObjectNode
  nodeDescription: 'Settings'
