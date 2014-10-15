ModalView = require 'views/kinds/ModalView'
template = require 'templates/play/level/modal/hero-victory-modal'
Achievement = require 'models/Achievement'
EarnedAchievement = require 'models/EarnedAchievement'
CocoCollection = require 'collections/CocoCollection'
LocalMongo = require 'lib/LocalMongo'
utils = require 'lib/utils'
ThangType = require 'models/ThangType'

module.exports = class HeroVictoryModal extends ModalView
  id: 'hero-victory-modal'
  template: template
  closeButton: false
  closesOnClickOutside: false

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
#    if c.achievements.length
#      c.achievements = [c.achievements[0].clone(), c.achievements[0].clone(), c.achievements[0].clone()]
#    for achievement, index in c.achievements
#      achievement.completed = index > 0
#      achievement.completedAWhileAgo = index > 1

    c.thangTypes = @thangTypes
    return c

  afterRender: ->
    super()
    return unless @supermodel.finished()
    @updateSavingProgressStatus()
    complete = _.once(_.bind(@beginAnimateNumbers, @))
    @animatedPanels = $()
    panels = @$el.find('.achievement-panel')
    for panel in panels
      panel = $(panel)
      continue unless panel.data('animate')
      @animatedPanels = @animatedPanels.add(panel)
      panel.delay(500)
      panel.queue(->
        $(this).addClass('earned') # animate out the grayscale
        $(this).dequeue()
      )
      panel.delay(500)
      panel.queue(->
        $(this).find('.reward-image-container').addClass('show')
        $(this).dequeue()
      )
      panel.delay(500)
      panel.queue(-> complete())
    @animationComplete = not @animatedPanels.length

  beginAnimateNumbers: ->
    @numericalItemPanels = _.map(@animatedPanels.find('.numerical'), (panel) -> {
      number: $(panel).data('number')
      textEl: $(panel).find('.reward-text')
      rootEl: $(panel)
      unit: $(panel).data('number-unit')
    })

    # TODO: mess with this more later. Doesn't seem to work, often times will pulse background red rather than animate
#    itemPanel.rootEl.find('.reward-image-container img').addClass('pulse') for itemPanel in @numericalItemPanels
    @numberAnimationStart = new Date()
    @totalXP = 0
    @totalXP += panel.number for panel in @numericalItemPanels when panel.unit is 'xp'
    @totalGems = 0
    @totalGems += panel.number for panel in @numericalItemPanels when panel.unit is 'gem'
    @gemEl = $('#gem-total')
    @XPEl = $('#xp-total')
    @numberAnimationInterval = setInterval(@tickNumberAnimation, 15 / 1000)

  tickNumberAnimation: =>
    pct = Math.min(1, (new Date() - @numberAnimationStart) / 1500)
    panel.textEl.text('+'+parseInt(panel.number*pct)) for panel in @numericalItemPanels
    @XPEl.text('+'+parseInt(@totalXP * pct))
    @gemEl.text('+'+parseInt(@totalGems * pct))
    @endAnimateNumbers() if pct is 1

  endAnimateNumbers: ->
    @$el.find('.pulse').removeClass('pulse')
    clearInterval(@numberAnimationInterval)
    @animationComplete = true
    @updateSavingProgressStatus()

  updateSavingProgressStatus: ->
    return unless @animationComplete
    @$el.find('#saving-progress-label').toggleClass('hide', @readyToContinue)
    @$el.find('#continue-button').toggleClass('hide', not @readyToContinue)
