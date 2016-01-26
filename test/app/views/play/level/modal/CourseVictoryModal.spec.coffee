
Course = require 'models/Course'
Level = require 'models/Level'
LevelSession = require 'models/LevelSession'
Achievements = require 'collections/Achievements'
CourseVictoryModal = require 'views/play/level/modal/CourseVictoryModal'
fixtures = require './CourseVictoryModal.fixtures'
NewItemView = require 'views/play/level/modal/NewItemView'
ProgressView = require 'views/play/level/modal/ProgressView'

describe 'CourseVictoryModal', ->

  it 'will eventually be the only victory modal'
  
  makeViewOptions = ->
    {
      course: new Course(fixtures.course)
      level: new Level(fixtures.level)
      session: new LevelSession(fixtures.session)
      achievements: new Achievements(fixtures.achievements)
      nextLevel: new Level(fixtures.nextLevel)
      courseInstanceID: '56414c3868785b5f152424f1'
      courseID: '560f1a9f22961295f9427742'
    }
    
  handleRequests = ->
    requests = jasmine.Ajax.requests.all()
    thangRequest = _.find(requests, (r) -> _.string.startsWith(r.url, '/db/thang.type'))
    thangRequest?.respondWith({status: 200, responseText: JSON.stringify(fixtures.thangType)})

    earnedAchievementRequests = _.where(requests, {url: '/db/earned_achievement'})
    for [request, response] in _.zip(earnedAchievementRequests, fixtures.earnedAchievements)
      request.respondWith({status: 200, responseText: JSON.stringify(response)})

    sessionsRequest = _.find(requests, (r) -> _.string.startsWith(r.url, '/db/course_instance'))
    sessionsRequest.respondWith({status: 200, responseText: JSON.stringify(fixtures.courseInstanceSessions)})

    campaignRequest = _.findWhere(requests, {url: '/db/campaign/55b29efd1cd6abe8ce07db0d'})
    campaignRequest.respondWith({status: 200, responseText: JSON.stringify(fixtures.campaign)})
    
  describe 'given a course level with a next level and no item or hero rewards', ->
    modal = null

    beforeEach (done) ->
      options = makeViewOptions()
      modal = new CourseVictoryModal(options)
      handleRequests()
      _.defer done

    it 'only shows the ProgressView', ->
      expect(_.size(modal.views)).toBe(1)
      expect(modal.views[0] instanceof ProgressView).toBe(true)

    xit '(demo)', -> currentView.openModalView(modal)
    
    describe 'its ProgressView', ->
      it 'has a next level button which navigates to the next level on click', ->
        spyOn(application.router, 'navigate')
        button = modal.$el.find('#next-level-btn')
        expect(button.length).toBe(1)
        button.click()
        expect(application.router.navigate).toHaveBeenCalled()
        
      it 'has two columns', ->
        expect(modal.$('.row:first .col-sm-12').length).toBe(0)
        expect(modal.$('.row:first .col-sm-5').length).toBe(1)
        expect(modal.$('.row:first .col-sm-7').length).toBe(1)
        
  describe 'given a course level without a next level', ->
    modal = null

    beforeEach (done) ->
      options = makeViewOptions()

      # make the level not have a next level
      level = options.level
      level.unset('nextLevel')
      delete options.nextLevel
      modal = new CourseVictoryModal(options)
      handleRequests()
      _.defer done
      
    describe 'its ProgressView', ->
      it 'has a single large column, since there is no next level to display', ->
        expect(modal.$('.row:first .col-sm-12').length).toBe(1)
        expect(modal.$('.row:first .col-sm-5').length).toBe(0)
        expect(modal.$('.row:first .col-sm-7').length).toBe(0)
        
      it 'has a done button which navigates to the CourseDetailsView for the given course instance', ->
        spyOn(application.router, 'navigate')
        button = modal.$el.find('#done-btn')
        expect(button.length).toBe(1)
        button.click()
        expect(application.router.navigate).toHaveBeenCalled()

    xit '(demo)', -> currentView.openModalView(modal)
      

  describe 'given a course level with a new item', ->
    modal = null
    
    beforeEach (done) ->
      options = makeViewOptions()
      
      # insert new item into achievement properties
      achievement = options.achievements.first()
      rewards = _.cloneDeep(achievement.get('rewards'))
      rewards.items = ["53e4108204c00d4607a89f78"]
      achievement.set('rewards', rewards)
      
      modal = new CourseVictoryModal(options)
      handleRequests()
      _.defer done
      
    it 'includes a NewItemView when the level rewards a new item', ->
      expect(_.size(modal.views)).toBe(2)
      expect(modal.views[0] instanceof NewItemView).toBe(true)
      
    it 'continues to the ProgressView when you click the continue button', ->
      expect(modal.currentView instanceof NewItemView).toBe(true)
      modal.$el.find('#continue-btn').click()
      expect(modal.currentView instanceof ProgressView).toBe(true)
    
    xit '(demo)', -> currentView.openModalView(modal)
