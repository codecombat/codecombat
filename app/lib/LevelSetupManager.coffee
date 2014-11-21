CocoClass = require 'lib/CocoClass'
PlayHeroesModal = require 'views/play/modal/PlayHeroesModal'
InventoryModal = require 'views/game-menu/InventoryModal'
LevelSession = require 'models/LevelSession'
SuperModel = require 'models/SuperModel'

module.exports = class LevelSetupManager extends CocoClass

  constructor: (@options) ->
    super()
    @supermodel = @options.supermodel ? new SuperModel()
    @session = @options.session
    if @session
      @fillSessionWithDefaults()
    else
      @loadSession()
    @loadModals()

  loadSession: ->
    url = "/db/level/#{@options.levelID}/session"
    #url += "?team=#{@team}" if @options.team  # TODO: figure out how to get the teams for multiplayer PVP hero style
    @session = new LevelSession().setURL url
    onSessionSync = ->
      @session.url = -> '/db/level.session/' + @id
      @fillSessionWithDefaults()
    @listenToOnce @session, 'sync', onSessionSync
    @session = @supermodel.loadModel(@session, 'level_session').model
    if @session.loaded
      onSessionSync.call @

  fillSessionWithDefaults: ->
    heroConfig = _.merge {}, me.get('heroConfig'), @session.get('heroConfig')
    @session.set('heroConfig', heroConfig)

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

  open: ->
    firstModal = if @options.hadEverChosenHero then @inventoryModal else @heroesModal
    @options.parent.openModalView(firstModal)
    #    @inventoryModal.onShown() # replace?
    Backbone.Mediator.publish 'audio-player:play-sound', trigger: 'game-menu-open', volume: 1


  #- Modal events

  onceHeroLoaded: (e) ->
    @inventoryModal.setHero(e.hero)

  onHeroesModalConfirmClicked: (e) ->
    @options.parent.openModalView(@inventoryModal)
    @inventoryModal.render()
    @inventoryModal.didReappear()
    @inventoryModal.onShown()
    @inventoryModal.setHero(e.hero)
    window.tracker?.trackEvent 'Play Level Modal', Action: 'Choose Inventory', ['Google Analytics']

  onChooseHeroClicked: ->
    @options.parent.openModalView(@heroesModal)
    @heroesModal.render()
    @heroesModal.didReappear()
    @inventoryModal.endHighlight()
    window.tracker?.trackEvent 'Play Level Modal', Action: 'Choose Hero', ['Google Analytics']

  onInventoryModalPlayClicked: ->
    @navigatingToPlay = true
    PlayLevelView = require 'views/play/level/PlayLevelView'
    LadderView = require 'views/play/ladder/LadderView'
    viewClass = if @options.levelPath is 'ladder' then LadderView else PlayLevelView
    Backbone.Mediator.publish 'router:navigate', {
      route: "/play/#{@options.levelPath || 'level'}/#{@options.levelID}"
      viewClass: viewClass
      viewArgs: [{supermodel: @supermodel}, @options.levelID]
    }

  destroy: ->
    @heroesModalDestroy.call @heroesModal unless @heroesModal.destroyed
    @inventoryModalDestroy.call @inventoryModal unless @inventoryModal.destroyed
    super()
