CocoClass = require 'core/CocoClass'
PlayHeroesModal = require 'views/play/modal/PlayHeroesModal'
InventoryModal = require 'views/play/menu/InventoryModal'
LevelSession = require 'models/LevelSession'
SuperModel = require 'models/SuperModel'
ThangType = require 'models/ThangType'
LevelOptions = require 'lib/LevelOptions'

lastHeroesEarned = me.get('earned')?.heroes ? []
lastHeroesPurchased = me.get('purchased')?.heroes ? []


module.exports = class LevelSetupManager extends CocoClass

  constructor: (@options) ->
    super()
    @supermodel = @options.supermodel ? new SuperModel()
    @session = @options.session
    if @session
      @fillSessionWithDefaults()
    else
      @loadSession()

  loadSession: ->
    url = "/db/level/#{@options.levelID}/session"
    #url += "?team=#{@team}" if @options.team  # TODO: figure out how to get the teams for multiplayer PVP hero style
    @session = new LevelSession().setURL url
    onSessionSync = ->
      return if @destroyed
      @session.url = -> '/db/level.session/' + @id
      @fillSessionWithDefaults()
    @listenToOnce @session, 'sync', onSessionSync
    @session = @supermodel.loadModel(@session, 'level_session').model
    if @session.loaded
      onSessionSync.call @

  fillSessionWithDefaults: ->
    heroConfig = _.merge {}, me.get('heroConfig'), @session.get('heroConfig')
    @session.set('heroConfig', heroConfig)
    @loadModals()

  loadModals: ->
    # build modals and prevent them from disappearing.
    @heroesModal = new PlayHeroesModal({supermodel: @supermodel, session: @session, confirmButtonI18N: 'play.next', levelID: @options.levelID, hadEverChosenHero: @options.hadEverChosenHero})
    @inventoryModal = new InventoryModal({supermodel: @supermodel, session: @session, levelID: @options.levelID})
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
    else if allowedHeroSlugs = LevelOptions[@options.levelID]?.allowedHeroes
      unless _.find(allowedHeroSlugs, (slug) -> ThangType.heroes[slug] is me.get('heroConfig')?.thangType)
        firstModal = @heroesModal
    lastHeroesEarned = me.get('earned')?.heroes ? []
    lastHeroesPurchased = me.get('purchased')?.heroes ? []

    @options.parent.openModalView(firstModal)
    #    @inventoryModal.onShown() # replace?
    @playSound 'game-menu-open'


  #- Modal events

  onceHeroLoaded: (e) ->
    @inventoryModal.setHero(e.hero) if window.currentModal is @inventoryModal

  onHeroesModalConfirmClicked: (e) ->
    @options.parent.openModalView(@inventoryModal)
    @inventoryModal.render()
    @inventoryModal.didReappear()
    @inventoryModal.onShown()
    @inventoryModal.setHero(e.hero) if e.hero
    window.tracker?.trackEvent 'Choose Inventory', category: 'Play Level', ['Google Analytics']

  onChooseHeroClicked: ->
    @options.parent.openModalView(@heroesModal)
    @heroesModal.render()
    @heroesModal.didReappear()
    @inventoryModal.endHighlight()
    window.tracker?.trackEvent 'Change Hero', category: 'Play Level', ['Google Analytics']

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
