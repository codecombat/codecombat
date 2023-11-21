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