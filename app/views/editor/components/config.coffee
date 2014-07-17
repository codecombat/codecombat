CocoView = require 'views/kinds/CocoView'
template = require 'templates/editor/components/config'

Level = require 'models/Level'
LevelComponent = require 'models/LevelComponent'
nodes = require '../level/treema_nodes'

module.exports = class ComponentConfigView extends CocoView
  id: 'component-config-column-view'
  template: template
  className: 'column'
  changed: false

  constructor: (options) ->
    super options
    @component = options.component
    @config = options.config or {}
    @world = options.world
    @level = options.level
    @editing = options.editing
    @callback = options.callback

  getRenderData: (context={}) ->
    context = super(context)
    context.component = @component
    context.configProperties = []
    context

  afterRender: ->
    super()
    @buildTreema()

  buildTreema: ->
    thangs = if @level? then @level.get('thangs') else []
    thangIDs = _.filter(_.pluck(thangs, 'id'))
    teams = _.filter(_.pluck(thangs, 'team'))
    superteams = _.filter(_.pluck(thangs, 'superteam'))
    superteams = _.union(teams, superteams)
    treemaOptions =
      supermodel: @supermodel
      schema: @component.configSchema
      data: _.cloneDeep @config
      callbacks: {change: @onConfigEdited}
      world: @world
      view: @
      thangIDs: thangIDs
      teams: teams
      superteams: superteams
      nodeClasses:
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
    treemaOptions.readOnly = not @editing

    @editThangTreema = @$el.find('.treema').treema treemaOptions
    @editThangTreema.build()
    @editThangTreema.open(2)
    @hideLoading()

  onConfigEdited: =>
    @changed = true
    @callback?(@data())

  data: -> @editThangTreema.data
