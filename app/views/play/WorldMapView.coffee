RootView = require 'views/kinds/RootView'
template = require 'templates/play/world-map-view'
LevelSession = require 'models/LevelSession'
CocoCollection = require 'collections/CocoCollection'
AudioPlayer = require 'lib/AudioPlayer'
PlayLevelModal = require 'views/play/modal/PlayLevelModal'
ThangType = require 'models/ThangType'
MusicPlayer = require 'lib/surface/MusicPlayer'
storage = require 'lib/storage'
AuthModal = require 'views/modal/AuthModal'

class LevelSessionsCollection extends CocoCollection
  url: ''
  model: LevelSession

  constructor: (model) ->
    super()
    @url = "/db/user/#{me.id}/level.sessions?project=state.complete,levelID"

module.exports = class WorldMapView extends RootView
  id: 'world-map-view'
  template: template

  events:
    'click .map-background': 'onClickMap'
    'click .level a': 'onClickLevel'
    'click .level-info-container .start-level': 'onClickStartLevel'
    'mouseenter .level a': 'onMouseEnterLevel'
    'mouseleave .level a': 'onMouseLeaveLevel'
    'mousemove .map': 'onMouseMoveMap'
    'click #volume-button': 'onToggleVolume'

  constructor: (options, @terrain) ->
    @terrain ?= 'dungeon' # or 'forest'
    super options
    @nextLevel = @getQueryVariable 'next'
    @levelStatusMap = {}
    @levelPlayCountMap = {}
    @sessions = @supermodel.loadCollection(new LevelSessionsCollection(), 'your_sessions', null, 0).model
    @listenToOnce @sessions, 'sync', @onSessionsLoaded
    @getLevelPlayCounts()
    $(window).on 'resize', @onWindowResize
    @playAmbientSound()
    @probablyCachedMusic = storage.load("loaded-menu-music-#{@terrain}")
    musicDelay = if @probablyCachedMusic then 1000 else 10000
    @playMusicTimeout = _.delay (=> @playMusic() unless @destroyed), musicDelay
    @preloadTopHeroes()
    @hadEverChosenHero = me.get('heroConfig')?.thangType
    window.tracker?.trackEvent 'World Map', Action: 'Loaded'

  destroy: ->
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
      @render() if @supermodel.finished()

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

  getRenderData: (context={}) ->
    context = super(context)
    context.campaign = _.find campaigns, { id: @terrain }
    for level, index in context.campaign.levels
      level.x ?= 10 + 80 * Math.random()
      level.y ?= 10 + 80 * Math.random()
      level.locked = index > 0 and not me.earnedLevel level.original
      window.levelUnlocksNotWorking = true if level.locked and level.id is @nextLevel  # Temporary
      level.locked = false if window.levelUnlocksNotWorking  # Temporary; also possible in HeroVictoryModal
      level.color = 'rgb(255, 80, 60)'
      if level.practice
        level.color = 'rgb(80, 130, 200)' unless me.getBranchingGroup() is 'all-practice'
        level.hidden = true if me.getBranchingGroup() is 'no-practice'
    context.levelStatusMap = @levelStatusMap
    context.levelPlayCountMap = @levelPlayCountMap
    context.isIPadApp = application.isIPadApp
    context.mapType = _.string.slugify @terrain
    context.nextLevel = @nextLevel
    context

  afterRender: ->
    super()
    @onWindowResize()
    unless application.isIPadApp
      _.defer => @$el?.find('.game-controls .btn').tooltip()  # Have to defer or i18n doesn't take effect.
      @$el.find('.level').tooltip()
    @$el.addClass _.string.slugify @terrain
    @updateVolume()
    @highlightElement '.level.next', delay: 500, duration: 60000, rotation: 0, sides: ['top'] unless window.currentModal

  afterInsert: ->
    super()
    return unless @getQueryVariable 'signup'
    return if me.get('email')
    @endHighlight()
    authModal = new AuthModal supermodel: @supermodel
    authModal.mode = 'signup'
    @openModalView authModal

  onSessionsLoaded: (e) ->
    for session in @sessions.models
      @levelStatusMap[session.get('levelID')] = if session.get('state')?.complete then 'complete' else 'started'
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
    return if $(e.target).attr('disabled') or $(e.target).parent().hasClass 'locked'
    if application.isIPadApp
      levelID = $(e.target).parents('.level').data('level-id')
      @$levelInfo = @$el.find(".level-info-container[data-level-id=#{levelID}]").show()
      @adjustLevelInfoPosition e
      @endHighlight()
    else
      levelElement = $(e.target).parents('.level')
      levelID = levelElement.data('level-id')
      @startLevel levelElement
    window.tracker?.trackEvent 'World Map', Action: 'Play Level', levelID: levelID

  onClickStartLevel: (e) ->
    @startLevel $(e.target).parents('.level-info-container')

  startLevel: (levelElement) ->
    playLevelModal = new PlayLevelModal supermodel: @supermodel, levelID: levelElement.data('level-id'), levelPath: levelElement.data('level-path'), levelName: levelElement.data('level-name'), hadEverChosenHero: @hadEverChosenHero
    @openModalView playLevelModal
    @$levelInfo?.hide()

  onMouseEnterLevel: (e) ->
    return if application.isIPadApp
    levelID = $(e.target).parents('.level').data('level-id')
    @$levelInfo = @$el.find(".level-info-container[data-level-id=#{levelID}]").show()
    @adjustLevelInfoPosition e
    @endHighlight()

  onMouseLeaveLevel: (e) ->
    return if application.isIPadApp
    levelID = $(e.target).parents('.level').data('level-id')
    @$el.find(".level-info-container[data-level-id='#{levelID}']").hide()

  onMouseMoveMap: (e) ->
    return if application.isIPadApp
    @adjustLevelInfoPosition e

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
    iPadWidth = 2048
    aspectRatio = mapWidth / mapHeight
    iPadAspectRatio = iPadWidth / iPadHeight
    pageWidth = $(window).width()
    pageHeight = $(window).height()
    widthRatio = pageWidth / mapWidth
    heightRatio = pageHeight / mapHeight
    iPadWidthRatio = pageWidth / iPadWidth
    if @terrain is 'dungeon'
      # Make sure we can see almost the whole map, fading to background in one dimension.
      if heightRatio <= iPadWidthRatio
        # Full width, full height, left and right margin
        resultingHeight = pageHeight
        resultingWidth = resultingHeight * aspectRatio
      else if iPadWidthRatio < heightRatio * (iPadAspectRatio / aspectRatio)
        # Cropped width, full height, left and right margin
        resultingWidth = pageWidth
        resultingHeight = resultingWidth / aspectRatio
      else
        # Cropped width, full height, top and bottom margin
        resultingWidth = pageWidth * aspectRatio / iPadAspectRatio
        resultingHeight = resultingWidth / aspectRatio
    else
      # Scale it in either dimension so that we're always full on one of the dimensions.
      if heightRatio > widthRatio
        resultingHeight = pageHeight
        resultingWidth = resultingHeight * aspectRatio
      else
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
    musicFile = {dungeon: '/music/music-menu-dungeon', forest: '/music/music-menu-grass'}[@terrain]
    Backbone.Mediator.publish 'music-player:play-music', play: true, file: musicFile
    storage.save("loaded-menu-music-#{@terrain}", true) unless @probablyCachedMusic

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


tutorials = [
  {
    name: 'Rescue Mission'
    difficulty: 1
    id: 'rescue-mission'
    image: '/file/db/level/52740644904ac0411700067c/rescue_mission_icon.png'
    description: 'Tharin has been captured! Start here.'
    x: 17.23
    y: 36.94
  }
  {
    name: 'Grab the Mushroom'
    difficulty: 1
    id: 'grab-the-mushroom'
    image: '/file/db/level/529662dfe0df8f0000000007/grab_the_mushroom_icon.png'
    description: 'Grab a powerup and smash a big ogre.'
    x: 22.6
    y: 35.1
  }
  {
    name: 'Drink Me'
    difficulty: 1
    id: 'drink-me'
    image: '/file/db/level/525dc5589a0765e496000006/drink_me_icon.png'
    description: 'Drink up and slay two munchkins.'
    x: 27.74
    y: 35.17
  }
  {
    name: 'Taunt the Guards'
    difficulty: 1
    id: 'taunt-the-guards'
    image: '/file/db/level/5276c9bdcf83207a2801ff8f/taunt_icon.png'
    description: 'Tharin, if clever, can escape with Phoebe.'
    x: 32.7
    y: 36.7
  }
  {
    name: 'It\'s a Trap'
    difficulty: 1
    id: 'its-a-trap'
    image: '/file/db/level/528aea2d7f37fc4e0700016b/its_a_trap_icon.png'
    description: 'Organize a dungeon ambush with archers.'
    x: 37.6
    y: 40.0
  }
  {
    name: 'Break the Prison'
    difficulty: 1
    id: 'break-the-prison'
    image: '/file/db/level/5275272c69abdcb12401216e/break_the_prison_icon.png'
    description: 'More comrades are imprisoned!'
    x: 44.1
    y: 39.5
  }
  {
    name: 'Taunt'
    difficulty: 1
    id: 'taunt'
    image: '/file/db/level/525f150306e1ab0962000018/taunt_icon.png'
    description: 'Taunt the ogre to claim victory.'
    x: 38.5
    y: 44.1
  }
  {
    name: 'Cowardly Taunt'
    difficulty: 1
    id: 'cowardly-taunt'
    image: '/file/db/level/525abfd9b12777d78e000009/cowardly_taunt_icon.png'
    description: 'Lure infuriated ogres to their doom.'
    x: 39.2
    y: 50.1
  }
  {
    name: 'Commanding Followers'
    difficulty: 1
    id: 'commanding-followers'
    image: '/file/db/level/525ef8ef06e1ab0962000003/commanding_followers_icon.png'
    description: 'Lead allied soldiers into battle.'
    x: 39.1
    y: 54.7
  }
  {
    name: 'Mobile Artillery'
    difficulty: 1
    id: 'mobile-artillery'
    image: '/file/db/level/525085419851b83f4b000001/mobile_artillery_icon.png'
    description: 'Blow ogres up!'
    x: 39.5
    y: 60.2
  }
]

experienced = [
  {
    name: 'Hunter Triplets'
    difficulty: 2
    id: 'hunter-triplets'
    image: '/file/db/level/526711d9add4f8965f000002/hunter_triplets_icon.png'
    description: 'Three soldiers go ogre hunting.'
    x: 51.76
    y: 35.5
  }
  {
    name: 'Emphasis on Aim'
    difficulty: 2
    id: 'emphasis-on-aim'
    image: '/file/db/level/525f384d96cd77000000000f/munchkin_masher_icon.png'
    description: 'Choose your targets carefully.'
    x: 61.47
    y: 33.46
   }
  {
    name: 'Zone of Danger'
    difficulty: 3
    id: 'zone-of-danger'
    image: '/file/db/level/526ae95c1e5cd30000000008/zone_of_danger_icon.png'
    description: 'Target the ogres swarming into arrow range.'
    x: 65.72
    y: 26.72
  }
  {
    name: 'Molotov Medic'
    difficulty: 2
    id: 'molotov-medic'
    image: '/file/db/level/52602ecb026e8481e7000001/generic_1.png'
    description: 'Tharin must play support in this dungeon battle.'
    x: 70.95
    y: 18.64
  }
  {
    name: 'Gridmancer'
    difficulty: 5
    id: 'gridmancer'
    image: '/file/db/level/52ae2460ef42c52f13000008/gridmancer_icon.png'
    description: 'Super algorithm challenge level!'
    x: 61.41
    y: 17.22
   }
]

arenas = [
  {
    name: 'Criss-Cross'
    difficulty: 5
    id: 'criss-cross'
    image: '/file/db/level/528aea2d7f37fc4e0700016b/its_a_trap_icon.png'
    description: 'Participate in a bidding war with opponents to reach the other side!'
    levelPath: 'ladder'
    x: 49.43
    y: 21.48
   }
  {
    name: 'Greed'
    difficulty: 4
    id: 'greed'
    image: '/file/db/level/526fd3043c637ece50001bb2/the_herd_icon.png'
    description: 'Liked Dungeon Arena and Gold Rush? Put them together in this economic arena!'
    levelPath: 'ladder'
    x: 45.00
    y: 23.34
   }
  {
    name: 'Dungeon Arena'
    difficulty: 3
    id: 'dungeon-arena'
    image: '/file/db/level/526ae95c1e5cd30000000008/zone_of_danger_icon.png'
    description: 'Play head-to-head against fellow Wizards in a dungeon melee!'
    levelPath: 'ladder'
    x: 36.82
    y: 23.17
  }
  {
    name: 'Gold Rush'
    difficulty: 3
    id: 'gold-rush'
    image: '/file/db/level/52602ecb026e8481e7000001/generic_1.png'
    description: 'Prove you are better at collecting gold than your opponent!'
    levelPath: 'ladder'
    x: 30.8
    y: 16.87
  }
  {
    name: 'Brawlwood'
    difficulty: 4
    id: 'brawlwood'
    image: '/file/db/level/525ef8ef06e1ab0962000003/commanding_followers_icon.png'
    description: 'Combat the armies of other Wizards in a strategic forest arena! (Fast computer required.)'
    levelPath: 'ladder'
    x: 41.93
    y: 12.79
  }
  {
    name: 'Sky Span (Testing)'
    difficulty: 3
    id: 'sky-span'
    image: '/file/db/level/526ae95c1e5cd30000000008/zone_of_danger_icon.png'
    description: 'Preview version of an upgraded Dungeon Arena. Help us with hero balance before release!'
    levelPath: 'ladder'
    x: 53.12
    y: 11.37
   }
]

classicAlgorithms = [
  {
    name: 'Bubble Sort Bootcamp Battle'
    difficulty: 3
    id: 'bubble-sort-bootcamp-battle'
    image: '/file/db/level/525ef8ef06e1ab0962000003/commanding_followers_icon.png'
    description: 'Write a bubble sort to organize your soldiers. - by Alexandru Caciulescu'
    x: 26.37
    y: 93.02
   }
  {
    name: 'Ogres of Hanoi'
    difficulty: 3
    id: 'ogres-of-hanoi'
    image: '/file/db/level/526fd3043c637ece50001bb2/the_herd_icon.png'
    description: 'Transfer a stack of ogres while preserving their honor. - by Alexandru Caciulescu'
    x: 32.39
    y: 92.67
  }
  {
    name: 'Danger! Minefield'
    difficulty: 3
    id: 'danger-minefield'
    image: '/file/db/level/526bda3fe79aefde2a003e36/mobile_artillery_icon.png'
    description: 'Learn how to find prime numbers while defusing mines! - by Alexandru Caciulescu'
    x: 38.07
    y: 92.76
  }
  {
    name: 'K-means++ Cluster Wars'
    difficulty: 4
    id: 'k-means-cluster-wars'
    image: '/file/db/level/525ef8ef06e1ab0962000003/commanding_followers_icon.png'
    description: 'Learn cluster analysis while leading armies into battle! - by Alexandru Caciulescu'
    x: 43.75
    y: 90.36
  }
  {
    name: 'Quicksort the Spiral'
    difficulty: 3
    id: 'quicksort-the-spiral'
    image: '/file/db/level/525ef8ef06e1ab0962000003/commanding_followers_icon.png'
    description: 'Learn Quicksort while sorting a spiral of ogres! - by Alexandru Caciulescu'
    x: 48.97
    y: 87.08
  }
  {
    name: 'Minimax Tic-Tac-Toe'
    difficulty: 4
    id: 'minimax-tic-tac-toe'
    image: '/file/db/level/525ef8ef06e1ab0962000003/commanding_followers_icon.png'
    description: 'Learn how to make a game AI with the Minimax algorithm. - by Alexandru Caciulescu'
    x: 55.96
    y: 82.73
  }
]

playerCreated = [
  {
    name: 'Extra Extrapolation'
    difficulty: 2
    id: 'extra-extrapolation'
    image: '/file/db/level/526bda3fe79aefde2a003e36/mobile_artillery_icon.png'
    description: 'Predict your target\'s position for deadly aim. - by Sootn'
    x: 42.67
    y: 67.98
  }
  {
    name: 'The Right Route'
    difficulty: 1
    id: 'the-right-route'
    image: '/file/db/level/526fd3043c637ece50001bb2/the_herd_icon.png'
    description: 'Strike at the weak point in an array of enemies. - by Aftermath'
    x: 47.38
    y: 70.55
  }
  {
    name: 'Sword Loop'
    difficulty: 2
    id: 'sword-loop'
    image: '/file/db/level/525dc5589a0765e496000006/drink_me_icon.png'
    description: 'Kill the ogres and save the peasants with for-loops. - by Prabh Simran Singh Baweja'
    x: 52.66
    y: 69.66
  }
  {
    name: 'Coin Mania'
    difficulty: 2
    id: 'coin-mania'
    image: '/file/db/level/529662dfe0df8f0000000007/grab_the_mushroom_icon.png'
    description: 'Learn while-loops to grab coins and potions. - by Prabh Simran Singh Baweja'
    x: 58.46
    y: 66.38
   }
  {
    name: 'Find the Spy'
    difficulty: 2
    id: 'find-the-spy'
    image: '/file/db/level/526ae95c1e5cd30000000008/zone_of_danger_icon.png'
    description: 'Identify the spies hidden among your soldiers - by Nathan Gossett'
    x: 63.11
    y: 62.74
   }
  {
    name: 'Harvest Time'
    difficulty: 2
    id: 'harvest-time'
    image: '/file/db/level/529662dfe0df8f0000000007/grab_the_mushroom_icon.png'
    description: 'Collect a hundred mushrooms in just five lines of code - by Nathan Gossett'
    x: 69.19
    y: 60.61
   }
  {
    name: 'Guide Everyone Home'
    difficulty: 2
    id: 'guide-everyone-home'
    image: '/file/db/level/52740644904ac0411700067c/rescue_mission_icon.png'
    description: 'Fetch the wizards teleporting into the area - by Nathan Gossett'
    x: 77.54
    y: 65.94
  }
  {
    name: "Let's go Fly a Kite"
    difficulty: 3
    id: 'lets-go-fly-a-kite'
    image: '/file/db/level/526711d9add4f8965f000002/hunter_triplets_icon.png'
    description: 'There is a horde of ogres marching on your village.  Stay out of reach and use your bow to take them out! - by Danny Whittaker'
    x: 84.29
    y: 61.23
  }
]

dungeon = [
  {
    name: 'Dungeons of Kithgard'
    type: 'hero'
    difficulty: 1
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
    difficulty: 1
    id: 'gems-in-the-deep'
    original: '54173c90844506ae0195a0b4'
    description: 'Quickly collect the gems; you will need them.'
    x: 29
    y: 12
    nextLevels:
      more_practice: 'forgetful-gemsmith'
      continue: 'shadow-guard'
      skip_ahead: 'true-names'
  }
  {
    name: 'Forgetful Gemsmith'
    type: 'hero'
    difficulty: 1
    id: 'forgetful-gemsmith'
    original: '544a98f62d002f0000fe331a'
    description: 'Grab even more gems as you practice moving.'
    x: 38
    y: 12
    nextLevels:
      continue: 'shadow-guard'
    practice: true
  }
  {
    name: 'Shadow Guard'
    type: 'hero'
    difficulty: 1
    id: 'shadow-guard'
    original: '54174347844506ae0195a0b8'
    description: 'Evade the Kithgard minion.'
    x: 50
    y: 11
    nextLevels:
      more_practice: 'kounter-kithwise'
      continue: 'true-names'
  }
  {
    name: 'Kounter Kithwise'
    type: 'hero'
    difficulty: 1
    id: 'kounter-kithwise'
    original: '54527a6257e83800009730c7'
    description: 'Practice your evasion skills with more guards.'
    x: 58
    y: 10
    nextLevels:
      more_practice: 'crawlways-of-kithgard'
      continue: 'true-names'
    practice: true
  }
  {
    name: 'Crawlways of Kithgard'
    type: 'hero'
    difficulty: 1
    id: 'crawlways-of-kithgard'
    original: '545287ef57e83800009730d5'
    description: 'Dart in and grab the gem–at the right moment.'
    x: 67
    y: 10
    nextLevels:
      continue: 'true-names'
    practice: true
  }
  {
    name: 'True Names'
    type: 'hero'
    difficulty: 1
    id: 'true-names'
    original: '541875da4c16460000ab990f'
    description: 'Learn an enemy\'s true name to defeat it.'
    x: 74
    y: 12
    nextLevels:
      more_practice: 'favorable-odds'
      continue: 'the-raised-sword'
  }
  {
    name: 'Favorable Odds'
    type: 'hero'
    difficulty: 1
    id: 'favorable-odds'
    original: '5452972f57e83800009730de'
    description: 'Test out your battle skills by defeating more munchkins.'
    x: 80.85
    y: 16
    nextLevels:
      continue: 'the-raised-sword'
    practice: true
  }
  {
    name: 'The Raised Sword'
    type: 'hero'
    difficulty: 1
    id: 'the-raised-sword'
    original: '5418aec24c16460000ab9aa6'
    description: 'Learn to equip yourself for combat.'
    x: 85
    y: 20
    nextLevels:
      continue: 'the-first-kithmaze'
  }
  {
    name: 'The First Kithmaze'
    type: 'hero'
    difficulty: 1
    id: 'the-first-kithmaze'
    original: '5418b9d64c16460000ab9ab4'
    description: 'The builders of Kithgard constructed many mazes to confuse travelers.'
    x: 78
    y: 29
    nextLevels:
      more_practice: 'descending-further'
      continue: 'the-second-kithmaze'
      skip_ahead: 'new-sight'
  }
  {
    name: 'Descending Further'
    type: 'hero'
    difficulty: 1
    id: 'descending-further'
    original: '5452a84d57e83800009730e4'
    description: 'Another day, another maze.'
    x: 70
    y: 28
    nextLevels:
      continue: 'the-second-kithmaze'
    practice: true
  }
  {
    name: 'The Second Kithmaze'
    type: 'hero'
    difficulty: 1
    id: 'the-second-kithmaze'
    original: '5418cf256bae62f707c7e1c3'
    description: 'Many have tried, few have found their way through this maze.'
    x: 59
    y: 25
    nextLevels:
      continue: 'new-sight'
  }
  {
    name: 'New Sight'
    type: 'hero'
    difficulty: 1
    id: 'new-sight'
    original: '5418d40f4c16460000ab9ac2'
    description: 'A true name can only be seen with the correct lenses.'
    x: 60
    y: 34
    nextLevels:
      continue: 'known-enemy'
  }
  {
    name: 'Known Enemy'
    type: 'hero'
    difficulty: 1
    id: 'known-enemy'
    original: '5452adea57e83800009730ee'
    description: 'Begin to use variables in your battles.'
    x: 68
    y: 42
    nextLevels:
      continue: 'master-of-names'
  }
  {
    name: 'Master of Names'
    type: 'hero'
    difficulty: 1
    id: 'master-of-names'
    original: '5452c3ce57e83800009730f7'
    description: 'Use your glasses to defend yourself from the Kithmen.'
    x: 75
    y: 46
    nextLevels:
      continue: 'lowly-kithmen'
      skip_ahead: 'closing-the-distance'
  }
  {
    name: 'Lowly Kithmen'
    type: 'hero'
    difficulty: 1
    id: 'lowly-kithmen'
    original: '541b24511ccc8eaae19f3c1f'
    description: 'Now that you can see them, they\'re everywhere!'
    x: 86
    y: 43
    nextLevels:
      continue: 'closing-the-distance'
      skip_ahead: 'the-final-kithmaze'
  }
  {
    name: 'Closing the Distance'
    type: 'hero'
    difficulty: 1
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
    difficulty: 1
    id: 'tactical-strike'
    original: '5452cfa706a59e000067e4f5'
    description: 'They\'re, uh, coming right for us! Sneak up behind them.'
    x: 88.65
    y: 63.06
    nextLevels:
      continue: 'the-final-kithmaze'
    practice: true
  }
  {
    name: 'The Final Kithmaze'
    type: 'hero'
    difficulty: 1
    id: 'the-final-kithmaze'
    original: '541b434e1ccc8eaae19f3c33'
    description: 'To escape you must find your way through an Elder Kithman\'s maze.'
    x: 81.93
    y: 65.86
    nextLevels:
      more_practice: 'the-gauntlet'
      continue: 'kithgard-gates'
  }
  {
    name: 'The Gauntlet'
    type: 'hero'
    difficulty: 1
    id: 'the-gauntlet'
    original: '5452d8b906a59e000067e4fa'
    description: 'Rush for the stairs, battling foes at every turn.'
    x: 84.89
    y: 73.88
    nextLevels:
      continue: 'kithgard-gates'
    practice: true
  }
  {
    name: 'Kithgard Gates'
    type: 'hero'
    difficulty: 1
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
    difficulty: 1
    id: 'cavern-survival'
    original: '544437e0645c0c0000c3291d'
    description: 'Stay alive longer than your opponent amidst hordes of ogres!'
    disabled: not me.isAdmin()
    x: 17.54
    y: 78.39
  }
]

forest = [
  {
    name: 'Defense of Plainswood'
    type: 'hero'
    difficulty: 1
    id: 'defense-of-plainswood'
    original: '541b67f71ccc8eaae19f3c62'
    description: 'Protect the peasants from the pursuing ogres.'
    nextLevels:
      continue: 'winding-trail'
    x: 29.63
    y: 53.69
  }
  {
    name: 'Winding Trail'
    type: 'hero'
    difficulty: 1
    id: 'winding-trail'
    original: '5446cb40ce01c23e05ecf027'
    description: 'Stay alive and navigate through the forest.'
    nextLevels:
      continue: 'thornbush-farm'
    x: 39.03
    y: 54.97
  }
  {
    name: 'Thornbush Farm'
    type: 'hero'
    difficulty: 1
    id: 'thornbush-farm'
    original: '5447030525cce60000745e2a'
    description: 'Determine refugee peasant from ogre when defending the farm.'
    nextLevels:
      continue: 'a-fiery-trap'
    x: 44.09
    y: 57.75
  }
  {
    name: 'A Fiery Trap'
    type: 'hero'
    difficulty: 1
    id: 'a-fiery-trap'
    original: '5448330517d7283e051f9b9e'
    description: 'Patrol the village entrances, but stay defensive.'
    disabled: true
    x: 40.14
    y: 63.96
  }
  #{
  #  name: ''
  #  type: 'hero'
  #  difficulty: 1
  #  id: ''
  #  description: ''
  #  x: 58.46
  #  y: 66.38
  # }
  #{
  #  name: ''
  #  type: 'hero'
  #  difficulty: 1
  #  id: ''
  #  description: ''
  #  x: 63.11
  #  y: 62.74
  # }
  #{
  #  name: ''
  #  type: 'hero'
  #  difficulty: 1
  #  id: ''
  #  description: ''
  #  x: 69.19
  #  y: 60.61
  # }
  #{
  #  name: ''
  #  type: 'hero'
  #  difficulty: 1
  #  id: ''
  #  description: ''
  #  x: 77.54
  #  y: 65.94
  #}
  #{
  #  name: ''
  #  type: 'hero'
  #  difficulty: 1
  #  id: ''
  #  description: ''
  #  x: 84.29
  #  y: 61.23
  #}
  {
    name: 'Dueling Grounds'
    type: 'hero-ladder'
    difficulty: 1
    id: 'dueling-grounds'
    original: '5442ba0e1e835500007eb1c7'
    description: 'Battle head-to-head against another hero in this basic beginner combat arena.'
    disabled: not me.isAdmin()
    x: 25.5
    y: 77.5
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
