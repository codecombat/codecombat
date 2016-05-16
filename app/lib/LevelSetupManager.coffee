CocoClass = require 'core/CocoClass'
PlayHeroesModal = require 'views/play/modal/PlayHeroesModal'
InventoryModal = require 'views/play/menu/InventoryModal'
Level = require 'models/Level'
LevelSession = require 'models/LevelSession'
SuperModel = require 'models/SuperModel'
ThangType = require 'models/ThangType'

lastHeroesEarned = me.get('earned')?.heroes ? []
lastHeroesPurchased = me.get('purchased')?.heroes ? []

module.exports = class LevelSetupManager extends CocoClass

  constructor: (@options) ->
    super()
    @supermodel = @options.supermodel ? new SuperModel()
    @session = @options.session
    unless @level = @options.level
      @loadLevel()
    if @session
      @fillSessionWithDefaults()
    else
      @loadSession()

  loadLevel: ->
    levelURL = "/db/level/#{@options.levelID}"
    @level = new Level().setURL levelURL
    @level = @supermodel.loadModel(@level).model
    if @level.loaded then @onLevelSync() else @listenToOnce @level, 'sync', @onLevelSync

  loadSession: ->
    sessionURL = "/db/level/#{@options.levelID}/session"
    #sessionURL += "?team=#{@team}" if @options.team  # TODO: figure out how to get the teams for multiplayer PVP hero style
    sessionURL += "?course=#{@options.courseID}" if @options.courseID
    @session = new LevelSession().setURL sessionURL
    @session = @supermodel.loadModel(@session).model
    if @session.loaded then @onSessionSync() else @listenToOnce @session, 'sync', @onSessionSync

  onLevelSync: ->
    return if @destroyed
    if @waitingToLoadModals
      @waitingToLoadModals = false
      @loadModals()

  onSessionSync: ->
    return if @destroyed
    @session.url = -> '/db/level.session/' + @id
    @fillSessionWithDefaults()

  fillSessionWithDefaults: ->
    heroConfig = _.merge {}, me.get('heroConfig'), @session.get('heroConfig')
    @session.set('heroConfig', heroConfig)
    if @level.loaded
      @loadModals()
    else
      @waitingToLoadModals = true

  loadModals: ->
    # build modals and prevent them from disappearing.
    if @level.get('slug') is 'zero-sum'
      sorcerer = '52fd1524c7e6cf99160e7bc9'
      if @session.get('creator') is '532dbc73a622924444b68ed9'  # Wizard Dude gets his own avatar
        sorcerer = '53e126a4e06b897606d38bef'
      @session.set 'heroConfig', {"thangType":sorcerer,"inventory":{"misc-0":"53e2396a53457600003e3f0f","programming-book":"546e266e9df4a17d0d449be5","minion":"54eb5dbc49fa2d5c905ddf56","feet":"53e214f153457600003e3eab","right-hand":"54eab7f52b7506e891ca7202","left-hand":"5463758f3839c6e02811d30f","wrists":"54693797a2b1f53ce79443e9","gloves":"5469425ca2b1f53ce7944421","torso":"546d4a549df4a17d0d449a97","neck":"54693274a2b1f53ce79443c9","eyes":"546941fda2b1f53ce794441d","head":"546d4ca19df4a17d0d449abf"}}
      @onInventoryModalPlayClicked()
      return
    if @level.get('slug') in ['ace-of-coders', 'elemental-wars']
      goliath = '55e1a6e876cb0948c96af9f8'
      @session.set 'heroConfig', {"thangType":goliath,"inventory":{"eyes":"53eb99f41a100989a40ce46e","neck":"54693274a2b1f53ce79443c9","wrists":"54693797a2b1f53ce79443e9","feet":"546d4d8e9df4a17d0d449acd","minion":"54eb5bf649fa2d5c905ddf4a","programming-book":"557871261ff17fef5abee3ee"}}
      @onInventoryModalPlayClicked()
      return
    if @level.get('slug') is 'assembly-speed'
      raider = '55527eb0b8abf4ba1fe9a107'
      @session.set 'heroConfig', {"thangType":raider,"inventory":{}}
      @onInventoryModalPlayClicked()
      return
    if @level.get('type', true) in ['course', 'course-ladder'] or window.serverConfig.picoCTF
      @onInventoryModalPlayClicked()
      return
    @heroesModal = new PlayHeroesModal({supermodel: @supermodel, session: @session, confirmButtonI18N: 'play.next', level: @level, hadEverChosenHero: @options.hadEverChosenHero})
    @inventoryModal = new InventoryModal({supermodel: @supermodel, session: @session, level: @level})
    @heroesModalDestroy = @heroesModal.destroy
    @inventoryModalDestroy = @inventoryModal.destroy
    @heroesModal.destroy = @inventoryModal.destroy = _.noop
    @listenTo @heroesModal, 'confirm-click', @onHeroesModalConfirmClicked
    @listenToOnce @heroesModal, 'hero-loaded', @onceHeroLoaded
    @listenTo @inventoryModal, 'choose-hero-click', @onChooseHeroClicked
    @listenTo @inventoryModal, 'play-click', @onInventoryModalPlayClicked
    @modalsLoaded = true
    if @waitingToOpen
      @waitingToOpen = false
      @open()

  open: ->
    return @waitingToOpen = true unless @modalsLoaded
    firstModal = if @options.hadEverChosenHero then @inventoryModal else @heroesModal
    if (not _.isEqual(lastHeroesEarned, me.get('earned')?.heroes ? []) or
        not _.isEqual(lastHeroesPurchased, me.get('purchased')?.heroes ? []))
      console.log 'Showing hero picker because heroes earned/purchased has changed.'
      firstModal = @heroesModal
    else if allowedHeroSlugs = @level.get 'allowedHeroes'
      unless _.find(allowedHeroSlugs, (slug) -> ThangType.heroes[slug] is me.get('heroConfig')?.thangType)
        firstModal = @heroesModal
    lastHeroesEarned = me.get('earned')?.heroes ? []
    lastHeroesPurchased = me.get('purchased')?.heroes ? []

    @options.parent.openModalView(firstModal)
    @trigger 'open'
    #    @inventoryModal.onShown() # replace?

  #- Modal events

  onceHeroLoaded: (e) ->
    @inventoryModal.setHero(e.hero) if window.currentModal is @inventoryModal

  onHeroesModalConfirmClicked: (e) ->
    @options.parent.openModalView(@inventoryModal)
    @inventoryModal.render()
    @inventoryModal.didReappear()
    @inventoryModal.onShown()
    @inventoryModal.setHero(e.hero) if e.hero
    window.tracker?.trackEvent 'Choose Inventory', category: 'Play Level'

  onChooseHeroClicked: ->
    @options.parent.openModalView(@heroesModal)
    @heroesModal.render()
    @heroesModal.didReappear()
    @inventoryModal.endHighlight()
    window.tracker?.trackEvent 'Change Hero', category: 'Play Level'

  onInventoryModalPlayClicked: ->
    @navigatingToPlay = true
    PlayLevelView = 'views/play/level/PlayLevelView'
    LadderView = 'views/ladder/LadderView'
    viewClass = if @options.levelPath is 'ladder' then LadderView else PlayLevelView
    Backbone.Mediator.publish 'router:navigate', {
      route: "/play/#{@options.levelPath || 'level'}/#{@options.levelID}"
      viewClass: viewClass
      viewArgs: [{supermodel: @supermodel}, @options.levelID]
    }

  destroy: ->
    @heroesModalDestroy?.call @heroesModal unless @heroesModal?.destroyed
    @inventoryModalDestroy?.call @inventoryModal unless @inventoryModal?.destroyed
    super()
