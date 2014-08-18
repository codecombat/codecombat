CocoView = require 'views/kinds/CocoView'
template = require 'templates/editor/component/thang-component-config-view'

Level = require 'models/Level'
LevelComponent = require 'models/LevelComponent'
nodes = require '../level/treema_nodes'

module.exports = class ThangComponentConfigView extends CocoView
  className: 'thang-component-config-view'
  template: template
  changed: false

  events:
    'click .treema-shortened': -> console.log 'clicked treema root'

  constructor: (options) ->
    super options
    @component = options.component
    @config = options.config or {}
    @world = options.world
    @level = options.level
    @callback = options.callback

  getRenderData: (context={}) ->
    context = super(context)
    context.component = @component.attributes
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
    config = $.extend true, {}, @config
    schema = $.extend true, {}, @component.get('configSchema')
    if @level?.get('type') is 'hero'
      schema.required = []
    treemaOptions =
      supermodel: @supermodel
      schema: schema
      data: config
      callbacks: {change: @onConfigEdited}
      world: @world
      view: @
      thangIDs: thangIDs
      teams: teams
      superteams: superteams
      nodeClasses:
        object: ComponentConfigNode
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
        'item-thang-type': nodes.ItemThangTypeNode

    @editThangTreema = @$el.find('.treema').treema treemaOptions
    @editThangTreema.build()
    @editThangTreema.open(2)
    if _.isEqual(@editThangTreema.data, {}) and not @editThangTreema.canAddChild()
      @$el.find('.panel-body').hide()

  onConfigEdited: =>
    @changed = true
    @trigger 'changed', { component: @component, config: @data() }

  data: -> @editThangTreema.data

class ComponentConfigNode extends TreemaObjectNode
  nodeDescription: 'Component Property'
