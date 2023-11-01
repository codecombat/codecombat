/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
const CoursesUpdateAccountView = require('views/courses/CoursesUpdateAccountView');
const factories = require('test/app/factories');

describe('/students/update-account', function() {

  describe('when logged out', function() {
    beforeEach(function(done) {
      me.clear();
      this.view = new CoursesUpdateAccountView();
      this.view.render();
      return done();
    });

    return it('shows log in button', function() {
      return expect(this.view.$el.find('.login-btn').length).toEqual(1);
    });
  });

  describe('when logged in as individual', function() {
    beforeEach(function(done) {
      me.set(factories.makeUser({}).attributes);
      this.view = new CoursesUpdateAccountView();
      this.view.render();
      expect(this.view.$el.find('.login-btn').length).toEqual(0);
      return done();
    });

    it('shows update to teacher button', function() {
      return expect(this.view.$el.find('.update-teacher-btn').length).toEqual(1);
    });

    return it('shows update to student button and classCode input', function() {
      expect(this.view.$el.find('.update-student-btn').length).toEqual(1);
      return expect(this.view.$el.find('input[name="classCode"]').length).toEqual(1);
    });
  });

  describe('when logged in as student', function() {
    beforeEach(function(done) {
      me.set(factories.makeUser({role: 'student'}).attributes);
      this.view = new CoursesUpdateAccountView();
      this.view.render();
      expect(this.view.$el.find('.login-btn').length).toEqual(0);
      expect(this.view.$el.find('.remain-teacher-btn').length).toEqual(0);
      expect(this.view.$el.find('.logout-btn').length).toEqual(1);
      return done();
    });

    it('shows remain a student button', function() {
      expect(this.view.$el.find('.remain-student-btn').length).toEqual(1);
      return expect(this.view.$el.find('input[name="classCode"]').length).toEqual(0);
    });

    return it('shows update to teacher button', function() {
      return expect(this.view.$el.find('.update-teacher-btn').length).toEqual(1);
    });
  });

  return describe('when logged in as teacher', function() {
    beforeEach(function(done) {
      me.set(factories.makeUser({role: 'teacher'}).attributes);
      this.view = new CoursesUpdateAccountView();
      this.view.render();
      expect(this.view.$el.find('.login-btn').length).toEqual(0);
      expect(this.view.$el.find('.remain-student-btn').length).toEqual(0);
      return done();
    });

    it('shows remain a teacher button', function() {
      return expect(this.view.$el.find('.remain-teacher-btn').length).toEqual(1);
    });

    return it('shows update to student button', function() {
      expect(this.view.$el.find('.update-student-btn').length).toEqual(1);
      return expect(this.view.$el.find('input[name="classCode"]').length).toEqual(1);
    });
  });
});
