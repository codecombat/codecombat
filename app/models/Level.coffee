CocoModel = require './CocoModel'
LevelComponent = require './LevelComponent'
LevelSystem = require './LevelSystem'
ThangType = require './ThangType'

module.exports = class Level extends CocoModel
  @className: 'Level'
  @schema: require 'schemas/models/level'
  urlRoot: '/db/level'

  serialize: (supermodel, session) ->
    o = @denormalize supermodel, session

    # Figure out Components
    o.levelComponents = _.cloneDeep (lc.attributes for lc in supermodel.getModels LevelComponent)
    @sortThangComponents o.thangs, o.levelComponents
    @fillInDefaultComponentConfiguration o.thangs, o.levelComponents

    # Figure out Systems
    systemModels = _.cloneDeep (ls.attributes for ls in supermodel.getModels LevelSystem)
    o.systems = @sortSystems o.systems, systemModels
    @fillInDefaultSystemConfiguration o.systems

    # Figure out ThangTypes' Components
    o.thangTypes = (original: tt.get('original'), name: tt.get('name'), components: $.extend(true, [], tt.get('components')) for tt in supermodel.getModels ThangType)
    @sortThangComponents o.thangTypes, o.levelComponents
    @fillInDefaultComponentConfiguration o.thangTypes, o.levelComponents

    o

  denormalize: (supermodel, session) ->
    o = $.extend true, {}, @attributes
    if @get('type') is 'hero'
      # TOOD: figure out if/when/how we are doing this for non-Hero levels that aren't expecting denormalization.
      for levelThang in o.thangs
        @denormalizeThang(levelThang, supermodel, session)
    o

  denormalizeThang: (levelThang, supermodel, session) ->
    levelThang.components ?= []
    thangType = supermodel.getModelByOriginal(ThangType, levelThang.thangType)

    # Empty out placeholder Components and store their values if we're the hero placeholder.
    placeholders = {}
    if levelThang.id is 'Hero Placeholder'
      for thangComponent in levelThang.components ? []
        placeholders[thangComponent.original] = thangComponent
      levelThang.components = []
      heroThangType = session?.get('heroConfig')?.thangType
      levelThang.thangType = heroThangType if heroThangType

    configs = {}
    for thangComponent in levelThang.components
      configs[thangComponent.original] = thangComponent

    for defaultThangComponent in thangType.get('components')
      if levelThangComponent = configs[defaultThangComponent.original]
        # Take the ThangType default Components and merge level-specific Component config into it
        copy = $.extend true, {}, defaultThangComponent.config
        levelThangComponent.config = _.merge copy, levelThangComponent.config

      else
        # Just add the Component as is
        levelThangComponent = $.extend true, {}, defaultThangComponent
        levelThang.components.push levelThangComponent

      if placeholderComponent = placeholders[defaultThangComponent.original]
        placeholderConfig = placeholderComponent.config ? {}
        if placeholderConfig.pos  # Pull in Physical pos x and y
          levelThangComponent.config.pos ?= {}
          levelThangComponent.config.pos.x = placeholderConfig.pos.x
          levelThangComponent.config.pos.y = placeholderConfig.pos.y
        else if placeholderConfig.team  # Pull in Allied team
          levelThangComponent.config.team = placeholderConfig.team
        else if placeholderConfig.programmableMethods
          # Take the ThangType default Programmable and merge level-specific Component config into it
          copy = $.extend true, {}, placeholderConfig
          levelThangComponent.config = _.merge copy, levelThangComponent.config

    if levelThang.id is 'Hero Placeholder' and equips = _.find levelThang.components, {original: LevelComponent.EquipsID}
      inventory = session?.get('heroConfig')?.inventory
      equips.config.inventory = $.extend true, {}, inventory if inventory


  sortSystems: (levelSystems, systemModels) ->
    [sorted, originalsSeen] = [[], {}]
    visit = (system) ->
      return if system.original of originalsSeen
      systemModel = _.find systemModels, {original: system.original}
      return console.error 'Couldn\'t find model for original', system.original, 'from', systemModels unless systemModel
      for d in systemModel.dependencies or []
        system2 = _.find levelSystems, {original: d.original}
        visit system2
      #console.log 'sorted systems adding', systemModel.name
      sorted.push {model: systemModel, config: _.cloneDeep system.config}
      originalsSeen[system.original] = true
    visit system for system in levelSystems
    sorted

  sortThangComponents: (thangs, levelComponents) ->
    # Here we have to sort the Components by their dependencies.
    # It's a bit tricky though, because we don't have either soft dependencies or priority levels.
    # Example: Programmable must come last, since it has to override any Component-provided methods that any other Component might have created. Can't enumerate all soft dependencies.
    # Example: Collides doesn't depend on Allied, but if both exist, Collides must come after Allied. Soft dependency example. Can't just figure out a proper priority to take care of it.
    # Decision? Just special case the sort logic in here until we have more examples than these two and decide how best to handle most of the cases then, since we don't really know the whole of the problem yet.
    # TODO: anything that depends on Programmable will break right now.

    for thang in thangs
      sorted = []
      visit = (c) ->
        return if c in sorted
        lc = _.find levelComponents, {original: c.original}
        console.error thang.id or thang.name, 'couldn\'t find lc for', c, 'of', levelComponents unless lc
        return unless lc
        if lc.name is 'Programmable'
          # Programmable always comes last
          visit c2 for c2 in _.without thang.components, c
        else
          for d in lc.dependencies or []
            c2 = _.find thang.components, {original: d.original}
            console.error thang.id or thang.name, 'couldn\'t find dependent Component', d.original, 'from', lc.name unless c2
            visit c2 if c2
          if lc.name is 'Collides'
            allied = _.find levelComponents, {name: 'Allied'}
            if allied
              collides = _.find(thang.components, {original: allied.original})
              visit collides if collides
        #console.log thang.id, 'sorted comps adding', lc.name
        sorted.push c
      for comp in thang.components
        visit comp
      thang.components = sorted

  fillInDefaultComponentConfiguration: (thangs, levelComponents) ->
    for thang in thangs
      for component in thang.components or []
        continue unless lc = _.find levelComponents, {original: component.original}
        component.config ?= {}
        @walkDefaults component.config, lc.configSchema.properties

  fillInDefaultSystemConfiguration: (levelSystems) ->
    for system in levelSystems ? []
      system.config ?= {}
      @walkDefaults system.config, system.model.configSchema.properties

  walkDefaults: (config, properties) ->
    return unless properties
    for prop, schema of properties
      if schema.default? and config[prop] is undefined
        #console.log 'Setting default of', config, 'for', prop, 'to', schema.default
        config[prop] = schema.default
      if schema.type is 'object' and config[prop]
        @walkDefaults config[prop], schema.properties
      else if schema.type is 'array' and config[prop]
        for item in config[prop] or []
          @walkDefaults item, schema.items

  dimensions: ->
    width = 0
    height = 0
    for thang in @get('thangs') or []
      for component in thang.components
        c = component.config
        continue unless c?
        width = c.width if c.width? and c.width > width
        height = c.height if c.height? and c.height > height
    return {width: width, height: height}
