ModalView = require 'views/core/ModalView'
template = require 'templates/play/level/modal/course-victory-modal'
Achievements = require 'collections/Achievements'
Level = require 'models/Level'
Campaign = require 'models/Campaign'
Course = require 'models/Course'
ThangType = require 'models/ThangType'
ThangTypes = require 'collections/ThangTypes'
LevelSessions = require 'collections/LevelSessions'
EarnedAchievement = require 'models/EarnedAchievement'
LocalMongo = require 'lib/LocalMongo'
ProgressView = require './ProgressView'
NewItemView = require './NewItemView'

module.exports = class CourseVictoryModal extends ModalView
  id: 'course-victory-modal'
  template: template
  closesOnClickOutside: false

  
  initialize: (options) ->
    @courseID = options.courseID
    @courseInstanceID = options.courseInstanceID
    @views = []

    @session = options.session
    @level = options.level
    @newItems = new ThangTypes()
    @newHeroes = new ThangTypes()
    
    @achievements = options.achievements
    if not @achievements
      @achievements = new Achievements()
      @achievements.fetchRelatedToLevel(@session.get('level').original)
      @achievements = @supermodel.loadCollection(@achievements, 'achievements').model
      @listenToOnce @achievements, 'sync', @onAchievementsLoaded
    else
      @onAchievementsLoaded()
    
    @playSound 'victory'
    @nextLevel = options.nextLevel
    if (nextLevel = @level.get('nextLevel')) and not @nextLevel
      @nextLevel = new Level().setURL "/db/level/#{nextLevel.original}/version/#{nextLevel.majorVersion}"
      @nextLevel = @supermodel.loadModel(@nextLevel, 'level').model
      
    @campaign = new Campaign()
    @course = options.course
    if @courseID and not @course
      @course = new Course().setURL "/db/course/#{@courseID}"
      @course = @supermodel.loadModel(@course, 'course').model
      if @course.loading
        @listenToOnce @course, 'sync', @onCourseLoaded
      else
        @onCourseLoaded()
    else if @course
      @onCourseLoaded()

    if @courseInstanceID
      @levelSessions = new LevelSessions()
      @levelSessions.fetchForCourseInstance(@courseInstanceID)
      @levelSessions = @supermodel.loadCollection(@levelSessions, 'sessions', { 
        data: { project: 'state.complete level.original playtime changed' }
      }).model


  onCourseLoaded: ->
    @campaign.set('_id', @course.get('campaignID'))
    @campaign = @supermodel.loadModel(@campaign, 'campaign').model

      
  onAchievementsLoaded: ->
    @achievements.models = _.filter @achievements.models, (m) -> not m.get('query')?.ladderAchievementDifficulty  # Don't show higher AI difficulty achievements
    itemOriginals = []
    heroOriginals = []
    achievementIDs = []
    for achievement in @achievements.models
      rewards = achievement.get('rewards') or {}
      heroOriginals.push rewards.heroes or []
      itemOriginals.push rewards.items or []
      achievement.completed = LocalMongo.matchesQuery(@session.attributes, achievement.get('query'))
      achievementIDs.push(achievement.id) if achievement.completed

    itemOriginals = _.uniq _.flatten itemOriginals
    heroOriginals = _.uniq _.flatten heroOriginals
    #project = ['original', 'rasterIcon', 'name', 'soundTriggers', 'i18n']  # This is what we need, but the PlayHeroesModal needs more, and so we load more to fill up the supermodel.
    project = ['original', 'rasterIcon', 'name', 'slug', 'soundTriggers', 'featureImages', 'gems', 'heroClass', 'description', 'components', 'extendedName', 'unlockLevelName', 'i18n']
    for [newThangTypeCollection, originals] in [[@newItems, itemOriginals], [@newHeroes, heroOriginals]]
      for original in originals
        thang= new ThangType()
        thang.url = "/db/thang.type/#{original}/version"
        thang.project = project
        @supermodel.loadModel(thang, 'thang')
        newThangTypeCollection.add(thang)
      
    @newEarnedAchievements = []
    for achievement in @achievements.models
      continue unless achievement.completed
      ea = new EarnedAchievement({
        collection: achievement.get('collection')
        triggeredBy: @session.id
        achievement: achievement.id
      })
      ea.save()
      # Can't just add models to supermodel because each ea has the same url
      ea.sr = @supermodel.addSomethingResource(ea.cid)
      @newEarnedAchievements.push ea
      @listenToOnce ea, 'sync', (model) ->
        model.sr.markLoaded()
        if _.all((ea.id for ea in @newEarnedAchievements))
          unless me.loading
            @supermodel.loadModel(me, 'user', {cache: false})
          @newEarnedAchievementsResource.markLoaded()

    
    # have to use a something resource because addModelResource doesn't handle models being upserted/fetched via POST like we're doing here
    @newEarnedAchievementsResource = @supermodel.addSomethingResource('earned achievements') if @newEarnedAchievements.length

  
  onLoaded: ->
    super()
    @views = []
    
    # TODO: Add main victory view
    # TODO: Add level up view
    # TODO: Add new hero view?
    
    for newItem in @newItems.models
      @views.push(new NewItemView({item: newItem}))
    
    progressView = new ProgressView({
      level: @level
      nextLevel: @nextLevel
      course: @course
      campaign: @campaign
      levelSessions: @levelSessions
    })
    
    progressView.once 'done', @onDone, @
    progressView.once 'next-level', @onNextLevel, @
    for view in @views
      view.on 'continue', @onViewContinue, @
    @views.push(progressView)
    
    @showView(_.first(@views))
  
  afterRender: ->
    super()
    @showView(@currentView)

  showView: (view) ->
    return unless view
    view.setElement(@$('.modal-content'))
    view.$el.attr('id', view.id)
    view.$el.addClass(view.className)
    view.render()
    @currentView = view

  onViewContinue: ->
    index = _.indexOf(@views, @currentView)
    @showView(@views[index+1])

  onNextLevel: ->
    link = "/play/level/#{@nextLevel.get('slug')}?course=#{@courseID}&course-instance=#{@courseInstanceID}"
    application.router.navigate(link, {trigger: true})

  onDone: ->
    link = "/courses/#{@courseID}/#{@courseInstanceID}"
    application.router.navigate(link, {trigger: true})
    
    