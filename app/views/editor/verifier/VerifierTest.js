const CocoClass = require('core/CocoClass')
const SuperModel = require('models/SuperModel')
const God = require('lib/God')
const GoalManager = require('lib/world/GoalManager')
const LevelLoader = require('lib/LevelLoader')
const utils = require('core/utils')
const aetherUtils = require('lib/aether_utils')

module.exports = class VerifierTest extends CocoClass {
  constructor (levelID, updateCallback, supermodel, language, options) {
    super()
    this.onWorldNecessitiesLoaded = this.onWorldNecessitiesLoaded.bind(this)
    this.fetchToken = this.fetchToken.bind(this)
    this.configureSession = this.configureSession.bind(this)
    this.cleanup = this.cleanup.bind(this)
    this.load = this.load.bind(this)
    this.levelID = levelID
    this.updateCallback = updateCallback
    this.supermodel = supermodel
    this.language = language
    this.options = options
    // TODO: turn this into a Subview
    // TODO: listen to the progress report from Angel to show a simulation progress bar (maybe even out of the number of frames we actually know it'll take)
    if (!this.supermodel) { this.supermodel = new SuperModel() }

    if (utils.getQueryVariable('dev') || this.options.devMode) {
      this.supermodel.shouldSaveBackups = model => // Make sure to load possibly changed things from localStorage.
        ['Level', 'LevelComponent', 'LevelSystem', 'ThangType'].includes(model.constructor.className)
    }
    this.solution = this.options.solution
    this.simpleDescription = ''
    this.name = ''
    if (this.language == null) { this.language = 'python' }
    this.userCodeProblems = []

    this.checkClampedProperties = utils.getQueryVariable('check_prop') || false
    this.checkPropKeys = ['maxHealth', 'maxSpeed', 'attackDamage', 'maxxSpeed', 'maxxAttackDamage']
    this.checkPropIndex = 0
    this.clampedProperties = {
      inited: false
    }
    // hero.attackDamage
    // hero.health
    // hero.maxHealth
    // hero.maxSpeed
    // level.recommendedHealth
    this.load()
  }

  load () {
    this.supermodel.resetProgress()
    this.loadStartTime = new Date()
    this.god = new God({ maxAngels: 1, headless: true })
    this.levelLoader = new LevelLoader({ supermodel: this.supermodel, levelID: this.levelID, headless: true, fakeSessionConfig: { codeLanguage: this.language, callback: this.configureSession } })
    this.listenToOnce(this.levelLoader, 'world-necessities-loaded', function () { return _.defer(this.onWorldNecessitiesLoaded) })
  }

  onWorldNecessitiesLoaded () {
    // Called when we have enough to build the world, but not everything is loaded
    this.grabLevelLoaderData()

    if (!this.solution) {
      this.error = 'No solution present...'
      this.state = 'no-solution'
      if (typeof this.updateCallback === 'function') {
        this.updateCallback({ test: this, state: 'no-solution' })
      }
      return
    }

    this.simpleDescription = this.solution.description ? `- ${this.solution.description}` : ''
    this.name = `${this.solution.testOnly ? '' : '[Solution]'} ${this.level.get('name')}`

    me.team = (this.team = 'humans')
    this.setupGod()
    this.initGoalManager()
    this.fetchToken(this.solution.source, this.language)
      .then(token => this.register(token))
  }

  fetchToken (source, language) {
    if (!['java', 'cpp'].includes(language)) {
      return Promise.resolve(source)
    }

    const headers = { Accept: 'application/json', 'Content-Type': 'application/json' }
    const service = window?.localStorage?.kodeKeeperService || 'https://asm14w94nk.execute-api.us-east-1.amazonaws.com/service/parse-code-kodekeeper'
    if(me.useChinaServices()) {
      headers['Authorization'] = 'APPCODE b3e285d032a343db8bd2b51a05a5ff1d'
      service = window?.localStorage?.kodeKeeperService || "https://kodekeeper.koudashijie.com/parse-code-kodekeeper"
    }
    return fetch(service, { method: 'POST', mode: 'cors', headers, body: JSON.stringify({ code: source, language }) })
      .then(x => x.json())
      .then(x => x.token)
  }

  configureSession (session, level) {
    let state
    try {
      if (session.solution == null) { session.solution = this.solution }
      session.set('heroConfig', session.solution.heroConfig)
      session.set('code', { 'hero-placeholder': { plan: session.solution.source } })
      state = session.get('state')
      state.flagHistory = session.solution.flagHistory
      state.realTimeInputEvents = session.solution.realTimeInputEvents
      state.difficulty = session.solution.difficulty || 0
      if (!_.isNumber(session.solution.seed)) { session.solution.seed = undefined } // TODO: migrate away from submissionCount/sessionID seed objects
    } catch (e) {
      this.state = 'error'
      this.error = `Could not load the session solution for ${level.get('name')}: ` + e.toString() + '\n' + e.stack
    }
  }

  grabLevelLoaderData () {
    this.world = this.levelLoader.world
    this.level = this.levelLoader.level
    this.session = this.levelLoader.session
    return this.solution != null ? this.solution : (this.solution = this.levelLoader.session.solution)
  }

  prepareTestingLevel (level) {
    const hero = this.world.getThangByID('Hero Placeholder')
    level.constrainHeroHealth = true
    if (!this.clampedProperties.inited) {
      this.clampedProperties = {
        inited: true,
        // min
        maxHealth: { prop: 'maxHealth', check: 'min', current: 1, lower: 5, upper: hero.maxHealth },
        maxSpeed: { prop: 'maxSpeed', check: 'min', current: 1, lower: 3, upper: hero.maxSpeed },
        attackDamage: { prop: 'attackDamage', check: 'min', current: 1, lower: 4, upper: hero.attackDamage || 13 },
        // max
        maxxSpeed: { prop: 'maxSpeed', check: 'max', current: 1, lower: hero.maxSpeed, upper: 50 },
        maxxAttackDamage: { prop: 'attackDamage', check: 'max', current: 1, lower: hero.attackDamage || 13, upper: 500 }
      }
    }
    const prop = this.checkPropKeys[this.checkPropIndex]
    // check max/min at first. if that work, we do not need to find better one
    if (this.clampedProperties[prop].check === 'min') {
      this.clampedProperties[prop].current = this.clampedProperties[prop].lower
    } else {
      this.clampedProperties[prop].current = this.clampedProperties[prop].upper
    }
    console.log(prop, 'new current: ', this.clampedProperties[prop].current)
    // let find min first

    level.recommendedHealth = this.clampedProperties.maxHealth.current
    level.maximumHealth = this.clampedProperties.maxHealth.current
    level.clampedProperties = level.clampedProperties || {}
    level.clampedProperties[this.clampedProperties[prop].prop] = {}
    level.clampedProperties[this.clampedProperties[prop].prop][this.clampedProperties[prop].check] = this.clampedProperties[prop].current
  }

  setupGod () {
    const level = this.level.serialize({ supermodel: this.supermodel, session: this.session, otherSession: null, headless: true, sessionless: false })
    if (this.checkClampedProperties) {
      this.prepareTestingLevel(level)
    }
    this.god.setLevel(level)
    this.god.setLevelSessionIDs([this.session.id])
    this.god.setWorldClassMap(this.world.classMap)
    this.god.lastFlagHistory = this.session.get('state').flagHistory
    this.god.lastDifficulty = this.session.get('state').difficulty
    this.god.lastFixedSeed = this.session.solution.seed
    this.god.lastSubmissionCount = 0
  }

  initGoalManager () {
    this.goalManager = new GoalManager(this.world, this.level.get('goals'), this.team)
    this.god.setGoalManager(this.goalManager)
  }

  register (tokenSource) {
    this.listenToOnce(this.god, 'infinite-loop', this.fail)
    this.listenToOnce(this.god, 'user-code-problem', this.onUserCodeProblem)
    this.listenToOnce(this.god, 'goals-calculated', this.processSingleGameResults)
    this.god.createWorld({ spells: aetherUtils.generateSpellsObject({ levelSession: this.session, token: tokenSource }) })
    this.state = 'running'
    this.reportResults()
  }

  extractTestLogs () {
    this.testLogs = []
    for (const log of this.god?.angelsShare?.busyAngels?.[0]?.allLogs || []) {
      if (log.indexOf('[TEST]') === -1) { continue }
      this.testLogs.push(log.replace(/\|.*?\| \[TEST\] /, ''))
    }
    return this.testLogs
  }

  reportResults () {
    return (typeof this.updateCallback === 'function' ? this.updateCallback({ test: this, state: this.state, testLogs: this.extractTestLogs() }) : undefined)
  }

  processSingleGameResults (e) {
    this.goals = e.goalStates
    this.frames = e.totalFrames
    this.lastFrameHash = e.lastFrameHash
    this.simulationFrameRate = e.simulationFrameRate
    this.state = 'complete'
    this.reportResults()
    this.scheduleCleanup()
  }

  isSuccessful (careAboutFrames) {
    if (careAboutFrames == null) { careAboutFrames = true }
    if (this.solution == null) { return false }
    if ((this.frames !== this.solution.frameCount) && !!careAboutFrames) { return false }
    if (this.simulationFrameRate < 30) { return false }
    if (this.goals && this.solution.goals) {
      for (const k in this.goals) {
        if (!this.solution.goals[k]) { continue }
        if (this.solution.goals[k] !== this.goals[k].status) { return false }
      }
    } else if (this.goals) {
      const allPassed = _.all(this.goals, goal => goal.status === 'success')
      const someFailed = _.any(this.goals, goal => goal.status !== 'success')
      if (this.solution.succeeds) { return allPassed }
      if (!this.solution.succeeds) { return someFailed }
    }
    return true
  }

  onUserCodeProblem (e) {
    console.warn('Found user code problem:', e)
    this.userCodeProblems.push(e.problem)
    this.reportResults()
  }

  onNonUserCodeProblem (e) {
    console.error('Found non-user-code problem:', e)
    this.error = `Failed due to non-user-code problem: ${JSON.stringify(e)}`
    this.state = 'error'
    this.reportResults()
    this.scheduleCleanup()
  }

  fail (e) {
    this.error = 'Failed due to infinite loop.'
    this.state = 'error'
    this.reportResults()
    this.scheduleCleanup()
  }

  scheduleCleanup () {
    if (this.checkClampedProperties && this.state !== 'running') {
      const prop = this.checkPropKeys[this.checkPropIndex]
      if (this.clampedProperties[prop].upper > this.clampedProperties[prop].lower) {
        const mid = this.clampedProperties[prop].current
        if (this.isSuccessful()) {
          if (this.clampedProperties[prop].check === 'min') {
            if (this.clampedProperties[prop].current === this.clampedProperties[prop].lower) {
              console.log('min value is working, exit')
              return setTimeout(this.cleanup, 100)
            } else {
              this.clampedProperties[prop].upper = mid
            }
          } else {
            if (this.clampedProperties[prop].current === this.clampedProperties[prop].upper) {
              console.log('max value is working, exit')
              return setTimeout(this.cleanup, 100)
            } else {
              this.clampedProperties[prop].lower = mid
            }
          }
        } else {
          if (this.clampedProperties[prop].check === 'min') {
            this.clampedProperties[prop].lower = mid + 1
          } else {
            this.clampedProperties[prop].upper = mid - 1
          }
        }
        return setTimeout(this.load, 500)
      } else {
        if (!this.isSuccessful()) {
          this.state = 'error'
          this.error = 'Could not find a solution within the clamped properties'
          console.log("error, couldn't find a solution within the clamped properties")
        } else {
          while (this.checkPropKeys.length > this.checkPropIndex + 1) {
            this.checkPropIndex += 1
            const newProp = this.checkPropKeys[this.checkPropIndex]
            const trueProp = this.clampedProperties[newProp].prop
            const check = this.clampedProperties[newProp].check
            const clampedProperties = this.level.get('clampedProperties') || {}
            if (trueProp in clampedProperties && (check in clampedProperties[trueProp])) {
              continue
            }
            console.log('checking .. ', this.checkPropKeys[this.checkPropIndex])
            return setTimeout(this.load, 500)
          }
        }
        return setTimeout(this.cleanup, 100)
      }
    }
  }

  printClampedPropertiesResult () {
    console.log('==============================================')
    console.log('find a solution within the clamped properties  for level: ', this.level.get('slug'))
    console.log('current clamped properties:', this.level.get('clampedProperties'))

    const clampedProperties = {}
    for (const prop in this.clampedProperties) {
      if (prop === 'inited') {
        continue
      }
      const trueProp = this.clampedProperties[prop].prop
      const check = this.clampedProperties[prop].check
      if (this.clampedProperties[prop].upper === this.clampedProperties[prop].lower) {
        clampedProperties[trueProp] = clampedProperties[trueProp] || {}
        clampedProperties[trueProp][check] = this.clampedProperties[prop].current
      }
    }
    console.log('suggested adding properties as:', clampedProperties)
    console.log('==============================================')
  }

  cleanup () {
    if (this.checkClampedProperties) {
      this.printClampedPropertiesResult()
    }
    if (this.levelLoader) {
      this.stopListening(this.levelLoader)
      this.levelLoader.destroy()
    }
    if (this.god) {
      this.stopListening(this.god)
      this.god.destroy()
    }
    this.world = null
  }
}
