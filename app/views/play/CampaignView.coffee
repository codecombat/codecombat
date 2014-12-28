RootView = require 'views/core/RootView'
template = require 'templates/play/campaign-view'
LevelSession = require 'models/LevelSession'
EarnedAchievement = require 'models/EarnedAchievement'
CocoCollection = require 'collections/CocoCollection'
Campaign = require 'models/Campaign'
AudioPlayer = require 'lib/AudioPlayer'
LevelSetupManager = require 'lib/LevelSetupManager'
ThangType = require 'models/ThangType'
MusicPlayer = require 'lib/surface/MusicPlayer'
storage = require 'core/storage'
AuthModal = require 'views/core/AuthModal'
SubscribeModal = require 'views/core/SubscribeModal'
Level = require 'models/Level'
utils = require 'core/utils'

trackedHourOfCode = false

class LevelSessionsCollection extends CocoCollection
  url: ''
  model: LevelSession

  constructor: (model) ->
    super()
    @url = "/db/user/#{me.id}/level.sessions?project=state.complete,levelID"

module.exports = class CampaignView extends RootView
  id: 'campaign-view'
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

  constructor: (options, @terrain='dungeon') ->
    super options
    options ?= {}

    @campaign = new Campaign({_id:@terrain})
    @campaign = @supermodel.loadModel(@campaign, 'campaign').model

    @editorMode = options.editorMode
    @levelStatusMap = {}
    @levelPlayCountMap = {}
    @sessions = @supermodel.loadCollection(new LevelSessionsCollection(), 'your_sessions', null, 0).model

    # Temporary attempt to make sure all earned rewards are accounted for. Figure out a better solution...
    @earnedAchievements = new CocoCollection([], {url: '/db/earned_achievement', model:EarnedAchievement, project: ['earnedRewards']})
    @listenToOnce @earnedAchievements, 'sync', ->
      earned = me.get('earned')
      for m in @earnedAchievements.models
        continue unless loadedEarned = m.get('earnedRewards')
        for group in ['heroes', 'levels', 'items']
          continue unless loadedEarned[group]
          for reward in loadedEarned[group]
            if reward not in earned[group]
              console.warn 'Filling in a gap for reward', group, reward
              earned[group].push(reward)

    @supermodel.loadCollection(@earnedAchievements, 'achievements')

    @listenToOnce @sessions, 'sync', @onSessionsLoaded
    @listenToOnce @campaign, 'sync', @getLevelPlayCounts
    $(window).on 'resize', @onWindowResize
    @probablyCachedMusic = storage.load("loaded-menu-music")
    musicDelay = if @probablyCachedMusic then 1000 else 10000
    @playMusicTimeout = _.delay (=> @playMusic() unless @destroyed), musicDelay
    @hadEverChosenHero = me.get('heroConfig')?.thangType
    @listenTo me, 'change:purchased', -> @renderSelectors('#gems-count')
    @listenTo me, 'change:spent', -> @renderSelectors('#gems-count')
    @listenTo me, 'change:heroConfig', -> @updateHero()
    window.tracker?.trackEvent 'Loaded World Map', category: 'World Map', ['Google Analytics']

    # If it's a new player who didn't appear to come from Hour of Code, we register her here without setting the hourOfCode property.
    elapsed = (new Date() - new Date(me.get('dateCreated')))
    if not trackedHourOfCode and not me.get('hourOfCode') and elapsed < 5 * 60 * 1000
      $('body').append($('<img src="http://code.org/api/hour/begin_codecombat.png" style="visibility: hidden;">'))
      trackedHourOfCode = true

    @requiresSubscription = not me.isPremium()

  destroy: ->
    @setupManager?.destroy()
    @$el.find('.ui-draggable').draggable 'destroy'
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

    levelSlugs = (level.slug for levelID, level of @campaign.get 'levels')
    levelPlayCountsRequest = @supermodel.addRequestResource 'play_counts', {
      url: '/db/level/-/play_counts'
      data: {ids: levelSlugs}
      method: 'POST'
      success: success
    }, 0
    levelPlayCountsRequest.load()

  onLoaded: ->
    return if @fullyRendered
    @fullyRendered = true
    @render()
    @preloadTopHeroes() unless me.get('heroConfig')?.thangType

  setCampaign: (@campaign) ->
    @render()

  onSubscribed: ->
    @requiresSubscription = false
    @render()

  getRenderData: (context={}) ->
    context = super(context)
    context.campaign = @campaign
    context.levels = _.values($.extend true, {}, @campaign.get('levels'))
    for level in context.levels
      level.position ?= { x: 10, y: 10 }
      level.locked = not me.ownsLevel level.original
      level.locked = false if @levelStatusMap[level.slug] in ['started', 'complete']
      level.locked = false if me.get('slug') is 'nick'
      level.locked = false if @editorMode
      level.disabled = true if not me.isAdmin() and level.adminOnly and not @levelStatusMap[level.slug] in ['started', 'complete']
      level.color = 'rgb(255, 80, 60)'
      if level.requiresSubscription
        level.color = 'rgb(80, 130, 200)'
      if level.unlocksHero
        level.unlockedHero = level.unlocksHero.originalID in (me.get('earned')?.heroes or [])
      level.hidden = level.locked or level.disabled

    # put lower levels in last, so in the world map they layer over one another properly.
    context.campaign.levels = (_.sortBy context.campaign.levels, (l) -> l.position.y).reverse()

    context.levelStatusMap = @levelStatusMap
    context.levelPlayCountMap = @levelPlayCountMap
    context.isIPadApp = application.isIPadApp
    context.mapType = _.string.slugify @terrain
    context.requiresSubscription = @requiresSubscription
    context.editorMode = @editorMode
    context.adjacentCampaigns = _.filter _.values(_.cloneDeep(@campaign.get('adjacentCampaigns') or {})), (ac) ->
      return false if ac.showIfUnlocked and ac.showIfUnlocked not in me.levels()
      ac.name = utils.i18n ac, 'name'
      ac.description = utils.i18n ac, 'description'
      styles = []
      styles.push "color: #{ac.color}" if ac.color
      styles.push "transform: rotate(#{ac.rotation}deg)" if ac.rotation
      ac.position ?= { x: 10, y: 10 }
      styles.push "left: #{ac.position.x}%"
      styles.push "top: #{ac.position.y}%"
      ac.style = styles.join('; ')
      return true
    context

  afterRender: ->
    super()
    @onWindowResize()
    unless application.isIPadApp
      _.defer => @$el?.find('.game-controls .btn').tooltip()  # Have to defer or i18n doesn't take effect.
      view = @
      @$el.find('.level, .campaign-switch').tooltip().each ->
        return unless me.isAdmin()
        $(@).draggable().on 'dragstop', ->
          bg = $('.map-background')
          x = ($(@).offset().left - bg.offset().left + $(@).outerWidth() / 2) / bg.width()
          y = 1 - ($(@).offset().top - bg.offset().top + $(@).outerHeight() / 2) / bg.height()
          e = { position: { x: (100 * x), y: (100 * y) }, levelOriginal: $(@).data('level-slug'), campaignID: $(@).data('campaign-id') }
          view.trigger 'level-moved', e if e.levelOriginal
          view.trigger 'adjacent-campaign-moved', e if e.campaignID
    @updateVolume()
    @updateHero()
    unless window.currentModal or not @fullyRendered
      @highlightElement '.level.next', delay: 500, duration: 60000, rotation: 0, sides: ['top']
    @applyCampaignStyles()

  afterInsert: ->
    super()
    return unless @getQueryVariable 'signup'
    return if me.get('email')
    @endHighlight()
    authModal = new AuthModal supermodel: @supermodel
    authModal.mode = 'signup'
    @openModalView authModal

  applyCampaignStyles: ->
    return unless @campaign.loaded
    if (backgrounds = @campaign.get 'backgroundImage') and backgrounds.length
      backgrounds = _.sortBy backgrounds, 'width'
      backgrounds.reverse()
      rules = []
      for background, i in backgrounds
        rule = "#campaign-view .map-background { background-image: url(/file/#{background.image}); }"
        rule = "@media screen and (max-width: #{background.width}px) { #{rule} }" if i
        rules.push rule
      utils.injectCSS rules.join('\n')
    if backgroundColor = @campaign.get 'backgroundColor'
      backgroundColorTransparent = @campaign.get 'backgroundColorTransparent'
      @$el.css 'background-color', backgroundColor
      for pos in ['top', 'right', 'bottom', 'left']
        @$el.find(".#{pos}-gradient").css 'background-image', "linear-gradient(to #{pos}, #{backgroundColorTransparent} 0%, #{backgroundColor} 100%)"
    @playAmbientSound()

  onSessionsLoaded: (e) ->
    return if @editorMode
    for session in @sessions.models
      @levelStatusMap[session.get('levelID')] = if session.get('state')?.complete then 'complete' else 'started'
    # TODO: add level.next = true for the next level they should do
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
    levelSlug = levelElement.data('level-slug')
    if @editorMode
      return @trigger 'level-clicked', levelSlug
    level = _.find _.values(@campaign.get('levels')), slug: levelSlug
    if application.isIPadApp
      @$levelInfo = @$el.find(".level-info-container[data-level-slug=#{levelSlug}]").show()
      @adjustLevelInfoPosition e
      @endHighlight()
    else
      if level.requiresSubscription and @requiresSubscription and not @levelStatusMap[level.slug] and not level.adventurer
        @openModalView new SubscribeModal()
        window.tracker?.trackEvent 'Show subscription modal', category: 'Subscription', label: 'map level clicked', level: levelSlug
      else if $(e.target).attr('disabled')
        Backbone.Mediator.publish 'router:navigate', route: '/contribute/adventurer'
        return
      else if $(e.target).parent().hasClass 'locked'
        return
      else
        @startLevel levelElement
        window.tracker?.trackEvent 'Clicked Level', category: 'World Map', levelID: levelSlug, ['Google Analytics']

  onClickStartLevel: (e) ->
    levelElement = $(e.target).parents('.level-info-container')
    @startLevel levelElement
    window.tracker?.trackEvent 'Clicked Start Level', category: 'World Map', levelID: levelElement.data('level-slug'), ['Google Analytics']

  startLevel: (levelElement) ->
    @setupManager?.destroy()
    @setupManager = new LevelSetupManager supermodel: @supermodel, levelID: levelElement.data('level-slug'), levelPath: levelElement.data('level-path'), levelName: levelElement.data('level-name'), hadEverChosenHero: @hadEverChosenHero, parent: @
    @setupManager.open()
    @$levelInfo?.hide()

  onMouseEnterLevel: (e) ->
    return if application.isIPadApp
    return if @editorMode
    levelSlug = $(e.target).parents('.level').data('level-slug')
    @$levelInfo = @$el.find(".level-info-container[data-level-slug=#{levelSlug}]").show()
    @adjustLevelInfoPosition e
    @endHighlight()

  onMouseLeaveLevel: (e) ->
    return if application.isIPadApp
    levelSlug = $(e.target).parents('.level').data('level-slug')
    @$el.find(".level-info-container[data-level-slug='#{levelSlug}']").hide()
    @$levelInfo = null

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
    mapWidth = {dungeon: 2350, forest: 2500, desert: 2350}[@terrain] or 2350
    aspectRatio = mapWidth / mapHeight
    pageWidth = @$el.width()
    pageHeight = @$el.height()
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
    return unless file = @campaign.get('ambientSound')?[AudioPlayer.ext.substr 1]
    src = "/file/#{file}"
    unless AudioPlayer.getStatus(src)?.loaded
      AudioPlayer.preloadSound src
      Backbone.Mediator.subscribeOnce 'audio-player:loaded', @playAmbientSound, @
      return
    @ambientSound = createjs.Sound.play src, loop: -1, volume: 0.1
    createjs.Tween.get(@ambientSound).to({volume: 0.5}, 1000)

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

  updateHero: ->
    return unless hero = me.get('heroConfig')?.thangType
    for slug, original of ThangType.heroes when original is hero
      @$el.find('.player-hero-icon').removeClass().addClass('player-hero-icon ' + slug)
      return
    console.error "CampaignView hero update couldn't find hero slug for original:", hero
