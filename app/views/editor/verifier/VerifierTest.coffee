CocoClass = require 'core/CocoClass'
SuperModel = require 'models/SuperModel'
{createAetherOptions} = require 'lib/aether_utils'
God = require 'lib/God'
GoalManager = require 'lib/world/GoalManager'
LevelLoader = require 'lib/LevelLoader'
utils = require 'core/utils'

module.exports = class VerifierTest extends CocoClass
  constructor: (@levelID, @updateCallback, @supermodel, @language, @options) ->
    super()
    # TODO: turn this into a Subview
    # TODO: listen to the progress report from Angel to show a simulation progress bar (maybe even out of the number of frames we actually know it'll take)
    @supermodel ?= new SuperModel()

    if utils.getQueryVariable('dev')
      @supermodel.shouldSaveBackups = (model) ->  # Make sure to load possibly changed things from localStorage.
        model.constructor.className in ['Level', 'LevelComponent', 'LevelSystem', 'ThangType']

    @language ?= 'python'
    @userCodeProblems = []
    @load()

  load: ->
    @loadStartTime = new Date()
    @god = new God maxAngels: 1, headless: true
    @levelLoader = new LevelLoader supermodel: @supermodel, levelID: @levelID, headless: true, fakeSessionConfig: {codeLanguage: @language, callback: @configureSession}
    @listenToOnce @levelLoader, 'world-necessities-loaded', @onWorldNecessitiesLoaded

  onWorldNecessitiesLoaded: ->
    # Called when we have enough to build the world, but not everything is loaded
    @grabLevelLoaderData()

    unless @solution
      @error = 'No solution present...'
      @state = 'no-solution'
      @updateCallback? state: 'no-solution'
      return
    me.team = @team = 'humans'
    @setupGod()
    @initGoalManager()
    @register()

  configureSession: (session, level) =>
    try
      session.solution = _.find level.getSolutions(), language: session.get('codeLanguage')
      session.set 'heroConfig', session.solution.heroConfig
      session.set 'code', {'hero-placeholder': plan: session.solution.source}
      state = session.get 'state'
      state.flagHistory = session.solution.flagHistory
      state.realTimeInputEvents = session.solution.realTimeInputEvents
      state.difficulty = session.solution.difficulty or 0
      session.solution.seed = undefined unless _.isNumber session.solution.seed  # TODO: migrate away from submissionCount/sessionID seed objects
    catch e
      @state = 'error'
      @error = "Could not load the session solution for #{level.get('name')}: " + e.toString() + "\n" + e.stack

  grabLevelLoaderData: ->
    @world = @levelLoader.world
    @level = @levelLoader.level
    @session = @levelLoader.session
    @solution = @levelLoader.session.solution

  setupGod: ->
    @god.setLevel @level.serialize @supermodel, @session
    @god.setLevelSessionIDs [@session.id]
    @god.setWorldClassMap @world.classMap
    @god.lastFlagHistory = @session.get('state').flagHistory
    @god.lastDifficulty = @session.get('state').difficulty
    @god.lastFixedSeed = @session.solution.seed
    @god.lastSubmissionCount = 0

  initGoalManager: ->
    @goalManager = new GoalManager(@world, @level.get('goals'), @team)
    @god.setGoalManager @goalManager

  register: ->
    @listenToOnce @god, 'infinite-loop', @fail
    @listenToOnce @god, 'user-code-problem', @onUserCodeProblem
    @listenToOnce @god, 'goals-calculated', @processSingleGameResults
    @god.createWorld @generateSpellsObject()
    @updateCallback? state: 'running'

  processSingleGameResults: (e) ->
    @goals = e.goalStates
    @frames = e.totalFrames
    @lastFrameHash = e.lastFrameHash
    @simulationFrameRate = e.simulationFrameRate
    @state = 'complete'
    @updateCallback? state: @state
    @scheduleCleanup()

  isSuccessful: () ->
    return false unless @solution?
    return false unless @frames == @solution.frameCount or @options.dontCareAboutFrames
    return false if @simulationFrameRate < 30
    if @goals and @solution.goals
      for k of @goals
        continue if not @solution.goals[k]
        return false if @solution.goals[k] != @goals[k].status
    return true

  onUserCodeProblem: (e) ->
    console.warn "Found user code problem:", e
    @userCodeProblems.push e.problem
    @updateCallback? state: @state

  onNonUserCodeProblem: (e) ->
    console.error "Found non-user-code problem:", e
    @error = "Failed due to non-user-code problem: #{JSON.stringify(e)}"
    @state = 'error'
    @updateCallback? state: @state
    @scheduleCleanup()

  fail: (e) ->
    @error = 'Failed due to infinite loop.'
    @state = 'error'
    @updateCallback? state: @state
    @scheduleCleanup()

  generateSpellsObject: ->
    aetherOptions = createAetherOptions functionName: 'plan', codeLanguage: @session.get('codeLanguage')
    spellThang = aether: new Aether aetherOptions
    spells = "hero-placeholder/plan": thangs: {'Hero Placeholder': spellThang}, name: 'plan'
    source = @session.get('code')['hero-placeholder'].plan
    try
      spellThang.aether.transpile source
    catch e
      console.log "Couldn't transpile!\n#{source}\n", e
      spellThang.aether.transpile ''
    spells

  scheduleCleanup: ->
    setTimeout @cleanup, 100

  cleanup: =>
    if @god
      @stopListening @god
      @god.destroy()

    @world = null
