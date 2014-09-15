CocoModel = require './CocoModel'
LevelComponent = require './LevelComponent'
LevelSystem = require './LevelSystem'
ThangType = require './ThangType'

module.exports = class Level extends CocoModel
  @className: 'Level'
  @schema: require 'schemas/models/level'
  urlRoot: '/db/level'

  serialize: (supermodel, session, cached=false) ->
    o = @denormalize supermodel, session # hot spot to optimize

    # Figure out Components
    o.levelComponents = if cached then @getCachedLevelComponents(supermodel) else $.extend true, [], (lc.attributes for lc in supermodel.getModels LevelComponent)
    @sortThangComponents o.thangs, o.levelComponents, 'Level Thang'
    @fillInDefaultComponentConfiguration o.thangs, o.levelComponents # hot spot to optimize

    # Figure out Systems
    systemModels = $.extend true, [], (ls.attributes for ls in supermodel.getModels LevelSystem)
    o.systems = @sortSystems o.systems, systemModels
    @fillInDefaultSystemConfiguration o.systems

    # Figure out ThangTypes' Components
    tmap = {}
    tmap[t.thangType] = true for t in o.thangs ? []
    o.thangTypes = (original: tt.get('original'), name: tt.get('name'), components: $.extend(true, [], tt.get('components')) for tt in supermodel.getModels ThangType when tmap[tt.get('original')] or tt.get('components'))
    @sortThangComponents o.thangTypes, o.levelComponents, 'ThangType'
    @fillInDefaultComponentConfiguration o.thangTypes, o.levelComponents

    o

  cachedLevelComponents: null

  getCachedLevelComponents: (supermodel) ->
    @cachedLevelComponents ?= {}
    levelComponents = supermodel.getModels LevelComponent
    newLevelComponents = []
    for levelComponent in levelComponents
      if levelComponent.hasLocalChanges()
        newLevelComponents.push $.extend(true, {}, levelComponent.attributes)
        continue
      @cachedLevelComponents[levelComponent.id] ?= @cachedLevelComponents[levelComponent.id] = $.extend(true, {}, levelComponent.attributes)
      newLevelComponents.push(@cachedLevelComponents[levelComponent.id])
    newLevelComponents

  denormalize: (supermodel, session) ->
    o = $.extend true, {}, @attributes
    if o.thangs and @get('type', true) is 'hero'
      # TOOD: figure out if/when/how we are doing this for non-Hero levels that aren't expecting denormalization.
      for levelThang in o.thangs
        @denormalizeThang(levelThang, supermodel, session)
    o

  denormalizeThang: (levelThang, supermodel, session) ->
    levelThang.components ?= []
    isHero = levelThang.id is 'Hero Placeholder'

    # Empty out placeholder Components and store their values if we're the hero placeholder.
    if isHero
      placeholders = {}
      placeholdersUsed = {}
      placeholderThangType = supermodel.getModelByOriginal(ThangType, levelThang.thangType)
      for defaultPlaceholderComponent in placeholderThangType.get('components')
        placeholders[defaultPlaceholderComponent.original] = defaultPlaceholderComponent
      for thangComponent in levelThang.components
        placeholders[thangComponent.original] = thangComponent
      levelThang.components = []  # We have stored the placeholder values, so we can inherit everything else.
      heroThangType = session?.get('heroConfig')?.thangType
      levelThang.thangType = heroThangType if heroThangType

    thangType = supermodel.getModelByOriginal(ThangType, levelThang.thangType)

    configs = {}
    for thangComponent in levelThang.components
      configs[thangComponent.original] = thangComponent

    for defaultThangComponent in thangType.get('components') or []
      if levelThangComponent = configs[defaultThangComponent.original]
        # Take the ThangType default Components and merge level-specific Component config into it
        copy = $.extend true, {}, defaultThangComponent.config
        levelThangComponent.config = _.merge copy, levelThangComponent.config

      else
        # Just add the Component as is
        levelThangComponent = $.extend true, {}, defaultThangComponent
        levelThang.components.push levelThangComponent

      if isHero and placeholderComponent = placeholders[defaultThangComponent.original]
        placeholdersUsed[placeholderComponent.original] = true
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

    if isHero
      if equips = _.find levelThang.components, {original: LevelComponent.EquipsID}
        inventory = session?.get('heroConfig')?.inventory
        equips.config ?= {}
        equips.config.inventory = $.extend true, {}, inventory if inventory
      for original, placeholderComponent of placeholders when not placeholdersUsed[original]
        levelThang.components.push placeholderComponent


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
      sorted.push {model: systemModel, config: $.extend true, {}, system.config}
      originalsSeen[system.original] = true
    visit system for system in levelSystems ? []
    sorted

  sortThangComponents: (thangs, levelComponents, parentType) ->
    # Here we have to sort the Components by their dependencies.
    # It's a bit tricky though, because we don't have either soft dependencies or priority levels.
    # Example: Programmable must come last, since it has to override any Component-provided methods that any other Component might have created. Can't enumerate all soft dependencies.
    # Example: Plans needs to come after everything except Programmable, since other Components that add plannable methods need to have done so by the time Plans is attached.
    # Example: Collides doesn't depend on Allied, but if both exist, Collides must come after Allied. Soft dependency example. Can't just figure out a proper priority to take care of it.
    # Decision? Just special case the sort logic in here until we have more examples than these two and decide how best to handle most of the cases then, since we don't really know the whole of the problem yet.
    # TODO: anything that depends on Programmable will break right now.

    for thang in thangs ? []
      programmableLevelComponent = null
      plansLevelComponent = null
      sorted = []
      visit = (c) ->
        return if c in sorted
        lc = _.find levelComponents, {original: c.original}
        console.error thang.id or thang.name, 'couldn\'t find lc for', c, 'of', levelComponents unless lc
        return unless lc
        if lc.name is 'Plans'
          # Plans always comes second-to-last, behind Programmable
          plansLevelComponent = c
          visit c2 for c2 in _.without thang.components, c, programmableLevelComponent
        else if lc.name is 'Programmable'
          # Programmable always comes last
          programmableLevelComponent = c
          visit c2 for c2 in _.without thang.components, c
        else
          for d in lc.dependencies or []
            c2 = _.find thang.components, {original: d.original}
            unless c2
              dependent = _.find levelComponents, {original: d.original}
              dependent = dependent?.name or d.original
              console.error parentType, thang.id or thang.name, 'does not have dependent Component', dependent, 'from', lc.name
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
    for thang in thangs ? []
      for component in thang.components or []
        continue unless lc = _.find levelComponents, {original: component.original}
        component.config ?= {}
        TreemaUtils.populateDefaults(component.config, lc.configSchema, tv4)
        @lastType = 'component'
        @lastOriginal = component.original
        @walkDefaults component.config, lc.configSchema.properties

  fillInDefaultSystemConfiguration: (levelSystems) ->
    for system in levelSystems ? []
      system.config ?= {}
      TreemaUtils.populateDefaults(system.config, system.model.configSchema, tv4)
      @lastType = 'system'
      @lastOriginal = system.model.name
      @walkDefaults system.config, system.model.configSchema.properties

  walkDefaults: (config, properties) ->
    # This function is redundant, but is the old implementation.
    # Remove it and calls to it once we stop seeing these warnings.
    return unless properties
    for prop, schema of properties
      if schema.default? and config[prop] is undefined
        console.warn 'Setting default of', config, 'for', prop, 'to', schema.default, 'but this method is deprecated... check your config schema!', @lastType, @lastOriginal
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
