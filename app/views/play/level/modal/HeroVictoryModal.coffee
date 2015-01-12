ModalView = require 'views/core/ModalView'
AuthModal = require 'views/core/AuthModal'
template = require 'templates/play/level/modal/hero-victory-modal'
Achievement = require 'models/Achievement'
EarnedAchievement = require 'models/EarnedAchievement'
CocoCollection = require 'collections/CocoCollection'
LocalMongo = require 'lib/LocalMongo'
utils = require 'core/utils'
ThangType = require 'models/ThangType'
LadderSubmissionView = require 'views/play/common/LadderSubmissionView'
AudioPlayer = require 'lib/AudioPlayer'
User = require 'models/User'
utils = require 'core/utils'

module.exports = class HeroVictoryModal extends ModalView
  id: 'hero-victory-modal'
  template: template
  closeButton: false
  closesOnClickOutside: false

  subscriptions:
    'ladder:game-submitted': 'onGameSubmitted'

  events:
    'click #continue-button': 'onClickContinue'
    'click .return-to-ladder-button': 'onClickReturnToLadder'
    'click .sign-up-button': 'onClickSignupButton'

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
    @previousXP = me.get 'points', true
    @previousLevel = me.level()
    Backbone.Mediator.publish 'audio-player:play-sound', trigger: 'victory'

  destroy: ->
    clearInterval @sequentialAnimationInterval
    super()

  onHidden: ->
    Backbone.Mediator.publish 'music-player:exit-menu', {}
    super()

  onAchievementsLoaded: ->
    @$el.toggleClass 'full-achievements', @achievements.models.length is 3
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

    @newEarnedAchievements = []
    for achievement in @achievements.models
      continue unless achievement.completed
      ea = new EarnedAchievement({
        collection: achievement.get('collection')
        triggeredBy: @session.id
        achievement: achievement.id
      })
      ea.save()
      @newEarnedAchievements.push ea
      @listenToOnce ea, 'sync', ->
        if _.all((ea.id for ea in @newEarnedAchievements))
          @newEarnedAchievementsResource.markLoaded()
          @listenToOnce me, 'sync', ->
            @readyToContinue = true
            @updateSavingProgressStatus()
          me.fetch cache: false unless me.loading

    @readyToContinue = true if not @achievements.models.length
    
    # have to use a something resource because addModelResource doesn't handle models being upserted/fetched via POST like we're doing here
    @newEarnedAchievementsResource = @supermodel.addSomethingResource('earned achievements') if @newEarnedAchievements.length

  getRenderData: ->
    c = super()
    c.levelName = utils.i18n @level.attributes, 'name'
    earnedAchievementMap = _.indexBy(@newEarnedAchievements or [], (ea) -> ea.get('achievement'))
    for achievement in @achievements.models
      earnedAchievement = earnedAchievementMap[achievement.id]
      if earnedAchievement
        achievement.completedAWhileAgo = new Date().getTime() - Date.parse(earnedAchievement.get('created')) > 30 * 1000
      achievement.worth = achievement.get 'worth', true
      achievement.gems = achievement.get('rewards')?.gems
    c.achievements = @achievements.models.slice()
    for achievement in c.achievements
      continue unless @supermodel.finished() and proportionalTo = achievement.get 'proportionalTo'
      # For repeatable achievements, we modify their base worth/gems by their repeatable growth functions.
      achievedAmount = utils.getByPath @session.attributes, proportionalTo
      func = achievement.getExpFunction()
      achievement.worth = (achievement.get('worth') ? 0) * func achievedAmount
      rewards = achievement.get 'rewards'
      achievement.gems = rewards?.gems * func achievedAmount if rewards?.gems

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

    elapsed = (new Date() - new Date(me.get('dateCreated')))
    isHourOfCode = me.get('hourOfCode') or elapsed < 120 * 60 * 1000
    # Later we should only check me.get('hourOfCode'), but for now so much traffic comes in that we just assume it.
    if isHourOfCode
      # Show the Hour of Code "I'm Done" tracking pixel after they played for 20 minutes
      enough = elapsed >= 20 * 60 * 1000
      tooMuch = elapsed > 120 * 60 * 1000
      showDone = elapsed >= 30 * 60 * 1000 and not tooMuch
      if enough and not tooMuch and not me.get('hourOfCodeComplete')
        $('body').append($('<img src="http://code.org/api/hour/finish_codecombat.png" style="visibility: hidden;">'))
        me.set 'hourOfCodeComplete', true  # Note that this will track even for players who don't have hourOfCode set.
        me.patch()
        window.tracker?.trackEvent 'Hour of Code Finish', {}
      # Show the "I'm done" button between 30 - 120 minutes if they definitely came from Hour of Code
      c.showHourOfCodeDoneButton = me.get('hourOfCode') and showDone

    return c

  afterRender: ->
    super()
    return unless @supermodel.finished()
    @playSelectionSound hero, true for original, hero of @thangTypes  # Preload them
    @updateSavingProgressStatus()
    @updateXPBars 0
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
    return if @destroyed
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
        @XPEl.text(totalXP)
        @updateXPBars(totalXP)
        xpTrigger = 'xp-' + (totalXP % 6)  # 6 xp sounds
        Backbone.Mediator.publish 'audio-player:play-sound', trigger: xpTrigger, volume: 0.5 + ratio / 2
        @lastTotalXP = totalXP
    else if panel.unit is 'gem'
      newGems = Math.floor(ratio * panel.number)
      totalGems = @totalGemsAnimated + newGems
      if totalGems isnt @lastTotalGems
        panel.textEl.text('+' + newGems)
        @gemEl.text(totalGems)
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

  updateXPBars: (achievedXP) ->
    previousXP = @previousXP
    previousLevel = @previousLevel

    currentXP = previousXP + achievedXP
    currentLevel = User.levelFromExp currentXP
    currentLevelXP = User.expForLevel currentLevel

    nextLevel = currentLevel + 1
    nextLevelXP = User.expForLevel nextLevel

    leveledUp = currentLevel > previousLevel
    totalXPNeeded = nextLevelXP - currentLevelXP
    alreadyAchievedPercentage = 100 * (previousXP - currentLevelXP) / totalXPNeeded
    alreadyAchievedPercentage = 0 if alreadyAchievedPercentage < 0  # In case of level up
    if leveledUp
      newlyAchievedPercentage = 100 * (currentXP - currentLevelXP) / totalXPNeeded
    else
      newlyAchievedPercentage = 100 * achievedXP / totalXPNeeded

    xpEl = $('#xp-wrapper')
    xpBarJustEarned = xpEl.find('.xp-bar-already-achieved').css('width', alreadyAchievedPercentage + '%')
    xpBarTotal = xpEl.find('.xp-bar-total').css('width', (alreadyAchievedPercentage + newlyAchievedPercentage) + '%')
    levelLabel = xpEl.find('.level')
    utils.replaceText levelLabel, currentLevel

    if leveledUp and (not @displayedLevel or currentLevel > @displayedLevel)
      @playSound 'level-up'
    @displayedLevel = currentLevel

  endSequentialAnimations: ->
    clearInterval @sequentialAnimationInterval
    @animationComplete = true
    @updateSavingProgressStatus()
    Backbone.Mediator.publish 'music-player:enter-menu', terrain: @level.get('terrain', true)

  updateSavingProgressStatus: ->
    @$el.find('#saving-progress-label').toggleClass('hide', @readyToContinue)
    @$el.find('.next-level-button').toggleClass('hide', not @readyToContinue)
    @$el.find('.sign-up-poke').toggleClass('hide', not @readyToContinue)

  onGameSubmitted: (e) ->
    ladderURL = "/play/ladder/#{@level.get('slug')}#my-matches"
    # Preserve the supermodel as we navigate back to the ladder.
    Backbone.Mediator.publish 'router:navigate', route: ladderURL, viewClass: 'views/ladder/LadderView', viewArgs: [{supermodel: @supermodel}, @level.get('slug')]

  playSelectionSound: (hero, preload=false) ->
    return unless sounds = hero.get('soundTriggers')?.selected
    return unless sound = sounds[Math.floor Math.random() * sounds.length]
    name = AudioPlayer.nameForSoundReference sound
    if preload
      AudioPlayer.preloadSoundReference sound
    else
      AudioPlayer.playSound name, 1

  getNextLevelCampaign: ->
    {'kithgard-gates': 'forest', 'siege-of-stonehold': 'desert'}[@level.get('slug')] or @level.get 'campaign'  # Much easier to just keep this updated than to dynamically figure it out.

  getNextLevelLink: ->
    link = '/play'
    nextCampaign = @getNextLevelCampaign()
    link += '/' + nextCampaign unless nextCampaign is 'dungeon'
    link

  onClickContinue: (e) ->
    @playSound 'menu-button-click'
    nextLevelLink = @getNextLevelLink()
    # Preserve the supermodel as we navigate back to the world map.
    Backbone.Mediator.publish 'router:navigate', route: nextLevelLink, viewClass: require('views/play/CampaignView'), viewArgs: [{supermodel: if @options.hasReceivedMemoryWarning then null else @supermodel}, @getNextLevelCampaign()]

  onClickReturnToLadder: (e) ->
    @playSound 'menu-button-click'
    e.preventDefault()
    route = $(e.target).data('href')
    # Preserve the supermodel as we navigate back to the ladder.
    Backbone.Mediator.publish 'router:navigate', route: route, viewClass: 'views/ladder/LadderView', viewArgs: [{supermodel: if @options.hasReceivedMemoryWarning then null else @supermodel}, @level.get('slug')]

  onClickSignupButton: (e) ->
    e.preventDefault()
    window.tracker?.trackEvent 'Started Signup', category: 'Play Level', label: 'Hero Victory Modal', level: @level.get('slug')
    @openModalView new AuthModal {mode: 'signup'}
