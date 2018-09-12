require('app/styles/play/level/modal/course-rewards-view.sass')
CocoView = require 'views/core/CocoView'
ThangType = require 'models/ThangType'
EarnedAchievement = require 'models/EarnedAchievement'
utils = require 'core/utils'
User = require 'models/User'

# This view is to show gems/xp/items earned after completing a level in classroom version.
# It is similar to that on HeroVictoryModal for home version, but excluding some which is not required here.
# TODO: Move this into a reusable component to be used by both home and classroom versions.

module.exports = class CourseRewardsView extends CocoView
  id: 'course-rewards-view'
  className: 'modal-content' 
  template: require('templates/play/level/modal/course-rewards-view')
  
  events:
    'click #continue-btn': 'onClickContinueButton'
    
  initialize: (options) ->
    super()
    @level = options.level
    @session = options.session
    @thangTypes = {}
    @achievements = options.achievements

  render: ->
    @loadAchievementsData()
    @previousXP = me.get 'points', true
    @previousLevel = me.level()
    super()

  afterRender: ->
    super()
    @initializeAnimations()

  onClickContinueButton: ->
    @trigger 'continue'

  loadAchievementsData: ->
    itemOriginals = []
    for achievement in @achievements.models
      rewards = achievement.get('rewards') or {}
      itemOriginals.push rewards.items or []

    # get the items earned from achievements
    itemOriginals = _.uniq _.flatten itemOriginals
    for itemOriginal in itemOriginals
      thangType = new ThangType()
      thangType.url = "/db/thang.type/#{itemOriginal}/version"
      thangType.project = ['original', 'rasterIcon', 'name', 'slug', 'soundTriggers', 'featureImages', 'gems', 'heroClass', 'description', 'components', 'extendedName', 'shortName', 'unlockLevelName', 'i18n', 'subscriber']
      @thangTypes[itemOriginal] = @supermodel.loadModel(thangType).model

    @newEarnedAchievements = []
    for achievement in @achievements.models
      continue unless achievement.completed
      ea = new EarnedAchievement({
        collection: achievement.get('collection')
        triggeredBy: @session.id
        achievement: achievement.id
      })
      if me.isSessionless()
        @newEarnedAchievements.push ea
      else
        ea.save()
        # Can't just add models to supermodel because each ea has the same url
        @newEarnedAchievements.push ea
        @listenToOnce ea, 'sync', (model) ->
          if _.all((ea.id for ea in @newEarnedAchievements))
            unless me.loading
              @supermodel.loadModel(me, {cache: false})
            @newEarnedAchievementsResource.markLoaded()
          me.fetch cache: false unless me.loading

    unless me.isSessionless()
      # have to use a something resource because addModelResource doesn't handle models being upserted/fetched via POST like we're doing here
      @newEarnedAchievementsResource = @supermodel.addSomethingResource('earned achievements') if @newEarnedAchievements.length

  getRenderData: ->
    c = super()
    # get the gems and xp earned from the achievements
    earnedAchievementMap = _.indexBy(@newEarnedAchievements or [], (ea) -> ea.get('achievement'))
    for achievement in (@achievements?.models or [])
      earnedAchievement = earnedAchievementMap[achievement.id]
      if earnedAchievement
        achievement.completedAWhileAgo = new Date().getTime() - Date.parse(earnedAchievement.attributes.changed) > 30 * 1000
      achievement.worth = achievement.get 'worth', true
      achievement.gems = achievement.get('rewards')?.gems
    c.achievements = @achievements?.models.slice() or []
    for achievement in c.achievements
      achievement.description = utils.i18n achievement.attributes, 'description'
      continue unless @supermodel.finished() and proportionalTo = achievement.get 'proportionalTo'
      # For repeatable achievements, we modify their base worth/gems by their repeatable growth functions.
      achievedAmount = utils.getByPath @session.attributes, proportionalTo
      previousAmount = Math.max(0, achievedAmount - 1)
      func = achievement.getExpFunction()
      achievement.previousWorth = (achievement.get('worth') ? 0) * func previousAmount
      achievement.worth = (achievement.get('worth') ? 0) * func achievedAmount
      rewards = achievement.get 'rewards'
      achievement.gems = rewards?.gems * func achievedAmount if rewards?.gems
      achievement.previousGems = rewards?.gems * func previousAmount if rewards?.gems

    c.thangTypes = @thangTypes
    return c

  initializeAnimations: ->
    return @endSequentialAnimations() unless @level.isType('course', 'hero', 'course-ladder', 'game-dev', 'web-dev')
    complete = _.once(_.bind(@beginSequentialAnimations, @))
    @animatedPanels = $()
    panels = @$el.find('.achievement-panel')
    for panel in panels
      panel = $(panel)
      continue unless panel.data('animate')?
      @animatedPanels = @animatedPanels.add(panel)
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

  beginSequentialAnimations: ->
    return if @destroyed
    return unless @level.isType('course', 'hero', 'course-ladder', 'game-dev', 'web-dev')
    @sequentialAnimatedPanels = _.map(@animatedPanels.find('.reward-panel'), (panel) -> {
      number: $(panel).data('number')
      previousNumber: $(panel).data('previous-number')
      textEl: $(panel).find('.reward-text')
      rootEl: $(panel)
      unit: $(panel).data('number-unit')
      item: $(panel).data('item-thang-type')
    })

    @totalXP = 0
    @totalXP += panel.number for panel in @sequentialAnimatedPanels when panel.unit is 'xp'
    @totalGems = 0
    @totalGems += panel.number for panel in @sequentialAnimatedPanels when panel.unit is 'gem'
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
      newXP = Math.floor(ratio * (panel.number - panel.previousNumber))
      totalXP = @totalXPAnimated + newXP
      if totalXP isnt @lastTotalXP
        panel.textEl.text('+' + newXP)
        xpTrigger = 'xp-' + (totalXP % 6)  # 6 xp sounds
        @playSound xpTrigger, (0.5 + ratio / 2)
        @lastTotalXP = totalXP
    else if panel.unit is 'gem'
      newGems = Math.floor(ratio * (panel.number - panel.previousNumber))
      totalGems = @totalGemsAnimated + newGems
      if totalGems isnt @lastTotalGems
        panel.textEl.text('+' + newGems)
        gemTrigger = 'gem-' + (parseInt(panel.number * ratio) % 4)  # 4 gem sounds
        @playSound gemTrigger, (0.5 + ratio / 2)
        @lastTotalGems = totalGems
    else if panel.item
      thangType = @thangTypes[panel.item]
      panel.textEl.text utils.i18n(thangType.attributes, 'name')
      @playSound 'item-unlocked' if 0.5 < ratio < 0.6
    if ratio is 1
      panel.rootEl.removeClass('animating').find('.reward-image-container img').removeClass('pulse')
      @sequentialAnimationStart = new Date()
      if panel.unit is 'xp'
        @totalXPAnimated += panel.number - panel.previousNumber
      else if panel.unit is 'gem'
        @totalGemsAnimated += panel.number - panel.previousNumber
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
    Backbone.Mediator.publish 'music-player:enter-menu', terrain: @level.get('terrain', true) or 'forest'