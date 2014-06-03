View = require 'views/kinds/CocoView'
template = require 'templates/editor/level/settings_tab'
Level = require 'models/Level'
Surface = require 'lib/surface/Surface'
nodes = require './treema_nodes'
{me} = require 'lib/auth'

module.exports = class SettingsTabView extends View
  id: 'editor-level-settings-tab-view'
  className: 'tab-pane'
  template: template

  # not thangs or scripts or the backend stuff
  editableSettings: [
    'name', 'description', 'documentation', 'nextLevel', 'background', 'victory', 'i18n', 'icon', 'goals',
    'type', 'showsGuide'
  ]

  subscriptions:
    'level-loaded': 'onLevelLoaded'

  constructor: (options) ->
    super options

  onLoaded: ->
  onLevelLoaded: (e) ->
    @level = e.level
    data = _.pick @level.attributes, (value, key) => key in @editableSettings
    schema = _.cloneDeep Level.schema
    schema.properties = _.pick schema.properties, (value, key) => key in @editableSettings
    schema.required = _.intersection schema.required, @editableSettings
    thangIDs = @getThangIDs()
    treemaOptions =
      filePath: "db/level/#{@level.get('original')}"
      supermodel: @supermodel
      schema: schema
      data: data
      readOnly: me.get('anonymous')
      callbacks: {change: @onSettingsChanged}
      thangIDs: thangIDs
      nodeClasses:
        thang: nodes.ThangNode

    @settingsTreema = @$el.find('#settings-treema').treema treemaOptions
    @settingsTreema.build()
    @settingsTreema.open()

  getThangIDs: ->
    (t.id for t in @level.get('thangs') when t.id isnt 'Interface')

  onSettingsChanged: (e) =>
    $('.level-title').text @settingsTreema.data.name
    for key in @editableSettings
      continue if @settingsTreema.data[key] is undefined
      @level.set key, @settingsTreema.data[key]
