# The System will operate on its Thangs of interest in each WorldFrame.
# Systems so far: AI, UI, Collision, Movement, Targeting, Programming, Combat, Vision, Hearing, Inventory, Actions
# Other Systems might be things like Attraction, EdgeBounce, EdgeWrap, and non-physics ones, too, like Rendering, Animation, ...

module.exports = class System
  @className: 'System'
  constructor: (@world, config) ->
    # Unlike with Component, we don't automatically copy all our properties onto the World.
    # Subclasses can copy select properties here if they like.
    for key, value of (config ? {})
      @[key] = value
    @registries = []
    @hashes = {}

  # Start is called once the beginning, after all Thangs have been loaded.
  start: (thangs) ->

  # Update is called once per frame on all thangs that currently have exist=true in the World.
  # We return a simple numeric hash that will combine to a frame hash help us determine whether this frame has changed later on.
  update: (thangs) ->
    hash = 0

  # Finish is called once at the end, after all frames have been generated.
  finish: (thangs) ->

  addRegistry: (condition) ->
    registry = []
    @registries.push [registry, condition]
    registry

  # Register is called whenever a Thang changes important state (exists, dead, etc), and can be called more specifically by individual Thangs.
  register: (thang) ->
    for [registry, condition] in @registries
      if condition thang
        if thang not in registry
          registry.push thang
      else
        thangIndex = registry.indexOf thang
        if thangIndex isnt -1
          registry.splice thangIndex, 1
    null

  # Override this to determine which registries have which conditions
  checkRegistration: (thang, registry) ->

  hashString: (s) ->
    return @hashes[s] if s of @hashes
    hash = 0
    for i in [0 ... Math.min(s.length, 100)]
      hash = hash * 31 + s.charCodeAt(i)
    hash = @hashes[s] = hash % 3.141592653589793
    hash

  toString: ->
    "<System: #{@constructor.className}"
