module.exports = class SpriteOptimizer
  debug: false

  constructor: (@thangTypeModel, options={}) ->
    @aggressiveShapes = options.aggressiveShapes
    @aggressiveContainers = options.aggressiveContainers
    console.log 'Optimizing with aggressiveShapes:', @aggressiveShapes, 'and containers', @aggressiveContainers if @debug
    @raw = $.extend(true, {}, @thangTypeModel.attributes.raw)
    @raw.shapes ?= {}
    @raw.containers ?= {}
    @raw.animations ?= {}
    @colorGroups = $.extend(true, {}, @thangTypeModel.attributes.colorGroups)
    @actions = $.extend(true, {}, @thangTypeModel.attributes.actions)

  optimize: ->
    if @debug
      console.log 'Got shapes to optimize:', @raw.shapes, JSON.stringify(@raw.shapes, null, 0).length, "chars", _.size(@raw.shapes), "shapes"
      console.log 'Got containers to optimize:', @raw.containers, JSON.stringify(@raw.containers, null, 0).length, "chars", _.size(@raw.containers), "containers"
      console.log 'Got animations to optimize:', @raw.animations, JSON.stringify(@raw.animations, null, 0).length, "chars", _.size(@raw.animations), "animations"
      if _.size @colorGroups
        console.log 'Got colors to optimize:', @colorGroups, JSON.stringify(@colorGroups, null, 0).length, "chars", _.flatten(_.values(@colorGroups)).length, "colored shapes"
      console.log "Total:", JSON.stringify(@raw, null, 0).length, "chars"

    for round in [1 .. 3]
      # Hacky hack: certain optimizations work better after others, so we run once for basic pass, 2nd time to finish deduping containers that now realize they're referencing duplicate shapes, and 3rd time to get the most frequent unique shape/container names shorter. Better coding could make this require fewer passes, but it runs pretty fast anyway.
      @optimizeShapes()

      if @debug
        console.log "Renamed/deduplicated shapes, round #{round}:", @raw.shapes, JSON.stringify(@raw.shapes, null, 0).length, "chars", _.size(@raw.shapes), "shapes"
        console.log "Renamed/deduplicated containers, round #{round}:", @raw.containers, JSON.stringify(@raw.containers, null, 0).length, "chars", _.size(@raw.containers), "containers"
        console.log "Total:", JSON.stringify(@raw, null, 0).length, "chars"

      if round is 1
        @cullUnused()

        if @debug
          console.log "Culled shapes, round #{round}:", @raw.shapes, JSON.stringify(@raw.shapes, null, 0).length, "chars", _.size(@raw.shapes), "shapes"
          console.log "Culled containers, round #{round}:", @raw.containers, JSON.stringify(@raw.containers, null, 0).length, "chars", _.size(@raw.containers), "containers"
          console.log "Culled animations, round #{round}:", @raw.animations, JSON.stringify(@raw.animations, null, 0).length, "chars", _.size(@raw.animations), "animations"
          if _.size @colorGroups
            console.log "Culled colors, round #{round}:", @colorGroups, JSON.stringify(@colorGroups, null, 0).length, "chars", _.flatten(_.values(@colorGroups)).length, "colored shapes"
          console.log "Total:", JSON.stringify(@raw, null, 0).length, "chars"

    @sortBySize()

    @saveToModel()

  saveToModel: ->
    @thangTypeModel.set('raw', @raw)
    @thangTypeModel.set('actions', @actions)
    if _.size @colorGroups
      @thangTypeModel.set('colorGroups', @colorGroups)

  keyForShape: (shape) ->
    shape = _.omit shape, 't' if @aggressiveShapes  # Sometimes transform doesn't matter as far as unique shapes go (ex.: Hero A Cinematic), but sometimes it does (ex.: Hero B)
    JSON.stringify(_.values(shape), null, 0)

  keyForContainer: (container) ->
    container = _.cloneDeep container
    if container.b
      for num, index in container.b
        # Containers can be pretty similar except for very small variations in floating point numbers, causing expensive duplicates.
        # Hack: round off to a few significant digits according to heuristics of how much we care for small/large values.
        # This algorithm is stupid but should work well enough to not bother with coming up with the Correct Solution.
        container.b[index] = (num / 1000).toFixed(Math.min(3, Math.max(1, 5 - Math.log10(Math.abs(num)))))
        # for(var num of [-0.51, -0.49, -0.06, -0.03, 0.03, 0.06, 0.49, 0.51, 1.4, 1.5, 1.51, 14.9, 15.6, 99, 101, 101.1, 253.35235, 253.56363, 1098, 1101, 1110, 1111111111]) console.log(num, (num / 1000).toFixed(Math.min(3, Math.max(1, 5 - Math.log10(Math.abs(num))))), Math.log10(Math.abs(num)))
    JSON.stringify(_.values(container), null, 0)

  nameShape: (n) ->
    # Brittle with sortBySize
    #'s' + n  # If we want to sort shapes by size, their keys can't be integer-like
    n + ''  # But we don't really care about sorting shapes by size

  nameContainer: (n) ->
    # Brittle with sortBySize
    'c' + n

  optimizeShapes: ->
    shapeRenamings = {}
    containerRenamings = {}
    shapeDuplicates = {}
    containerDuplicates = {}

    # Rename shapes from 40-character hashes to simple numeric strings starting from 1, in order of usage frequency
    # Just look inside containers; raw.animations.shapes appears to always be empty, probably a legacy field.
    shapeFrequencies = {}
    for containerName, container of @raw.containers ? {}
      for child in container.c ? []
        continue if child.gn  # It's actually a container, not a shape
        shapeFrequencies[child] = (shapeFrequencies[child] ? 0) + 1
    shapesByFrequency = _.sortBy _.pairs(shapeFrequencies), ([shapeName, frequency]) -> -frequency
    for [shape, frequency] in shapesByFrequency
      shapeKey = @keyForShape @raw.shapes[shape]
      if newShapeName = shapeDuplicates[shapeKey]
        shapeRenamings[shape] = newShapeName  # This deduplicates identical shapes, keeping only the first
      else
        shapeDuplicates[shapeKey] = shapeRenamings[shape] = @nameShape _.size(shapeRenamings)

    if @debug
      console.log shapesByFrequency
      console.log shapeRenamings

    firstContainers = {}  # Just for debugging which containers we are rereferencing duplicates to

    # Now rename containers, which can be inside other containers or inside animations.
    # Containers can be referenced in more places inside animations and tweens, but let's not worry about frequency of use inside those; too complicated.
    containerFrequencies = {}
    for containerName, container of @raw.containers ? {}
      for child in container.c ? []
        if child.gn  # It's actually a container, not a shape
          containerFrequencies[child.gn] = (containerFrequencies[child.gn] ? 0) + 1
    for animationName, animation of @raw.animations ? {}
      for container in animation.containers ? []
        if container.bn isnt 'bn_' + container.gn + '_0'
          console.error 'Unexpected bn/gn name relationship', container.bn, container.gn
        containerFrequencies[container.gn] = (containerFrequencies[container.gn] ? 0) + 1
    for name, action of @actions
      if action.container
        containerFrequencies[action.container] = (containerFrequencies[action.container] ? 0) + 1
      for relatedActionName, relatedAction of action.relatedActions ? {}
        if relatedAction.container
          containerFrequencies[relatedAction.container] = (containerFrequencies[relatedAction.container] ? 0) + 1
    containersByFrequency = _.sortBy _.pairs(containerFrequencies), ([containerName, frequency]) -> -frequency
    for [container, frequency] in containersByFrequency
      containerKey = @keyForContainer @raw.containers[container]
      if @aggressiveContainers and newContainerName = containerDuplicates[containerKey]
        # TODO: fix issue where the same animation might have multiple tweens targeting the same container (which breaks) if we consolidate identical containers. Exmaple: Hero A Cinematic eatPopcorn animation, with three tweens referencing what would be c0 (most common container, a hand used 13 times overall)
        # Until now, only do this in aggressive mode (currently: shift+click the reoptimize button)
        containerRenamings[container] = newContainerName
        # This deduplicates identical containers, keeping only the first
        # It won't work right until we have also renamed the shapes within the containers, which is why we run multiple times. ;)
        if @debug and not _.isEqual @raw.containers[container], firstContainers[containerKey]
          console.log container, _.cloneDeep(@raw.containers[container]), 'is the same as', _.cloneDeep(firstContainers[containerKey])
      else
        containerDuplicates[containerKey] = containerRenamings[container] = @nameContainer _.size(containerRenamings)
        firstContainers[containerKey] = @raw.containers[container]

    if @debug
      console.log containersByFrequency
      console.log containerRenamings

    # Don't bother renaming animations, there aren't that many of them.
    # We also needn't bother deduping them, because we usually don't have that many duplicate animations, it's uncommon that we would configure an action to use two versions of the same animation, and it's just unfortunate if nested animations happen to nest two versions of the same animation.

    # Now reference the new names: in raw.shapes
    newShapes = {}
    for oldShapeName, newShapeName of shapeRenamings
      newShapes[newShapeName] = @raw.shapes[oldShapeName]
    @raw.shapes = newShapes

    # ... in raw.containers
    newContainers = {}
    for oldContainerName, newContainerName of containerRenamings
      newContainers[newContainerName] = @raw.containers[oldContainerName]
    @raw.containers = newContainers

    # ... for shapes and containers inside other containers
    for containerName, container of @raw.containers ? {}
      for child, index in container.c ? []
        if child.gn
          child.gn = containerRenamings[child.gn]
        else
          container.c[index] = shapeRenamings[child]

    # ... for containers inside various levels of nesting in animations and their tweens
    for animationName, animation of @raw.animations ? {}
      for container in animation.containers ? []
        container.gn = containerRenamings[container.gn]
        container.bn = 'bn_' + container.gn + '_0'  # I think bn always follows this pattern and can be derived from gn
      for tween in animation.tweens ? []
        for step in tween ? []
          for target, index in step.a ? []
            if renamedTarget = containerRenamings[target?.replace?(/bn_([a-f0-9]+)_0/i, '$1')]
              step.a[index] = 'bn_' + renamedTarget + '_0'
            else if target?.state and target.state.length
              for subTarget in target.state
                if subTarget?.t and renamedTarget = containerRenamings[subTarget.t.replace?(/bn_([a-f0-9]+)_0/i, '$1')]
                  subTarget.t = 'bn_' + renamedTarget + '_0'
            else if target?.length
              for subEntry in target
                if subEntry?.state?.length
                  for subSubEntry in subEntry.state
                    if renamedTarget = containerRenamings[subSubEntry?.t?.replace?(/bn_([a-f0-9]+)_0/i, '$1')]
                      subSubEntry.t = 'bn_' + renamedTarget + '_0'

    # ... and when containers are referenced directly within actions
    for name, action of @actions
      if action.container and renamedTarget = containerRenamings[action.container]
        action.container = renamedTarget
      for relatedActionName, relatedAction of action.relatedActions ? {}
        if relatedAction.container and renamedTarget = containerRenamings[relatedAction.container]
          relatedAction.container = renamedTarget

    # Also rename shapes within color groups
    for group, shapes of @colorGroups
      for oldShapeName, index in shapes
        if newShapeName = shapeRenamings[oldShapeName]
          shapes[index] = newShapeName

    if @debug
      console.log shapeRenamings
      console.log containerRenamings

  cullUnused: ->
    # Opposite direction of optimizeShapes. With more time, we could DRY this logic out, but let's do it quick, dirty, and WET.
    return unless _.size(@actions)  # Don't just delete everything if we are optimizing before we've configured any actions

    used = shapes: new Set(), containers: new Set(), animations: new Set()

    # We'll only process animations that correspond to a configured action
    for name, action of @actions
      used.animations.add action.animation if action.animation
      used.containers.add action.container if action.container  # Sometimes actions reference containers directly
      for relatedActionName, relatedAction of action.relatedActions ? {}
        used.animations.add relatedAction.animation if relatedAction.animation
        used.containers.add relatedAction.container if relatedAction.container

    # Make sure that we mark any nested animations as used. Feeling like stack solution instead of recursive today.
    animationsToProcess = Array.from used.animations
    while animation = animationsToProcess.pop()
      rawAnimation = @raw.animations[animation]
      for child in (rawAnimation.animations ? []) when child.gn and not used.animations.has child.gn
          used.animations.add child.gn
          animationsToProcess.push child.gn

    # Now walk the animations and mark their containers.
    # Just to be sure, mark containers used in tweens. This may be unnecessary; not bothering to do it for animations.
    for animationName in Array.from used.animations
      animation = @raw.animations[animationName]
      used.containers.add container.gn for container in animation.containers ? []
      for tween in animation.tweens ? []
        for step in tween ? []
          for target, index in step.a ? []
            # Tween targets may be containers or animations. Animations aren't renamed, so skip the ones with long names.
            if (containerName = target?.replace?(/bn_([c0-9]+)_0/i, '$1')) and containerName.length < 40
              used.containers.add containerName
            else if target?.state and target.state.length
              for subTarget in target.state
                if subTarget?.t and (containerName = subTarget?.t?.replace?(/bn_([c0-9]+)_0/i, '$1')) and containerName.length < 40
                  used.containers.add containerName
            else if target?.length
              for subEntry in target
                if subEntry?.state?.length
                  for subSubEntry in subEntry.state
                    if (containerName = subSubEntry?.t?.replace?(/bn_([c0-9]+)_0/i, '$1')) and containerName.length < 40
                      used.containers.add containerName

    # Make sure that we mark any nested containers as used
    containersToProcess = Array.from used.containers
    while container = containersToProcess.pop()
      rawContainer = @raw.containers[container]
      for child in (rawContainer.c ? []) when child.gn and not used.containers.has child.gn
          used.containers.add child.gn
          containersToProcess.push child.gn

    # Now that we know all the containers that are used, we know all the shapes that are used
    for container in Array.from used.containers
      rawContainer = @raw.containers[container]
      for child in (rawContainer.c ? []) when _.isString child
        used.shapes.add child

    if @debug
      console.log 'Used', used.shapes.size, 'shapes out of', _.size @raw.shapes
      console.log 'Used', used.containers.size, 'containers out of', _.size @raw.containers
      console.log 'Used', used.animations.size, 'animations out of', _.size @raw.animations

    @raw.shapes = _.omit @raw.shapes, (val, key) -> not used.shapes.has key
    @raw.containers = _.omit @raw.containers, (val, key) -> not used.containers.has key
    @raw.animations = _.omit @raw.animations, (val, key) -> not used.animations.has key

  sortBySize: ->
    # Could re-enable this if we wanted to put biggest shapes first, would have to put 'a' back in shape key for non-integer ordering
    #shapesBySize = Object.fromEntries Object.entries(@raw.shapes).sort (a, b) ->
    #  aScore = if a[1].bounds then 1000 * a[1].bounds[2] * a[1].bounds[3] else parseInt(a, 10)
    #  bScore = if b[1].bounds then 1000 * b[1].bounds[2] * b[1].bounds[3] else parseInt(b, 10)
    #  bScore - aScore
    #
    #console.log 'Shapes by size:', shapesBySize if @debug
    #
    #@raw.shapes = shapesBySize

    for shapeName, shape of @raw.shapes ? {}
      delete shape.bounds  # We don't even need this!

    # We do like having the biggest containers at the top, to help track down duplicate-ish containers and problems
    containersBySize = Object.fromEntries Object.entries(@raw.containers).sort (a, b) ->
      aScore = if a[1].b then 1000 * a[1].b[2] * a[1].b[3] else parseInt(a[0].slice(1), 10)
      bScore = if b[1].b then 1000 * b[1].b[2] * b[1].b[3] else parseInt(b[0].slice(1), 10)
      bScore - aScore

    console.log 'Containers by size:', containersBySize if @debug

    @raw.containers = containersBySize
