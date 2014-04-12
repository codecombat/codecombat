View = require 'views/kinds/CocoView'
template = require 'templates/editor/level/scripts_tab'
Level = require 'models/Level'
Surface = require 'lib/surface/Surface'
nodes = require './treema_nodes'

module.exports = class ScriptsTabView extends View
  id: "editor-level-scripts-tab-view"
  template: template
  className: 'tab-pane'

  subscriptions:
    'level-loaded': 'onLevelLoaded'

  constructor: (options) ->
    super options
    @world = options.world
    @files = options.files

  onLevelLoaded: (e) ->
    @level = e.level
    @dimensions = @level.dimensions()
    scripts = $.extend(true, [], @level.get('scripts') ? [])
    treemaOptions =
      schema: Level.schema.properties.scripts
      data: scripts
      callbacks:
        change: @onScriptsChanged
        select: @onScriptSelected
      nodeClasses:
        object: ScriptNode
      view: @
    @scriptsTreema = @$el.find('#scripts-treema').treema treemaOptions
    @scriptsTreema.build()
    if @scriptsTreema.childrenTreemas[0]?
      @scriptsTreema.childrenTreemas[0].select()
      @scriptsTreema.childrenTreemas[0].broadcastChanges() # can get rid of this after refactoring treema

  onScriptsChanged: (e) =>
    @level.set 'scripts', @scriptsTreema.data

  onScriptSelected: (e, selected) =>
    selected = if selected.length > 1 then selected[0].getLastSelectedTreema() else selected[0]
    unless selected
      @$el.find('#script-treema').replaceWith($('<div id="script-treema"></div>'))
      @selectedScriptPath = null
      return

    thangIDs = @getThangIDs()
    treemaOptions =
      world: @world
      filePath: "db/level/#{@level.get('original')}"
      files: @files
      view: @
      schema: Level.schema.properties.scripts.items
      data: selected.data
      thangIDs: thangIDs
      dimensions: @dimensions
      supermodel: @supermodel
      readOnly: true unless me.isAdmin() or @level.hasWriteAccess(me)
      callbacks:
        change: @onScriptChanged
      nodeClasses:
        'event-value-chain': EventPropsNode
        'event-prereqs': EventPrereqsNode
        'event-prereq': EventPrereqNode
        'event-channel': ChannelNode
        'thang': nodes.ThangNode
        'milliseconds': nodes.MillisecondsNode
        'seconds': nodes.SecondsNode
        'point2d': nodes.WorldPointNode
        'viewport': nodes.WorldViewportNode
        'bounds': nodes.WorldBoundsNode

    newPath = selected.getPath()
    return if newPath is @selectedScriptPath
    @scriptTreema = @$el.find('#script-treema').treema treemaOptions
    @scriptTreema.build()
    @scriptTreema.childrenTreemas?.noteChain?.open()
    @selectedScriptPath = newPath

  getThangIDs: ->
    (t.id for t in @level.get('thangs') when t.id isnt 'Interface')

  onScriptChanged: =>
    @scriptsTreema.set(@selectedScriptPath, @scriptTreema.data)


class ScriptNode extends TreemaObjectNode
  valueClass: 'treema-script'
  collection: false
  buildValueForDisplay: (valEl) ->
    val = @data.id or @data.channel
    s = "#{val}"
    @buildValueForDisplaySimply valEl, s

  onTabPressed: (e) ->
    @tabToCurrentScript()
    e.preventDefault()

  onRightArrowPressed: ->
    @tabToCurrentScript()

  tabToCurrentScript: ->
    @settings.view.scriptTreema?.keepFocus()
    window.v = @settings.view
    firstRow = @settings.view.scriptTreema?.$el.find('.treema-node:visible').data('instance')
    return unless firstRow?
    firstRow.select()


class EventPropsNode extends TreemaNode.nodeMap.string
  valueClass: 'treema-event-props'

  arrayToString: -> (@data or []).join('.')

  buildValueForDisplay: (valEl) ->
    joined = @arrayToString()
    joined = '(unset)' if not joined.length
    @buildValueForDisplaySimply valEl, joined

  buildValueForEditing: (valEl) -> @buildValueForEditingSimply(valEl, @arrayToString())

  saveChanges: (valEl) ->
    @data = (s for s in $('input', valEl).val().split('.') when s.length)

class EventPrereqsNode extends TreemaNode.nodeMap.array
  open: (depth=2) ->
    super(depth)

  addNewChild: ->
    newTreema = super(arguments)
    return unless newTreema?
    newTreema.open()
    newTreema.childrenTreemas.eventProps?.edit()

class EventPrereqNode extends TreemaNode.nodeMap.object
  buildValueForDisplay: (valEl) ->
    eventProp = (@data.eventProps or []).join('.')
    eventProp = '(unset)' unless eventProp.length
    statements = []
    for key, value of @data
      continue if key is 'eventProps'
      comparison = @schema.properties[key].title
      value = value.toString()
      statements.push("#{comparison} #{value}")
    statements = statements.join(', ')
    s = "#{eventProp} #{statements}"
    @buildValueForDisplaySimply valEl, s

class ChannelNode extends TreemaNode.nodeMap.string
  buildValueForEditing: (valEl) ->
    super(valEl)
    valEl.find('input').autocomplete(source: channels, minLength: 0, delay: 0, autoFocus: true)
    valEl

channels = [
  "tome:palette-hovered",
  "tome:palette-clicked",
  "tome:spell-shown",
  "end-current-script",
  "goal-manager:new-goal-states",
  "god:new-world-created",
  "help-multiplayer",
  "help-next",
  "help-overview",
  "level-restart-ask",
  "level-set-playing",
  "level:docs-hidden",
  "level:team-set",
  "playback:manually-scrubbed",
  "sprite:speech-updated",
  "surface:coordinates-shown",
  "surface:frame-changed",
  "surface:sprite-selected",
  "world:thang-attacked-when-out-of-range",
  "world:thang-collected-item",
  "world:thang-died",
  "world:thang-left-map",
  "world:thang-touched-goal",
  "world:won"
]
