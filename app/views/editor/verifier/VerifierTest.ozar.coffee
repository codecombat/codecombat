CocoClass = require 'core/CocoClass'
SuperModel = require 'models/SuperModel'
{createAetherOptions} = require 'lib/aether_utils'
God = require 'lib/God'
GoalManager = require 'lib/world/GoalManager'
LevelLoader = require 'lib/LevelLoader'
utils = require 'core/utils'
aetherUtils = require 'lib/aether_utils'

module.exports = class VerifierTest extends CocoClass
  constructor: (@levelID, @updateCallback, @supermodel, @language, @options) ->
    super()
    # TODO: turn this into a Subview
    # TODO: listen to the progress report from Angel to show a simulation progress bar (maybe even out of the number of frames we actually know it'll take)
    @supermodel ?= new SuperModel()

    if utils.getQueryVariable('dev') or @options.devMode
      @supermodel.shouldSaveBackups = (model) ->  # Make sure to load possibly changed things from localStorage.
        model.constructor.className in ['Level', 'LevelComponent', 'LevelSystem', 'ThangType']
    @solution = @options.solution
    @language ?= 'python'
    @userCodeProblems = []
    @load()

  load: ->
    @loadStartTime = new Date()
    @god = new God maxAngels: 1, headless: true
    @levelLoader = new LevelLoader supermodel: @supermodel, levelID: @levelID, headless: true, fakeSessionConfig: {codeLanguage: @language, callback: @configureSession}
    @listenToOnce @levelLoader, 'world-necessities-loaded', -> _.defer @onWorldNecessitiesLoaded

  onWorldNecessitiesLoaded: =>
    # Called when we have enough to build the world, but not everything is loaded
    @grabLevelLoaderData()

    unless @solution
      @error = 'No solution present...'
      @state = 'no-solution'
      @updateCallback? test: @, state: 'no-solution'
      return
    me.team = @team = 'humans'
    @setupGod()
    @initGoalManager()
    @register()

  configureSession: (session, level) =>
    try
      session.solution = _.filter(level.getSolutions(), language: session.get('codeLanguage'))[@options.solutionIndex]
      session.solution ?= @solution
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
    @solution ?= @levelLoader.session.solution

  setupGod: ->
    @god.setLevel @level.serialize {@supermodel, @session, otherSession: null, headless: true, sessionless: false}
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
    @god.createWorld {spells: aetherUtils.generateSpellsObject {levelSession: @session}}
    @state = 'running'
    @reportResults()

  extractTestLogs: ->
    @testLogs = []
    for log in @god?.angelsShare?.busyAngels?[0]?.allLogs ? []
      continue if log.indexOf('[TEST]') is -1
      @testLogs.push log.replace /\|.*?\| \[TEST\] /, ''
    @testLogs

  reportResults: ->
    @updateCallback? test: @, state: @state, testLogs: @extractTestLogs()

  processSingleGameResults: (e) ->
    @goals = e.goalStates
    @frames = e.totalFrames
    @lastFrameHash = e.lastFrameHash
    @simulationFrameRate = e.simulationFrameRate
    @state = 'complete'
    @reportResults()
    @scheduleCleanup()

  isSuccessful: (careAboutFrames=true) ->
    return false unless @solution?
    return false unless @frames == @solution.frameCount or not careAboutFrames
    return false if @simulationFrameRate < 30
    if @goals and @solution.goals
      for k of @goals
        continue if not @solution.goals[k]
        return false if @solution.goals[k] != @goals[k].status
    return true

  onUserCodeProblem: (e) ->
    console.warn "Found user code problem:", e
    @userCodeProblems.push e.problem
    @reportResults()

  onNonUserCodeProblem: (e) ->
    console.error "Found non-user-code problem:", e
    @error = "Failed due to non-user-code problem: #{JSON.stringify(e)}"
    @state = 'error'
    @reportResults()
    @scheduleCleanup()

  fail: (e) ->
    @error = 'Failed due to infinite loop.'
    @state = 'error'
    @reportResults()
    @scheduleCleanup()

  scheduleCleanup: ->
    setTimeout @cleanup, 100

  cleanup: =>
    if @levelLoader
      @stopListening @levelLoader
      @levelLoader.destroy()
    if @god
      @stopListening @god
      @god.destroy()
    @world = null
