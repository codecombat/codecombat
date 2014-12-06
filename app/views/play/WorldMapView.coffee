RootView = require 'views/core/RootView'
template = require 'templates/play/world-map-view'
LevelSession = require 'models/LevelSession'
EarnedAchievement = require 'models/EarnedAchievement'
CocoCollection = require 'collections/CocoCollection'
AudioPlayer = require 'lib/AudioPlayer'
LevelSetupManager = require 'lib/LevelSetupManager'
ThangType = require 'models/ThangType'
MusicPlayer = require 'lib/surface/MusicPlayer'
storage = require 'core/storage'
AuthModal = require 'views/core/AuthModal'
SubscribeModal = require 'views/play/modal/SubscribeModal'

trackedHourOfCode = false

class LevelSessionsCollection extends CocoCollection
  url: ''
  model: LevelSession

  constructor: (model) ->
    super()
    @url = "/db/user/#{me.id}/level.sessions?project=state.complete,levelID"

module.exports = class WorldMapView extends RootView
  id: 'world-map-view'
  template: template

  subscriptions:
    'subscribe-modal:subscribed': 'onSubscribed'

  events:
    'click .map-background': 'onClickMap'
    'click .level a': 'onClickLevel'
    'click .level-info-container .start-level': 'onClickStartLevel'
    'mouseenter .level a': 'onMouseEnterLevel'
    'mouseleave .level a': 'onMouseLeaveLevel'
    'mousemove .map': 'onMouseMoveMap'
    'click #volume-button': 'onToggleVolume'

  constructor: (options, @terrain) ->
    if options and application.isIPAdApp  # TODO: later only clear the SuperModel if it has received a memory warning (not in app store yet)
      options.supermodel = null
    @terrain ?= 'dungeon' # or 'forest'
    super options
    @nextLevel = @getQueryVariable 'next'
    @levelStatusMap = {}
    @levelPlayCountMap = {}
    @sessions = @supermodel.loadCollection(new LevelSessionsCollection(), 'your_sessions', null, 0).model

    # Temporary attempt to make sure all earned rewards are accounted for. Figure out a better solution...
    @earnedAchievements = new CocoCollection([], {url: '/db/earned_achievement', model:EarnedAchievement, project: ['earnedRewards']})
    @listenToOnce @earnedAchievements, 'sync', ->
      earned = me.get('earned')
      addedSomething = false
      for m in @earnedAchievements.models
        continue unless loadedEarned = m.get('earnedRewards')
        for group in ['heroes', 'levels', 'items']
          continue unless loadedEarned[group]
          for reward in loadedEarned[group]
            if reward not in earned[group]
              console.warn 'Filling in a gap for reward', group, reward
              earned[group].push(reward)
              addedSomething = true
    @supermodel.loadCollection(@earnedAchievements, 'achievements')

    @listenToOnce @sessions, 'sync', @onSessionsLoaded
    @getLevelPlayCounts()
    $(window).on 'resize', @onWindowResize
    @playAmbientSound()
    @probablyCachedMusic = storage.load("loaded-menu-music")
    musicDelay = if @probablyCachedMusic then 1000 else 10000
    @playMusicTimeout = _.delay (=> @playMusic() unless @destroyed), musicDelay
    @hadEverChosenHero = me.get('heroConfig')?.thangType
    @listenTo me, 'change:purchased', -> @renderSelectors('#gems-count')
    @listenTo me, 'change:spent', -> @renderSelectors('#gems-count')
    window.tracker?.trackEvent 'Loaded World Map', category: 'World Map', ['Google Analytics']

    # If it's a new player who didn't appear to come from Hour of Code, we register her here without setting the hourOfCode property.
    elapsed = (new Date() - new Date(me.get('dateCreated')))
    if not trackedHourOfCode and not me.get('hourOfCode') and elapsed < 5 * 60 * 1000
      $('body').append($('<img src="http://code.org/api/hour/begin_codecombat.png" style="visibility: hidden;">'))
      trackedHourOfCode = true

    @requiresSubscription = @terrain isnt 'dungeon' and not me.isPremium()

  destroy: ->
    @setupManager?.destroy()
    $(window).off 'resize', @onWindowResize
    if ambientSound = @ambientSound
      # Doesn't seem to work; stops immediately.
      createjs.Tween.get(ambientSound).to({volume: 0.0}, 1500).call -> ambientSound.stop()
    @musicPlayer?.destroy()
    clearTimeout @playMusicTimeout
    super()

  getLevelPlayCounts: ->
    return unless me.isAdmin()
    success = (levelPlayCounts) =>
      return if @destroyed
      for level in levelPlayCounts
        @levelPlayCountMap[level._id] = playtime: level.playtime, sessions: level.sessions
      @render() if @fullyRendered

    levelIDs = []
    for campaign in campaigns
      for level in campaign.levels
        levelIDs.push level.id
    levelPlayCountsRequest = @supermodel.addRequestResource 'play_counts', {
      url: '/db/level/-/play_counts'
      data: {ids: levelIDs}
      method: 'POST'
      success: success
    }, 0
    levelPlayCountsRequest.load()

  onLoaded: ->
    return if @fullyRendered
    @fullyRendered = true
    @render()
    @preloadTopHeroes() unless me.get('heroConfig')?.thangType

  onSubscribed: ->
    @requiresSubscription = false
    @render()

  getRenderData: (context={}) ->
    context = super(context)
    context.campaign = _.find campaigns, { id: @terrain }
    for level, index in context.campaign.levels
      level.x ?= 10 + 80 * Math.random()
      level.y ?= 10 + 80 * Math.random()
      level.locked = index > 0 and not me.ownsLevel level.original
      window.levelUnlocksNotWorking = true if level.locked and level.id is @nextLevel  # Temporary
      level.locked = false if window.levelUnlocksNotWorking  # Temporary; also possible in HeroVictoryModal
      level.locked = false if @levelStatusMap[level.id] in ['started', 'complete']
      level.locked = false if me.get('slug') is 'nick'
      level.disabled = false if @levelStatusMap[level.id] in ['started', 'complete']
      level.color = 'rgb(255, 80, 60)'
      if level.requiresSubscription
        level.color = 'rgb(80, 130, 200)'
    context.levelStatusMap = @levelStatusMap
    context.levelPlayCountMap = @levelPlayCountMap
    context.isIPadApp = application.isIPadApp
    context.mapType = _.string.slugify @terrain
    context.nextLevel = @nextLevel
    context.forestIsAvailable = @startedForestLevel or '541b67f71ccc8eaae19f3c62' in (me.get('earned')?.levels or [])
    context.requiresSubscription = @requiresSubscription
    context

  afterRender: ->
    super()
    @onWindowResize()
    unless application.isIPadApp
      _.defer => @$el?.find('.game-controls .btn').tooltip()  # Have to defer or i18n doesn't take effect.
      @$el.find('.level').tooltip().each ->
        return unless me.isAdmin()
        $(@).draggable().on 'dragstop', ->
          bg = $('.map-background')
          x = ($(@).offset().left - bg.offset().left + $(@).outerWidth() / 2) / bg.width()
          y = 1 - ($(@).offset().top - bg.offset().top + $(@).outerHeight() / 2) / bg.height()
          console.log "#{$(@).data('level-id')}\n    x: #{(100 * x).toFixed(2)}\n    y: #{(100 * y).toFixed(2)}\n"
    @$el.addClass _.string.slugify @terrain
    @updateVolume()
    unless window.currentModal or not @fullyRendered
      @highlightElement '.level.next', delay: 500, duration: 60000, rotation: 0, sides: ['top']
      if levelID = @$el.find('.level.next').data('level-id')
        @$levelInfo = @$el.find(".level-info-container[data-level-id=#{levelID}]").show()
        pos = @$el.find('.level.next').offset()
        @adjustLevelInfoPosition pageX: pos.left, pageY: pos.top
        @manuallyPositionedLevelInfoID = levelID

  afterInsert: ->
    super()
    return unless @getQueryVariable 'signup'
    return if me.get('email')
    @endHighlight()
    authModal = new AuthModal supermodel: @supermodel
    authModal.mode = 'signup'
    @openModalView authModal

  onSessionsLoaded: (e) ->
    forestLevels = (f.id for f in forest)
    for session in @sessions.models
      @levelStatusMap[session.get('levelID')] = if session.get('state')?.complete then 'complete' else 'started'
      @startedForestLevel = true if session.get('levelID') in forestLevels
    if @nextLevel and @levelStatusMap[@nextLevel] is 'complete'
      @nextLevel = null
    @render()

  onClickMap: (e) ->
    @$levelInfo?.hide()
    # Easy-ish way of figuring out coordinates for placing level dots.
    x = e.offsetX / @$el.find('.map-background').width()
    y = (1 - e.offsetY / @$el.find('.map-background').height())
    console.log "    x: #{(100 * x).toFixed(2)}\n    y: #{(100 * y).toFixed(2)}\n"

  onClickLevel: (e) ->
    e.preventDefault()
    e.stopPropagation()
    @$levelInfo?.hide()
    levelElement = $(e.target).parents('.level')
    levelID = levelElement.data('level-id')
    campaign = _.find campaigns, id: @terrain
    level = _.find campaign.levels, id: levelID
    if application.isIPadApp
      @$levelInfo = @$el.find(".level-info-container[data-level-id=#{levelID}]").show()
      @adjustLevelInfoPosition e
      @endHighlight()
    else
      if level.requiresSubscription and @requiresSubscription and not @levelStatusMap[level.id] and not level.adventurer
        modal = if me.get('anonymous') then AuthModal else SubscribeModal
        @openModalView new modal()
        if modal is SubscribeModal
          window.tracker?.trackEvent 'Show subscription modal', category: 'Subscription', label: 'map level clicked'
          window.tracker?.trackPageView "subscription/show-modal", ['Google Analytics']
      else if $(e.target).attr('disabled')
        Backbone.Mediator.publish 'router:navigate', route: '/contribute/adventurer'
        return
      else if $(e.target).parent().hasClass 'locked'
        return
      else
        @startLevel levelElement
        window.tracker?.trackEvent 'Clicked Level', category: 'World Map', levelID: levelID, ['Google Analytics']
        window.tracker?.trackPageView "world-map/clicked-level/#{levelID}", ['Google Analytics']

  onClickStartLevel: (e) ->
    levelElement = $(e.target).parents('.level-info-container')
    @startLevel levelElement
    window.tracker?.trackEvent 'Clicked Start Level', category: 'World Map', levelID: levelElement.data('level-id'), ['Google Analytics']
    window.tracker?.trackPageView "world-map/clicked-start-level/#{levelElement.data('level-id')}", ['Google Analytics']

  startLevel: (levelElement) ->
    @setupManager?.destroy()
    @setupManager = new LevelSetupManager supermodel: @supermodel, levelID: levelElement.data('level-id'), levelPath: levelElement.data('level-path'), levelName: levelElement.data('level-name'), hadEverChosenHero: @hadEverChosenHero, parent: @
    @setupManager.open()
    @$levelInfo?.hide()

  onMouseEnterLevel: (e) ->
    return if application.isIPadApp
    levelID = $(e.target).parents('.level').data('level-id')
    return if @manuallyPositionedLevelInfoID and levelID isnt @manuallyPositionedLevelInfoID
    @$levelInfo = @$el.find(".level-info-container[data-level-id=#{levelID}]").show()
    @adjustLevelInfoPosition e
    @endHighlight()
    @manuallyPositionedLevelInfoID = false

  onMouseLeaveLevel: (e) ->
    return if application.isIPadApp
    levelID = $(e.target).parents('.level').data('level-id')
    return if @manuallyPositionedLevelInfoID and levelID isnt @manuallyPositionedLevelInfoID
    @$el.find(".level-info-container[data-level-id='#{levelID}']").hide()
    @manuallyPositionedLevelInfoID = null
    @$levelInfo = null

  onMouseMoveMap: (e) ->
    return if application.isIPadApp
    @adjustLevelInfoPosition e unless @manuallyPositionedLevelInfoID

  adjustLevelInfoPosition: (e) ->
    return unless @$levelInfo
    @$map ?= @$el.find('.map')
    mapOffset = @$map.offset()
    mapX = e.pageX - mapOffset.left
    mapY = e.pageY - mapOffset.top
    margin = 20
    width = @$levelInfo.outerWidth()
    @$levelInfo.css('left', Math.min(Math.max(margin, mapX - width / 2), @$map.width() - width - margin))
    height = @$levelInfo.outerHeight()
    top = mapY - @$levelInfo.outerHeight() - 60
    if top < 20
      top = mapY + 60
    @$levelInfo.css('top', top)

  onWindowResize: (e) =>
    mapHeight = iPadHeight = 1536
    mapWidth = if @terrain is 'dungeon' then 2350 else 2500
    aspectRatio = mapWidth / mapHeight
    pageWidth = $(window).width()
    pageHeight = $(window).height()
    widthRatio = pageWidth / mapWidth
    heightRatio = pageHeight / mapHeight
    # Make sure we can see the whole map, fading to background in one dimension.
    if heightRatio <= widthRatio
      # Left and right margin
      resultingHeight = pageHeight
      resultingWidth = resultingHeight * aspectRatio
    else
      # Top and bottom margin
      resultingWidth = pageWidth
      resultingHeight = resultingWidth / aspectRatio
    resultingMarginX = (pageWidth - resultingWidth) / 2
    resultingMarginY = (pageHeight - resultingHeight) / 2
    @$el.find('.map').css(width: resultingWidth, height: resultingHeight, 'margin-left': resultingMarginX, 'margin-top': resultingMarginY)

  playAmbientSound: ->
    return if @ambientSound
    return unless file = {dungeon: 'ambient-dungeon', forest: 'ambient-map-grass'}[@terrain]
    src = "/file/interface/#{file}#{AudioPlayer.ext}"
    unless AudioPlayer.getStatus(src)?.loaded
      AudioPlayer.preloadSound src
      Backbone.Mediator.subscribeOnce 'audio-player:loaded', @playAmbientSound, @
      return
    @ambientSound = createjs.Sound.play src, loop: -1, volume: 0.1
    createjs.Tween.get(@ambientSound).to({volume: 1.0}, 1000)

  playMusic: ->
    @musicPlayer = new MusicPlayer()
    musicFile = '/music/music-menu'
    Backbone.Mediator.publish 'music-player:play-music', play: true, file: musicFile
    storage.save("loaded-menu-music", true) unless @probablyCachedMusic

  preloadTopHeroes: ->
    for heroID in ['captain', 'knight']
      url = "/db/thang.type/#{ThangType.heroes[heroID]}/version"
      continue if @supermodel.getModel url
      fullHero = new ThangType()
      fullHero.setURL url
      @supermodel.loadModel fullHero, 'thang'

  updateVolume: (volume) ->
    volume ?= me.get('volume') ? 1.0
    classes = ['vol-off', 'vol-down', 'vol-up']
    button = $('#volume-button', @$el)
    button.toggleClass 'vol-off', volume <= 0.0
    button.toggleClass 'vol-down', 0.0 < volume < 1.0
    button.toggleClass 'vol-up', volume >= 1.0
    createjs.Sound.setVolume(if volume is 1 then 0.6 else volume)  # Quieter for now until individual sound FX controls work again.
    if volume isnt me.get 'volume'
      me.set 'volume', volume
      me.patch()

  onToggleVolume: (e) ->
    button = $(e.target).closest('#volume-button')
    classes = ['vol-off', 'vol-down', 'vol-up']
    volumes = [0, 0.4, 1.0]
    for oldClass, i in classes
      if button.hasClass oldClass
        newI = (i + 1) % classes.length
        break
      else if i is classes.length - 1  # no oldClass
        newI = 2
    @updateVolume volumes[newI]


dungeon = [
  {
    name: 'Dungeons of Kithgard'
    type: 'hero'
    id: 'dungeons-of-kithgard'
    original: '528110f30268d018e3000001'
    description: 'Grab the gem, but touch nothing else. Start here.'
    x: 14
    y: 15.5
    nextLevels:
      continue: 'gems-in-the-deep'
      skip_ahead: 'shadow-guard'
  }
  {
    name: 'Gems in the Deep'
    type: 'hero'
    id: 'gems-in-the-deep'
    original: '54173c90844506ae0195a0b4'
    description: 'Quickly collect the gems; you will need them.'
    x: 29
    y: 12
    nextLevels:
      continue: 'shadow-guard'
      skip_ahead: 'forgetful-gemsmith'
  }
  {
    name: 'Shadow Guard'
    type: 'hero'
    id: 'shadow-guard'
    original: '54174347844506ae0195a0b8'
    description: 'Evade the Kithgard minion.'
    x: 40.54
    y: 11.03
    nextLevels:
      more_practice: 'kounter-kithwise'
      continue: 'forgetful-gemsmith'
  }
  {
    name: 'Kounter Kithwise'
    type: 'hero'
    id: 'kounter-kithwise'
    original: '54527a6257e83800009730c7'
    description: 'Practice your evasion skills with more guards.'
    x: 35.37
    y: 20.61
    nextLevels:
      continue: 'crawlways-of-kithgard'
    practice: true
    requiresSubscription: true
  }
  {
    name: 'Crawlways of Kithgard'
    type: 'hero'
    id: 'crawlways-of-kithgard'
    original: '545287ef57e83800009730d5'
    description: 'Dart in and grab the gem–at the right moment.'
    x: 36.48
    y: 29.03
    nextLevels:
      continue: 'forgetful-gemsmith'
    practice: true
    requiresSubscription: true
  }
  {
    name: 'Forgetful Gemsmith'
    type: 'hero'
    id: 'forgetful-gemsmith'
    original: '544a98f62d002f0000fe331a'
    description: 'Grab even more gems as you practice moving.'
    x: 54.98
    y: 10.53
    nextLevels:
      continue: 'true-names'
  }
  {
    name: 'True Names'
    type: 'hero'
    id: 'true-names'
    original: '541875da4c16460000ab990f'
    description: 'Learn an enemy\'s true name to defeat it.'
    x: 68.44
    y: 10.70
    nextLevels:
      more_practice: 'favorable-odds'
      continue: 'the-raised-sword'
  }
  {
    name: 'Favorable Odds'
    type: 'hero'
    id: 'favorable-odds'
    original: '5452972f57e83800009730de'
    description: 'Test out your battle skills by defeating more munchkins.'
    x: 88.25
    y: 14.92
    nextLevels:
      continue: 'the-raised-sword'
    practice: true
    requiresSubscription: true
  }
  {
    name: 'The Raised Sword'
    type: 'hero'
    id: 'the-raised-sword'
    original: '5418aec24c16460000ab9aa6'
    description: 'Learn to equip yourself for combat.'
    x: 81.51
    y: 17.92
    nextLevels:
      continue: 'haunted-kithmaze'
  }
  {
    name: 'Haunted Kithmaze'
    type: 'hero'
    id: 'haunted-kithmaze'
    original: '545a5914d820eb0000f6dc0a'
    description: 'The builders of Kithgard constructed many mazes to confuse travelers.'
    x: 78
    y: 29
    nextLevels:
      more_practice: 'descending-further'
      continue: 'the-second-kithmaze'
  }
  {
    name: 'Riddling Kithmaze'
    type: 'hero'
    id: 'riddling-kithmaze'
    original: '5418b9d64c16460000ab9ab4'
    description: 'If at first you go astray, change your loop to find the way.'
    x: 69.97
    y: 28.03
    nextLevels:
      more_practice: 'descending-further'
      continue: 'the-second-kithmaze'
    practice: true
    requiresSubscription: true
  }
  {
    name: 'Descending Further'
    type: 'hero'
    id: 'descending-further'
    original: '5452a84d57e83800009730e4'
    description: 'Another day, another maze.'
    x: 61.68
    y: 22.80
    nextLevels:
      continue: 'the-second-kithmaze'
    practice: true
    requiresSubscription: true
  }
  {
    name: 'The Second Kithmaze'
    type: 'hero'
    id: 'the-second-kithmaze'
    original: '5418cf256bae62f707c7e1c3'
    description: 'Many have tried, few have found their way through this maze.'
    x: 54.49
    y: 26.49
    nextLevels:
      continue: 'dread-door'
  }
  {
    name: 'Dread Door'
    type: 'hero'
    id: 'dread-door'
    original: '5418d40f4c16460000ab9ac2'
    description: 'Behind a dread door lies a chest full of riches.'
    x: 60.52
    y: 33.70
    nextLevels:
      continue: 'known-enemy'
  }
  {
    name: 'Known Enemy'
    type: 'hero'
    id: 'known-enemy'
    original: '5452adea57e83800009730ee'
    description: 'Begin to use variables in your battles.'
    x: 67
    y: 39
    nextLevels:
      continue: 'master-of-names'
  }
  {
    name: 'Master of Names'
    type: 'hero'
    id: 'master-of-names'
    original: '5452c3ce57e83800009730f7'
    description: 'Use your glasses to defend yourself from the Kithmen.'
    x: 75
    y: 46
    nextLevels:
      continue: 'lowly-kithmen'
  }
  {
    name: 'Lowly Kithmen'
    type: 'hero'
    id: 'lowly-kithmen'
    original: '541b24511ccc8eaae19f3c1f'
    description: 'Now that you can see them, they\'re everywhere!'
    x: 85
    y: 40
    nextLevels:
      continue: 'closing-the-distance'
  }
  {
    name: 'Closing the Distance'
    type: 'hero'
    id: 'closing-the-distance'
    original: '541b288e1ccc8eaae19f3c25'
    description: 'Kithmen are not the only ones to stand in your way.'
    x: 93
    y: 47
    nextLevels:
      more_practice: 'tactical-strike'
      continue: 'the-final-kithmaze'
  }
  {
    name: 'Tactical Strike'
    type: 'hero'
    id: 'tactical-strike'
    original: '5452cfa706a59e000067e4f5'
    description: 'They\'re, uh, coming right for us! Sneak up behind them.'
    x: 83.23
    y: 52.73
    nextLevels:
      continue: 'the-final-kithmaze'
    practice: true
    requiresSubscription: true
  }
  {
    name: 'The Final Kithmaze'
    type: 'hero'
    id: 'the-final-kithmaze'
    original: '541b434e1ccc8eaae19f3c33'
    description: 'To escape you must find your way through an Elder Kithman\'s maze.'
    x: 86.95
    y: 64.70
    nextLevels:
      more_practice: 'the-gauntlet'
      continue: 'kithgard-gates'
  }
  {
    name: 'The Gauntlet'
    type: 'hero'
    id: 'the-gauntlet'
    original: '5452d8b906a59e000067e4fa'
    description: 'Rush for the stairs, battling foes at every turn.'
    x: 76.50
    y: 72.69
    nextLevels:
      continue: 'kithgard-gates'
    practice: true
    requiresSubscription: true
  }
  {
    name: 'Kithgard Gates'
    type: 'hero'
    id: 'kithgard-gates'
    original: '541c9a30c6362edfb0f34479'
    description: 'Escape the Kithgard dungeons and don\'t let the guardians get you.'
    x: 89
    y: 82
    nextLevels:
      continue: 'defense-of-plainswood'
  }
  {
    name: 'Cavern Survival'
    type: 'hero-ladder'
    id: 'cavern-survival'
    original: '544437e0645c0c0000c3291d'
    description: 'Stay alive longer than your opponent amidst hordes of ogres!'
    x: 17.54
    y: 78.39
  }
]

forest = [
  {
    name: 'Defense of Plainswood'
    type: 'hero'
    id: 'defense-of-plainswood'
    original: '541b67f71ccc8eaae19f3c62'
    description: 'Protect the peasants from the pursuing ogres.'
    nextLevels:
      continue: 'winding-trail'
    x: 18
    y: 37
  }
  {
    name: 'Winding Trail'
    type: 'hero'
    id: 'winding-trail'
    original: '5446cb40ce01c23e05ecf027'
    description: 'Stay alive and navigate through the forest.'
    nextLevels:
      continue: 'endangered-burl'
    x: 24
    y: 35
  }
  {
    name: 'Endangered Burl'
    type: 'hero'
    id: 'endangered-burl'
    original: '546e97033f1c1c1be898402b'
    description: 'Hunt ogres in the woods, but watch out for lumbering beasts.'
    nextLevels:
      continue: 'village-guard'
    x: 29
    y: 35
  }
  {
    name: 'Village Guard'
    type: 'hero'
    id: 'village-guard'
    original: '546e91b8a4b7840000ee92dc'
    description: 'Defend a village from marauding munchkin mayhem.'
    nextLevels:
      continue: 'thornbush-farm'
    x: 33
    y: 37
    practice: true
    requiresSubscription: true
  }
  {
    name: 'Thornbush Farm'
    type: 'hero'
    id: 'thornbush-farm'
    original: '5447030525cce60000745e2a'
    description: 'Determine refugee peasant from ogre when defending the farm.'
    nextLevels:
      continue: 'back-to-back'
    x: 37
    y: 40
  }
  {
    name: 'Back to Back'
    type: 'hero'
    id: 'back-to-back'
    original: '5448330517d7283e051f9b9e'
    description: 'Patrol the village entrances, but stay defensive.'
    nextLevels:
      continue: 'ogre-encampment'
    x: 39
    y: 47.5
  }
  {
    name: 'Ogre Encampment'
    type: 'hero'
    id: 'ogre-encampment'
    original: '5456b3c8d5ada30000525605'
    description: 'Recover stolen treasure from an ogre encampment.'
    nextLevels:
      continue: 'woodland-cleaver'
    x: 39
    y: 55
   }
  {
    name: 'Woodland Cleaver'
    type: 'hero'
    id: 'woodland-cleaver'
    original: '5456bb8dd5ada30000525613'
    description: 'Use your new cleave ability to fend off munchkins.'
    nextLevels:
      continue: 'shield-rush'
    x: 39.5
    y: 61
   }
  {
    name: 'Shield Rush'
    type: 'hero'
    id: 'shield-rush'
    original: '5459570bb4461871053292f5'
    description: 'Combine cleave and shield to endure an ogre onslaught.'
    nextLevels:
      continue: 'peasant-protection'
    x: 42
    y: 68
  }

  # Warrior branch
  {
    name: 'Peasant Protection'
    type: 'hero'
    id: 'peasant-protection'
    original: '545ec477e7f60fd6c55760e9'
    description: 'Stay close to Victor.'
    nextLevels:
      continue: 'munchkin-swarm'
    x: 44.5
    y: 75.5
  }
  {
    name: 'Munchkin Swarm'
    type: 'hero'
    id: 'munchkin-swarm'
    original: '545edba9e7f60fd6c5576133'
    description: 'Loot a gigantic chest while surrounded by a swarm of ogre munchkins.'
    nextLevels:
      continue: 'coinucopia'
    x: 49
    y: 81
  }

  # Ranger branch
  {
    name: 'Munchkin Harvest'
    type: 'hero'
    id: 'munchkin-harvest'
    original: '5470001860f6cc376131525d'
    description: 'Join forces with a new hero: Amara Arrowhead.'
    nextLevels:
      continue: 'swift-dagger'
    x: 38
    y: 72
    requiresSubscription: true
  }
  {
    name: 'Swift Dagger'
    type: 'hero'
    id: 'swift-dagger'
    original: '54701f7860f6cc37613152a1'
    description: 'Deal damage from a distance with your new hero.'
    nextLevels:
      continue: 'shrapnel'
    x: 33
    y: 72
    requiresSubscription: true
  }
  {
    name: 'Shrapnel'
    type: 'hero'
    id: 'shrapnel'
    original: '5470291c60f6cc37613152d1'
    description: 'Explore the explosive arts.'
    nextLevels:
      continue: 'coinucopia'
    x: 28
    y: 73
    requiresSubscription: true
  }

  # Wizard branch
  {
    name: 'Arcane Ally'
    type: 'hero'
    id: 'arcane-ally'
    original: '5470b98ceb739dbc9d2402c7'
    description: 'Stand your ground against large ogres with a new hero: Ms. Hushbaum.'
    nextLevels:
      continue: 'touch-of-death'
    x: 47
    y: 71
    adventurer: true
    requiresSubscription: true
  }
  {
    name: 'Touch of Death'
    type: 'hero'
    id: 'touch-of-death'
    original: '5470ca33eb739dbc9d2402ee'
    description: 'Learn your first spell to siphon life from your foes.'
    nextLevels:
      continue: 'bonemender'
    x: 52
    y: 70
    adventurer: true
    requiresSubscription: true
  }
  {
    name: 'Bonemender'
    type: 'hero'
    id: 'bonemender'
    original: '5470d013eb739dbc9d240323'
    description: 'Cast regeneration on allied soldiers to withstand a siege.'
    nextLevels:
      continue: 'coinucopia'
    x: 58
    y: 67
    adventurer: true
    requiresSubscription: true
  }

  {
    name: 'Coinucopia'
    type: 'hero'
    id: 'coinucopia'
    original: '545bb1181e649a4495f887df'
    description: 'Start playing in real-time with input flags as you collect gold coins!'
    nextLevels:
      continue: 'copper-meadows'
    x: 56
    y: 82
  }
  {
    name: 'Copper Meadows'
    type: 'hero'
    id: 'copper-meadows'
    original: '5462491c688f333d05d8af38'
    description: 'This level exercises: if/else, object members, variables, flag placement, and collection.'
    nextLevels:
      continue: 'drop-the-flag'
    x: 60
    y: 86
  }
  {
    name: 'Drop the Flag'
    type: 'hero'
    id: 'drop-the-flag'
    original: '54626472f3c64b7b0598590c'
    description: 'This level exercises: flag position, object members.'
    nextLevels:
      continue: 'deadly-pursuit'
    x: 65.5
    y: 91
  }
  {
    name: 'Deadly Pursuit'
    type: 'hero'
    id: 'deadly-pursuit'
    original: '54626f270cacde3f055434ac'
    description: 'This level exercises: if/else, flag placement and timing, item collection.'
    nextLevels:
      continue: 'rich-forager'
    x: 74.5
    y: 92
    requiresSubscription: true
  }
  {
    name: 'Rich Forager'
    type: 'hero'
    id: 'rich-forager'
    original: '546283ddfdd66af405fa8209'
    description: 'This level exercises: if/else if, collection, combat.'
    nextLevels:
      continue: 'multiplayer-treasure-grove'
    x: 80
    y: 88
    adventurer: true
    requiresSubscription: true
  }
  {
    name: 'Siege of Stonehold'
    type: 'hero'
    id: 'siege-of-stonehold'
    original: '54712072eb739dbc9d24034b'
    description: 'Unlock the desert world, if you are strong enough to win this epic battle!'
    #nextLevels:
    #  continue: ''
    disabled: not me.isAdmin()
    x: 85.5
    y: 83.5
    adventurer: true
    requiresSubscription: true
  }
  {
    name: 'Multiplayer Treasure Grove'
    type: 'hero-ladder'
    id: 'multiplayer-treasure-grove'
    original: '5469643c37600b40e0e09c5b'
    description: 'Mix collection, flags, and combat in this multiplayer coin-gathering arena.'
    x: 56.5
    y: 20
    adventurer: true
  }
  {
    name: 'Dueling Grounds'
    type: 'hero-ladder'
    id: 'dueling-grounds'
    original: '5442ba0e1e835500007eb1c7'
    description: 'Battle head-to-head against another hero in this basic beginner combat arena.'
    x: 83
    y: 23
    adventurer: true
  }
]

WorldMapView.campaigns = campaigns = [
  #{id: 'beginner', name: 'Beginner Campaign', description: '... in which you learn the wizardry of programming.', levels: tutorials, color: "rgb(255, 80, 60)"}
  #{id: 'multiplayer', name: 'Multiplayer Arenas', description: '... in which you code head-to-head against other players.', levels: arenas, color: "rgb(80, 5, 60)"}
  #{id: 'dev', name: 'Random Harder Levels', description: '... in which you learn the interface while doing something a little harder.', levels: experienced, color: "rgb(80, 60, 255)"}
  #{id: 'classic_algorithms' ,name: 'Classic Algorithms', description: '... in which you learn the most popular algorithms in Computer Science.', levels: classicAlgorithms, color: "rgb(110, 80, 120)"}
  #{id: 'player_created', name: 'Player-Created', description: '... in which you battle against the creativity of your fellow <a href=\"/contribute#artisan\">Artisan Wizards</a>.', levels: playerCreated, color: "rgb(160, 160, 180)"}
  {id: 'dungeon', name: 'Dungeon Campaign', levels: dungeon }
  {id: 'forest', name: 'Forest Campaign', levels: forest }
]
