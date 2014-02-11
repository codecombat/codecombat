View = require 'views/kinds/RootView'
template = require 'templates/home'
WizardSprite = require 'lib/surface/WizardSprite'
ThangType = require 'models/ThangType'
LevelLoader = require 'lib/LevelLoader'
God = require 'lib/God'

GoalManager = require 'lib/world/GoalManager'

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
      #TODO: Refactor. So much refactor.
      world = {}
      god = new God()
      levelLoader = new LevelLoader(levelName, @supermodel, data.sessions[0].sessionID)
      levelLoader.once 'loaded-all', =>
        world = levelLoader.world
        level = levelLoader.level
        levelLoader.destroy()
        god.level = level.serialize @supermodel
        god.worldClassMap = world.classMap
        god.goalManager = new GoalManager(world)
        #move goals in here
        goalsToAdd = god.goalManager.world.scripts[0].noteChain[0].goals.add
        god.goalManager.goals = goalsToAdd
        god.goalManager.goalStates =
          "destroy-humans":
            keyFrame: 0
            killed:
              "Human Base": false
            status: "incomplete"
          "destroy-ogres":
            keyFrame:0
            killed:
              "Ogre Base": false
            status: "incomplete"
        god.spells = @filterProgrammableComponents level.attributes.thangs, @generateSpellToSourceMap data.sessions
        god.createWorld()

        Backbone.Mediator.subscribe 'god:new-world-created', @onWorldCreated, @

  onWorldCreated: (data) ->
    console.log "GOAL STATES"
    console.log data


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


