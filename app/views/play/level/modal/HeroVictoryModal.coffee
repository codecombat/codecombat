ModalView = require 'views/kinds/ModalView'
template = require 'templates/play/level/modal/hero-victory-modal'
Achievement = require 'models/Achievement'
EarnedAchievement = require 'models/EarnedAchievement'
CocoCollection = require 'collections/CocoCollection'
LocalMongo = require 'lib/LocalMongo'
utils = require 'lib/utils'
ThangType = require 'models/ThangType'
LadderSubmissionView = require 'views/play/common/LadderSubmissionView'
AudioPlayer = require 'lib/AudioPlayer'

module.exports = class HeroVictoryModal extends ModalView
  id: 'hero-victory-modal'
  template: template
  closeButton: false
  closesOnClickOutside: false

  subscriptions:
    'ladder:game-submitted': 'onGameSubmitted'

  events:
    'click #continue-button': 'onClickContinue'
    'click .next-level-branch-button': 'onClickNextLevelBranch'
    'click .return-to-ladder-button': 'onClickReturnToLadder'

  constructor: (options) ->
    super(options)
    @session = options.session
    @level = options.level
    achievements = new CocoCollection([], {
      url: "/db/achievement?related=#{@session.get('level').original}"
      model: Achievement
    })
    @thangTypes = {}
    @achievements = @supermodel.loadCollection(achievements, 'achievements').model
    @listenToOnce @achievements, 'sync', @onAchievementsLoaded
    @readyToContinue = false
    @waitingToContinueSince = new Date()
    Backbone.Mediator.publish 'audio-player:play-sound', trigger: 'victory'

  destroy: ->
    clearInterval @sequentialAnimationInterval
    super()

  onHidden: ->
    Backbone.Mediator.publish 'music-player:exit-menu', {}
    super()

  onAchievementsLoaded: ->
    thangTypeOriginals = []
    achievementIDs = []
    for achievement in @achievements.models
      rewards = achievement.get('rewards') or {}
      thangTypeOriginals.push rewards.heroes or []
      thangTypeOriginals.push rewards.items or []
      achievement.completed = LocalMongo.matchesQuery(@session.attributes, achievement.get('query'))
      achievementIDs.push(achievement.id) if achievement.completed

    thangTypeOriginals = _.uniq _.flatten thangTypeOriginals
    for thangTypeOriginal in thangTypeOriginals
      thangType = new ThangType()
      thangType.url = "/db/thang.type/#{thangTypeOriginal}/version"
      thangType.project = ['original', 'rasterIcon', 'name', 'soundTriggers']
      @thangTypes[thangTypeOriginal] = @supermodel.loadModel(thangType, 'thang').model

    if achievementIDs.length
      url = "/db/earned_achievement?view=get-by-achievement-ids&achievementIDs=#{achievementIDs.join(',')}"
      earnedAchievements = new CocoCollection([], {
        url: url
        model: EarnedAchievement
      })
      earnedAchievements.sizeShouldBe = achievementIDs.length
      res = @supermodel.loadCollection(earnedAchievements, 'earned_achievements')
      @earnedAchievements = res.model
      @listenTo @earnedAchievements, 'sync', ->
        if (new Date() - @waitingToContinueSince) > 20 * 1000
          # In case there is some network problem, like we saw with CloudFlare + school proxies, we'll let them keep playing.
          application.tracker?.trackEvent 'Unlocking Failed', level: @level.get('slug'), label: @level.get('slug')
          window.levelUnlocksNotWorking = true
          @readyToContinue = true
          @updateSavingProgressStatus()
        else if @earnedAchievements.models.length < @earnedAchievements.sizeShouldBe
          @earnedAchievements.fetch()
        else
          @listenToOnce me, 'sync', ->
            @readyToContinue = true
            @updateSavingProgressStatus()
          me.fetch() unless me.loading
    else
      @readyToContinue = true

  getRenderData: ->
    c = super()
    c.levelName = utils.i18n @level.attributes, 'name'
    earnedAchievementMap = _.indexBy(@earnedAchievements?.models or [], (ea) -> ea.get('achievement'))
    for achievement in @achievements.models
      earnedAchievement = earnedAchievementMap[achievement.id]
      if earnedAchievement
        achievement.completedAWhileAgo = new Date() - Date.parse(earnedAchievement.get('created')) > 30 * 1000
    c.achievements = @achievements.models

    # for testing the three states
    #if c.achievements.length
    #  c.achievements = [c.achievements[0].clone(), c.achievements[0].clone(), c.achievements[0].clone()]
    #for achievement, index in c.achievements
    ##  achievement.completed = index > 0
    ##  achievement.completedAWhileAgo = index > 1
    #  achievement.completed = true
    #  achievement.completedAWhileAgo = false
    #  achievement.attributes.worth = (index + 1) * achievement.get('worth', true)
    #  rewards = achievement.get('rewards') or {}
    #  rewards.gems *= (index + 1)

    c.thangTypes = @thangTypes
    c.me = me
    c.readyToRank = @level.get('type', true) is 'hero-ladder' and @session.readyToRank()
    c.level = @level
    @continueLevelLink = @getNextLevelLink 'continue'
    @morePracticeLevelLink = me.isAdmin() and @getNextLevelLink 'more_practice'
    @skipAheadLevelLink = me.isAdmin() and @getNextLevelLink 'skip_ahead'
    c.continueButtons = [
      {key: 'skip_ahead', link: @skipAheadLevelLink, 'choice-explicit': 'skip', 'choice-implicit': 'too_easy'}
      {key: 'continue', link: @continueLevelLink, 'choice-explicit': 'next_level', 'choice-implicit': 'just_right'}
      {key: 'more_practice', link: @morePracticeLevelLink, 'choice-explicit': 'more_practice', 'choice-implicit': 'too_hard'}
    ]
    return c

  afterRender: ->
    super()
    return unless @supermodel.finished()
    @playSelectionSound hero, true for original, hero of @thangTypes  # Preload them
    @updateSavingProgressStatus()
    @$el.find('#victory-header').delay(250).queue(->
      $(@).removeClass('out').dequeue()
      Backbone.Mediator.publish 'audio-player:play-sound', trigger: 'victory-title-appear'  # TODO: actually add this
    )
    complete = _.once(_.bind(@beginSequentialAnimations, @))
    @animatedPanels = $()
    panels = @$el.find('.achievement-panel')
    for panel in panels
      panel = $(panel)
      continue unless panel.data('animate')
      @animatedPanels = @animatedPanels.add(panel)
      panel.delay(500)  # Waiting for victory header to show up and fall
      panel.queue(->
        $(@).addClass('earned') # animate out the grayscale
        $(@).dequeue()
      )
      panel.delay(500)
      panel.queue(->
        $(@).find('.reward-image-container').addClass('show')
        $(@).dequeue()
      )
      panel.delay(500)
      panel.queue(-> complete())
    @animationComplete = not @animatedPanels.length
    complete() if @animationComplete
    if @level.get('type', true) is 'hero-ladder'
      @ladderSubmissionView = new LadderSubmissionView session: @session, level: @level
      @insertSubView @ladderSubmissionView, @$el.find('.ladder-submission-view')

  beginSequentialAnimations: ->
    @sequentialAnimatedPanels = _.map(@animatedPanels.find('.reward-panel'), (panel) -> {
      number: $(panel).data('number')
      textEl: $(panel).find('.reward-text')
      rootEl: $(panel)
      unit: $(panel).data('number-unit')
      hero: $(panel).data('hero-thang-type')
      item: $(panel).data('item-thang-type')
    })

    @totalXP = 0
    @totalXP += panel.number for panel in @sequentialAnimatedPanels when panel.unit is 'xp'
    @totalGems = 0
    @totalGems += panel.number for panel in @sequentialAnimatedPanels when panel.unit is 'gem'
    @gemEl = $('#gem-total')
    @XPEl = $('#xp-total')
    @totalXPAnimated = @totalGemsAnimated = @lastTotalXP = @lastTotalGems = 0
    @sequentialAnimationStart = new Date()
    @sequentialAnimationInterval = setInterval(@tickSequentialAnimation, 1000 / 60)

  tickSequentialAnimation: =>
    # TODO: make sure the animation pulses happen when the numbers go up and sounds play (up to a max speed)
    return @endSequentialAnimations() unless panel = @sequentialAnimatedPanels[0]
    if panel.number
      duration = Math.log(panel.number + 1) / Math.LN10 * 1000  # Math.log10 is ES6
    else
      duration = 1000
    ratio = @getEaseRatio (new Date() - @sequentialAnimationStart), duration
    if panel.unit is 'xp'
      newXP = Math.floor(ratio * panel.number)
      totalXP = @totalXPAnimated + newXP
      if totalXP isnt @lastTotalXP
        panel.textEl.text('+' + newXP)
        @XPEl.text('+' + totalXP)
        xpTrigger = 'xp-' + (totalXP % 6)  # 6 xp sounds
        Backbone.Mediator.publish 'audio-player:play-sound', trigger: xpTrigger, volume: 0.5 + ratio / 2
        @lastTotalXP = totalXP
    else if panel.unit is 'gem'
      newGems = Math.floor(ratio * panel.number)
      totalGems = @totalGemsAnimated + newGems
      if totalGems isnt @lastTotalGems
        panel.textEl.text('+' + newGems)
        @gemEl.text('+' + totalGems)
        gemTrigger = 'gem-' + (parseInt(panel.number * ratio) % 4)  # 4 gem sounds
        Backbone.Mediator.publish 'audio-player:play-sound', trigger: gemTrigger, volume: 0.5 + ratio / 2
        @lastTotalGems = totalGems
    else if panel.item
      thangType = @thangTypes[panel.item]
      panel.textEl.text(thangType.get('name'))
      Backbone.Mediator.publish 'audio-player:play-sound', trigger: 'item-unlocked', volume: 1 if 0.5 < ratio < 0.6
    else if panel.hero
      thangType = @thangTypes[panel.hero]
      panel.textEl.text(thangType.get('name'))
      @playSelectionSound thangType if 0.5 < ratio < 0.6
    if ratio is 1
      panel.rootEl.removeClass('animating').find('.reward-image-container img').removeClass('pulse')
      @sequentialAnimationStart = new Date()
      if panel.unit is 'xp'
        @totalXPAnimated += panel.number
      else if panel.unit is 'gem'
        @totalGemsAnimated += panel.number
      @sequentialAnimatedPanels.shift()
      return
    panel.rootEl.addClass('animating').find('.reward-image-container').removeClass('pending-reward-image').find('img').addClass('pulse')

  getEaseRatio: (timeSinceStart, duration) ->
    # Ease in/out quadratic - http://gizma.com/easing/
    timeSinceStart = Math.min timeSinceStart, duration
    t = 2 * timeSinceStart / duration
    if t < 1
      return 0.5 * t * t
    --t
    -0.5 * (t * (t - 2) - 1)

  endSequentialAnimations: ->
    clearInterval @sequentialAnimationInterval
    @animationComplete = true
    @updateSavingProgressStatus()
    Backbone.Mediator.publish 'music-player:enter-menu', terrain: @level.get('terrain', true)

  updateSavingProgressStatus: ->
    return unless @animationComplete
    @$el.find('#saving-progress-label').toggleClass('hide', @readyToContinue)
    @$el.find('.next-level-button').toggleClass('hide', not @readyToContinue)
    @$el.find('.sign-up-poke').toggleClass('hide', not @readyToContinue)

  onGameSubmitted: (e) ->
    ladderURL = "/play/ladder/#{@level.get('slug')}#my-matches"
    # Preserve the supermodel as we navigate back to the ladder.
    Backbone.Mediator.publish 'router:navigate', route: ladderURL, viewClass: require('views/play/ladder/LadderView'), viewArgs: [{supermodel: @supermodel}]

  playSelectionSound: (hero, preload=false) ->
    return unless sounds = hero.get('soundTriggers')?.selected
    return unless sound = sounds[Math.floor Math.random() * sounds.length]
    name = AudioPlayer.nameForSoundReference sound
    if preload
      AudioPlayer.preloadSoundReference sound
    else
      AudioPlayer.playSound name, 1

  # Branching group testing

  getNextLevel: (type) ->
    for campaign in require('views/play/WorldMapView').campaigns
      break if levelInfo
      for level in campaign.levels
        if level.id is @level.get 'slug'
          levelInfo = level
          break
    levelInfo?.nextLevels?[type]  # 'more_practice', 'skip_ahead', 'continue'

  getNextLevelMap: ->
    # TODO: dynamically figure out which world map to return to
    if @level.get('slug') in ['kithgard-gates', 'defense-of-plainswood', 'winding-trail', 'thornbush-farm', 'a-fiery-trap']
      return 'forest'
    return 'dungeon'

  getNextLevelLink: (type) ->
    link = '/play'
    nextMap = @getNextLevelMap()
    link += '/' + nextMap unless nextMap is 'dungeon'
    return link unless nextLevel = @getNextLevel type
    "#{link}?next=#{nextLevel}"

  onClickContinue: (e) ->
    nextLevelLink = @continueLevelLink
    if me.getBranchingGroup() is 'all-practice' and @morePracticeLevelLink
      nextLevelLink = @morePracticeLevelLink
    skipPrompt = me.getBranchingGroup() in ['no-practice', 'all-practice']
    skipPrompt ||= not (@skipAheadLevelLink or @morePractiveLevelLink) and me.getBranchingGroup() is 'choice-explicit'
    if skipPrompt
      # Preserve the supermodel as we navigate back to the world map.
      Backbone.Mediator.publish 'router:navigate', route: nextLevelLink, viewClass: require('views/play/WorldMapView'), viewArgs: [{supermodel: @supermodel}, @getNextLevelMap()]
    else
      # Hide everything except the buttons prompting them for which kind of next level to do
      @$el.find('.modal-footer, .modal-body > *').hide()
      @$el.find('.next-levels-prompt').show()

  onClickNextLevelBranch: (e) ->
    e.preventDefault()
    route = $(e.target).data('href') or "/play/#{@getNextLevelMap()}"
    application.tracker?.trackEvent 'Branch Selected', level: @level.get('slug'), label: @level.get('slug'), branch: $(e.target).data('branch-key'), branchingGroup: me.getBranchingGroup(), route: route
    # Preserve the supermodel as we navigate back to world map.
    console.log 'would navigate to', route
    Backbone.Mediator.publish 'router:navigate', route: route, viewClass: require('views/play/WorldMapView'), viewArgs: [{supermodel: @supermodel}, @getNextLevelMap()]

  onClickReturnToLadder: (e) ->
    e.preventDefault()
    route = $(e.target).data('href')
    # Preserve the supermodel as we navigate back to the ladder.
    Backbone.Mediator.publish 'router:navigate', route: route, viewClass: require('views/play/ladder/LadderView'), viewArgs: [{supermodel: @supermodel}, @level.get('slug')]
