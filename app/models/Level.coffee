CocoModel = require './CocoModel'
LevelComponent = require './LevelComponent'
LevelSystem = require './LevelSystem'
ThangType = require './ThangType'

module.exports = class Level extends CocoModel
  @className: 'Level'
  @schema: require 'schemas/models/level'
  @levels:
    'dungeons-of-kithgard': '5411cb3769152f1707be029c'
    'defense-of-plainswood': '541b67f71ccc8eaae19f3c62'
  urlRoot: '/db/level'
  editableByArtisans: true

  serialize: (supermodel, session, otherSession, cached=false) ->
    o = @denormalize supermodel, session, otherSession # hot spot to optimize

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
    o.thangTypes = (original: tt.get('original'), name: tt.get('name'), components: $.extend(true, [], tt.get('components')) for tt in supermodel.getModels ThangType when tmap[tt.get('original')] or (tt.get('components') and not tt.notInLevel))
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

  denormalize: (supermodel, session, otherSession) ->
    o = $.extend true, {}, @attributes
    if o.thangs and @get('type', true) in ['hero', 'hero-ladder', 'hero-coop', 'course', 'course-ladder']
      for levelThang in o.thangs
        @denormalizeThang(levelThang, supermodel, session, otherSession)
    o

  denormalizeThang: (levelThang, supermodel, session, otherSession) ->
    levelThang.components ?= []
    isHero = /Hero Placeholder/.test(levelThang.id) and @get('type', true) in ['hero', 'hero-ladder', 'hero-coop']
    if isHero and otherSession
      # If it's a hero and there's another session, find the right session for it.
      # If there is no other session (playing against default code, or on single player), clone all placeholders.
      # TODO: actually look at the teams on these Thangs to determine which session should go with which placeholder.
      if levelThang.id is 'Hero Placeholder 1' and session.get('team') is 'humans'
        session = otherSession
      else if levelThang.id is 'Hero Placeholder' and session.get('team') is 'ogres'
        session = otherSession

    # Empty out placeholder Components and store their values if we're the hero placeholder.
    if isHero
      placeholders = {}
      placeholdersUsed = {}
      placeholderThangType = supermodel.getModelByOriginal(ThangType, levelThang.thangType)
      unless placeholderThangType
        console.error "Couldn't find placeholder ThangType for the hero!"
        isHero = false
      else
        for defaultPlaceholderComponent in placeholderThangType.get('components')
          placeholders[defaultPlaceholderComponent.original] = defaultPlaceholderComponent
        for thangComponent in levelThang.components
          placeholders[thangComponent.original] = thangComponent
        levelThang.components = []  # We have stored the placeholder values, so we can inherit everything else.
        heroThangType = session?.get('heroConfig')?.thangType
        levelThang.thangType = heroThangType if heroThangType

    thangType = supermodel.getModelByOriginal(ThangType, levelThang.thangType, (m) -> m.get('components')?)

    configs = {}
    for thangComponent in levelThang.components
      configs[thangComponent.original] = thangComponent

    for defaultThangComponent in thangType?.get('components') or []
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
          levelThangComponent.config ?= {}
          levelThangComponent.config.pos ?= {}
          levelThangComponent.config.pos.x = placeholderConfig.pos.x
          levelThangComponent.config.pos.y = placeholderConfig.pos.y
          levelThangComponent.config.rotation = placeholderConfig.rotation
        else if placeholderConfig.team  # Pull in Allied team
          levelThangComponent.config ?= {}
          levelThangComponent.config.team = placeholderConfig.team
        else if placeholderConfig.significantProperty  # For levels where we cheat on what counts as an enemy
          levelThangComponent.config ?= {}
          levelThangComponent.config.significantProperty = placeholderConfig.significantProperty
        else if placeholderConfig.programmableMethods
          # Take the ThangType default Programmable and merge level-specific Component config into it
          copy = $.extend true, {}, placeholderConfig
          programmableProperties = levelThangComponent.config?.programmableProperties ? []
          copy.programmableProperties = _.union programmableProperties, copy.programmableProperties ? []
          levelThangComponent.config = _.merge copy, levelThangComponent.config
        else if placeholderConfig.extraHUDProperties
          levelThangComponent.config ?= {}
          levelThangComponent.config.extraHUDProperties = _.union(levelThangComponent.config.extraHUDProperties ? [], placeholderConfig.extraHUDProperties)
        else if placeholderConfig.voiceRange  # Pull in voiceRange
          levelThangComponent.config ?= {}
          levelThangComponent.config.voiceRange = placeholderConfig.voiceRange
          levelThangComponent.config.cooldown = placeholderConfig.cooldown

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
    # Example: Moves doesn't depend on Acts, but if both exist, Moves must come after Acts. Another soft dependency example.
    # Decision? Just special case the sort logic in here until we have more examples than these two and decide how best to handle most of the cases then, since we don't really know the whole of the problem yet.
    # TODO: anything that depends on Programmable will break right now.

    for thang in thangs ? []
      sorted = []
      visit = (c, namesToIgnore) ->
        return if c in sorted
        lc = _.find levelComponents, {original: c.original}
        console.error thang.id or thang.name, 'couldn\'t find lc for', c, 'of', levelComponents unless lc
        return unless lc
        return if namesToIgnore and lc.name in namesToIgnore
        if lc.name is 'Plans'
          # Plans always comes second-to-last, behind Programmable
          visit c2, [lc.name, 'Programmable'] for c2 in thang.components
        else if lc.name is 'Programmable'
          # Programmable always comes last
          visit c2, [lc.name] for c2 in thang.components
        else
          for d in lc.dependencies or []
            c2 = _.find thang.components, {original: d.original}
            unless c2
              dependent = _.find levelComponents, {original: d.original}
              dependent = dependent?.name or d.original
              console.error parentType, thang.id or thang.name, 'does not have dependent Component', dependent, 'from', lc.name
            visit c2 if c2
          if lc.name is 'Collides'
            if allied = _.find levelComponents, {name: 'Allied'}
              allied = _.find(thang.components, {original: allied.original})
              visit allied if allied
          if lc.name is 'Moves'
            if acts = _.find levelComponents, {name: 'Acts'}
              acts = _.find(thang.components, {original: acts.original})
              visit acts if acts
        #console.log thang.id, 'sorted comps adding', lc.name
        sorted.push c
      for comp in thang.components
        visit comp
      thang.components = sorted

  fillInDefaultComponentConfiguration: (thangs, levelComponents) ->
    # This is slow, so I inserted some optimizations to speed it up by caching the eventual defaults of commonly-used Components.
    @defaultComponentConfigurations ?= {}
    cached = 0
    missed = 0
    cachedConfigs = 0
    for thang in thangs ? []
      for component in thang.components or []
        isPhysical = component.original is LevelComponent.PhysicalID
        if not isPhysical and defaultConfiguration = _.find @defaultComponentConfigurations[component.original], ((d) -> _.isEqual component, d.originalComponent)
          component.config = defaultConfiguration.defaultedConfig
          ++cached
          continue
        continue unless lc = _.find levelComponents, {original: component.original}
        unless isPhysical
          originalComponent = $.extend true, {}, component
        component.config ?= {}
        TreemaUtils.populateDefaults(component.config, lc.configSchema ? {}, tv4)
        @lastType = 'component'
        @lastOriginal = component.original
        unless isPhysical
          @defaultComponentConfigurations[component.original] ?= []
          @defaultComponentConfigurations[component.original].push originalComponent: originalComponent, defaultedConfig: component.config
          ++cachedConfigs
        ++missed
    #console.log 'cached', cached, 'missed', missed

  fillInDefaultSystemConfiguration: (levelSystems) ->
    for system in levelSystems ? []
      system.config ?= {}
      TreemaUtils.populateDefaults(system.config, system.model.configSchema, tv4)
      @lastType = 'system'
      @lastOriginal = system.model.name

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
