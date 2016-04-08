SuperModel = require 'models/SuperModel'
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
    # TODO: turn this into a Subview
    # TODO: listen to Backbone.Mediator.publish 'god:non-user-code-problem', problem: event.data.problem, god: @shared.god from Angel to detect when we can't load the thing
    # TODO: listen to the progress report from Angel to show a simulation progress bar (maybe even out of the number of frames we actually know it'll take)
    @supermodel ?= new SuperModel()
    @session = @parent.session
    @load()

  load: () ->
    @loadStartTime = new Date()
    @god = new God maxAngels: 1
    @levelLoader = new LevelLoader supermodel: @supermodel, levelID: @levelID, headless: true, defaultGear: true, fakeSessionConfig: {codeLanguage: 'python', callback: @configureSession}
    @parent.listenToOnce @levelLoader, 'world-necessities-loaded', @onWorldNecessitiesLoaded.bind(@)

  onWorldNecessitiesLoaded: ->
    # Called when we have enough to build the world, but not everything is loaded
    @grabLevelLoaderData()
    unless @solution
      Backbone.Mediator.publish 'test:update', state: 'error'
      @state = 'error'
      return
    team = @world.teamForPlayer(0)

    @god.setLevel @level.serialize @supermodel, @session
    #@god.setLevelSessionIDs [@session.id]
    @god.setWorldClassMap @world.classMap

    @setTeam team
    @initGoalManager()
    @register()
    @parent.listenToOnce @god, 'goals-calculated', @processSingleGameResults.bind(@)

  configureSession: (session, level) =>
    # TODO: reach into and find hero and get the config from the solution
    try
      hero = _.find level.get("thangs"), id: "Hero Placeholder"
      programmable = _.find(hero.components, (x) -> x.config?.programmableMethods?.plan).config.programmableMethods.plan
      session.solution = _.find (programmable.solutions ? []), language: session.get('codeLanguage')
      session.set 'heroConfig', session.solution.heroConfig
      session.set 'code', {'hero-placeholder': plan: session.solution.source}
      state = session.get 'state'
      state.flagHistory = session.solution.flagHistory
      state.difficulty = session.solution.difficulty or 0
      session.solution.seed = undefined unless _.isNumber session.solution.seed  # TODO: migrate away from submissionCount/sessionID seed objects
    catch e
      @state = 'error'
      console.error "Could not load the session solution for #{@level.get('name')}:", e

  grabLevelLoaderData: ->
    @world = @levelLoader.world
    @level = @levelLoader.level
    @session = @levelLoader.session
    @solution = @levelLoader.session.solution

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
    # TODO: make an alternative for constructing a TomeView, and then don't let the TomeView know about fixedSeed
    @tome = new TomeView levelID: @levelID, session: @session, otherSession: @otherSession, thangs: @world.thangs, supermodel: @supermodel, level: @level, observing: @observing, courseID: @courseID, courseInstanceID: @courseInstanceID, god: @god, fixedSeed: @solution.seed
    @tome.afterRender()
    Backbone.Mediator.publish 'test:update', state: 'running'

  processSingleGameResults: (e) ->
    @goals = e.goalStates
    Backbone.Mediator.publish 'test:update', state: 'complete'

module.exports = class VerifierView extends RootView
  className: 'style-flat'
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
    # TODO: rework to handle N at a time instead of all at once
    # TODO: sort tests by unexpected result first
    testLevels = ["dungeons-of-kithgard", "gems-in-the-deep", "shadow-guard", "kounter-kithwise", "crawlways-of-kithgard", "enemy-mine", "illusory-interruption", "forgetful-gemsmith", "signs-and-portents", "favorable-odds", "true-names", "the-prisoner", "banefire", "the-raised-sword", "kithgard-librarian", "fire-dancing", "loop-da-loop", "haunted-kithmaze", "riddling-kithmaze", "descending-further", "the-second-kithmaze", "dread-door", "cupboards-of-kithgard", "hack-and-dash", "known-enemy", "master-of-names", "lowly-kithmen", "closing-the-distance", "tactical-strike", "the-skeleton", "a-mayhem-of-munchkins", "the-final-kithmaze", "the-gauntlet", "radiant-aura", "kithgard-gates", "destroying-angel", "deadly-dungeon-rescue", "kithgard-brawl", "cavern-survival", "breakout", "attack-wisely", "kithgard-mastery", "kithgard-apprentice", "robot-ragnarok", "defense-of-plainswood", "peasant-protection", "forest-fire-dancing"]
    #testLevels = testLevels.slice 0, 15
    levelIDs = if @levelID then [@levelID] else testLevels
    supermodel = if @levelID then @supermodel else undefined
    @tests = (new Test @, levelID, supermodel for levelID in levelIDs)

  update: (e) ->
    # TODO: show unworkable tests instead of hiding them
    @tests = _.filter @tests, (test) -> test.state isnt 'error'
    @render()

  onThangsLoaded: ->

  onCtrlS: ->
    alert 'sorry'

  onEscapePressed: ->
    alert 'sorry'
