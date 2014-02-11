View = require 'views/kinds/RootView'
template = require 'templates/home'
WizardSprite = require 'lib/surface/WizardSprite'
ThangType = require 'models/ThangType'
LevelLoader = require 'lib/LevelLoader'
God = require 'lib/God'

module.exports = class HomeView extends View
  id: 'home-view'
  template: template

  events:
    'mouseover #beginner-campaign': 'onMouseOverButton'
    'mouseout #beginner-campaign': 'onMouseOutButton'
    'click #simulate-button': 'onSimulateButtonClick'

  getRenderData: ->
    c = super()
    if $.browser
      majorVersion = parseInt($.browser.version.split('.')[0])
      c.isOldBrowser = true if $.browser.mozilla && majorVersion < 21
      c.isOldBrowser = true if $.browser.chrome && majorVersion < 17
      c.isOldBrowser = true if $.browser.safari && majorVersion < 536
    else
      console.warn 'no more jquery browser version...'
    c

  afterRender: ->
    super()
    @$el.find('.modal').on 'shown.bs.modal', ->
      $('input:visible:first', @).focus()

    wizOriginal = "52a00d55cf1818f2be00000b"
    url = "/db/thang_type/#{wizOriginal}/version"
    @wizardType = new ThangType()
    @wizardType.url = -> url
    @wizardType.fetch()
    @wizardType.once 'sync', @initCanvas

    # Try to find latest level and set "Play" link to go to that level
    if localStorage?
      lastLevel = localStorage["lastLevel"]
      if lastLevel? and lastLevel isnt ""
        playLink = @$el.find("#beginner-campaign")
        if playLink?
          href = playLink.attr("href").split("/")
          href[href.length-1] = lastLevel if href.length isnt 0
          href = href.join("/")
          playLink.attr("href", href)
    else
      console.log("TODO: Insert here code to get latest level played from the database. If this can't be found, we just let the user play the first level.")

  initCanvas: =>
    @stage = new createjs.Stage($('#beginner-campaign canvas', @$el)[0])
    @createWizard()

  turnOnStageUpdates: ->
    clearInterval @turnOff
    @interval = setInterval(@updateStage, 40) unless @interval

  turnOffStageUpdates: ->
    turnOffFunc = =>
      clearInterval @interval
      clearInterval @turnOff
      @interval = null
      @turnOff = null
    @turnOff = setInterval turnOffFunc, 2000

  createWizard: (scale=1.0) ->
    spriteOptions = thangID: "Beginner Wizard", resolutionFactor: scale
    @wizardSprite = new WizardSprite @wizardType, spriteOptions
    @wizardSprite.update()
    wizardDisplayObject = @wizardSprite.displayObject
    wizardDisplayObject.x = 120
    wizardDisplayObject.y = 35
    wizardDisplayObject.scaleX = wizardDisplayObject.scaleY = scale
    wizardDisplayObject.scaleX *= -1
    @stage.addChild wizardDisplayObject
    @stage.update()

  onMouseOverButton: ->
    @turnOnStageUpdates()
    @wizardSprite?.queueAction 'cast'

  onMouseOutButton: ->
    @turnOffStageUpdates()
    @wizardSprite?.queueAction 'idle'

  updateStage: =>
    @stage?.update()

  willDisappear: ->
    super()
    clearInterval(@interval) if @interval
    @interval = null

  didReappear: ->
    super()
    @turnOnStageUpdates()

  onSimulateButtonClick: (e) =>
    $.get "/queue/scoring", (data) =>
      levelName = data.sessions[0].levelID
      console.log data

      world = {}
      god = new God()
      levelLoader = new LevelLoader(levelName, @supermodel, data.sessions[0].sessionID)
      levelLoader.once 'loaded-all', =>
        world = levelLoader.world
        level = levelLoader.level
        levelLoader.destroy()
        god.spells = @filterProgrammableComponents level.attributes.thangs, @generateSpellToSourceMap data.sessions

        #generate spell
        #spells = @createSpells programmableThangs
        #console.log spells

        god.level = level.serialize @supermodel
        god.worldClassMap = world.classMap

        god.createWorld()

        Backbone.Mediator.subscribe 'god:new-world-created', @onWorldCreated, @

  onWorldCreated: (data) ->
    console.log "GOAL STATES"
    console.log data.goalStates


  filterProgrammableComponents: (thangs, spellToSourceMap) =>
    spells = {}
    for thang in thangs
      isTemplate = false
      for component in thang.components
        if component.config? and _.has component.config,'programmableMethods'
          for methodName, method of component.config.programmableMethods
            if typeof method is 'string'
              isTemplate = true
              break

            pathComponents = [thang.id,methodName]
            pathComponents[0] = _.string.slugify pathComponents[0]
            spellKey = pathComponents.join '/'
            spells[spellKey] ?= {}
            spells[spellKey].thangs ?= {}
            spells[spellKey].name = methodName
            thangID = _.string.slugify thang.id
            spells[spellKey].thangs[thang.id] ?= {}
            spells[spellKey].thangs[thang.id].aether = @createAether methodName, method
            if spellToSourceMap[thangID]? then source = spellToSourceMap[thangID][methodName] else source = ""
            spells[spellKey].thangs[thang.id].aether.transpile source
          if isTemplate
            break

    spells

  createAether : (methodName, method) ->
    aetherOptions =
      functionName: methodName
      protectAPI: false
      includeFlow: false
    return new Aether aetherOptions

  generateSpellToSourceMap: (sessions) ->
    spellKeyToSourceMap = {}
    spellSources = {}
    for session in sessions
      teamSpells = session.teamSpells[session.team]
      _.merge spellSources, _.pick(session.code, teamSpells)

      #merge common ones, this overwrites until the last session
      commonSpells = session.teamSpells["common"]
      if commonSpells?
        _.merge spellSources, _.pick(session.code, commonSpells)

    spellSources

    #spells must have spellKey: spell
    #spell must have spell.thangs as thangID: spellThang and spell.name
    #spellThang must have spellThang.aether as an Aether instance


    #god.level =
    ###
    @levelLoader = new LevelLoader(@levelID, @supermodel, @sessionID)
    @levelLoader.once 'loaded-all', @onLevelLoaderLoaded
    @god = new God()
    god.spells = data.code #mock to have it work

    @god.level = @level.serialize @supermodel
    @god.worldClassMap = @world.classMap

    god.createWorld()

    Listen for finished event, should be able to pull out goal states, somehow.

    Level has a list of thangs. You must find which one of the thangs has programmable components.
    The programmable thangs you would create the aether instance for each one for each of its programmable
    methods. Like tome_view.coffee/createSpells is doing. The world will reconstruct the clones, so if it is
    a cloneOf, just skip it. Any programmable method where the method is actually like something that has a name
    and a source, you must create an aether out of it. spellkeys must be created, so once you have that
    you can find matching spellkeys and go get the code.
    To make an aether instance, look at spell.coffee

    protectAPI: false
    includeFlow: false

    Look in level.thangs and world.coffee
    loadFromLevel is slow but works
    Find every thang which has a component which has an original of the ID of the original programmable component
    The config property will have original, then config.


    ###


