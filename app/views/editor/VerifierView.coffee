RootView = require 'views/core/RootView'
template = require 'templates/editor/verifierView'
ThangType = require 'models/ThangType'
CocoCollection = require 'collections/CocoCollection'

God = require 'lib/God'
GoalManager = require 'lib/world/GoalManager'
ScriptManager = require 'lib/scripts/ScriptManager'
LevelBus = require 'lib/LevelBus'
LevelLoader = require 'lib/LevelLoader'
LevelSession = require 'models/LevelSession'
Level = require 'models/Level'
LevelComponent = require 'models/LevelComponent'

TomeView = require 'views/play/level/tome/TomeView'
GoalsView = require 'views/play/level/LevelGoalsView'

class Test
  constructor: (@parent, @levelID, @supermodel) ->
    @session = @parent.session
    @load()

  load: () ->
    @loadStartTime = new Date()
    console.log "Loading", @
    @god = new God debugWorker: true
    @levelLoader = new LevelLoader supermodel: @supermodel, levelID: @levelID, headless: true, defaultGear: true
    @parent.listenToOnce @levelLoader, 'world-necessities-loaded', @onWorldNecessitiesLoaded.bind(@)

  onWorldNecessitiesLoaded: ->
    # Called when we have enough to build the world, but not everything is loaded
    @grabLevelLoaderData()
    team = @world.teamForPlayer(0)

    @god.setLevel @level.serialize @supermodel, @session
    #@god.setLevelSessionIDs [@session.id]
    @god.setWorldClassMap @world.classMap

    @setTeam team
    @initGoalManager()
    @register()
    @parent.listenToOnce @god, 'goals-calculated', @processSingleGameResults.bind(@)

  grabLevelLoaderData: ->
    @world = @levelLoader.world
    @level = @levelLoader.level 
    @heroPlaceholder = @level.get("thangs").filter((x) -> x.id == "Hero Placeholder").pop()
    @programmable = @heroPlaceholder.components.filter((x) -> x.config?.programmableMethods?.plan).pop()
    @gear =  @heroPlaceholder.components.filter((x) -> x.config?.inventory).pop()
    @solution = @programmable.config.programmableMethods.plan.solutions[0]
    #@solution.source = "self.say(Esper.str(10))\n" + @solution.source
    @session = @levelLoader.session

    #@session = new LevelSession
    #@session.set 'teamSpells', humans: ["hero-placeholder/plan"]
    #@session.set 'creator', null #Prevents session from being saved
    @session.set 'codeLanguage', @solution.language
    @session.set 'submittedCodeLanguage', @solution.language
    @session.set 'code', 'hero-placeholder':
      plan:  @solution.source
    @session.set 'heroConfig', @gear.config
    #@session.save()

  setTeam: (team) ->
    team = team?.team unless _.isString team
    team ?= 'humans'
    me.team = team
    @session.set 'team', team
    Backbone.Mediator.publish 'level:team-set', team: team  # Needed for scripts
    @team = team

  initGoalManager: ->
    @goalManager = new GoalManager(@world, @level.get('goals'), @team)
    @god.setGoalManager @goalManager

  register: ->
    #@bus = LevelBus.get(@levelID, @session.id)
    #@bus.setSession(@session)
    @tome = new TomeView levelID: @levelID, session: @session, otherSession: @otherSession, thangs: @world.thangs, supermodel: @supermodel, level: @level, observing: @observing, courseID: @courseID, courseInstanceID: @courseInstanceID, god: @god
    @tome.afterRender()
    #@bus.setSpells @tome.spells
    Backbone.Mediator.publish 'test:update'

    

  processSingleGameResults: (e) ->
    @goals = e.goalStates
    Backbone.Mediator.publish 'test:update'

module.exports = class VerifierView extends RootView
  template: template
  id: 'verifier-view'
  events:
    'input input': 'searchUpdate'
    'change input': 'searchUpdate'

  subscriptions:
    'test:update': 'update'

  shortcuts:
    'ctrl+s': 'onCtrlS'
    'esc': 'onEscapePressed'

  constructor: (options, @levelID) ->
    super options
    @levelID ?= 'dungeons-of-kithgard'
    window.rob = @

    @tests = []
    @test = new Test(@, @levelID, @supermodel)
    @tests.push @test
    #@tests.push new Test(@, 'kithguard-dungeon', @supermodel)

  update: () ->
    console.log "Updating, view"
    @render()
  



  onThangsLoaded: ->

  onCtrlS: ->
    alert 'sorry'

  onEscapePressed: ->
    alert 'sorry'

