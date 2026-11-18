/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
const CoursesView = require('views/courses/CoursesView');
const HeroSelectModal = require('views/courses/HeroSelectModal');
const Classrooms = require('collections/Classrooms');
const CourseInstances = require('collections/CourseInstances');
const Courses = require('collections/Courses');
const auth = require('core/auth');
const factories = require('test/app/factories');

describe('CoursesView', function() {

  const modal = null;
  let view = null;

  describe('aiLeagueTiles for a Code Ninjas camper', function () {
    beforeEach(function () {
      me.set(factories.makeUser({ role: 'student', clientCreator: '57fff652b0783842003fed00' }).attributes)
      view = new CoursesView()
      view.classrooms = new Classrooms([factories.makeClassroom({ type: 'camp-esports' }), factories.makeClassroom({ type: 'camp-junior' })])
    })

    afterEach(() => me.unset('aiDisabled'))

    it('keeps the Ozaria and camp activities tiles when AI is turned off for the user', function () {
      me.set('aiDisabled', true)
      const hrefs = view.aiLeagueTiles().map(tile => tile.a.href)
      expect(hrefs.length).toBe(2)
      expect(hrefs[0]).toContain('ozaria.com')
      expect(hrefs[1]).toContain('drive.google.com')
    })

    it('shows the Roblox and AI League tiles too when AI is on', function () {
      me.set('aiDisabled', false)
      const hrefs = view.aiLeagueTiles().map(tile => tile.a.href)
      expect(hrefs[1]).toContain('roblox.com')
      expect(hrefs[hrefs.length - 1]).toContain('/league')
    })
  })

  return describe('Change Hero button', function() {
    beforeEach(function(done) {
      me.set(factories.makeUser({ role: 'student' }).attributes);
      view = new CoursesView();
      const classrooms = new Classrooms([factories.makeClassroom()]);
      const courseInstances = new CourseInstances([factories.makeCourseInstance()]);
      const courses = new Courses([factories.makeCourse()]);
      view.classrooms.fakeRequests[0].respondWith({ status: 200, responseText: classrooms.stringify() });
      view.courseInstances.fakeRequests[0].respondWith({ status: 200, responseText: courseInstances.stringify() });
      view.render();
      jasmine.demoEl(view.$el);
      return done();
    });

    return it('opens the modal when you click Change Hero', function() {
      spyOn(view, 'openModalView');
      view.$('.change-hero-btn').click();
      expect(view.openModalView).toHaveBeenCalled();
      const args = view.openModalView.calls.argsFor(0);
      return expect(args[0] instanceof HeroSelectModal).toBe(true);
    });
  });
});