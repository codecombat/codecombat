TeacherCoursesView = require 'views/courses/TeacherCoursesView'
HeroSelectModal = require 'views/courses/HeroSelectModal'
Classrooms = require 'collections/Classrooms'
Courses = require 'collections/Courses'
Campaigns = require 'collections/Campaigns'
Levels = require 'collections/Levels'
factories = require 'test/app/factories'

describe 'TeacherCoursesView', ->

  modal = null
  view = null

  describe 'Play Level form', ->
    beforeEach (done) ->
      me.set(factories.makeUser({ role: 'teacher' }).attributes)
      view = new TeacherCoursesView()
      classrooms = new Classrooms([factories.makeClassroom()])
      levels1 = new Levels([ factories.makeLevel({ name: 'Dungeons of Kithgard' }), factories.makeLevel(), factories.makeLevel() ])
      levels2 = new Levels([ factories.makeLevel(), factories.makeLevel(), factories.makeLevel() ])
      campaigns = new Campaigns([factories.makeCampaign({}, { levels: levels1 }), factories.makeCampaign({}, { levels: levels2 })])
      courses = new Courses([factories.makeCourse({}, {campaign: campaigns.at(0)}), factories.makeCourse({}, {campaign: campaigns.at(1)})])
      view.ownedClassrooms.fakeRequests[0].respondWith({ status: 200, responseText: classrooms.stringify() })
      view.campaigns.fakeRequests[0].respondWith({ status: 200, responseText: campaigns.stringify() })
      view.courses.fakeRequests[0].respondWith({ status: 200, responseText: courses.stringify() })
      view.onLoaded()
      done()

    it 'opens HeroSelectModal for the first level of the first course', (done) ->
      spyOn(view, 'openModalView').and.callFake (modal) -> modal
      spyOn(application.router, 'navigate')
      view.$('.play-level-button').first().click()
      expect(view.openModalView).toHaveBeenCalled()
      expect(application.router.navigate).not.toHaveBeenCalled()
      args = view.openModalView.calls.argsFor(0)
      modalView = args[0]
      expect(modalView instanceof HeroSelectModal).toBe(true)
      modalView.trigger('hero-select:success')
      expect(application.router.navigate).not.toHaveBeenCalled()
      modalView.trigger('hide')
      modalView.trigger('hidden')
      _.defer ->
        expect(application.router.navigate).toHaveBeenCalled()
        done()

    it "doesn't open HeroSelectModal for other levels", ->
      spyOn(view, 'openModalView')
      spyOn(application.router, 'navigate')
      secondLevelSlug = view.$('.level-select:first option:nth-child(2)').val()
      view.$('.level-select').first().val(secondLevelSlug)
      view.$('.play-level-button').first().click()
      expect(view.openModalView).not.toHaveBeenCalled()
      expect(application.router.navigate).toHaveBeenCalled()

    it "doesn't open HeroSelectModal for other courses", ->
      spyOn(view, 'openModalView')
      spyOn(application.router, 'navigate')
      view.$('.play-level-button').get(1).click()
      expect(view.openModalView).not.toHaveBeenCalled()
      expect(application.router.navigate).toHaveBeenCalled()

    it "remembers the selected hero" # TODO
