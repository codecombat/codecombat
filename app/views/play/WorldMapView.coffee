RootView = require 'views/kinds/RootView'
template = require 'templates/play/world-map-view'
LevelSession = require 'models/LevelSession'
CocoCollection = require 'collections/CocoCollection'
AudioPlayer = require 'lib/AudioPlayer'
PlayLevelModal = require 'views/play/modal/PlayLevelModal'

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

  constructor: (options) ->
    super options
    @levelStatusMap = {}
    @levelPlayCountMap = {}
    @sessions = @supermodel.loadCollection(new LevelSessionsCollection(), 'your_sessions', null, 0).model
    @listenToOnce @sessions, 'sync', @onSessionsLoaded
    @getLevelPlayCounts()
    $(window).on 'resize', @onWindowResize
    @playAmbientSound()

  destroy: ->
    $(window).off 'resize', @onWindowResize
    if ambientSound = @ambientSound
      # Doesn't seem to work; stops immediately.
      createjs.Tween.get(ambientSound).to({volume: 0.0}, 1500).call -> ambientSound.stop()
    super()

  getLevelPlayCounts: ->
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
    context.campaigns = campaigns
    for campaign in context.campaigns
      for level in campaign.levels
        level.x ?= 10 + 80 * Math.random()
        level.y ?= 10 + 80 * Math.random()
    context.levelStatusMap = @levelStatusMap
    context.levelPlayCountMap = @levelPlayCountMap
    context.isIPadApp = application.isIPadApp
    context

  afterRender: ->
    super()
    @onWindowResize()
    unless application.isIPadApp
      _.defer => @$el.find('.game-controls button').tooltip()  # Have to defer or i18n doesn't take effect.
      @$el.find('.level').tooltip()

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
    return if $(e.target).attr('disabled')
    if application.isIPadApp
      levelID = $(e.target).parents('.level').data('level-id')
      @$levelInfo = @$el.find(".level-info-container[data-level-id=#{levelID}]").show()
      @adjustLevelInfoPosition e
    else
      @startLevel $(e.target).parents('.level')

  onClickStartLevel: (e) ->
    @startLevel $(e.target).parents('.level-info-container')

  startLevel: (levelElement) ->
    playLevelModal = new PlayLevelModal supermodel: @supermodel, levelID: levelElement.data('level-id'), levelPath: levelElement.data('level-path'), levelName: levelElement.data('level-name')
    @openModalView playLevelModal
    @$levelInfo?.hide()

  onMouseEnterLevel: (e) ->
    return if application.isIPadApp
    levelID = $(e.target).parents('.level').data('level-id')
    @$levelInfo = @$el.find(".level-info-container[data-level-id=#{levelID}]").show()
    @adjustLevelInfoPosition e

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
    forestMapWidth = 2401
    forestMapHeight = 1536
    aspectRatio = forestMapWidth / forestMapHeight
    pageWidth = $(window).width()
    pageHeight = $(window).height()
    widthRatio = pageWidth / forestMapWidth
    heightRatio = pageHeight / forestMapHeight
    if widthRatio > heightRatio
      resultingWidth = pageWidth
      resultingHeight = resultingWidth / aspectRatio
    else
      resultingHeight = pageHeight
      resultingWidth = resultingHeight * aspectRatio
    resultingMarginX = (pageWidth - resultingWidth) / 2
    resultingMarginY = (pageHeight - resultingHeight) / 2
    @$el.find('.map').css(width: resultingWidth, height: resultingHeight, 'margin-left': resultingMarginX, 'margin-top': resultingMarginY)

  playAmbientSound: ->
    return if @ambientSound
    terrain = 'Grass'
    return unless file = {Dungeon: 'ambient-map-dungeon', Grass: 'ambient-map-grass'}[terrain]
    src = "/file/interface/#{file}#{AudioPlayer.ext}"
    unless AudioPlayer.getStatus(src)?.loaded
      AudioPlayer.preloadSound src
      Backbone.Mediator.subscribeOnce 'audio-player:loaded', @playAmbientSound, @
      return
    @ambientSound = createjs.Sound.play src, loop: -1, volume: 0.1
    createjs.Tween.get(@ambientSound).to({volume: 1.0}, 1000)


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

hero = [
  {
    name: 'Dungeons of Kithgard'
    type: 'hero'
    difficulty: 1
    id: 'dungeons-of-kithgard'
    description: 'Grab the gem, but touch nothing else. Start here.'
    x: 17.23
    y: 36.94
  }
  {
    name: 'Gems in the Deep'
    type: 'hero'
    difficulty: 1
    id: 'gems-in-the-deep'
    description: 'Quickly collect the gems; you will need them.'
    x: 22.6
    y: 35.1
  }
  {
    name: 'Shadow Guard'
    type: 'hero'
    difficulty: 1
    id: 'shadow-guard'
    description: 'Evade the Kithgard minion.'
    x: 27.74
    y: 35.17
  }
  {
    name: 'True Names'
    type: 'hero'
    difficulty: 1
    id: 'true-names'
    description: 'Learn an enemy\'s true name to defeat it.'
    x: 32.7
    y: 36.7
  }
  {
    name: 'The Raised Sword'
    type: 'hero'
    difficulty: 1
    id: 'the-raised-sword'
    description: 'Learn to equip yourself for combat.'
    x: 36.6
    y: 39.5
  }
  {
    name: 'The First Kithmaze'
    type: 'hero'
    difficulty: 1
    id: 'the-first-kithmaze'
    description: 'The builders of Kith constructed many mazes to confuse travelers.'
    x: 38.4
    y: 43.5
  }
  {
    name: 'The Second Kithmaze'
    type: 'hero'
    difficulty: 1
    id: 'the-second-kithmaze'
    description: 'Many have tried, few have found their way through this maze.'
    x: 38.9
    y: 48.1
  }
  {
    name: 'New Sight'
    type: 'hero'
    difficulty: 1
    id: 'new-sight'
    description: 'A true name can only be seen with the correct lenses.'
    x: 39.3
    y: 53.1
  }
  {
    name: 'Lowly Kithmen'
    type: 'hero'
    difficulty: 1
    id: 'lowly-kithmen'
    description: 'Use your glasses to seek out and attack the Kithmen.'
    x: 39.4
    y: 57.7
  }
  {
    name: 'A Bolt in the Dark'
    type: 'hero'
    difficulty: 1
    id: 'a-bolt-in-the-dark'
    description: 'Kithmen are not the only ones to stand in your way.'
    x: 40.0
    y: 63.2
  }
  {
    name: 'The Final Kithmaze'
    type: 'hero'
    difficulty: 1
    id: 'the-final-kithmaze'
    description: 'To escape you must find your way through an Elder Kithman\'s maze.'
    x: 42.67
    y: 67.98
  }
  {
    name: 'Kithgard Gates'
    type: 'hero'
    difficulty: 1
    id: 'kithgard-gates'
    description: 'Escape the Kithgard dungeons and don\'t let the guardians get you.'
    x: 47.38
    y: 70.55
  }
  {
    name: 'Defence of Plainswood'
    type: 'hero'
    difficulty: 1
    id: 'defence-of-plainswood'
    description: 'Protect the peasants from the pursuing ogres.'
    x: 52.66
    y: 69.66
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

]

campaigns = [
  #{id: 'beginner', name: 'Beginner Campaign', description: '... in which you learn the wizardry of programming.', levels: tutorials, color: "rgb(255, 80, 60)"}
  #{id: 'multiplayer', name: 'Multiplayer Arenas', description: '... in which you code head-to-head against other players.', levels: arenas, color: "rgb(80, 5, 60)"}
  #{id: 'dev', name: 'Random Harder Levels', description: '... in which you learn the interface while doing something a little harder.', levels: experienced, color: "rgb(80, 60, 255)"}
  #{id: 'classic' ,name: 'Classic Algorithms', description: '... in which you learn the most popular algorithms in Computer Science.', levels: classicAlgorithms, color: "rgb(110, 80, 120)"}
  #{id: 'player_created', name: 'Player-Created', description: '... in which you battle against the creativity of your fellow <a href=\"/contribute#artisan\">Artisan Wizards</a>.', levels: playerCreated, color: "rgb(160, 160, 180)"}
  {id: 'beginner', name: 'Beginner Campaign', levels: hero, color: 'rgb(255, 80, 60)'}
]
