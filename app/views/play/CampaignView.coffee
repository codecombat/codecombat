RootView = require 'views/core/RootView'
template = require 'templates/play/campaign-view'
LevelSession = require 'models/LevelSession'
EarnedAchievement = require 'models/EarnedAchievement'
CocoCollection = require 'collections/CocoCollection'
Achievements = require 'collections/Achievements'
Campaign = require 'models/Campaign'
AudioPlayer = require 'lib/AudioPlayer'
LevelSetupManager = require 'lib/LevelSetupManager'
ThangType = require 'models/ThangType'
MusicPlayer = require 'lib/surface/MusicPlayer'
storage = require 'core/storage'
CreateAccountModal = require 'views/core/CreateAccountModal'
SubscribeModal = require 'views/core/SubscribeModal'
LeaderboardModal = require 'views/play/modal/LeaderboardModal'
Level = require 'models/Level'
utils = require 'core/utils'
require 'vendor/three'
ParticleMan = require 'core/ParticleMan'
ShareProgressModal = require 'views/play/modal/ShareProgressModal'
UserPollsRecord = require 'models/UserPollsRecord'
Poll = require 'models/Poll'
PollModal = require 'views/play/modal/PollModal'
CourseInstance = require 'models/CourseInstance'
codePlay = require('lib/code-play')

require 'game-libraries'

class LevelSessionsCollection extends CocoCollection
  url: ''
  model: LevelSession

  constructor: (model) ->
    super()
    @url = "/db/user/#{me.id}/level.sessions?project=state.complete,levelID,state.difficulty,playtime"

class CampaignsCollection extends CocoCollection
  # We don't send all of levels, just the parts needed in countLevels
  url: '/db/campaign/-/overworld?project=slug,adjacentCampaigns,name,fullName,description,i18n,color,levels'
  model: Campaign

module.exports = class CampaignView extends RootView
  id: 'campaign-view'
  template: template

  subscriptions:
    'subscribe-modal:subscribed': 'onSubscribed'

  events:
    'click .map-background': 'onClickMap'
    'click .level': 'onClickLevel'
    'dblclick .level': 'onDoubleClickLevel'
    'click .level-info-container .start-level': 'onClickStartLevel'
    'click .level-info-container .view-solutions': 'onClickViewSolutions'
    'click .level-info-container .course-version button': 'onClickCourseVersion'
    'click #volume-button': 'onToggleVolume'
    'click #back-button': 'onClickBack'
    'click #clear-storage-button': 'onClickClearStorage'
    'click .portal .campaign': 'onClickPortalCampaign'
    'click .portal .beta-campaign': 'onClickPortalCampaign'
    'click a .campaign-switch': 'onClickCampaignSwitch'
    'mouseenter .portals': 'onMouseEnterPortals'
    'mouseleave .portals': 'onMouseLeavePortals'
    'mousemove .portals': 'onMouseMovePortals'
    'click .poll': 'showPoll'
  shortcuts:
    'shift+s': 'onShiftS'

  constructor: (options, @terrain) ->
    super options
    @terrain = 'picoctf' if window.serverConfig.picoCTF
    @editorMode = options?.editorMode
    @requiresSubscription = not me.isPremium()
    if @editorMode
      @terrain ?= 'dungeon'
    @levelStatusMap = {}
    @levelPlayCountMap = {}
    @levelDifficultyMap = {}

    if utils.getQueryVariable('hour_of_code')
      me.set('hourOfCode', true)
      me.patch()
      pixelCode = if @terrain is 'game-dev-hoc' then 'code_combat_gamedev' else 'code_combat'
      $('body').append($("<img src='https://code.org/api/hour/begin_#{pixelCode}.png' style='visibility: hidden;'>"))

    # HoC: Fake us up a "mode" for HeroVictoryModal to return hero without levels realizing they're in a copycat campaign, or clear it if we started playing.
    shouldReturnToGameDevHoc = @terrain is 'game-dev-hoc'
    storage.save 'should-return-to-game-dev-hoc', shouldReturnToGameDevHoc

    if window.serverConfig.picoCTF
      @supermodel.addRequestResource(url: '/picoctf/problems', success: (@picoCTFProblems) =>).load()
    else
      unless @editorMode
        @sessions = @supermodel.loadCollection(new LevelSessionsCollection(), 'your_sessions', {cache: false}, 0).model
        @listenToOnce @sessions, 'sync', @onSessionsLoaded
      unless @terrain
        @campaigns = @supermodel.loadCollection(new CampaignsCollection(), 'campaigns', null, 1).model
        @listenToOnce @campaigns, 'sync', @onCampaignsLoaded
        return

    @campaign = new Campaign({_id:@terrain})
    @campaign = @supermodel.loadModel(@campaign).model

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

    @supermodel.loadCollection(@earnedAchievements, 'achievements', {cache: false})

    @listenToOnce @campaign, 'sync', @getLevelPlayCounts
    $(window).on 'resize', @onWindowResize
    @probablyCachedMusic = storage.load("loaded-menu-music")
    musicDelay = if @probablyCachedMusic then 1000 else 10000
    @playMusicTimeout = _.delay (=> @playMusic() unless @destroyed), musicDelay
    @hadEverChosenHero = me.get('heroConfig')?.thangType
    @listenTo me, 'change:purchased', -> @renderSelectors('#gems-count')
    @listenTo me, 'change:spent', -> @renderSelectors('#gems-count')
    @listenTo me, 'change:earned', -> @renderSelectors('#gems-count')
    @listenTo me, 'change:heroConfig', -> @updateHero()
    window.tracker?.trackEvent 'Loaded World Map', category: 'World Map', label: @terrain

  destroy: ->
    @setupManager?.destroy()
    @$el.find('.ui-draggable').off().draggable 'destroy'
    $(window).off 'resize', @onWindowResize
    if ambientSound = @ambientSound
      # Doesn't seem to work; stops immediately.
      createjs.Tween.get(ambientSound).to({volume: 0.0}, 1500).call -> ambientSound.stop()
    @musicPlayer?.destroy()
    clearTimeout @playMusicTimeout
    @particleMan?.destroy()
    clearInterval @portalScrollInterval
    super()

  showLoading: ($el) ->
    unless @campaign
      @$el.find('.game-controls, .user-status').addClass 'hidden'
      @$el.find('.portal .campaign-name span').text $.i18n.t 'common.loading'

  hideLoading: ->
    unless @campaign
      @$el.find('.game-controls, .user-status').removeClass 'hidden'

  getLevelPlayCounts: ->
    return unless me.isAdmin()
    return  # TODO: get rid of all this? It's redundant with new campaign editor analytics, unless we want to show player counts on leaderboards buttons.
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
    @checkForUnearnedAchievements()
    @preloadTopHeroes() unless me.get('heroConfig')?.thangType
    @$el.find('#campaign-status').delay(4000).animate({top: "-=58"}, 1000) unless @terrain is 'dungeon'
    if not me.get('hourOfCode') and @terrain
      if me.get('anonymous') and me.get('lastLevel') is 'shadow-guard' and me.level() < 4 and !features.noAuth
        @openModalView new CreateAccountModal supermodel: @supermodel, showSignupRationale: true
      else if me.get('name') and me.get('lastLevel') in ['forgetful-gemsmith', 'signs-and-portents'] and
      me.level() < 5 and not (me.get('ageRange') in ['18-24', '25-34', '35-44', '45-100']) and
      not storage.load('sent-parent-email') and not me.isPremium()
        @openModalView new ShareProgressModal()

  setCampaign: (@campaign) ->
    @render()

  onSubscribed: ->
    @requiresSubscription = false
    @render()

  getRenderData: (context={}) ->
    context = super(context)
    context.campaign = @campaign
    context.levels = _.values($.extend true, {}, @campaign?.get('levels') ? {})
    if me.level() < 12 and @terrain is 'dungeon' and not @editorMode
      reject = if me.getFourthLevelGroup() is 'signs-and-portents' then 'forgetful-gemsmith' else 'signs-and-portents'
      context.levels = _.reject context.levels, slug: reject
    if features.freeOnly
      context.levels = _.reject context.levels, (level) ->
        return false if features.codePlay and codePlay.canPlay(level.slug)
        return level.requiresSubscription
    if features.brainPop
      context.levels = _.filter context.levels, (level) ->
        level.slug in ['dungeons-of-kithgard', 'gems-in-the-deep', 'shadow-guard', 'true-names']
    @annotateLevels(context.levels)
    count = @countLevels context.levels
    context.levelsCompleted = count.completed
    context.levelsTotal = count.total

    @determineNextLevel context.levels if @sessions?.loaded or @editorMode
    # put lower levels in last, so in the world map they layer over one another properly.
    context.levels = (_.sortBy context.levels, (l) -> l.position.y).reverse()
    @campaign.renderedLevels = context.levels if @campaign

    context.levelStatusMap = @levelStatusMap
    context.levelDifficultyMap = @levelDifficultyMap
    context.levelPlayCountMap = @levelPlayCountMap
    context.isIPadApp = application.isIPadApp
    context.picoCTF = window.serverConfig.picoCTF
    context.requiresSubscription = @requiresSubscription
    context.editorMode = @editorMode
    context.adjacentCampaigns = _.filter _.values(_.cloneDeep(@campaign?.get('adjacentCampaigns') or {})), (ac) =>
      if ac.showIfUnlocked and not @editorMode
        return false if _.isString(ac.showIfUnlocked) and ac.showIfUnlocked not in me.levels()
        return false if _.isArray(ac.showIfUnlocked) and _.intersection(ac.showIfUnlocked, me.levels()).length <= 0
      ac.name = utils.i18n ac, 'name'
      styles = []
      styles.push "color: #{ac.color}" if ac.color
      styles.push "transform: rotate(#{ac.rotation}deg)" if ac.rotation
      ac.position ?= { x: 10, y: 10 }
      styles.push "left: #{ac.position.x}%"
      styles.push "top: #{ac.position.y}%"
      ac.style = styles.join('; ')
      return true
    context.marked = marked
    context.i18n = utils.i18n

    if @campaigns
      context.campaigns = {}
      for campaign in @campaigns.models when campaign.get('slug') isnt 'auditions'
        context.campaigns[campaign.get('slug')] = campaign
        if @sessions?.loaded
          levels = _.values($.extend true, {}, campaign.get('levels') ? {})
          if me.level() < 12 and campaign.get('slug') is 'dungeon' and not @editorMode
            reject = if me.getFourthLevelGroup() is 'signs-and-portents' then 'forgetful-gemsmith' else 'signs-and-portents'
            levels = _.reject levels, slug: reject
          if features.freeOnly
            levels = _.reject levels, (level) ->
              return false if features.codePlay and codePlay.canPlay(level.slug)
              return level.requiresSubscription
          count = @countLevels levels
          campaign.levelsTotal = count.total
          campaign.levelsCompleted = count.completed
          if campaign.get('slug') is 'dungeon'
            campaign.locked = false
          else unless campaign.levelsTotal
            campaign.locked = true
          else
            campaign.locked = true
      for campaign in @campaigns.models
        for acID, ac of campaign.get('adjacentCampaigns') ? {}
          if _.isString(ac.showIfUnlocked)
            _.find(@campaigns.models, id: acID)?.locked = false if ac.showIfUnlocked in me.levels()
          else if _.isArray(ac.showIfUnlocked)
            _.find(@campaigns.models, id: acID)?.locked = false if _.intersection(ac.showIfUnlocked, me.levels()).length > 0

    context

  afterRender: ->
    super()
    @onWindowResize()
    unless application.isIPadApp
      _.defer => @$el?.find('.game-controls .btn:not(.poll)').addClass('has-tooltip').tooltip()  # Have to defer or i18n doesn't take effect.
      view = @
      @$el.find('.level, .campaign-switch').addClass('has-tooltip').tooltip().each ->
        return unless me.isAdmin() and view.editorMode
        $(@).draggable().on 'dragstop', ->
          bg = $('.map-background')
          x = ($(@).offset().left - bg.offset().left + $(@).outerWidth() / 2) / bg.width()
          y = 1 - ($(@).offset().top - bg.offset().top + $(@).outerHeight() / 2) / bg.height()
          e = { position: { x: (100 * x), y: (100 * y) }, levelOriginal: $(@).data('level-original'), campaignID: $(@).data('campaign-id') }
          view.trigger 'level-moved', e if e.levelOriginal
          view.trigger 'adjacent-campaign-moved', e if e.campaignID
    @updateVolume()
    @updateHero()
    unless window.currentModal or not @fullyRendered
      @highlightElement '.level.next', delay: 500, duration: 60000, rotation: 0, sides: ['top']
      @createLines() if @editorMode
      @showLeaderboard @options.justBeatLevel?.get('slug') if @options.showLeaderboard# or true  # Testing
    @applyCampaignStyles()
    @testParticles()

  onShiftS: (e) ->
    @generateCompletionRates() if @editorMode

  generateCompletionRates: ->
    return unless me.isAdmin()
    startDay = utils.getUTCDay -14
    endDay = utils.getUTCDay -1
    $(".map-background").css('background-image','none')
    $(".gradient").remove()
    $("#campaign-view").css("background-color", "black")
    for level in @campaign?.renderedLevels ? []
      $("div[data-level-slug=#{level.slug}] .level-kind").text("Loading...")
      request = @supermodel.addRequestResource 'level_completions', {
        url: '/db/analytics_perday/-/level_completions'
        data: {startDay: startDay, endDay: endDay, slug: level.slug}
        method: 'POST'
        success: @onLevelCompletionsLoaded.bind(@, level)
      }, 0
      request.load()

  onLevelCompletionsLoaded: (level, data) ->
    return if @destroyed
    started = 0
    finished = 0
    for day in data
      started += day.started ? 0
      finished += day.finished ? 0
    if started is 0
      ratio = 0
    else
      ratio = finished / started
    rateDisplay = (ratio * 100).toFixed(1) + '%'
    $("div[data-level-slug=#{level.slug}] .level-kind").html((if started < 1000 then started else (started / 1000).toFixed(1) + "k") + "<br>" + rateDisplay)
    if ratio <= 0.5
      color = "rgb(255, 0, 0)"
    else if ratio > 0.5 and ratio <= 0.85
      offset = (ratio - 0.5) / 0.35
      color = "rgb(255, #{Math.round(256 * offset)}, 0)"
    else if ratio > 0.85 and ratio <= 0.95
      offset = (ratio - 0.85) / 0.1
      color = "rgb(#{Math.round(256 * (1-offset))}, 256, 0)"
    else
      color = "rgb(0, 256, 0)"
    $("div[data-level-slug=#{level.slug}] .level-kind").css({"color":color, "width":256+"px", "transform":"translateX(-50%) translateX(15px)"})
    $("div[data-level-slug=#{level.slug}]").css("background-color", color)

  afterInsert: ->
    super()
    if @getQueryVariable('signup') and not me.get('email')
      return @promptForSignup()
    if not me.isPremium() and (@isPremiumCampaign() or (@options.worldComplete and not features.noAuth))
      if not me.get('email')
        return @promptForSignup()
      campaignSlug = window.location.pathname.split('/')[2]
      return @promptForSubscription campaignSlug, 'premium campaign visited'

  promptForSignup: ->
    return if features.noAuth
    
    @endHighlight()
    authModal = new CreateAccountModal supermodel: @supermodel
    authModal.mode = 'signup'
    @openModalView authModal

  promptForSubscription: (slug, label) ->
    @endHighlight()
    @openModalView new SubscribeModal()
    # TODO: Added levelID on 2/9/16. Remove level property and associated AnalyticsLogEvent 'properties.level' index later.
    window.tracker?.trackEvent 'Show subscription modal', category: 'Subscription', label: label, level: slug, levelID: slug

  isPremiumCampaign: (slug) ->
    slug ||= window.location.pathname.split('/')[2]
    /campaign-(game|web)-dev-\d/.test slug

  showAds: ->
    return false # No ads for now.
    if application.isProduction() && !me.isPremium() && !me.isTeacher() && !window.serverConfig.picoCTF
      return me.getCampaignAdsGroup() is 'leaderboard-ads'
    false

  annotateLevels: (orderedLevels) ->
    previousIncompletePracticeLevel = false # Lock owned levels if there's a earlier incomplete practice level to play
    for level, levelIndex in orderedLevels
      level.position ?= { x: 10, y: 10 }
      level.locked = not me.ownsLevel(level.original) or previousIncompletePracticeLevel
      level.locked = true if level.slug is 'kithgard-mastery' and @calculateExperienceScore() is 0
      level.locked = true if level.requiresSubscription and @requiresSubscription and me.get('hourOfCode')
      level.locked = false if @levelStatusMap[level.slug] in ['started', 'complete']
      level.locked = false if @editorMode
      level.locked = false if @campaign?.get('name') in ['Auditions', 'Intro']
      level.locked = false if me.isInGodMode()
      level.disabled = true if level.adminOnly and @levelStatusMap[level.slug] not in ['started', 'complete']
      level.disabled = false if me.isInGodMode()
      level.color = 'rgb(255, 80, 60)'
      level.color = 'rgb(80, 130, 200)' if level.requiresSubscription and not features.codePlay
      level.color = 'rgb(200, 80, 200)' if level.adventurer
      level.color = 'rgb(193, 193, 193)' if level.locked
      level.unlocksHero = _.find(level.rewards, 'hero')?.hero
      if level.unlocksHero
        level.purchasedHero = level.unlocksHero in (me.get('purchased')?.heroes or [])

      level.unlocksItem = _.find(level.rewards, 'item')?.item
      level.unlocksPet = utils.petThangIDs.indexOf(level.unlocksItem) isnt -1

      if window.serverConfig.picoCTF
        if problem = _.find(@picoCTFProblems or [], pid: level.picoCTFProblem)
          level.locked = false if problem.unlocked or level.slug is 'digital-graffiti'
          #level.locked = false  # Testing to see all levels
          level.description = """
            ### #{problem.name}
            #{level.description or problem.description}

            #{problem.category} - #{problem.score} points
          """
          level.color = 'rgb(80, 130, 200)' if problem.solved

      if @campaign?.levelIsPractice(level) and not level.locked and @levelStatusMap[level.slug] isnt 'complete' and
      (not level.requiresSubscription or level.adventurer or not @requiresSubscription)
        previousIncompletePracticeLevel = true

      level.hidden = level.locked
      if level.concepts?.length
        level.displayConcepts = level.concepts
        maxConcepts = 6
        if level.displayConcepts.length > maxConcepts
          level.displayConcepts = level.displayConcepts.slice -maxConcepts

      level.unlockedInSameCampaign = levelIndex < 5  # First few are always counted (probably unlocked in previous campaign)
      for otherLevel in orderedLevels when not level.unlockedInSameCampaign and otherLevel isnt level
        for reward in (otherLevel.rewards ? []) when reward.level
          level.unlockedInSameCampaign ||= reward.level is level.original

  countLevels: (orderedLevels) ->
    count = total: 0, completed: 0

    if @campaign?.get('slug') is 'game-dev-hoc'
      # HoC: Just order left-to-right instead of looking at unlocks, which we don't use for this copycat campaign
      orderedLevels = _.sortBy orderedLevels, (level) -> level.position.x
      count.completed++ for level in orderedLevels when @levelStatusMap[level.slug] is 'complete'
      count.total = orderedLevels.length
      return count

    for level, levelIndex in orderedLevels
      @annotateLevels(orderedLevels) unless level.locked?  # Annotate if we haven't already.
      continue if level.disabled
      completed = @levelStatusMap[level.slug] is 'complete'
      started = @levelStatusMap[level.slug] is 'started'
      ++count.total if (level.unlockedInSameCampaign or not level.locked) and (started or completed or not (level.locked and level.practice and level.slug.substring(level.slug.length - 2) in ['-a', '-b', '-c', '-d']))
      ++count.completed if completed

    count

  showLeaderboard: (levelSlug) ->
    leaderboardModal = new LeaderboardModal supermodel: @supermodel, levelSlug: levelSlug
    @openModalView leaderboardModal

  determineNextLevel: (orderedLevels) ->
    dontPointTo = ['lost-viking', 'kithgard-mastery']  # Challenge levels we don't want most players bashing heads against
    subscriptionPrompts = [{slug: 'boom-and-bust', unless: 'defense-of-plainswood'}]

    if @campaign?.get('slug') is 'game-dev-hoc'
      # HoC: Just order left-to-right instead of looking at unlocks, which we don't use for this copycat campaign
      orderedLevels = _.sortBy orderedLevels, (level) -> level.position.x
      for level in orderedLevels
        if @levelStatusMap[level.slug] isnt 'complete'
          level.next = true
          # Unlock and re-annotate this level
          # May not be unlocked/awarded due to different game-dev-hoc progression using mostly shared levels
          level.locked = false
          level.hidden = level.locked
          level.disabled = false
          level.color = 'rgb(255, 80, 60)'
          return

    findNextLevel = (nextLevels, practiceOnly) =>
      for nextLevelOriginal in nextLevels
        nextLevel = _.find orderedLevels, original: nextLevelOriginal
        continue if not nextLevel or nextLevel.locked
        continue if practiceOnly and not @campaign.levelIsPractice(nextLevel)

        # If it's a challenge level, we efficiently determine whether we actually do want to point it out.
        if nextLevel.slug is 'kithgard-mastery' and not @levelStatusMap[nextLevel.slug] and @calculateExperienceScore() >= 3
          unless (timesPointedOut = storage.load("pointed-out-#{nextLevel.slug}") or 0) > 3
            # We may determineNextLevel more than once per render, so we can't just do this once. But we do give up after a couple highlights.
            dontPointTo = _.without dontPointTo, nextLevel.slug
            storage.save "pointed-out-#{nextLevel.slug}", timesPointedOut + 1

        # Should we point this level out?
        if not nextLevel.disabled and @levelStatusMap[nextLevel.slug] isnt 'complete' and nextLevel.slug not in dontPointTo and
        not nextLevel.replayable and (
          me.isPremium() or not nextLevel.requiresSubscription or nextLevel.adventurer or
          _.any(subscriptionPrompts, (prompt) => nextLevel.slug is prompt.slug and not @levelStatusMap[prompt.unless])
        )
          nextLevel.next = true
          return true
      false

    foundNext = false
    for level, levelIndex in orderedLevels
      # Iterate through all levels in order and look to find the first unlocked one that meets all our criteria for being pointed out as the next level.
      if @campaign.get('type') is 'course'
        level.nextLevels = []
        for nextLevel, nextLevelIndex in orderedLevels when nextLevelIndex > levelIndex
          continue if nextLevel.practice and level.nextLevels.length
          break if level.practice and not nextLevel.practice
          level.nextLevels.push nextLevel.original
          break unless nextLevel.practice
      else
        level.nextLevels = (reward.level for reward in level.rewards ? [] when reward.level)
      foundNext = findNextLevel(level.nextLevels, true) unless foundNext # Check practice levels first
      foundNext = findNextLevel(level.nextLevels, false) unless foundNext

    if not foundNext and orderedLevels[0] and not orderedLevels[0].locked and @levelStatusMap[orderedLevels[0].slug] isnt 'complete'
      orderedLevels[0].next = true

  calculateExperienceScore: ->
    adultPoint = me.get('ageRange') in ['18-24', '25-34', '35-44', '45-100']  # They have to have answered the poll for this, likely after Shadow Guard.
    speedPoints = 0
    for [levelSlug, speedThreshold] in [['dungeons-of-kithgard', 50], ['gems-in-the-deep', 55], ['shadow-guard', 55], ['forgetful-gemsmith', 40], ['true-names', 40]]
      if _.find(@sessions?.models, (session) -> session.get('levelID') is levelSlug)?.attributes.playtime <= speedThreshold
        ++speedPoints
    experienceScore = adultPoint + speedPoints  # 0-6 score of how likely we think they are to be experienced and ready for Kithgard Mastery
    return experienceScore

  createLines: ->
    for level in @campaign?.renderedLevels ? []
      for nextLevelOriginal in level.nextLevels ? []
        if nextLevel = _.find(@campaign.renderedLevels, original: nextLevelOriginal)
          @createLine level.position, nextLevel.position

  createLine: (o1, o2) ->
    mapHeight = parseFloat($(".map").css("height"))
    mapWidth = parseFloat($(".map").css("width"))
    return unless mapHeight > 0
    ratio =  mapWidth / mapHeight
    p1 = x: o1.x, y: o1.y / ratio
    p2 = x: o2.x, y: o2.y / ratio
    length = Math.sqrt(Math.pow(p1.x - p2.x , 2) + Math.pow(p1.y - p2.y, 2))
    angle = Math.atan2(p1.y - p2.y, p2.x - p1.x) * 180 / Math.PI
    transform = "translateY(-50%) translateX(-50%) rotate(#{angle}deg) translateX(50%)"
    line = $('<div>').appendTo('.map').addClass('next-level-line').css(transform: transform, width: length + '%', left: o1.x + '%', bottom: (o1.y - 0.5) + '%')
    line.append($('<div class="line">')).append($('<div class="point">'))

  applyCampaignStyles: ->
    return unless @campaign?.loaded
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

  testParticles: ->
    return unless @campaign?.loaded and $.browser.chrome  # Sometimes this breaks in non-Chrome browsers, according to A/B tests.
    @particleMan ?= new ParticleMan()
    @particleMan.removeEmitters()
    @particleMan.attach @$el.find('.map')
    for level in @campaign.renderedLevels ? {}
      continue if level.hidden and (@campaign.levelIsPractice(level) or not level.unlockedInSameCampaign)
      terrain = @terrain.replace('-branching-test', '').replace(/(campaign-)?(game|web)-dev-\d/, 'forest').replace(/(intro|game-dev-hoc)/, 'dungeon')
      particleKey = ['level', terrain]
      particleKey.push level.type if level.type and not (level.type in ['hero', 'course'])  # Would use isType, but it's not a Level model
      particleKey.push 'replayable' if level.replayable
      particleKey.push 'premium' if level.requiresSubscription
      particleKey.push 'gate' if level.slug in ['kithgard-gates', 'siege-of-stonehold', 'clash-of-clones', 'summits-gate']
      particleKey.push 'hero' if level.unlocksHero and not level.unlockedHero
      #particleKey.push 'item' if level.slug is 'robot-ragnarok'  # TODO: generalize
      continue if particleKey.length is 2  # Don't show basic levels
      continue unless level.hidden or _.intersection(particleKey, ['item', 'hero-ladder', 'replayable', 'game-dev']).length
      @particleMan.addEmitter level.position.x / 100, level.position.y / 100, particleKey.join('-')

  onMouseEnterPortals: (e) ->
    return unless @campaigns?.loaded and @sessions?.loaded
    @portalScrollInterval = setInterval @onMouseMovePortals, 100
    @onMouseMovePortals e

  onMouseLeavePortals: (e) ->
    return unless @portalScrollInterval
    clearInterval @portalScrollInterval
    @portalScrollInterval = null

  onMouseMovePortals: (e) =>
    return unless @portalScrollInterval
    $portal = @$el.find('.portal')
    $portals = @$el.find('.portals')
    if e
      @portalOffsetX = Math.round Math.max 0, e.clientX - $portal.offset().left
    bodyWidth = $('body').innerWidth()
    fraction = @portalOffsetX / bodyWidth
    return if 0.2 < fraction < 0.8
    direction = if fraction < 0.5 then 1 else -1
    magnitude = 0.2 * bodyWidth * (if direction is -1 then fraction - 0.8 else 0.2 - fraction) / 0.2
    portalsWidth = 2536  # TODO: if we add campaigns or change margins, this will get out of date...
    scrollTo = $portals.offset().left + direction * magnitude
    scrollTo = Math.max bodyWidth - portalsWidth, scrollTo
    scrollTo = Math.min 0, scrollTo
    $portals.stop().animate {marginLeft: scrollTo}, 100, 'linear'

  onSessionsLoaded: (e) ->
    return if @editorMode
    for session in @sessions.models
      unless @levelStatusMap[session.get('levelID')] is 'complete'  # Don't overwrite a complete session with an incomplete one
        @levelStatusMap[session.get('levelID')] = if session.get('state')?.complete then 'complete' else 'started'
      @levelDifficultyMap[session.get('levelID')] = session.get('state').difficulty if session.get('state')?.difficulty
    @render()
    @loadUserPollsRecord() unless me.get('anonymous') or window.serverConfig.picoCTF

  onCampaignsLoaded: (e) ->
    @render()

  preloadLevel: (levelSlug) ->
    levelURL = "/db/level/#{levelSlug}"
    level = new Level().setURL levelURL
    level = @supermodel.loadModel(level, null, 0).model
    sessionURL = "/db/level/#{levelSlug}/session"
    @preloadedSession = new LevelSession().setURL sessionURL
    @listenToOnce @preloadedSession, 'sync', @onSessionPreloaded
    @preloadedSession = @supermodel.loadModel(@preloadedSession, {cache: false}).model
    @preloadedSession.levelSlug = levelSlug

  onSessionPreloaded: (session) ->
    session.url = -> '/db/level.session/' + @id
    levelElement = @$el.find('.level-info-container:visible')
    return unless session.levelSlug is levelElement.data 'level-slug'
    return unless difficulty = session.get('state')?.difficulty
    badge = $("<span class='badge'>#{difficulty}</span>")
    levelElement.find('.start-level .badge').remove()
    levelElement.find('.start-level').append badge

  onClickMap: (e) ->
    @$levelInfo?.hide()
    if @sessions?.models.length < 3
      # Restore the next level higlight for very new players who might otherwise get lost.
      @highlightElement '.level.next', delay: 500, duration: 60000, rotation: 0, sides: ['top']

  onClickLevel: (e) ->
    e.preventDefault()
    e.stopPropagation()
    @$levelInfo?.hide()
    levelElement = $(e.target).parents('.level')
    levelSlug = levelElement.data('level-slug')
    levelOriginal = levelElement.data('level-original')
    if @editorMode
      return @trigger 'level-clicked', levelOriginal
    @$levelInfo = @$el.find(".level-info-container[data-level-slug=#{levelSlug}]").show()
    @checkForCourseOption levelOriginal
    @adjustLevelInfoPosition e
    @endHighlight()
    @preloadLevel levelSlug

  onDoubleClickLevel: (e) ->
    return unless @editorMode
    levelElement = $(e.target).parents('.level')
    levelOriginal = levelElement.data('level-original')
    @trigger 'level-double-clicked', levelOriginal

  onClickStartLevel: (e) ->
    levelElement = $(e.target).parents('.level-info-container')
    levelSlug = levelElement.data('level-slug')
    levelOriginal = levelElement.data('level-original')
    level = _.find _.values(@campaign.get('levels')), slug: levelSlug

    requiresSubscription = level.requiresSubscription or (me.isOnPremiumServer() and not (level.slug in ['dungeons-of-kithgard', 'gems-in-the-deep', 'shadow-guard', 'forgetful-gemsmith', 'signs-and-portents', 'true-names']))
    canPlayAnyway = not @requiresSubscription or level.adventurer or @levelStatusMap[level.slug] or (features.codePlay and codePlay.canPlay(level.slug))
    if requiresSubscription and not canPlayAnyway
      @promptForSubscription levelSlug, 'map level clicked'
    else
      @startLevel levelElement
      window.tracker?.trackEvent 'Clicked Start Level', category: 'World Map', levelID: levelSlug

  onClickCourseVersion: (e) ->
    levelSlug = $(e.target).parents('.level-info-container').data 'level-slug'
    courseID = $(e.target).parents('.course-version').data 'course-id'
    courseInstanceID = $(e.target).parents('.course-version').data 'course-instance-id'
    url = "/play/level/#{levelSlug}?course=#{courseID}&course-instance=#{courseInstanceID}"
    Backbone.Mediator.publish 'router:navigate', route: url

  startLevel: (levelElement) ->
    @setupManager?.destroy()
    levelSlug = levelElement.data 'level-slug'
    session = @preloadedSession if @preloadedSession?.loaded and @preloadedSession.levelSlug is levelSlug
    @setupManager = new LevelSetupManager supermodel: @supermodel, levelID: levelSlug, levelPath: levelElement.data('level-path'), levelName: levelElement.data('level-name'), hadEverChosenHero: @hadEverChosenHero, parent: @, session: session
    unless @setupManager?.navigatingToPlay
      @$levelInfo.find('.level-info, .progress').toggleClass('hide')
      @listenToOnce @setupManager, 'open', ->
        @$levelInfo?.find('.level-info, .progress').toggleClass('hide')
        @$levelInfo?.hide()
      @setupManager.open()

  onClickViewSolutions: (e) ->
    levelElement = $(e.target).parents('.level-info-container')
    levelSlug = levelElement.data('level-slug')
    level = _.find _.values(@campaign.get('levels')), slug: levelSlug
    if level.type in ['hero-ladder', 'course-ladder']  # Would use isType, but it's not a Level model
      Backbone.Mediator.publish 'router:navigate', route: "/play/ladder/#{levelSlug}", viewClass: 'views/ladder/LadderView', viewArgs: [{supermodel: @supermodel}, levelSlug]
    else
      @showLeaderboard levelSlug

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
    if top < 100
      top = mapY + 60
    @$levelInfo.css('top', top)

  onWindowResize: (e) =>
    mapHeight = iPadHeight = 1536
    mapWidth = {dungeon: 2350, forest: 2500, auditions: 2500, desert: 2411, mountain: 2422, glacier: 2421}[@terrain] or 2350
    aspectRatio = mapWidth / mapHeight
    pageWidth = @$el.width()
    pageHeight = @$el.height()
    pageHeight -= adContainerHeight if adContainerHeight = $('.ad-container').outerHeight()
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
    @testParticles() if @particleMan

  playAmbientSound: ->
    return unless me.get 'volume'
    return if @ambientSound
    return unless file = @campaign?.get('ambientSound')?[AudioPlayer.ext.substr 1]
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

  checkForCourseOption: (levelOriginal) ->
    return unless me.get('courseInstances')?.length
    @courseOptionsChecked ?= {}
    return if @courseOptionsChecked[levelOriginal]
    @courseOptionsChecked[levelOriginal] = true
    courseInstances = new CocoCollection [], url: "/db/course_instance/-/find_by_level/#{levelOriginal}", model: CourseInstance
    courseInstances.comparator = (ci) -> return -(ci.get('members') ? []).length
    @supermodel.loadCollection courseInstances, 'course_instances'
    @listenToOnce courseInstances, 'sync', =>
      return if @destroyed
      return unless courseInstance = courseInstances.models[0]
      @$el.find(".course-version[data-level-original='#{levelOriginal}']").removeClass('hidden').data('course-id': courseInstance.get('courseID'), 'course-instance-id': courseInstance.id)

  preloadTopHeroes: ->
    return if window.serverConfig.picoCTF
    for heroID in ['captain', 'knight']
      url = "/db/thang.type/#{ThangType.heroes[heroID]}/version"
      continue if @supermodel.getModel url
      fullHero = new ThangType()
      fullHero.setURL url
      @supermodel.loadModel fullHero

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
      @playAmbientSound() if volume

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

  onClickBack: (e) ->
    Backbone.Mediator.publish 'router:navigate',
      route: "/play"
      viewClass: CampaignView
      viewArgs: [{supermodel: @supermodel}]

  onClickClearStorage: (e) ->
    localStorage.clear()
    noty {
      text: 'Local storage cleared. Reload to view the original campaign.'
      layout: 'topCenter'
      timeout: 5000
      type: 'information'
    }

  updateHero: ->
    return unless hero = me.get('heroConfig')?.thangType
    for slug, original of ThangType.heroes when original is hero
      @$el.find('.player-hero-icon').removeClass().addClass('player-hero-icon ' + slug)
      return
    console.error "CampaignView hero update couldn't find hero slug for original:", hero

  onClickPortalCampaign: (e) ->
    campaign = $(e.target).closest('.campaign, .beta-campaign')
    return if campaign.is('.locked') or campaign.is('.silhouette')
    campaignSlug = campaign.data('campaign-slug')
    if @isPremiumCampaign(campaignSlug) and not me.isPremium()
      return @promptForSubscription campaignSlug, 'premium campaign clicked'
    Backbone.Mediator.publish 'router:navigate',
      route: "/play/#{campaignSlug}"
      viewClass: CampaignView
      viewArgs: [{supermodel: @supermodel}, campaignSlug]

  onClickCampaignSwitch: (e) ->
    campaignSlug = $(e.target).data('campaign-slug')
    console.log campaignSlug, @isPremiumCampaign campaignSlug
    if @isPremiumCampaign(campaignSlug) and not me.isPremium()
      e.preventDefault()
      e.stopImmediatePropagation()
      return @promptForSubscription campaignSlug, 'premium campaign switch clicked'

  loadUserPollsRecord: ->
    url = "/db/user.polls.record/-/user/#{me.id}"
    @userPollsRecord = new UserPollsRecord().setURL url
    onRecordSync = ->
      return if @destroyed
      @userPollsRecord.url = -> '/db/user.polls.record/' + @id
      lastVoted = new Date(@userPollsRecord.get('changed') or 0)
      interval = new Date() - lastVoted
      if interval > 22 * 60 * 60 * 1000  # Wait almost a day before showing the next poll
        @loadPoll()
      else
        console.log 'Poll will be ready in', (22 * 60 * 60 * 1000 - interval) / (60 * 60 * 1000), 'hours.'
    @listenToOnce @userPollsRecord, 'sync', onRecordSync
    @userPollsRecord = @supermodel.loadModel(@userPollsRecord, null, 0).model
    onRecordSync.call @ if @userPollsRecord.loaded

  loadPoll: ->
    url = "/db/poll/#{@userPollsRecord.id}/next"
    @poll = new Poll().setURL url
    onPollSync = ->
      return if @destroyed
      @poll.url = -> '/db/poll/' + @id
      _.delay (=> @activatePoll?()), 1000
    onPollError = (poll, response, request) ->
      if response.status is 404
        console.log 'There are no more polls left.'
      else
        console.error "Couldn't load poll:", response.status, response.statusText
      delete @poll
    @listenToOnce @poll, 'sync', onPollSync
    @listenToOnce @poll, 'error', onPollError
    @poll = @supermodel.loadModel(@poll, null, 0).model
    onPollSync.call @ if @poll.loaded

  activatePoll: ->
    pollTitle = utils.i18n @poll.attributes, 'name'
    $pollButton = @$el.find('button.poll').removeClass('hidden').addClass('highlighted').attr(title: pollTitle).addClass('has-tooltip').tooltip title: pollTitle
    if me.get('lastLevel') is 'shadow-guard'
      @showPoll()
    else
      $pollButton.tooltip 'show'

  showPoll: ->
    pollModal = new PollModal supermodel: @supermodel, poll: @poll, userPollsRecord: @userPollsRecord
    @openModalView pollModal
    $pollButton = @$el.find 'button.poll'
    pollModal.on 'vote-updated', ->
      $pollButton.removeClass('highlighted').tooltip 'hide'


  getLoadTrackingTag: () ->
    @campaign?.get?('slug') or 'overworld'

  mergeWithPrerendered: (el) ->
    true

  checkForUnearnedAchievements: ->
    return unless @campaign
    
    # Another layer attempting to make sure users unlock levels properly.
    
    # Every time the user goes to the campaign view (after initial load),
    # load achievements for that campaign.
    # Look for any achievements where the related level is complete, but
    # the reward level is not earned.
    # Try to create EarnedAchievements for each such Achievement found.
    
    achievements = new Achievements()
    
    achievements.fetchForCampaign(
      @campaign.get('slug'),
      { data: { project: 'related,rewards,name' } })
    
    .done((achievements) =>
      return if @destroyed
      sessionsComplete = _(currentView.sessions.models)
        .filter (s) => s.get('levelID')
        .filter (s) => s.get('state') && s.get('state').complete
        .map (s) => [s.get('levelID'), s.id]
        .value()

      sessionsCompleteMap = _.zipObject(sessionsComplete)
      
      campaignLevels = @campaign.get('levels')
      
      levelsEarned = _(me.get('earned')?.levels)
        .filter (levelOriginal) => campaignLevels[levelOriginal]
        .map (levelOriginal) => campaignLevels[levelOriginal].slug
        .filter()
        .value()

      levelsEarnedMap = _.zipObject(
        levelsEarned,
        _.times(levelsEarned.length, -> true)
      )
      
      levelAchievements = _.filter(achievements, 
        (a) -> a.rewards && a.rewards.levels && a.rewards.levels.length)
      
      for achievement in levelAchievements
        continue unless campaignLevels[achievement.related]
        relatedLevelSlug = campaignLevels[achievement.related].slug
        for levelOriginal in achievement.rewards.levels
          continue unless campaignLevels[levelOriginal]
          rewardLevelSlug = campaignLevels[levelOriginal].slug
          if sessionsCompleteMap[relatedLevelSlug] and not levelsEarnedMap[rewardLevelSlug]
            ea = new EarnedAchievement({
              achievement: achievement._id,
              triggeredBy: sessionsCompleteMap[relatedLevelSlug],
              collection: 'level.sessions'
            })
            ea.notyErrors = false
            ea.save()
            .error ->
              console.warn 'Achievement NOT complete:', achievement.name
    )
