ThangState = require './thang_state'
{thangNames} = require './names'
{ArgumentError} = require './errors'
Rand = require './rand'

module.exports = class Thang
  @className: 'Thang'
  @remainingThangNames: {}

  @nextID: (spriteName, world) ->
    originals = thangNames[spriteName] or [spriteName]
    remaining = Thang.remainingThangNames[spriteName]
    remaining = Thang.remainingThangNames[spriteName] = originals.slice() unless remaining?.length

    baseName = remaining.splice(world.rand.rand(remaining.length), 1)[0]
    i = 0
    while true
      name = if i then "#{baseName} #{i}" else baseName
      extantThang = world.thangMap[name]
      break unless extantThang
      i++
    name

  @resetThangIDs: -> Thang.remainingThangNames = {}
  isThang: true
  apiProperties: ['id', 'spriteName', 'health', 'pos', 'team']

  constructor: (@world, @spriteName, @id) ->
    @spriteName ?= @constructor.className
    @id ?= @constructor.nextID @spriteName, @world
    @addTrackedProperties ['exists', 'boolean']  # TODO: move into Systems/Components, too?
    #console.log "Generated #{@toString()}."

  destroy: ->
    # Just trying to destroy __aetherAPIClone, but might as well nuke everything just in case
    @[key] = undefined for key of @
    @destroyed = true
    @destroy = ->

  updateRegistration: ->
    system.register @ for system in @world.systems

  publishNote: (channel, event) ->
    event.thang = @
    @world.publishNote channel, event

  getGoalState: (goalID) ->
    @world.getGoalState goalID

  setGoalState: (goalID, status) ->
    @world.setGoalState goalID, status

  getThangByID: (id) ->
    @world.getThangByID id

  addComponents: (components...) ->
    # We don't need to keep the components around after attaching them, but we will keep their initial config for recreating Thangs
    @components ?= []
    for [componentClass, componentConfig] in components
      @components.push [componentClass, componentConfig]
      if _.isString componentClass  # We had already turned it into a string, so re-classify it momentarily
        componentClass = @world.classMap[componentClass]
      else
        @world?.classMap[componentClass.className] ?= componentClass
      c = new componentClass componentConfig ? {}
      c.world = @world
      c.attach @

  # [prop, type]s of properties which have values tracked across WorldFrames. Also call keepTrackedProperty some non-expensive time when you change it or it will be skipped.
  addTrackedProperties: (props...) ->
    @trackedPropertiesKeys ?= []
    @trackedPropertiesTypes ?= []
    @trackedPropertiesUsed ?= []
    for [prop, type] in props
      unless type in ThangState.trackedPropertyTypes
        # How should errors for busted Components work? We can't recover from this and run the world.
        throw new Error "Type #{type} for property #{prop} is not a trackable property type: #{ThangState.trackedPropertyTypes}"
      oldPropIndex = @trackedPropertiesKeys.indexOf prop
      if oldPropIndex is -1
        @trackedPropertiesKeys.push prop
        @trackedPropertiesTypes.push type
        @trackedPropertiesUsed.push false
      else
        oldType = @trackedPropertiesTypes[oldPropIndex]
        if type isnt oldType
          throw new Error "Two types were specified for trackable property #{prop}: #{oldType} and #{type}."

  keepTrackedProperty: (prop) ->
    # Wish we could do this faster, but I can't think of how.
    propIndex = @trackedPropertiesKeys.indexOf prop
    if propIndex isnt -1
      @trackedPropertiesUsed[propIndex] = true

  # @trackedFinalProperties: names of properties which need to be tracked once at the end of the World; don't worry about types
  addTrackedFinalProperties: (props...) ->
    @trackedFinalProperties ?= []
    @trackedFinalProperties = @trackedFinalProperties.concat (k for k in props when not (k in @trackedFinalProperties))

  getState: ->
    @_state = new ThangState @
  setState: (state) ->
    @_state = state.restore()

  toString: -> @id

  createMethodChain: (methodName) ->
    @methodChains ?= {}
    chain = @methodChains[methodName]
    return chain if chain
    chain = @methodChains[methodName] = {original: @[methodName], user: null, components: []}
    @[methodName] = _.partial @callChainedMethod, methodName  # Optimize! _.partial is fastest I've found
    chain

  appendMethod: (methodName, newMethod) ->
    # Components add methods that come after the original method
    @createMethodChain(methodName).components.push newMethod

  callChainedMethod: (methodName, args...) ->
    # Optimize this like crazy--but how?
    chain = @methodChains[methodName]
    primaryMethod = chain.user or chain.original
    ret = primaryMethod?.apply @, args
    for componentMethod in chain.components
      ret2 = componentMethod.apply @, args
      ret = ret2 ? ret  # override return value only if not null
    ret

  getMethodSource: (methodName) ->
    source = {}
    if @methodChains? and methodName of @methodChains
      chain = @methodChains[methodName]
      source.original = chain.original.toString()
      source.user = chain.user?.toString()
    else
      source.original = @[methodName]?.toString() ? ''
    source.original = Aether.getFunctionBody source.original
    source

  serialize: ->
    o = {spriteName: @spriteName, id: @id, components: [], finalState: {}}
    for [componentClass, componentConfig], i in (@components ? [])
      if _.isString componentClass
        componentClassName = componentClass
      else
        componentClassName = componentClass.className
        @world.classMap[componentClass.className] ?= componentClass
      o.components.push [componentClassName, componentConfig]
    for trackedFinalProperty in @trackedFinalProperties ? []
      # TODO: take some (but not all) of serialize logic from ThangState to handle other types
      o.finalState[trackedFinalProperty] = @[trackedFinalProperty]
    # Since we might keep tracked properties later during streaming, we need to know which we think are unused.
    o.unusedTrackedPropertyKeys = (@trackedPropertiesKeys[propIndex] for used, propIndex in @trackedPropertiesUsed when not used)
    o

  @deserialize: (o, world, classMap, levelComponents) ->
    t = new Thang world, o.spriteName, o.id
    for [componentClassName, componentConfig] in o.components
      unless componentClass = classMap[componentClassName]
        console.debug 'Compiling new Component while deserializing:', componentClassName
        componentModel = _.find levelComponents, name: componentClassName
        componentClass = world.loadClassFromCode componentModel.js, componentClassName, 'component'
        world.classMap[componentClassName] = componentClass
      t.addComponents [componentClass, componentConfig]
    t.unusedTrackedPropertyKeys = o.unusedTrackedPropertyKeys
    t.unusedTrackedPropertyValues = (t[prop] for prop in o.unusedTrackedPropertyKeys)
    for prop, val of o.finalState
      # TODO: take some (but not all) of deserialize logic from ThangState to handle other types
      t[prop] = val
    t

  serializeForAether: ->
    {CN: @constructor.className, id: @id}

  getLankOptions: ->
    colorConfigs = @teamColors or @world?.getTeamColors() or {}
    options = {colorConfig: {}}
    if @id is 'Hero Placeholder' and not @world.getThangByID 'Hero Placeholder 1'

      # Single player color customization options
      player_tints = me.get('ozariaHeroConfig')?.tints or []
      player_tints.forEach((tint) =>
        for key,value of (tint.colorGroups or {})
          options.colorConfig[key] = _.clone(value)
      )

      return options
    if @team and teamColor = colorConfigs[@team]
      options.colorConfig.team = teamColor
    if @color and color = @grabColorConfig @color
      options.colorConfig.color = color
    if @colors
      options.colorConfig[colorType] = colorValue for colorType, colorValue of @colors
    options

  grabColorConfig: (color) ->
    {
      green: {hue: 0.33, saturation: 0.5, lightness: 0.5}
      black: {hue: 0, saturation: 0, lightness: 0.25}
      violet: {hue: 0.83, saturation: 0.5, lightness: 0.5}
    }[color]
