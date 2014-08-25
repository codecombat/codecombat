CocoView = require 'views/kinds/CocoView'
template = require 'templates/play/level/level-flags-view'
{me} = require 'lib/auth'

module.exports = class LevelFlagsView extends CocoView
  id: 'level-flags-view'
  template: template

  subscriptions:
    'playback:real-time-playback-started': 'onRealTimePlaybackStarted'
    'playback:real-time-playback-ended': 'onRealTimePlaybackEnded'
    'surface:stage-mouse-down': 'onStageMouseDown'
    'god:new-world-created': 'onNewWorld'
    'god:streaming-world-updated': 'onNewWorld'
    'surface:remove-flag': 'onRemoveFlag'

  events:
    'click .green-flag': -> @onFlagSelected color: 'green', source: 'button'
    'click .black-flag': -> @onFlagSelected color: 'black', source: 'button'
    'click .violet-flag': -> @onFlagSelected color: 'violet', source: 'button'

  shortcuts:
    'g': -> @onFlagSelected color: 'green', source: 'shortcut'
    'b': -> @onFlagSelected color: 'black', source: 'shortcut'
    'v': -> @onFlagSelected color: 'violet', source: 'shortcut'
    'esc': -> @onFlagSelected color: null, source: 'shortcut'
    'delete, del, backspace': 'onDeletePressed'

  constructor: (options) ->
    super options
    @world = options.world

  onRealTimePlaybackStarted: (e) ->
    @realTime = true
    @$el.show()
    @flags = {}
    @flagHistory = []

  onRealTimePlaybackEnded: (e) ->
    @onFlagSelected color: null
    @realTime = false
    @$el.hide()

  onFlagSelected: (e) ->
    return unless @realTime
    color = if e.color is @flagColor then null else e.color
    @flagColor = color
    Backbone.Mediator.publish 'level:flag-color-selected', color: color
    @$el.find('.flag-button').removeClass('active')
    @$el.find(".#{color}-flag").addClass('active') if color

  onStageMouseDown: (e) ->
    return unless @flagColor and @realTime
    pos = x: e.worldPos.x, y: e.worldPos.y
    flag = player: me.id, team: me.team, color: @flagColor, pos: pos, time: @world.dt * @world.frames.length, active: true
    @flags[@flagColor] = flag
    @flagHistory.push flag
    Backbone.Mediator.publish 'level:flag-updated', flag
    #console.log 'trying to place flag at', @world.age, 'and think it will happen by', flag.time

  onDeletePressed: (e) ->
    return unless @realTime
    Backbone.Mediator.publish 'surface:remove-selected-flag', {}

  onRemoveFlag: (e) ->
    delete @flags[e.color]
    flag = player: me.id, team: me.team, color: e.color, time: @world.dt * @world.frames.length, active: false
    @flagHistory.push flag
    Backbone.Mediator.publish 'level:flag-updated', flag
    #console.log e.color, 'deleted at time', flag.time

  onNewWorld: (event) ->
    return unless event.world.name is @world.name
    @world = @options.world = event.world
