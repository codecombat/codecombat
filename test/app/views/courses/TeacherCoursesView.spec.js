/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
const TeacherCoursesView = require('views/courses/TeacherCoursesView');
const HeroSelectModal = require('views/courses/HeroSelectModal');
const Classrooms = require('collections/Classrooms');
const Courses = require('collections/Courses');
const Campaigns = require('collections/Campaigns');
const Levels = require('collections/Levels');
const factories = require('test/app/factories');

describe('TeacherCoursesView', function() {

  const modal = null;
  let view = null;

  return describe('Play Level form', function() {
    beforeEach(function(done) {
      me.set(factories.makeUser({ role: 'teacher' }).attributes);
      view = new TeacherCoursesView();
      const classrooms = new Classrooms([factories.makeClassroom()]);
      const levels1 = new Levels([ factories.makeLevel({ name: 'Dungeons of Kithgard' }), factories.makeLevel(), factories.makeLevel() ]);
      const levels2 = new Levels([ factories.makeLevel(), factories.makeLevel(), factories.makeLevel() ]);
      const campaigns = new Campaigns([factories.makeCampaign({}, { levels: levels1 }), factories.makeCampaign({}, { levels: levels2 })]);
      const courses = new Courses([factories.makeCourse({}, {campaign: campaigns.at(0)}), factories.makeCourse({}, {campaign: campaigns.at(1)})]);
      view.ownedClassrooms.fakeRequests[0].respondWith({ status: 200, responseText: classrooms.stringify() });
      view.campaigns.fakeRequests[0].respondWith({ status: 200, responseText: campaigns.stringify() });
      view.courses.fakeRequests[0].respondWith({ status: 200, responseText: courses.stringify() });
      view.onLoaded();
      return done();
    });

    it('opens HeroSelectModal for the first level of the first course', function(done) {
      spyOn(view, 'openModalView').and.callFake(modal => modal);
      spyOn(application.router, 'navigate');
      view.$('.play-level-button').first().click();
      expect(view.openModalView).toHaveBeenCalled();
      expect(application.router.navigate).not.toHaveBeenCalled();
      const args = view.openModalView.calls.argsFor(0);
      const modalView = args[0];
      expect(modalView instanceof HeroSelectModal).toBe(true);
      modalView.trigger('hero-select:success');
      expect(application.router.navigate).not.toHaveBeenCalled();
      modalView.trigger('hide');
      modalView.trigger('hidden');
      return _.defer(function() {
        expect(application.router.navigate).toHaveBeenCalled();
        return done();
      });
    });

    it("doesn't open HeroSelectModal for other levels", function() {
      spyOn(view, 'openModalView');
      spyOn(application.router, 'navigate');
      const secondLevelSlug = view.$('.level-select:first option:nth-child(2)').val();
      view.$('.level-select').first().val(secondLevelSlug);
      view.$('.play-level-button').first().click();
      expect(view.openModalView).not.toHaveBeenCalled();
      return expect(application.router.navigate).toHaveBeenCalled();
    });

    it("doesn't open HeroSelectModal for other courses", function() {
      spyOn(view, 'openModalView');
      spyOn(application.router, 'navigate');
      view.$('.play-level-button').get(1).click();
      expect(view.openModalView).not.toHaveBeenCalled();
      return expect(application.router.navigate).toHaveBeenCalled();
    });

    return it("remembers the selected hero");
  });
}); // TODO
