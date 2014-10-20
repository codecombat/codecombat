ModalView = require 'views/kinds/ModalView'
template = require 'templates/play/level/modal/hero-victory-modal'
Achievement = require 'models/Achievement'
EarnedAchievement = require 'models/EarnedAchievement'
CocoCollection = require 'collections/CocoCollection'
LocalMongo = require 'lib/LocalMongo'
utils = require 'lib/utils'
ThangType = require 'models/ThangType'
LadderSubmissionView = require 'views/play/common/LadderSubmissionView'

module.exports = class HeroVictoryModal extends ModalView
  id: 'hero-victory-modal'
  template: template
  closeButton: false
  closesOnClickOutside: false

  subscriptions:
    'ladder:game-submitted': 'onGameSubmitted'

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
    Backbone.Mediator.publish 'audio-player:play-sound', trigger: 'victory'

  onAchievementsLoaded: ->
    thangTypeOriginals = []
    achievementIDs = []
    for achievement in @achievements.models
      rewards = achievement.get('rewards')
      thangTypeOriginals.push rewards.heroes or []
      thangTypeOriginals.push rewards.items or []
      achievement.completed = LocalMongo.matchesQuery(@session.attributes, achievement.get('query'))
      achievementIDs.push(achievement.id) if achievement.completed

    thangTypeOriginals = _.uniq _.flatten thangTypeOriginals
    for thangTypeOriginal in thangTypeOriginals
      thangType = new ThangType()
      thangType.url = "/db/thang.type/#{thangTypeOriginal}/version"
      thangType.project = ['original', 'rasterIcon', 'name']
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
        if @earnedAchievements.models.length < @earnedAchievements.sizeShouldBe
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
    #  achievement.attributes.worth = (index + 1) * achievement.get('worth')
    #  rewards = achievement.get('rewards')
    #  rewards.gems *= (index + 1)

    c.thangTypes = @thangTypes
    c.me = me
    c.readyToRank = @level.get('type', true) is 'hero-ladder' and @session.readyToRank()
    return c

  afterRender: ->
    super()
    return unless @supermodel.finished()
    @$el.addClass 'with-sign-up' if me.get('anonymous')
    @updateSavingProgressStatus()
    @$el.find('#victory-header').delay(250).queue(-> $(@).removeClass('out').dequeue())
    complete = _.once(_.bind(@beginAnimateNumbers, @))
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
    if @level.get('type', true) is 'hero-ladder'
      @ladderSubmissionView = new LadderSubmissionView session: @session, level: @level
      @insertSubView @ladderSubmissionView, @$el.find('.ladder-submission-view')

  beginAnimateNumbers: ->
    @numericalItemPanels = _.map(@animatedPanels.find('.numerical'), (panel) -> {
      number: $(panel).data('number')
      textEl: $(panel).find('.reward-text')
      rootEl: $(panel)
      unit: $(panel).data('number-unit')
    })

    @totalXP = 0
    @totalXP += panel.number for panel in @numericalItemPanels when panel.unit is 'xp'
    @totalGems = 0
    @totalGems += panel.number for panel in @numericalItemPanels when panel.unit is 'gem'
    @gemEl = $('#gem-total')
    @XPEl = $('#xp-total')
    @totalXPAnimated = @totalGemsAnimated = @lastTotalXP = @lastTotalGems = 0
    @numberAnimationStart = new Date()
    @numberAnimationInterval = setInterval(@tickNumberAnimation, 1000 / 60)

  tickNumberAnimation: =>
    # TODO: make sure the animation pulses happen when the numbers go up and sounds play (up to a max speed)
    return @endAnimateNumbers() unless panel = @numericalItemPanels[0]
    duration = Math.log(panel.number + 1) / Math.LN10 * 1000  # Math.log10 is ES6
    ratio = @getEaseRatio (new Date() - @numberAnimationStart), duration
    if panel.unit is 'xp'
      totalXP = @totalXPAnimated + Math.floor(ratio * panel.number)
      if totalXP isnt @lastTotalXP
        panel.textEl.text('+' + totalXP)
        @XPEl.text('+' + totalXP)
        xpTrigger = 'xp-' + (totalXP % 6)  # 6 xp sounds
        Backbone.Mediator.publish 'audio-player:play-sound', trigger: xpTrigger, volume: 0.5 + ratio / 2
        @lastTotalXP = totalXP
    else
      totalGems = @totalGemsAnimated + Math.floor(ratio * panel.number)
      if totalGems isnt @lastTotalGems
        panel.textEl.text('+' + totalGems)
        @gemEl.text('+' + totalGems)
        gemTrigger = 'gem-' + (parseInt(panel.number * ratio) % 4)  # 4 gem sounds
        Backbone.Mediator.publish 'audio-player:play-sound', trigger: gemTrigger, volume: 0.5 + ratio / 2
        @lastTotalGems = totalGems
    if ratio is 1
      panel.rootEl.removeClass('animating').find('.reward-image-container img').removeClass('pulse')
      @numberAnimationStart = new Date()
      if panel.unit is 'xp'
        @totalXPAnimated += panel.number
      else
        @totalGemsAnimated += panel.number
      @numericalItemPanels.shift()
      return
    panel.rootEl.addClass('animating').find('.reward-image-container img').addClass('pulse')

  getEaseRatio: (timeSinceStart, duration) ->
    # Ease in/out quadratic - http://gizma.com/easing/
    timeSinceStart = Math.min timeSinceStart, duration
    t = 2 * timeSinceStart / duration
    if t < 1
      return 0.5 * t * t
    --t
    -0.5 * (t * (t - 2) - 1)

  endAnimateNumbers: ->
    clearInterval @numberAnimationInterval
    @animationComplete = true
    @updateSavingProgressStatus()

  updateSavingProgressStatus: ->
    return unless @animationComplete
    @$el.find('#saving-progress-label').toggleClass('hide', @readyToContinue)
    @$el.find('#continue-button').toggleClass('hide', not @readyToContinue)

  onGameSubmitted: (e) ->
    ladderURL = "/play/ladder/#{@level.get('slug')}#my-matches"
    Backbone.Mediator.publish 'router:navigate', route: ladderURL


  # TODO: award heroes/items and play an awesome sound when you get one

  destroy: ->
    clearInterval @numberAnimationInterval
    super()
