Course = require 'models/Course'
Level = require 'models/Level'
LevelSession = require 'models/LevelSession'
CourseVictoryModal = require 'views/play/level/modal/CourseVictoryModal'
ProgressView = require 'views/play/level/modal/ProgressView'
factories = require 'test/app/factories'

describe 'CourseVictoryModal', ->
  beforeEach ->
    me.clear()

  it 'will eventually be the only victory modal'

  makeViewOptions = ->
    level = factories.makeLevel()
    course = factories.makeCourse()
    courseInstance = factories.makeCourseInstance()
    {
      course: factories.makeCourse()
      level: level
      session: factories.makeLevelSession({ state: { complete: true } }, { level })
      nextLevel: factories.makeLevel()
      courseInstanceID: courseInstance.id
      courseID: course.id
    }

  nextLevelRequest = null

  handleRequests = (modal) ->
    requests = jasmine.Ajax.requests.all()
    modal.levelSessions.fakeRequests[0].respondWith({ status: 200, responseText: '[]' })
    modal.classroom.fakeRequests[0].respondWith({
      status: 200, responseText: factories.makeClassroom().stringify()
    })
    if me.fakeRequests
      lastRequest = _.last(me.fakeRequests)
      if not lastRequest.response
        lastRequest.respondWith({
          status: 200, responseText: factories.makeUser().stringify()
        })
    nextLevelRequest = modal.nextLevel.fakeRequests[0]

  describe 'given a course level with a next level and no item or hero rewards', ->
    modal = null

    beforeEach (done) ->
      options = makeViewOptions()
      modal = new CourseVictoryModal(options)
      handleRequests(modal)
      nextLevelRequest.respondWith({status: 200, responseText: factories.makeLevel().stringify()})
      _.defer done

    it 'only shows the ProgressView', ->
      expect(_.size(modal.views)).toBe(1)
      expect(modal.views[0] instanceof ProgressView).toBe(true)

    it '(demo)', -> jasmine.demoModal(modal)

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
      handleRequests(modal)
      nextLevelRequest.respondWith({status: 404, responseText: '{}'})
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

    it '(demo)', -> jasmine.demoModal(modal)
