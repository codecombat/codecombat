CocoModel = require './CocoModel'
LevelComponent = require './LevelComponent'
LevelSystem = require './LevelSystem'
LevelConstants = require 'lib/LevelConstants'
ThangTypeConstants = require 'lib/ThangTypeConstants'
utils = require 'core/utils'

# Pure functions for use in Vue
# First argument is always a raw Level.attributes
# Accessible via eg. `Level.isProject(levelObj)`
LevelLib = {
  isProject: (level) ->
    return level?.shareable is 'project'
}

module.exports = class Level extends CocoModel
  @className: 'Level'
  @schema: require 'schemas/models/level'
  @levels: LevelConstants.levels
  urlRoot: '/db/level'
  editableByArtisans: true

  serialize: (options) ->
    {supermodel, session, otherSession, @headless, @sessionless, cached} = options
    cached ?= false
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
    sessionHeroes = [session?.get('heroConfig')?.thangType, otherSession?.get('heroConfig')?.thangType]
    o.thangTypes = []
    for tt in supermodel.getModels 'ThangType'
      if tmap[tt.get('original')] or
        (tt.get('kind') isnt 'Hero' and tt.get('kind')? and tt.get('components') and not tt.notInLevel) or
        (tt.get('kind') is 'Hero' and (@isType('course', 'course-ladder', 'game-dev') or tt.get('original') in sessionHeroes))
          o.thangTypes.push (original: tt.get('original'), name: tt.get('name'), components: $.extend(true, [], tt.get('components')), kind: tt.get('kind'))
    @sortThangComponents o.thangTypes, o.levelComponents, 'ThangType'
    @fillInDefaultComponentConfiguration o.thangTypes, o.levelComponents

    o.picoCTFProblem = @picoCTFProblem if @picoCTFProblem

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
    if o.thangs and @isType('hero', 'hero-ladder', 'hero-coop', 'course', 'course-ladder', 'game-dev', 'web-dev')
      thangTypesWithComponents = (tt for tt in supermodel.getModels('ThangType') when tt.get('components')?)
      thangTypesByOriginal = _.indexBy thangTypesWithComponents, (tt) -> tt.get('original')  # Optimization
      for levelThang in o.thangs
        @denormalizeThang(levelThang, supermodel, session, otherSession, thangTypesByOriginal)
    o

  denormalizeThang: (levelThang, supermodel, session, otherSession, thangTypesByOriginal) ->
    levelThang.components ?= []
    if /Hero Placeholder/.test(levelThang.id) and @get('assessment') isnt 'open-ended' 
      if @isType('hero', 'hero-ladder', 'hero-coop') and !me.isStudent()
        isHero = true
      else if @isType('course') and me.showHeroAndInventoryModalsToStudents() and not @isAssessment()
        isHero = true
      else
        isHero = false

    if isHero and @usesConfiguredMultiplayerHero()
      isHero = false  # Don't use the hero from the session, but rather the one configured in this level

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
      placeholderThangType = thangTypesByOriginal[levelThang.thangType]
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

    thangType = thangTypesByOriginal[levelThang.thangType]

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
        levelThangComponent.config ?= {}
        config = levelThangComponent.config
        if placeholderConfig.pos  # Pull in Physical pos x and y
          config.pos ?= {}
          config.pos.x = placeholderConfig.pos.x
          config.pos.y = placeholderConfig.pos.y
          config.rotation = placeholderConfig.rotation
        else if placeholderConfig.team  # Pull in Allied team
          config.team = placeholderConfig.team
        else if placeholderConfig.significantProperty  # For levels where we cheat on what counts as an enemy
          config.significantProperty = placeholderConfig.significantProperty
        else if placeholderConfig.programmableMethods
          # Take the ThangType default Programmable and merge level-specific Component config into it
          copy = $.extend true, {}, placeholderConfig
          programmableProperties = config?.programmableProperties ? []
          copy.programmableProperties = _.union programmableProperties, copy.programmableProperties ? []
          levelThangComponent.config = config = _.merge copy, config
        else if placeholderConfig.extraHUDProperties
          config.extraHUDProperties = _.union(config.extraHUDProperties ? [], placeholderConfig.extraHUDProperties)
        else if placeholderConfig.voiceRange  # Pull in voiceRange
          config.voiceRange = placeholderConfig.voiceRange
          config.cooldown = placeholderConfig.cooldown

    if isHero
      if equips = _.find levelThang.components, {original: LevelComponent.EquipsID}
        inventory = session?.get('heroConfig')?.inventory
        equips.config ?= {}
        equips.config.inventory = $.extend true, {}, inventory if inventory
      for original, placeholderComponent of placeholders when not placeholdersUsed[original]
        levelThang.components.push placeholderComponent

    # Load the user's chosen hero AFTER getting stats from default char
    if /Hero Placeholder/.test(levelThang.id) and @isType('course') and not @headless and not @sessionless and not window.serverConfig.picoCTF and @get('assessment') isnt 'open-ended' and (not me.showHeroAndInventoryModalsToStudents() or @isAssessment())
      heroThangType = me.get('heroConfig')?.thangType or ThangTypeConstants.heroes.captain
      # use default hero in class if classroomItems is on
      if @isAssessment() and me.showHeroAndInventoryModalsToStudents()
        heroThangType = ThangTypeConstants.heroes.captain
      levelThang.thangType = heroThangType if heroThangType

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

    originalsToComponents = _.indexBy levelComponents, 'original'  # Optimization for speed
    alliedComponent = _.find levelComponents, name: 'Allied'
    actsComponent = _.find levelComponents, name: 'Acts'

    for thang in thangs ? []
      originalsToThangComponents = _.indexBy thang.components, 'original'
      sorted = []
      visit = (c, namesToIgnore) ->
        return if c in sorted
        lc = originalsToComponents[c.original]
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
            c2 = originalsToThangComponents[d.original]
            unless c2
              dependent = originalsToComponents[d.original]
              dependent = dependent?.name or d.original
              console.error parentType, thang.id or thang.name, 'does not have dependent Component', dependent, 'from', lc.name
            visit c2 if c2
          if lc.name is 'Collides' and alliedComponent
            if allied = originalsToThangComponents[alliedComponent.original]
              visit allied
          if lc.name is 'Moves' and actsComponent
            if acts = originalsToThangComponents[actsComponent.original]
              visit acts
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

  isLadder: -> return Level.isLadder(@attributes)

  @isLadder: (level) -> level.type?.indexOf('ladder') > -1

  isProject: -> Level.isProject(@attributes)

  isType: (types...) ->
    return @get('type', true) in types

  getSolutions: ->
    return [] unless hero = _.find (@get("thangs") ? []), id: 'Hero Placeholder'
    return [] unless plan = _.find(hero.components ? [], (x) -> x?.config?.programmableMethods?.plan)?.config.programmableMethods.plan
    solutions = _.cloneDeep plan.solutions ? []
    for solution in solutions
      try
        solution.source = _.template(solution?.source)(utils.i18n(plan, 'context'))
      catch e
        console.error "Problem with template and solution comments for '#{@get('slug') or @get('name')}'\n", e
    solutions

  getSampleCode: (team='humans') ->
    heroThangID = if team is 'ogres' then 'Hero Placeholder 1' else 'Hero Placeholder'
    return {} unless hero = _.find (@get("thangs") ? []), id: heroThangID
    return {} unless plan = _.find(hero.components ? [], (x) -> x?.config?.programmableMethods?.plan)?.config.programmableMethods.plan
    sampleCode = _.cloneDeep plan.languages ? {}
    sampleCode.javascript = plan.source
    for language, code of sampleCode
      try
        sampleCode[language] = _.template(code)(plan.context)
      catch e
        console.error "Problem with template and solution comments for", @get('slug'), e
    sampleCode

  @thresholdForScore: ({level, type, score}) ->
    return null unless levelScoreTypes = level.scoreTypes
    return null unless levelScoreType = _.find(levelScoreTypes, {type})
    for threshold in ['gold', 'silver', 'bronze']
      thresholdValue = levelScoreType.thresholds[threshold]
      if type in LevelConstants.lowerIsBetterScoreTypes
        achieved = score <= thresholdValue
      else
        achieved = score >= thresholdValue
      if achieved
        return threshold

  isSummative: -> @get('assessment') in ['open-ended', 'cumulative']

  usesConfiguredMultiplayerHero: ->
    # For hero-ladder levels where we have configured Hero Placeholder inventory equipment, we must have intended to use it instead of letting the player choose their hero/equipment.
    return false unless @isType 'hero-ladder'
    return false unless levelThang = _.find @get('thangs'), id: 'Hero Placeholder'
    equips = _.find levelThang.components, {original: LevelComponent.EquipsID}
    return equips?.config?.inventory?

  isAssessment: -> @get('assessment')?

_.assign(Level, LevelLib)
