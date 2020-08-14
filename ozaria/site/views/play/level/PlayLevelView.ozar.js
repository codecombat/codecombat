/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__
 * DS104: Avoid inline assignments
 * DS204: Change includes calls to have a more natural evaluation order
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */

import OzariaTransitionModal from '../modal/OzariaTransitionModal'
import RestartLevelModal from 'ozaria/site/views/play/level/modal/RestartLevelModal'
import { getNextLevelForLevel } from 'ozaria/site/common/ozariaUtils'

require('app/styles/play/level/level-loading-view.sass')
require('ozaria/site/styles/play/level/tome/spell_palette_entry.sass')
require('ozaria/site/styles/play/play-level-view.sass')
const RootView = require('views/core/RootView')
const template = require('ozaria/site/templates/play/play-level-view.pug')
const { me } = require('core/auth')
const ThangType = require('models/ThangType')
const Classroom = require('models/Classroom')
const CourseInstance = require('models/CourseInstance')
const utils = require('core/utils')
const storage = require('core/storage')

// tools
const Surface = require('lib/surface/Surface')
const God = require('lib/God')
const GoalManager = require('lib/world/GoalManager')
const ScriptManager = require('lib/scripts/ScriptManager')
const LevelBus = require('lib/LevelBus')
const LevelLoader = require('lib/LevelLoader')
const AudioPlayer = require('lib/AudioPlayer')
const GameUIState = require('models/GameUIState')
const createjs = require('lib/createjs-parts')

// subviews
const LevelLoadingView = require('app/views/play/level/LevelLoadingView')
const ProblemAlertView = require('./tome/ProblemAlertView')
const TomeView = require('./tome/TomeView')
const LevelHUDView = require('./LevelHUDView')
const LevelDialogueView = require('./LevelDialogueView')
const ControlBarView = require('./ControlBarView')
const LevelPlaybackView = require('./LevelPlaybackView')
const CapstonePlaybackView = require('./CapstonePlaybackView.vue').default
const GoalsView = require('./LevelGoalsView')
const LevelFlagsView = require('./LevelFlagsView')
const GoldView = require('./LevelGoldView')
const GameDevTrackView = require('./GameDevTrackView')
const DuelStatsView = require('./DuelStatsView')
const VictoryModal = require('./modal/VictoryModal')
const HeroVictoryModal = require('./modal/HeroVictoryModal')
const CourseVictoryModal = require('./modal/CourseVictoryModal')
const InfiniteLoopModal = require('./modal/InfiniteLoopModal')
const LevelSetupManager = require('lib/LevelSetupManager')
const ContactModal = require('../../core/ContactModal')
const SurfaceContextMenuView = require('./SurfaceContextMenuView')
const WebSurfaceView = require('./WebSurfaceView')
const SpellPaletteView = require('./tome/SpellPaletteView')
const store = require('core/store')
const GameMenuModal = require('ozaria/site/views/play/menu/GameMenuModal')
const TutorialPlayView = require('./TutorialPlayView').default
const ThangTypeHUDComponent = require('./ThangTypeHUDComponent').default

require('lib/game-libraries')
window.Box2D = require('exports-loader?Box2D!vendor/scripts/Box2dWeb-2.1.a.3')

const PROFILE_ME = false

class PlayLevelView extends RootView {
  // Prototype definitions have been moved to the end.

  // Initial Setup #############################################################

  constructor (options, levelID) {
    super(options)

    if (typeof console.profile === 'function' && PROFILE_ME) {
      console.profile()
    }
    this.onWindowResize = this.onWindowResize.bind(this)
    this.onSubmissionComplete = this.onSubmissionComplete.bind(this)
    this.levelID = levelID

    // We need to know the cached campaign data for the current classroom of the user. One way of doing this is:
    // 1) Get the courseInstanceID, and use it to get the courseInstance.classroomID
    // 2) Get the classroom.courses, filtered by the courseID
    // 3) Using the classroom's courses object, get the campaign, and from the campaign get the ID

    this.courseID = options.courseID || utils.getQueryVariable('course')
    this.courseInstanceID = options.courseInstanceID || utils.getQueryVariable('course-instance')
    this.campaignID = store.state.campaigns.campaignByCourseInstanceId[this.courseInstanceId] ||
      store.state.campaigns.campaignByCourseId[this.courseId]
    this.isEditorPreview = utils.getQueryVariable('dev')
    this.sessionID = utils.getQueryVariable('session') || this.options.sessionID
    this.observing = utils.getQueryVariable('observing')
    this.opponentSessionID = utils.getQueryVariable('opponent') || this.options.opponent
    this.capstoneStage = this.getCapstoneStageFromArguments() || 1
    this.continueEditing = utils.getQueryVariable('continueEditing') || false

    this.gameUIState = new GameUIState()

    $('flying-focus').remove() // Causes problems, so yank it out for play view.
    $(window).on('resize', this.onWindowResize)

    if (this.isEditorPreview) {
      this.supermodel.shouldSaveBackups = (
        model // Make sure to load possibly changed things from localStorage.
      ) =>
        ['Level', 'LevelComponent', 'LevelSystem', 'ThangType'].includes(
          model.constructor.className
        )

      const f = () => {
        if (!this.levelLoader) {
          return typeof this.load === 'function' ? this.load() : undefined
        }
      } // Wait to see if it's just given to us through setLevel.
      setTimeout(f, 100)
    } else {
      this.load()
      if (!this.observing) {
        trackEvent('Started Level Load', {
          category: 'Play Level',
          level: this.levelID,
          label: this.levelID
        })
      }
    }
  }

  onClick () {
    // workaround to get users out of permanent idle status
    if (application.userIsIdle) {
      application.idleTracker.onVisible()
    }

    // hide context menu if visible
    if (this.$('#surface-context-menu-view').is(':visible')) {
      return Backbone.Mediator.publish('level:surface-context-menu-hide', {})
    }
  }

  setLevel (level, givenSupermodel) {
    this.level = level
    this.supermodel.models = givenSupermodel.models
    this.supermodel.collections = givenSupermodel.collections
    this.supermodel.shouldSaveBackups = givenSupermodel.shouldSaveBackups

    const serializedLevel = this.level.serialize({
      supermodel: this.supermodel,
      session: this.session,
      otherSession: this.otherSession,
      headless: false,
      sessionless: false
    })
    if (me.constrainHeroHealth()) {
      serializedLevel.constrainHeroHealth = true
    }
    if (this.god != null) {
      this.god.setLevel(serializedLevel)
    }
    if (this.world) {
      return this.world.loadFromLevel(serializedLevel, false)
    } else {
      return this.load()
    }
  }

  load () {
    this.loadStartTime = new Date()
    const levelLoaderOptions = {
      supermodel: this.supermodel,
      levelID: this.levelID,
      sessionID: this.sessionID,
      opponentSessionID: this.opponentSessionID,
      team: utils.getQueryVariable('team'),
      observing: this.observing,
      courseID: this.courseID,
      courseInstanceID: this.courseInstanceID
    }
    if (me.isSessionless()) {
      levelLoaderOptions.fakeSessionConfig = {}
    }
    console.debug('PlayLevelView: Create LevelLoader')
    this.levelLoader = new LevelLoader(levelLoaderOptions)
    this.listenToOnce(
      this.levelLoader,
      'world-necessities-loaded',
      this.onWorldNecessitiesLoaded
    )
    return this.listenTo(
      this.levelLoader,
      'world-necessity-load-failed',
      this.onWorldNecessityLoadFailed
    )
  }

  onLevelLoaded (e) {
    let needle
    if (this.destroyed) {
      return
    }
    if (
      _.all([
        (me.isStudent() || me.isTeacher()) && !application.getHocCampaign(),
        !this.courseID,
        !e.level.isType('course-ladder'),

        // TODO: Add a general way for standalone levels to be accessed by students, teachers
        ((needle = e.level.get('slug')),
        ![
          'peasants-and-munchkins',
          'game-dev-2-tournament-project',
          'game-dev-3-tournament-project'
        ].includes(needle))
      ])
    ) {
      return _.defer(() => application.router.redirectHome())
    }

    if (!e.level.isType('web-dev')) {
      // This is triggered before this.capstoneStage is updated based on sessions.
      // But God updates it by itself for session users
      this.god = new God({
        gameUIState: this.gameUIState,
        indefiniteLength: e.level.isType('game-dev'),
        capstoneStage: this.capstoneStage
      })
    }
    if (this.waitingToSetUpGod) {
      return this.setupGod()
    }
  }

  trackLevelLoadEnd () {
    if (this.isEditorPreview) {
      return
    }
    this.loadEndTime = new Date()
    this.loadDuration = this.loadEndTime - this.loadStartTime
    console.debug(
      `Level unveiled after ${(this.loadDuration / 1000).toFixed(2)}s`
    )
    if (!this.observing && application.tracker) {
      trackEvent('Finished Level Load', {
        category: 'Play Level',
        label: this.levelID,
        level: this.levelID,
        loadDuration: this.loadDuration
      })
      application.tracker.trackTiming(
        this.loadDuration,
        'Level Load Time',
        this.levelID,
        this.levelID
      )
    }
  }

  isCourseMode () {
    return this.courseID && this.courseInstanceID
  }

  showAds () {
    return false // No ads for now.
  }

  // CocoView overridden methods ###############################################

  getRenderData () {
    const c = super.getRenderData()
    c.world = this.world
    return c
  }

  toggleSpellPalette () {
    this.$el.toggleClass('no-api')
    return $(window).trigger('resize')
  }

  afterRender () {
    super.afterRender()
    if (typeof window.onPlayLevelViewLoaded === 'function') {
      window.onPlayLevelViewLoaded(this)
    } // still a hack
    this.insertSubView(
      (this.loadingView = new LevelLoadingView({
        level:
          (this.levelLoader != null ? this.levelLoader.level : undefined) !=
          null
            ? this.levelLoader != null
              ? this.levelLoader.level
              : undefined
            : this.level,
        session:
          (this.levelLoader != null ? this.levelLoader.session : undefined) !=
          null
            ? this.levelLoader != null
              ? this.levelLoader.session
              : undefined
            : this.session
      }))
    ) // May not have @level loaded yet
    this.$el.find('#level-done-button').hide()
    $('body').addClass('is-playing')
  }

  afterInsert () {
    return super.afterInsert()
  }

  // Partially Loaded Setup ####################################################

  onWorldNecessitiesLoaded () {
    console.debug('PlayLevelView: world necessities loaded')
    // Called when we have enough to build the world, but not everything is loaded
    store.dispatch('game/resetTutorial')
    this.grabLevelLoaderData()
    const randomTeam = this.world && this.world.teamForPlayer() // If no team is set, then we will want to equally distribute players to teams
    const team = utils.getQueryVariable('team') || this.session.get('team') || randomTeam || 'humans'
    this.loadOpponentTeam(team)
    this.setupGod()
    this.setTeam(team)
    this.initGoalManager()
    this.insertSubviews()
    this.initVolume()
    this.register()
    this.controlBar.setBus(this.bus)
    return this.initScriptManager()
  }

  onWorldNecessityLoadFailed (resource) {
    return this.loadingView.onLoadError(resource)
  }

  grabLevelLoaderData () {
    this.session = this.levelLoader.session
    this.level = this.levelLoader.level
    this.updateCapstoneStage() // update this.capstoneStage based on session's state
    store.commit('game/setLevel', this.level.attributes)
    // Set current campaign id and unit map URL details for acodus chrome
    const campaignID = this.campaignID || this.level.get('campaign')
    // This campaign ID will be wrong when the data is outdated, but the state for campaigns is fault tolerant:
    store.commit('layoutChrome/setUnitMapUrlDetails', { courseId: this.courseID, courseInstanceId: this.courseInstanceID })
    store.dispatch('unitMap/buildLevelsData', { campaignHandle: campaignID, courseInstanceId: this.courseInstanceID, courseId: this.courseID })
    if (this.level.isType('web-dev')) {
      this.$el.addClass('web-dev') // Hide some of the elements we won't be using
      return
    }
    this.world = this.levelLoader.world
    if (this.level.isType('game-dev')) {
      this.$el.addClass('game-dev')
      this.howToPlayText = utils.i18n(
        this.level.attributes,
        'studentPlayInstructions'
      )
      if (this.howToPlayText == null) {
        this.howToPlayText = $.i18n.t(
          'play_game_dev_level.default_student_instructions'
        )
      }
      this.howToPlayText = marked(this.howToPlayText, { sanitize: true })
      this.renderSelectors('#how-to-play-game-dev-panel')
    }
    if (
      this.level.isType(
        'hero',
        'hero-ladder',
        'hero-coop',
        'course',
        'course-ladder',
        'game-dev'
      )
    ) {
      this.$el.addClass('hero')
    } // TODO: figure out what this does and comment it
    if (
      _.any(
        this.world.thangs,
        t =>
          (t.programmableProperties &&
            Array.from(t.programmableProperties).includes('findFlags')) ||
          (t.inventory != null ? t.inventory.flag : undefined)
      ) ||
      this.level.get('slug') === 'sky-span'
    ) {
      this.$el.addClass('flags')
    }
    // TODO: Update terminology to always be opponentSession or otherSession
    // TODO: E.g. if it's always opponent right now, then variable names should be opponentSession until we have coop play
    this.otherSession = this.levelLoader.opponentSession
    if (!this.level.isType('game-dev')) {
      this.worldLoadFakeResources = [] // first element (0) is 1%, last (99) is 100%
      for (let percent = 1; percent <= 100; percent++) {
        this.worldLoadFakeResources.push(
          this.supermodel.addSomethingResource(1)
        )
      }
    }
    return this.renderSelectors('#stop-real-time-playback-button')
  }

  updateCapstoneStage () {
    const maxCapstoneStage = GoalManager.maxCapstoneStage(((this.level || {}).attributes || {}).additionalGoals)
    if (!me.isSessionless() && this.session) {
      // As a player, we always want to get it from the session, which is undefined on stage 1:
      this.capstoneStage = (this.session.get('state') || {}).capstoneStage || 1

      if (!this.level) {
        return
      }

      // We don't want to overshoot the capstoneStage, as it causes problems with nextLevels lookups and share modals
      if (this.capstoneStage > maxCapstoneStage) {
        this.capstoneStage = maxCapstoneStage
      }
    }

    // We don't have a capstoneStage somehow, then it should begin at 1
    if (!this.capstoneStage) {
      this.capstoneStage = 1
    }

    // We have capstone jumping powers so we can set it any time we want
    // As long as it's not trying to set it back to the default of 1
    const capstoneStageFromArguments = this.getCapstoneStageFromArguments()
    if ((me.isAdmin() || me.isTeacher()) && capstoneStageFromArguments) {
      this.capstoneStage = capstoneStageFromArguments
    }
    // Save student goal directed code into another field if student has entered creativeMode at end of capstone.
    if (this.session && this.capstoneStage === maxCapstoneStage && this.level.get('creativeMode') === true) {
      const code = this.session.get('code') || {}
      if (!code['saved-capstone-normal-code'] && code['hero-placeholder']) {
        code['saved-capstone-normal-code'] = _.cloneDeep(code['hero-placeholder'])
        this.session.set('code', code)
        this.session.set('published', true)
        this.session.save()
      }
    }
  }

  getCapstoneStageFromArguments () {
    return parseInt(
      utils.getQueryVariable('capstoneStage') ||
      utils.getQueryVariable('capstonestage') || // Case sensitive, so this is easier to use
      this.options.capstoneStage, 10)
  }

  onWorldLoadProgressChanged (e) {
    if (e.god !== this.god) {
      return
    }
    if (!this.worldLoadFakeResources) {
      return
    }
    if (this.lastWorldLoadPercent == null) {
      this.lastWorldLoadPercent = 0
    }
    const worldLoadPercent = Math.floor(100 * e.progress)
    for (
      let percent = this.lastWorldLoadPercent + 1, end = worldLoadPercent;
      percent <= end;
      percent++
    ) {
      this.worldLoadFakeResources[percent - 1].markLoaded()
    }
    this.lastWorldLoadPercent = worldLoadPercent
    if (worldLoadPercent === 100) {
      this.worldFakeLoadResources = null
    } // Done, don't need to watch progress any more.
  }

  loadOpponentTeam (myTeam) {
    let opponentSpells = []
    const object = this.session.get('teamSpells') || (this.otherSession && this.otherSession.get('teamSpells')) || {}
    for (let spellTeam in object) {
      const spells = object[spellTeam]
      if (spellTeam === myTeam || !myTeam) {
        continue
      }
      opponentSpells = opponentSpells.concat(spells)
    }
    if (
      !this.session.get('teamSpells') &&
      (this.otherSession != null
        ? this.otherSession.get('teamSpells')
        : undefined)
    ) {
      this.session.set('teamSpells', this.otherSession.get('teamSpells'))
    }
    const opponentCode =
      (this.otherSession != null ? this.otherSession.get('code') : undefined) ||
      {}
    const myCode = this.session.get('code') || {}
    for (let spell of Array.from(opponentSpells)) {
      let thang;
      [thang, spell] = Array.from(spell.split('/'))
      const c =
        opponentCode[thang] != null ? opponentCode[thang][spell] : undefined
      if (myCode[thang] == null) {
        myCode[thang] = {}
      }
      if (c) {
        myCode[thang][spell] = c
      } else {
        delete myCode[thang][spell]
      }
    }
    return this.session.set('code', myCode)
  }

  setupGod () {
    if (this.level.isType('web-dev')) {
      return
    }
    if (!this.god) {
      return (this.waitingToSetUpGod = true)
    }
    this.waitingToSetUpGod = undefined
    const serializedLevel = this.level.serialize({
      supermodel: this.supermodel,
      session: this.session,
      otherSession: this.otherSession,
      headless: false,
      sessionless: false
    })
    if (me.constrainHeroHealth()) {
      serializedLevel.constrainHeroHealth = true
    }
    this.god.setLevel(serializedLevel)
    this.god.setLevelSessionIDs(
      this.otherSession
        ? [this.session.id, this.otherSession.id]
        : [this.session.id]
    )
    return this.god.setWorldClassMap(this.world.classMap)
  }

  setTeam (team) {
    if (!_.isString(team)) {
      team = (team || {}).team
    }
    if (!team) {
      team = 'humans'
    }
    me.team = team
    this.session.set('team', team)
    Backbone.Mediator.publish('level:team-set', { team }) // Needed for scripts
    this.team = team
  }

  initGoalManager () {
    const options = {
      additionalGoals: this.level.get('additionalGoals'),
      session: this.session,
      capstoneStage: this.capstoneStage,
      creativeMode: this.level.get('creativeMode') || false
    }
    if (this.level.get('assessment') === 'cumulative') {
      options.minGoalsToComplete = 1
    }
    this.goalManager = new GoalManager(
      this.world,
      this.level.get('goals'),
      this.team,
      options
    )
    if (typeof (this.god || {}).setGoalManager === 'function') {
      this.god.setGoalManager(this.goalManager)
    }
  }

  updateGoals (goals) {
    this.level.set('goals', goals)
    this.goalManager.destroy()
    this.initGoalManager()
  }

  updateSpellPalette (thang, spell) {
    if (
      !thang ||
      (this.spellPaletteView != null
        ? this.spellPaletteView.thang
        : undefined) === thang ||
      (!thang.programmableProperties &&
        !thang.apiProperties &&
        !thang.programmableHTMLProperties)
    ) {
      return
    }
    const useHero =
      /hero/.test(spell.getSource()) ||
      !/(self[\.\:]|this\.|\@)/.test(spell.getSource())
    this.spellPaletteView = this.insertSubView(
      new SpellPaletteView({
        thang,
        supermodel: this.supermodel,
        programmable: spell != null ? spell.canRead() : undefined,
        language:
          (spell != null ? spell.language : undefined) != null
            ? spell != null
              ? spell.language
              : undefined
            : this.session.get('codeLanguage'),
        session: this.session,
        level: this.level,
        courseID: this.courseID,
        courseInstanceID: this.courseInstanceID,
        useHero
      })
    )
  }
  // @spellPaletteView.toggleControls {}, spell.view.controlsEnabled if spell?.view   # TODO: know when palette should have been disabled but didn't exist

  insertSubviews () {
    let needle
    this.tome = new TomeView({
      levelID: this.levelID,
      session: this.session,
      otherSession: this.otherSession,
      playLevelView: this,
      thangs:
        (this.world != null ? this.world.thangs : undefined) != null
          ? this.world != null
            ? this.world.thangs
            : undefined
          : [],
      supermodel: this.supermodel,
      level: this.level,
      observing: this.observing,
      courseID: this.courseID,
      courseInstanceID: this.courseInstanceID,
      god: this.god,
      capstoneStage: this.capstoneStage
    })
    this.insertSubView(this.tome)

    if (this.level.get('ozariaType') === 'capstone') {
      // TODO: Is this a memory leak?
      new CapstonePlaybackView({
        el: this.$el.find('#playback-view')[0]
      })
    } else if (!this.level.isType('web-dev')) {
      this.insertSubView(
        new LevelPlaybackView({ session: this.session, level: this.level })
      )
    }
    this.insertSubView(
      new GoalsView({ level: this.level, session: this.session })
    )
    if (this.$el.hasClass('flags')) {
      this.insertSubView(
        new LevelFlagsView({ levelID: this.levelID, world: this.world })
      )
    }
    const goldInDuelStatsView = ((needle = this.level.get('slug')),
    ['wakka-maul', 'cross-bones'].includes(needle))
    if (!this.level.isType('web-dev', 'game-dev') && !goldInDuelStatsView) {
      this.insertSubView(new GoldView({}))
    }

    const HUDThangTypeList = this.world.frames[0]?.thangStateMap?.['Hero Placeholder']?.thang?.HUDThangTypeList
    if (Array.isArray(HUDThangTypeList)) {
      new ThangTypeHUDComponent({
        el: this.$el.find('#thangtype-hud-view')[0],
        propsData: {
          thangTypes: this.supermodel.getModels(ThangType),
          initialHUDThangTypeList: HUDThangTypeList
        }
      })
    }

    if (this.level.isType('game-dev')) {
      this.insertSubView(new GameDevTrackView({}))
      this.$('#game-dev-track-view').addClass('hide')
    }
    if (!this.level.isType('web-dev')) {
      this.insertSubView(new LevelHUDView({ level: this.level }))
    }
    this.insertSubView(new TutorialPlayView({
      level: this.level
    }))
    this.insertSubView(
      new ProblemAlertView({
        session: this.session,
        level: this.level,
        supermodel: this.supermodel
      })
    )
    this.insertSubView(
      new SurfaceContextMenuView({ session: this.session, level: this.level })
    )
    if (this.level.isType('hero-ladder', 'course-ladder')) {
      this.insertSubView(
        new DuelStatsView({
          level: this.level,
          session: this.session,
          otherSession: this.otherSession,
          supermodel: this.supermodel,
          thangs: this.world.thangs,
          showsGold: goldInDuelStatsView
        })
      )
    }
    this.controlBar = new ControlBarView({
      worldName: utils.i18n(this.level.attributes, 'name'),
      session: this.session,
      level: this.level,
      supermodel: this.supermodel,
      courseID: this.courseID,
      courseInstanceID: this.courseInstanceID
    })
    this.insertSubView(this.controlBar)

    // Note: This may be buggy now that the goalManager is being messed with
    // to handle even more complex capstone states, and reloading on the same page
    if (this.level.isType('web-dev')) {
      this.webSurface = new WebSurfaceView({
        level: this.level,
        goalManager: this.goalManager
      })
      this.insertSubView(this.webSurface)
    }
  }

  initVolume () {
    let volume = me.get('volume')
    if (volume == null) {
      volume = 1.0
    }
    return Backbone.Mediator.publish('level:set-volume', { volume })
  }

  initScriptManager () {
    if (this.level.isType('web-dev')) {
      return
    }
    this.scriptManager = new ScriptManager({
      scripts: this.world.scripts || [],
      view: this,
      session: this.session,
      levelID: this.level.get('slug')
    })
    return this.scriptManager.loadFromSession()
  }

  register () {
    this.bus = LevelBus.get(this.levelID, this.session.id)
    this.bus.setSession(this.session)
    return this.bus.setSpells(this.tome.spells)
  }

  // Load Completed Setup ######################################################

  onSessionLoaded (e) {
    let left1
    console.log('PlayLevelView: loaded session', e.session)
    store.commit('game/setTimesCodeRun', e.session.get('timesCodeRun') || 0)
    store.commit(
      'game/setTimesAutocompleteUsed',
      e.session.get('timesAutocompleteUsed') || 0
    )
    if (this.session) {
      return
    }
    // Just the level and session have been loaded by the level loader
    if (
      e.level.isType('hero', 'hero-ladder', 'hero-coop') &&
      !_.size(
        (left1 = __guard__(e.session.get('heroConfig'), x => x.inventory)) !=
          null
          ? left1
          : {}
      ) &&
      e.level.get('assessment') !== 'open-ended'
    ) {
      // Delaying this check briefly so LevelLoader.loadDependenciesForSession has a chance to set the heroConfig on the level session
      return _.defer(() => {
        let left2
        if (
          _.size(
            (left2 = __guard__(
              e.session.get('heroConfig'),
              x1 => x1.inventory
            )) != null
              ? left2
              : {}
          )
        ) {
          return
        }
        // TODO: which scenario is this executed for?
        if (this.setupManager != null) {
          this.setupManager.destroy()
        }
        this.setupManager = new LevelSetupManager({
          supermodel: this.supermodel,
          level: e.level,
          levelID: this.levelID,
          parent: this,
          session: e.session,
          courseID: this.courseID,
          courseInstanceID: this.courseInstanceID
        })
        return this.setupManager.open()
      })
    }
  }

  onLoaded () {
    return _.defer(() => this.onLevelLoaderLoaded())
  }

  onLevelLoaderLoaded () {
    // Everything is now loaded
    if (this.levelLoader.progress() !== 1) {
      return
    } // double check, since closing the guide may trigger this early

    // Save latest level played.
    if (
      !this.observing &&
      !this.levelLoader.level.isType('ladder', 'ladder-tutorial')
    ) {
      me.set('lastLevel', this.levelID)
      me.save()
      if (application.tracker != null) {
        application.tracker.identify()
      }
    }
    if (this.otherSession) {
      this.saveRecentMatch()
    }
    this.levelLoader.destroy()
    this.levelLoader = null
    if (this.level.isType('web-dev')) {
      return Backbone.Mediator.publish('level:started', {})
    } else {
      return this.initSurface()
    }
  }

  saveRecentMatch () {
    let left
    const allRecentlyPlayedMatches =
      (left = storage.load('recently-played-matches')) != null ? left : {}
    const recentlyPlayedMatches =
      allRecentlyPlayedMatches[this.levelID] != null
        ? allRecentlyPlayedMatches[this.levelID]
        : []
    allRecentlyPlayedMatches[this.levelID] = recentlyPlayedMatches
    if (
      !_.find(recentlyPlayedMatches, { otherSessionID: this.otherSession.id })
    ) {
      recentlyPlayedMatches.unshift({
        yourTeam: me.team,
        otherSessionID: this.otherSession.id,
        opponentName: this.otherSession.get('creatorName')
      })
    }
    recentlyPlayedMatches.splice(8)
    return storage.save('recently-played-matches', allRecentlyPlayedMatches)
  }

  initSurface () {
    const webGLSurface = $('canvas#webgl-surface', this.$el)
    const normalSurface = $('canvas#normal-surface', this.$el)
    const surfaceOptions = {
      thangTypes: this.supermodel.getModels(ThangType),
      observing: this.observing,
      playerNames: this.findPlayerNames(),
      levelType: this.level.get('type', true),
      stayVisible: this.showAds(),
      gameUIState: this.gameUIState,
      level: this.level // TODO: change from levelType to level
    }
    this.surface = new Surface(
      this.world,
      normalSurface,
      webGLSurface,
      surfaceOptions
    )
    const worldBounds = this.world.getBounds()
    const bounds = [
      { x: worldBounds.left, y: worldBounds.top },
      { x: worldBounds.right, y: worldBounds.bottom }
    ]
    this.surface.camera.setBounds(bounds)
    this.surface.camera.zoomTo({ x: 0, y: 0 }, 0.1, 0)
    return this.listenTo(this.surface, 'resize', function ({ height }) {
      this.$('#stop-real-time-playback-button').css({ top: height - 30 })
      return this.$('#how-to-play-game-dev-panel').css({ height })
    })
  }

  findPlayerNames () {
    if (!this.level.isType('ladder', 'hero-ladder', 'course-ladder')) {
      return {}
    }
    const playerNames = {}
    for (let session of [this.session, this.otherSession]) {
      if (session != null ? session.get('team') : undefined) {
        playerNames[session.get('team')] =
          session.get('creatorName') || 'Anonymous'
      }
    }
    return playerNames
  }

  // Once Surface is Loaded ####################################################

  onLevelStarted () {
    if (this.surface == null && this.webSurface == null) {
      return
    }
    console.log('PlayLevelView: level started')
    this.loadingView.showReady()
    this.trackLevelLoadEnd()
    if (
      window.currentModal &&
      !window.currentModal.destroyed &&
      [VictoryModal, CourseVictoryModal, HeroVictoryModal].indexOf(
        window.currentModal.constructor
      ) === -1
    ) {
      return Backbone.Mediator.subscribeOnce(
        'modal:closed',
        this.onLevelStarted,
        this
      )
    }
    if (this.surface != null) {
      this.surface.showLevel()
    }
    Backbone.Mediator.publish('level:set-time', { time: 0 })
    if (this.scriptManager != null) {
      this.scriptManager.initializeCamera()
    }

    store.dispatch('game/setTutorialActive', true)
  }

  onLoadingViewUnveiling (e) {
    return this.selectHero()
  }

  onLoadingViewUnveiled (e) {
    this.startLevel()
  }

  startLevel () {
    Backbone.Mediator.publish('level:loading-view-unveiling', {})
    if (this.level.isType('course-ladder', 'hero-ladder') || this.observing) {
      // We used to autoplay by default, but now we only do it if the level says to in the introduction script.
      Backbone.Mediator.publish('level:set-playing', { playing: true })
    }
    if (this.loadingView) {
      this.loadingView.$el.remove()
      this.removeSubView(this.loadingView)
      this.loadingView = null
    }
    this.playAmbientSound()
    if (!this.observing && this.level) {
      if (this.level.get('ozariaType') === 'capstone') {
        trackEvent('Loaded Capstone Stage', {
          category: 'Play Level',
          levelOriginalId: this.level.original || this.level.attributes.original,
          levelSessionId: this.session != null ? this.session.get('_id') : undefined,
          capstoneStage: this.capstoneStage
        }, ['Google Analytics'])
      } else if (this.level.get('ozariaType') === 'challenge') {
        trackEvent('Loaded Challenge Level', {
          category: 'Play Level',
          levelOriginalId: this.level.original || this.level.attributes.original,
          levelSessionId: this.session != null ? this.session.get('_id') : undefined
        }, ['Google Analytics'])
      } else {
        trackEvent('Loaded Practice Level', {
          category: 'Play Level',
          levelOriginalId: this.level.original || this.level.attributes.original,
          levelSessionId: this.session != null ? this.session.get('_id') : undefined
        }, ['Google Analytics'])
      }
    } else if (!this.level) {
      console.error('Expecte this.level to exist in PlayLevelView.startLevel, skipping event logging.')
    }
    $(window).trigger('resize')

    if (this.goalManager.goalStates['has-stopped-playing-game']) {
      this.goalManager.setGoalState('has-stopped-playing-game', 'incomplete')
    }
  }

  onSetVolume (e) {
    createjs.Sound.volume = e.volume === 1 ? 0.6 : e.volume // Quieter for now until individual sound FX controls work again.
    if (e.volume && !this.ambientSound) {
      return this.playAmbientSound()
    }
  }

  playAmbientSound () {
    let file
    if (this.destroyed) {
      return
    }
    if (this.ambientSound) {
      return
    }
    if (!me.get('volume')) {
      return
    }
    if (
      !(file = { Dungeon: 'ambient-dungeon', Grass: 'ambient-grass' }[this.level.get('terrain')])
    ) {
      return
    }
    const src = `/file/interface/${file}${AudioPlayer.ext}`
    if (!__guard__(AudioPlayer.getStatus(src), x => x.loaded)) {
      AudioPlayer.preloadSound(src)
      Backbone.Mediator.subscribeOnce(
        'audio-player:loaded',
        this.playAmbientSound,
        this
      )
      return
    }
    this.ambientSound = createjs.Sound.play(src, { loop: -1, volume: 0.1 })
    return createjs.Tween.get(this.ambientSound).to({ volume: 1.0 }, 10000)
  }

  selectHero () {
    Backbone.Mediator.publish('level:suppress-selection-sounds', {
      suppress: true
    })
    Backbone.Mediator.publish('tome:select-primary-sprite', {})
    Backbone.Mediator.publish('level:suppress-selection-sounds', {
      suppress: false
    })
    return this.surface != null ? this.surface.focusOnHero() : undefined
  }

  // callbacks

  onCtrlS (e) {
    return e.preventDefault()
  }

  onEscapePressed (e) {
    if (this.$el.hasClass('real-time')) {
      return Backbone.Mediator.publish('playback:stop-real-time-playback', {})
    } else if (this.$el.hasClass('cinematic')) {
      return Backbone.Mediator.publish('playback:stop-cinematic-playback', {})
    }
  }

  onLevelReloadFromData (e) {
    const isReload = Boolean(this.world)
    if (isReload) {
      // Make sure to share any models we loaded that the parent didn't, like hero equipment, in case the parent relodaed
      for (let url in this.supermodel.models) {
        const model = this.supermodel.models[url]
        if (!e.supermodel.models[url]) {
          e.supermodel.registerModel(model)
        }
      }
    }
    this.setLevel(e.level, e.supermodel)
    if (isReload) {
      this.scriptManager.setScripts(e.level.get('scripts'))
      this.updateGoals(e.level.get('goals'))
      return Backbone.Mediator.publish('tome:cast-spell', {}) // a bit hacky
    }
  }

  onLevelReloadThangType (e) {
    const tt = e.thangType
    for (let url in this.supermodel.models) {
      const model = this.supermodel.models[url]
      if (model.id === tt.id) {
        for (let key in tt.attributes) {
          const val = tt.attributes[key]
          model.attributes[key] = val
        }
        break
      }
    }
    return Backbone.Mediator.publish('tome:cast-spell', {})
  }

  onOpenRestartModal (e) {
    this.openModalView(new RestartLevelModal(this.session))
  }

  onOpenOptionsModal (e) {
    this.openModalView(new GameMenuModal({ level: this.level, session: this.session, supermodel: this.supermodel }))
  }

  onWindowResize (e) {
    return this.endHighlight()
  }

  onDisableControls (e) {
    if (e.controls && !Array.from(e.controls).includes('level')) {
      return
    }
    this.shortcutsEnabled = false
    this.wasFocusedOn = document.activeElement
    return $('body').focus()
  }

  onEnableControls (e) {
    if (e.controls != null && !Array.from(e.controls).includes('level')) {
      return
    }
    this.shortcutsEnabled = true
    if (this.wasFocusedOn) {
      $(this.wasFocusedOn).focus()
    }
    this.wasFocusedOn = null
  }

  onDonePressed () {
    this.showVictory()
  }

  onShowVictory (e) {
    e = e || {}
    const currentCapstoneStage = this.capstoneStage // this.capstoneStage updated in showVictory/softReload
    if (
      !this.level.isType(
        'hero',
        'hero-ladder',
        'hero-coop',
        'course',
        'course-ladder',
        'game-dev',
        'web-dev'
      )
    ) {
      $('#level-done-button').show()
    }

    if (!this.observing) {
      if (this.level.get('ozariaType') === 'capstone') {
        if (e.capstoneInProgress) {
          trackEvent('Completed Capstone Stage', {
            category: 'Play Level',
            levelOriginalId: this.level.original || this.level.attributes.original,
            levelSessionId: this.session != null ? this.session.get('_id') : undefined,
            playtime: this.session != null ? this.session.get('playtime') : undefined,
            capstoneStage: currentCapstoneStage || this.capstoneStage
          }, ['Google Analytics'])
        } else {
          trackEvent('Completed Capstone Level', {
            category: 'Play Level',
            levelOriginalId: this.level.original || this.level.attributes.original,
            levelSessionId: this.session != null ? this.session.get('_id') : undefined,
            playtime: this.session != null ? this.session.get('playtime') : undefined
          }, ['Google Analytics'])
        }
      } else if (this.level.get('ozariaType') === 'challenge') {
        trackEvent('Completed Challenge Level', {
          category: 'Play Level',
          levelOriginalId: this.level.original || this.level.attributes.original,
          levelSessionId: this.session != null ? this.session.get('_id') : undefined
        }, ['Google Analytics'])
      } else {
        trackEvent('Completed Practice Level', {
          category: 'Play Level',
          levelOriginalId: this.level.original || this.level.attributes.original,
          levelSessionId: this.session != null ? this.session.get('_id') : undefined,
          playtime: this.session != null ? this.session.get('playtime') : undefined
        }, ['Google Analytics'])
      }
      if (application.tracker) {
        application.tracker.trackTiming(
          new Date() - this.loadEndTime,
          'Level Victory Time',
          this.levelID,
          this.levelID
        )
      }
    }

    if (e.showModal) {
      this.showVictory(_.pick(e, 'manual', 'capstoneInProgress'))
    }
  }

  showVictory (options) {
    if (options == null) {
      options = {}
    }
    if (this.level.hasLocalChanges()) {
      return
    } // Don't award achievements when beating level changed in level editor

    const additionalGoals = this.level.get('additionalGoals')
    if (
      this.level.isType('game-dev') &&
      this.level.get('shareable') &&
      !options.manual &&
      !additionalGoals
    ) {
      return
    }
    if (this.showVictoryHandlingInProgress) {
      return
    }
    this.showVictoryHandlingInProgress = true
    this.endHighlight()
    const goToNextDirectly = options.capstoneInProgress
    options = {
      level: this.level,
      courseId: this.courseID,
      courseInstanceId: this.courseInstanceID,
      goToNextDirectly: goToNextDirectly && !this.continueEditing
    }

    if (this.level.isCapstone()) {
      options.capstoneStage = this.capstoneStage.toString()
    }
    if (!me.isSessionless()) {
      this.onSubmissionComplete()

      if (this.continueEditing) {
        options.showShareModal = true
      }
    }

    if (this.level.isCapstone()) {
      const campaignLevel = store.state.unitMap.currentLevelsList[this.level.original || this.level.attributes.original]
      if (!getNextLevelForLevel(campaignLevel, this.capstoneStage)) {
        // If there is no nextLevel, we simply go to the next capstoneStage directly
        this.softReload()
        return
      }
    }

    let ModalClass = OzariaTransitionModal
    if (this.level.isType('course-ladder')) {
      options.courseInstanceID =
        utils.getQueryVariable('course-instance') ||
        utils.getQueryVariable('league')
    }

    const victoryModal = new ModalClass(options)
    this.openModalView(victoryModal)
    victoryModal.once('hidden', () => {
      this.showVictoryHandlingInProgress = false
    })

    if (me.get('anonymous')) {
      // Signup will go here on completion instead of reloading.
      window.nextURL = `/play/${this.campaignID || this.level.get('campaign') || ''}`
    }
  }

  onRestartLevel () {
    this.tome.reloadAllCode()
    if (me.isAdmin() && this.level.get('ozariaType') === 'capstone') {
      const shouldResetCapstone = window.confirm('Do you want to restart capstone stage progress to 1?')
      if (shouldResetCapstone) {
        const code = this.session.get('code') || {}
        if (code['saved-capstone-normal-code']) {
          delete code['saved-capstone-normal-code']
          this.session.set('code', code)
        }
        const state = this.session.get('state')
        if (state) {
          state.capstoneStage = 1
          this.session.set('state', state)
        }
        this.session.save(null, {
          success: () => setTimeout(application.router.reload, 3000) // Give settings time to propagate before reloading the page
        })
      }
    }

    Backbone.Mediator.publish('level:restarted', {})
    $('#level-done-button', this.$el).hide()
    if (!this.observing) {
      trackEvent('Confirmed Restart', {
        category: 'Play Level',
        level: this.level.get('name'),
        label: this.level.get('name')
      })
    }

    store.dispatch('game/resetTutorial')
    this.scriptManager.setScripts(this.level.get('scripts'))
    store.dispatch('game/setTutorialActive', true)
  }

  onInfiniteLoop (e) {
    if (!e.firstWorld || e.god !== this.god) {
      return
    }
    this.openModalView(
      new InfiniteLoopModal({ nonUserCodeProblem: e.nonUserCodeProblem, isCapstone: this.level.isCapstone() || false })
    )
    if (!this.observing) {
      trackEvent('Saw Initial Infinite Loop', {
        category: 'Play Level',
        level: this.level.get('name'),
        label: this.level.get('name')
      })
    }
  }

  onHighlightDOM (e) {
    return this.highlightElement(e.selector, {
      delay: e.delay,
      sides: e.sides,
      offset: e.offset,
      rotation: e.rotation
    })
  }

  onEndHighlight () {
    return this.endHighlight()
  }

  onFocusDom (e) {
    return $(e.selector).focus()
  }

  onContactClicked (e) {
    if (me.isStudent()) {
      console.error('Student clicked contact modal.')
      return
    }
    const contactModal = new ContactModal({
      levelID: this.level.get('slug') || this.level.id,
      courseID: this.courseID,
      courseInstanceID: this.courseInstanceID
    })
    Backbone.Mediator.publish('level:contact-button-pressed', {})
    this.openModalView(contactModal)
    const screenshot = this.surface.screenshot(1, 'image/png', 1.0, 1)
    const body = {
      b64png: screenshot.replace('data:image/png;base64,', ''),
      filename: `screenshot-${this.levelID}-${_.string.slugify(
        new Date().toString()
      )}.png`,
      path: `db/user/${me.id}`,
      mimetype: 'image/png'
    }
    contactModal.screenshotURL = `http://codecombat.com/file/${body.path}/${
      body.filename
    }`
    window.screenshot = screenshot
    window.screenshotURL = contactModal.screenshotURL
    return $.ajax('/file', {
      type: 'POST',
      data: body,
      success () {
        if (typeof contactModal.updateScreenshot === 'function') {
          contactModal.updateScreenshot()
        }
      }
    })
  }

  onSurfaceContextMenu (e) {
    if (
      !this.surface.showCoordinates ||
      (!navigator.clipboard && !document.queryCommandSupported('copy'))
    ) {
      return
    }
    __guardMethod__(e, 'preventDefault', o => o.preventDefault())
    const pos = { x: e.clientX, y: e.clientY }
    const wop = this.surface.coordinateDisplay.lastPos
    return Backbone.Mediator.publish('level:surface-context-menu-pressed', {
      posX: pos.x,
      posY: pos.y,
      wopX: wop.x,
      wopY: wop.y
    })
  }

  // Dynamic sound loading

  onNewWorld (e) {
    if (this.headless) {
      return
    }
    const { scripts } = this.world // Since these worlds don't have scripts, preserve them.
    this.world = e.world

    // without this check, when removing goals, goals aren't updated properly. Make sure we update
    // the goals once the first frame is finished.
    if (this.world.age > 0 && this.willUpdateStudentGoals) {
      this.willUpdateStudentGoals = false
      this.updateStudentGoals()
      this.updateLevelName()
    }

    this.world.scripts = scripts
    const thangTypes = this.supermodel.getModels(ThangType)
    const startFrame =
      this.lastWorldFramesLoaded != null ? this.lastWorldFramesLoaded : 0
    const finishedLoading = this.world.frames.length === this.world.totalFrames
    this.realTimePlaybackWaitingForFrames = false
    if (finishedLoading) {
      this.lastWorldFramesLoaded = 0
      if (this.waitingForSubmissionComplete) {
        if (this.level.get('ozariaType') !== 'capstone') {
          _.defer(this.onSubmissionComplete) // Give it a frame to make sure we have the latest goals
        }

        this.waitingForSubmissionComplete = false
      }
    } else {
      this.lastWorldFramesLoaded = this.world.frames.length
    }
    for (var [spriteName, message] of Array.from(
      this.world.thangDialogueSounds(startFrame)
    )) {
      var sound, thangType
      if (
        !(thangType = _.find(thangTypes, m => m.get('name') === spriteName))
      ) {
        continue
      }
      if (
        !(sound = AudioPlayer.soundForDialogue(
          message,
          thangType.get('soundTriggers')
        ))
      ) {
        continue
      }
      AudioPlayer.preloadSoundReference(sound)
    }
    if (this.level.isType('game-dev')) {
      this.session.updateKeyValueDb(e.keyValueDb)
    }

    this.loadScriptsForCapstoneStage(scripts, this.capstoneStage)
  }

  // Real-time playback
  onRealTimePlaybackStarted (e) {
    this.$el.addClass('real-time').focus()
    this.willUpdateStudentGoals = true
    this.updateStudentGoals()
    this.updateLevelName()
    this.onWindowResize()
    this.realTimePlaybackWaitingForFrames = true
    if (this.level.isType('game-dev')) {
      this.$('#game-dev-track-view').removeClass('hide')
    }
  }

  updateStudentGoals () {
    if (!this.level.isType('game-dev')) {
      return
    }
    // Set by users. Defined in `game.GameUI` component in the level editor.
    if (
      __guard__(
        this.world.uiText != null ? this.world.uiText.directions : undefined,
        x => x.length
      )
    ) {
      this.studentGoals = this.world.uiText.directions.map(direction => ({
        type: 'user_defined',
        direction
      }))
    } else {
      this.studentGoals =
        this.world.thangMap['Hero Placeholder'].stringGoals != null
          ? this.world.thangMap['Hero Placeholder'].stringGoals.map(g =>
            JSON.parse(g)
          )
          : undefined
    }
    this.renderSelectors('#how-to-play-game-dev-panel')
    return this.$('#how-to-play-game-dev-panel').removeClass('hide')
  }

  updateLevelName () {
    if (this.world.uiText != null ? this.world.uiText.levelName : undefined) {
      return this.controlBar.setLevelName(this.world.uiText.levelName)
    }
  }

  onRealTimePlaybackEnded (e) {
    // TODO Improve later with GoalManger reworking
    // Mark the goal completed and prevent the goalmanager destroying
    // The game goal should have the certain name
    if (!this.updateAetherIsRunning && this.goalManager.goalStates['has-stopped-playing-game']) {
      this.goalManager.setGoalState('has-stopped-playing-game', 'success')
    }

    if (store.getters['game/clickedUpdateCapstoneCode'] && this.goalManager.goalStates['has-clicked-update-button']) {
      this.goalManager.setGoalState('has-clicked-update-button', 'success')
    }

    this.updateAetherIsRunning = false

    if (!this.$el.hasClass('real-time')) {
      return
    }
    if (this.level.isType('game-dev')) {
      this.$('#how-to-play-game-dev-panel').addClass('hide')
      this.$('#game-dev-track-view').addClass('hide')
    }
    this.$el.removeClass('real-time')
    this.onWindowResize()
    if (this.level.isType('game-dev')) {
      this.session.saveKeyValueDb()
    }
    if (
      this.world.frames.length === this.world.totalFrames &&
      !(this.surface.countdownScreen != null
        ? this.surface.countdownScreen.showing
        : undefined) &&
      !this.realTimePlaybackWaitingForFrames &&
      this.level.get('ozariaType') !== 'capstone'
    ) {
      return _.delay(this.onSubmissionComplete, 750) // Wait for transition to end.
    } else {
      this.waitingForSubmissionComplete = true
    }

    // Hack to work around bugged goal states not calling notify in specific cases (stage 3 on Chapter 1):
    if (this.level.get('ozariaType') === 'capstone') {
      setTimeout(function () {
        this.goalManager.notifyGoalChanges()
      }.bind(this), 2000)
    }
  }

  // Cinematice playback
  onCinematicPlaybackStarted (e) {
    this.$el.addClass('cinematic').focus()
    this.onWindowResize()
  }

  onCinematicPlaybackEnded (e) {
    if (!this.$el.hasClass('cinematic')) {
      return
    }
    this.$el.removeClass('cinematic')
    this.onWindowResize()
  }

  onSubmissionComplete () {
    if (this.destroyed) {
      return
    }

    Backbone.Mediator.publish('level:set-time', { ratio: 1 })

    // Don't award achievements when beating level changed in level editor
    if (this.level.hasLocalChanges()) {
      return
    }

    if (this.goalManager.finishLevel()) {
      const showModalFn = () =>
        Backbone.Mediator.publish('level:show-victory', { showModal: true })
      this.session.recordScores(this.world.scores, this.level)

      // Skip triggering the victory modal automatically for ozaria capstone levels.
      if (this.level.get('ozariaType') !== 'capstone') {
        if (this.level.get('replayable')) {
          return this.session.increaseDifficulty(showModalFn)
        } else {
          return showModalFn()
        }
      }
    }
  }

  destroy () {
    let ambientSound
    if (this.levelLoader != null) {
      this.levelLoader.destroy()
    }
    if (this.surface != null) {
      this.surface.destroy()
    }
    if (this.god != null) {
      this.god.destroy()
    }
    if (this.goalManager != null) {
      this.goalManager.destroy()
    }
    if (this.scriptManager != null) {
      this.scriptManager.destroy()
    }
    if (this.setupManager != null) {
      this.setupManager.destroy()
    }
    if ((ambientSound = this.ambientSound)) {
      // Doesn't seem to work; stops immediately.
      createjs.Tween.get(ambientSound)
        .to({ volume: 0.0 }, 1500)
        .call(() => ambientSound.stop())
    }
    $(window).off('resize', this.onWindowResize)
    delete window.world // not sure where this is set, but this is one way to clean it up
    if (this.bus != null) {
      this.bus.destroy()
    }
    delete window.nextURL
    if (PROFILE_ME) {
      if (typeof console.profileEnd === 'function') {
        console.profileEnd()
      }
    }
    if (this.level) {
      if (this.level.get('ozariaType') === 'capstone') {
        trackEvent('Unloaded Capstone Stage', {
          category: 'Play Level',
          levelOriginalId: this.level.original || this.level.attributes.original,
          levelSessionId: this.session != null ? this.session.get('_id') : undefined,
          capstoneStage: this.capstoneStage
        }, ['Google Analytics'])
      } else if (this.level.get('ozariaType') === 'challenge') {
        trackEvent('Unloaded Challenge Level', {
          category: 'Play Level',
          levelOriginalId: this.level.original || this.level.attributes.original,
          levelSessionId: this.session != null ? this.session.get('_id') : undefined
        }, ['Google Analytics'])
      } else {
        trackEvent('Unloaded Practice Level', {
          category: 'Play Level',
          levelOriginalId: this.level.original || this.level.attributes.original,
          levelSessionId: this.session != null ? this.session.get('_id') : undefined
        }, ['Google Analytics'])
      }
    } else if (!this.level) {
      console.error('Expecte this.level to exist in PlayLevelView.destroy, skipping event logging.')
    }
    return super.destroy()
  }

  onItemPurchased (e) {
    let left
    const heroConfig =
      (left = this.session.get('heroConfig')) != null ? left : {}
    const inventory = heroConfig.inventory != null ? heroConfig.inventory : {}
    const slot = e.item.getAllowedSlots()[0]
    if (slot && !inventory[slot]) {
      // Open up the inventory modal so they can equip the new item
      if (this.setupManager != null) {
        this.setupManager.destroy()
      }
      this.setupManager = new LevelSetupManager({
        supermodel: this.supermodel,
        level: this.level,
        levelID: this.levelID,
        parent: this,
        session: this.session,
        hadEverChosenHero: true
      })
      return this.setupManager.open()
    }
  }

  getLoadTrackingTag () {
    return this.level != null ? this.level.get('slug') : undefined
  }

  onRunCode () {
    return store.commit('game/incrementTimesCodeRun')
  }

  // Update the elements on the page without reloading the entire page.
  // This lets us progress to a new capstoneStage and update each element that needs this information.
  softReload () {
    this.showVictoryHandlingInProgress = false
    this.updateCapstoneStage()

    if (me.isSessionless() || !this.session) {
      this.capstoneStage += 1
      let url = document.URL
      if (url.indexOf('capstoneStage') > 0) {
        url = url.replace(new RegExp('capstoneStage=[^&]+'), 'capstoneStage=' + this.capstoneStage)
      } else if (url.indexOf('?') > 0) { // No capstoneStage query parameter found, but at least there is a query parameter
        url += '&capstoneStage=' + this.capstoneStage
      } else { // Somehow we don't have ANY query parameters... unlikely to ever reach this state
        url += '?capstoneStage=' + this.capstoneStage
      }

      window.history.pushState(null, null, url)
    }


    store.dispatch('game/resetTutorial', {
      keepIntro: true
    })
    this.scriptManager.setScripts(this.level.get('scripts'))
    this.goalManager.destroy()
    this.initGoalManager()
    this.tome.softReloadCapstoneStage(this.capstoneStage)
    Backbone.Mediator.publish('tome:updateAether')

    this.loadScriptsForCapstoneStage(this.world.scripts, this.capstoneStage)
    store.dispatch('game/setTutorialActive', true)
  }

  updateAetherRunning (e) {
    store.dispatch('game/setClickedUpdateCapstoneCode', true)
    this.updateAetherIsRunning = true
  }

  loadScriptsForCapstoneStage (scripts, capstoneStage) {
    if (!scripts) {
      console.error('Tried to loadScriptsForCapstoneStage but scripts was empty')
      return
    }

    const matchesCapstoneStage = { eventProps: ['god', 'capstoneStage'], equalTo: capstoneStage }
    scripts
      .filter(script => (script.eventPrereqs || []).find(e => _.isEqual(e, matchesCapstoneStage)))
      .forEach(script => {
        const sayEvents = ScriptManager.extractSayEvents(script)
        if (sayEvents.length) {
          store.dispatch('game/addTutorialStepsFromSayEvents', sayEvents)
        }
      })
  }
}

PlayLevelView.prototype.id = 'level-view'
PlayLevelView.prototype.template = template
PlayLevelView.prototype.cache = false
PlayLevelView.prototype.shortcutsEnabled = true
PlayLevelView.prototype.isEditorPreview = false

PlayLevelView.prototype.subscriptions = {
  'level:set-volume': 'onSetVolume',
  'level:show-victory': 'onShowVictory',
  'level:restart': 'onRestartLevel',
  'level:highlight-dom': 'onHighlightDOM',
  'level:end-highlight-dom': 'onEndHighlight',
  'level:focus-dom': 'onFocusDom',
  'level:disable-controls': 'onDisableControls',
  'level:enable-controls': 'onEnableControls',
  'god:world-load-progress-changed': 'onWorldLoadProgressChanged',
  'god:new-world-created': 'onNewWorld',
  'god:streaming-world-updated': 'onNewWorld',
  'god:infinite-loop': 'onInfiniteLoop',
  'level:reload-from-data': 'onLevelReloadFromData',
  'level:reload-thang-type': 'onLevelReloadThangType',
  'level:open-restart-modal': 'onOpenRestartModal',
  'level:open-options-modal': 'onOpenOptionsModal',
  'level:started': 'onLevelStarted',
  'level:loading-view-unveiling': 'onLoadingViewUnveiling',
  'level:loading-view-unveiled': 'onLoadingViewUnveiled',
  'level:loaded': 'onLevelLoaded',
  'level:session-loaded': 'onSessionLoaded',
  'playback:real-time-playback-started': 'onRealTimePlaybackStarted',
  'playback:real-time-playback-ended': 'onRealTimePlaybackEnded',
  'playback:cinematic-playback-started': 'onCinematicPlaybackStarted',
  'playback:cinematic-playback-ended': 'onCinematicPlaybackEnded',
  'store:item-purchased': 'onItemPurchased',
  'tome:manual-cast': 'onRunCode',
  'tome:updateAetherRunning': 'updateAetherRunning'
}

PlayLevelView.prototype.events = {
  'click #level-done-button': 'onDonePressed',
  'click #stop-real-time-playback-button' () {
    return Backbone.Mediator.publish('playback:stop-real-time-playback', {})
  },
  'click #stop-cinematic-playback-button' () {
    return Backbone.Mediator.publish('playback:stop-cinematic-playback', {})
  },
  'click #fullscreen-editor-background-screen' (e) {
    return Backbone.Mediator.publish('tome:toggle-maximize', {})
  },
  'click .contact-link': 'onContactClicked',
  'contextmenu #webgl-surface': 'onSurfaceContextMenu',
  click: 'onClick'
}

PlayLevelView.prototype.shortcuts = {
  'ctrl+s': 'onCtrlS',
  esc: 'onEscapePressed'
}

/**
 * @param {string} action
 * @param {Object} properties
 * @param {string[]} includeIntegrations
 */
function trackEvent (action, properties = {}, includeIntegrations = []) {
  if (application.tracker != null) {
    application.tracker.trackEvent(action, properties, includeIntegrations)
  }
}

function __guard__ (value, transform) {
  return typeof value !== 'undefined' && value !== null
    ? transform(value)
    : undefined
}
function __guardMethod__ (obj, methodName, transform) {
  if (
    typeof obj !== 'undefined' &&
    obj !== null &&
    typeof obj[methodName] === 'function'
  ) {
    return transform(obj, methodName)
  } else {
    return undefined
  }
}

module.exports = PlayLevelView
