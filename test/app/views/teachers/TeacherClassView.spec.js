/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__, or convert again using --optional-chaining
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
const TeacherClassView = require('views/courses/TeacherClassView');
const storage = require('core/storage');
const forms = require('core/forms');
const factories = require('test/app/factories');
const Users = require('collections/Users');
const Courses = require('collections/Courses');
const Levels = require('collections/Levels');
const LevelSessions = require('collections/LevelSessions');
const CourseInstances = require('collections/CourseInstances');
const Prepaids = require('collections/Prepaids');

describe('/teachers/classes/:handle', function() {});

describe('TeacherClassView', () => // describe 'when logged out', ->
//   it 'responds with 401 error'
//   it 'shows Log In and Create Account buttons'

// describe "when you don't own the class", ->
//   it 'responds with 403 error'
//   it 'shows Log Out button'

describe('when logged in', function() {
  beforeEach(function(done) {
    const me = factories.makeUser({});

    this.courses = new Courses([
      factories.makeCourse({name: 'First Course', _id: '5632661322961295f9428638'}),
      factories.makeCourse({name: 'Second Course'}),
      factories.makeCourse({name: 'Beta Course', releasePhase: 'beta'}),
    ]);
    this.releasedCourses = new Courses(this.courses.where({ releasePhase: 'released' }));
    this.available1 = factories.makePrepaid({maxRedeemers: 1});
    this.available2 = factories.makePrepaid({maxRedeemers: 1, type: 'starter_license', includedCourseIDs: [this.courses.at(0).id]});
    const expired = factories.makePrepaid({endDate: moment().subtract(1, 'day').toISOString()});
    this.prepaids = new Prepaids([this.available1, this.available2, expired]);
    this.students = new Users([
      factories.makeUser({name: 'Abner'}),
      factories.makeUser({name: 'Abigail'}),
      factories.makeUser({name: 'Abby'}, {prepaid: this.available1}),
      factories.makeUser({name: 'Ben'}, {prepaid: this.available2}),
      factories.makeUser({name: 'Ned'}, {prepaid: expired}),
      factories.makeUser({name: 'Ebner'}, {prepaid: expired})
    ]);
    this.levels = new Levels(_.times(2, () => factories.makeLevel({ concepts: ['basic_syntax', 'arguments', 'functions'] })));
    this.levels.push(factories.makeLevel({ name: "Practice Level", concepts: ['basic_syntax', 'arguments', 'functions'], practice: true }));
    this.levels.push(factories.makeLevel({ concepts: ['basic_syntax', 'arguments', 'functions'], primerLanguage: 'javascript' }));

    return _.defer(done);
  });

  describe('when python classroom', function() {
    beforeEach(function(done) {
      let level;
      this.classroom = factories.makeClassroom({ aceConfig: { language: 'python' }}, { courses: this.releasedCourses, members: this.students, levels: [this.levels, new Levels()] });
      this.courseInstances = new CourseInstances([
        factories.makeCourseInstance({}, { course: this.releasedCourses.first(), classroom: this.classroom, members: this.students }),
        factories.makeCourseInstance({}, { course: this.releasedCourses.last(), classroom: this.classroom, members: this.students })
      ]);

      const sessions = [];
      this.finishedStudent = this.students.models[0];
      this.finishedStudentWithPractice = this.students.models[1];
      this.unfinishedStudent = this.students.last();
      for (level of Array.from(this.levels.models)) {
        sessions.push(factories.makeLevelSession(
            {state: {complete: true}, playtime: 60},
            {level, creator: this.finishedStudentWithPractice})
        );
        if (level.get('practice')) { continue; }
        sessions.push(factories.makeLevelSession(
            {state: {complete: true}, playtime: 60},
            {level, creator: this.finishedStudent})
        );
      }
      sessions.push(factories.makeLevelSession(
          {state: {complete: true}, playtime: 60},
          {level: this.levels.first(), creator: this.unfinishedStudent})
      );
      this.levelSessions = new LevelSessions(sessions);

      this.view = new TeacherClassView({}, this.courseInstances.first().id);
      this.view.classroom.fakeRequests[0].respondWith({ status: 200, responseText: this.classroom.stringify() });
      this.view.courses.fakeRequests[0].respondWith({ status: 200, responseText: this.courses.stringify() });
      this.view.courseInstances.fakeRequests[0].respondWith({ status: 200, responseText: this.courseInstances.stringify() });
      this.view.students.fakeRequests[0].respondWith({ status: 200, responseText: this.students.stringify() });
      this.view.classroom.sessions.fakeRequests[0].respondWith({ status: 200, responseText: this.levelSessions.stringify() });
      this.view.levels.fakeRequests[0].respondWith({ status: 200, responseText: this.levels.stringify() });
      this.view.prepaids.fakeRequests[0].respondWith({ status: 200, responseText: this.prepaids.stringify() });

      jasmine.demoEl(this.view.$el);
      return _.defer(done);
    });

    it('has contents', function() {
      return expect(this.view.$el.children().length).toBeGreaterThan(0);
    });

    // it "shows the classroom's name and description"
    // it "shows the classroom's join code"

    describe('the Students tab', function() {
      beforeEach(function(done) {
        this.view.state.set('activeTab', '#students-tab');
        return _.defer(done);
      });

      // it 'shows all of the students'
      // it 'sorts correctly by Name'
      // it 'sorts correctly by Progress'

      return describe('bulk-assign controls', () => it('shows alert when assigning but no students are selected', function(done) {
        expect(this.view.$el.find('.no-students-selected').hasClass('visible')).toBe(false);
        this.view.$el.find('.assign-to-selected-students').click();
        return _.defer(() => {
          expect(this.view.$el.find('.no-students-selected').hasClass('visible')).toBe(true);
          return done();
        });
      }));
    });

    // describe 'the Course Progress tab', ->
    //   it 'shows the correct Course Overview progress'
    //
    //   describe 'when viewing another course'
    //     it 'still shows the correct Course Overview progress'
    //

    describe('the License Status tab', function() {
      beforeEach(function(done) {
        this.view.state.set('activeTab', '#license-status-tab');
        return _.defer(done);
      });

      return describe('Enroll button', () => it('calls enrollStudents with that user when clicked', function() {
        spyOn(this.view, 'enrollStudents');
        this.view.$el.find('.enroll-student-button:first').click();
        expect(this.view.enrollStudents).toHaveBeenCalled();
        const users = this.view.enrollStudents.calls.argsFor(0)[0];
        expect(users.size()).toBe(1);
        return expect(users.first().id).toBe(this.view.students.models[0].id);
      }));
    }); // TODO: Make test less brittle

    /*
      describe 'Revoke button', ->
        it 'opens a confirm modal once clicked', ->
          spyOn(window, 'confirm').and.returnValue(true)
          @view.$('.revoke-student-button:first').click()
          expect(window.confirm).toHaveBeenCalled()

        describe 'once the prepaid is successfully revoked', ->
          beforeEach ->
            spyOn(window, 'confirm').and.returnValue(true)
            button = @view.$('.revoke-student-button:first')
            @revokedUser = @view.students.get(button.data('user-id'))
            @view.$('.revoke-student-button:first').click()
            request = jasmine.Ajax.requests.mostRecent()
            request.respondWith({
              status: 200
              responseText: '{}'
            })

          it 'updates the user and rerenders the page', ->
            if @view.$(".enroll-student-button[data-user-id='#{@revokedUser.id}']").length isnt 1
              fail('Could not find enroll student button for user whose enrollment was revoked')
     */

    return describe('Export Student Progress (CSV) button', () => it('downloads a CSV file', function(done) {
      spyOn(window, 'saveAs').and.callFake((blob, fileName) => {
        const reader = new FileReader();
        reader.onload = event => {
          const encodedCSV = reader.result;
          const progressData = decodeURI(encodedCSV);
          const lines = progressData.split('\n');
          expect(lines.length).toBe(this.students.length + 1);
          for (var line of Array.from(lines)) {
            var simplerLine = line.replace(/"[^"]+"/g, '""');
            // Name, Username,Email,Total Levels,Total Playtime(humanize), Total Playtime(seconds), [CS1 Levels, CS1 Playtime, ...], Concepts
            expect(simplerLine.match(/[^,]+/g).length).toBe(6 + (this.releasedCourses.length * 3) + 1);
            if (simplerLine.match(new RegExp(this.finishedStudent.get('email')))) {
              expect(simplerLine).toMatch(/3,3 minutes,180,3,3 minutes,180,0/);
            } else if (simplerLine.match(new RegExp(this.finishedStudentWithPractice.get('email')))) {
              expect(simplerLine).toMatch(/3,3 minutes,180,3,3 minutes,180,0/);
            } else if (simplerLine.match(new RegExp(this.unfinishedStudent.get('email')))) {
              expect(simplerLine).toMatch(/1,a minute,60,1,a minute,60,0/);
            } else if (simplerLine.match(/@/)) {
              expect(simplerLine).toMatch(/0,0,0,0,0/);
            }
          }
          return done();
        };
        return reader.readAsText(blob);
      });
      this.view.calculateProgressAndLevelsAux();
      return this.view.$el.find('.export-student-progress-btn').click();
    }));
  });

  describe('when javascript classroom', function() {
    beforeEach(function(done) {
      let level;
      this.classroom = factories.makeClassroom({ aceConfig: { language: 'javascript' }}, { courses: this.releasedCourses, members: this.students, levels: [this.levels, new Levels()]});
      this.courseInstances = new CourseInstances([
        factories.makeCourseInstance({}, { course: this.releasedCourses.first(), classroom: this.classroom, members: this.students }),
        factories.makeCourseInstance({}, { course: this.releasedCourses.last(), classroom: this.classroom, members: this.students })
      ]);

      const sessions = [];
      this.finishedStudent = this.students.first();
      this.unfinishedStudent = this.students.last();
      const classLanguage = __guard__(this.classroom.get('aceConfig'), x => x.language);
      for (level of Array.from(this.levels.models)) {
        if (classLanguage && (classLanguage === level.get('primerLanguage'))) { continue; }
        if (level.get('practice')) { continue; }
        sessions.push(factories.makeLevelSession(
            {state: {complete: true}, playtime: 60},
            {level, creator: this.finishedStudent})
        );
      }
      sessions.push(factories.makeLevelSession(
          {state: {complete: true}, playtime: 60},
          {level: this.levels.first(), creator: this.unfinishedStudent})
      );
      this.levelSessions = new LevelSessions(sessions);

      this.view = new TeacherClassView({}, this.courseInstances.first().id);
      this.view.classroom.fakeRequests[0].respondWith({ status: 200, responseText: this.classroom.stringify() });
      this.view.courses.fakeRequests[0].respondWith({ status: 200, responseText: this.courses.stringify() });
      this.view.courseInstances.fakeRequests[0].respondWith({ status: 200, responseText: this.courseInstances.stringify() });
      this.view.students.fakeRequests[0].respondWith({ status: 200, responseText: this.students.stringify() });
      this.view.classroom.sessions.fakeRequests[0].respondWith({ status: 200, responseText: this.levelSessions.stringify() });
      this.view.levels.fakeRequests[0].respondWith({ status: 200, responseText: this.levels.stringify() });
      this.view.prepaids.fakeRequests[0].respondWith({ status: 200, responseText: this.prepaids.stringify() });

      jasmine.demoEl(this.view.$el);
      return _.defer(done);
    });

    return describe('Export Student Progress (CSV) button', () => it('downloads a CSV file', function(done) {
      spyOn(window, 'saveAs').and.callFake((blob, fileName) => {
        const reader = new FileReader();
        reader.onload = event => {
          const encodedCSV = reader.result;
          const progressData = decodeURI(encodedCSV);
          const lines = progressData.split('\n');
          expect(lines.length).toBe(this.students.length + 1);
          for (var line of Array.from(lines)) {
            var simplerLine = line.replace(/"[^"]+"/g, '""');
            // Name, Username,Email,Total Levels,Total Playtime(humanize), Total Playtime(seconds), [CS1 Levels, CS1 Playtime, ...], Concepts
            expect(simplerLine.match(/[^,]+/g).length).toBe(6 + (this.releasedCourses.length * 3) + 1);
            if (simplerLine.match(new RegExp(this.finishedStudent.get('email')))) {
              expect(simplerLine).toMatch(/2,2 minutes,120,2,2 minutes,120,0/);
            } else if (simplerLine.match(new RegExp(this.unfinishedStudent.get('email')))) {
              expect(simplerLine).toMatch(/1,a minute,60,1,a minute,60,0/);
            } else if (simplerLine.match(/@/)) {
              expect(simplerLine).toMatch(/0,0,0,0/);
            }
          }
          return done();
        };
        return reader.readAsText(blob);
      });
      this.view.calculateProgressAndLevelsAux();
      return this.view.$el.find('.export-student-progress-btn').click();
    }));
  });

  describe('.assignCourse(courseID, members)', function() {
    beforeEach(function(done) {
      let level;
      this.classroom = factories.makeClassroom({ aceConfig: { language: 'javascript' }}, { courses: this.releasedCourses, members: this.students, levels: [this.levels, new Levels()]});
      this.courseInstances = new CourseInstances([
        factories.makeCourseInstance({}, { course: this.releasedCourses.first(), classroom: this.classroom, members: new Users() }),
        factories.makeCourseInstance({}, { course: this.releasedCourses.last(), classroom: this.classroom, members: new Users() })
      ]);

      const sessions = [];
      this.finishedStudent = this.students.first();
      this.unfinishedStudent = this.students.last();
      const classLanguage = __guard__(this.classroom.get('aceConfig'), x => x.language);
      for (level of Array.from(this.levels.models)) {
        if (classLanguage && (classLanguage === level.get('primerLanguage'))) { continue; }
        sessions.push(factories.makeLevelSession(
            {state: {complete: true}, playtime: 60},
            {level, creator: this.finishedStudent})
        );
      }
      sessions.push(factories.makeLevelSession(
          {state: {complete: true}, playtime: 60},
          {level: this.levels.first(), creator: this.unfinishedStudent})
      );
      this.levelSessions = new LevelSessions(sessions);

      this.view = new TeacherClassView({}, this.courseInstances.first().id);
      this.view.classroom.fakeRequests[0].respondWith({ status: 200, responseText: this.classroom.stringify() });
      this.view.courses.fakeRequests[0].respondWith({ status: 200, responseText: this.courses.stringify() });
      this.view.courseInstances.fakeRequests[0].respondWith({ status: 200, responseText: this.courseInstances.stringify() });
      this.view.students.fakeRequests[0].respondWith({ status: 200, responseText: this.students.stringify() });
      this.view.classroom.sessions.fakeRequests[0].respondWith({ status: 200, responseText: this.levelSessions.stringify() });
      this.view.levels.fakeRequests[0].respondWith({ status: 200, responseText: this.levels.stringify() });
      this.view.prepaids.fakeRequests[0].respondWith({ status: 200, responseText: this.prepaids.stringify() });

      jasmine.demoEl(this.view.$el);
      return _.defer(done);
    });

    return describe('when the student has a starter license', () => describe('and the course is NOT covered by starter licenses', function() {
      beforeEach(function(done) {
        spyOn(this.view.prepaids.at(1), 'redeem');
        const starterId = this.available2.get('_id');
        this.starterStudent = this.students.find(s => s.get('products').length && (s.get('products')[0].prepaid === starterId));
        this.view.assignCourse(this.courses.at(1).id, [this.starterStudent.id]);
        return this.view.wait('begin-redeem-for-assign-course').then(done);
      });

      return it('replaces their license with a full license', function(done) {
        expect(this.view.prepaids.at(1).redeem).toHaveBeenCalled();
        return done();
      });
    }));
  });

  return describe('.assignCourse(courseID, members)', function() {
    beforeEach(function(done) {
      let level;
      this.classroom = factories.makeClassroom({ aceConfig: { language: 'javascript' }}, { courses: this.releasedCourses, members: this.students, levels: [this.levels, new Levels()]});
      this.courseInstances = new CourseInstances([
        factories.makeCourseInstance({}, { course: this.releasedCourses.first(), classroom: this.classroom, members: this.students }),
        factories.makeCourseInstance({}, { course: this.releasedCourses.last(), classroom: this.classroom, members: this.students })
      ]);

      const sessions = [];
      this.finishedStudent = this.students.first();
      this.unfinishedStudent = this.students.last();
      const classLanguage = __guard__(this.classroom.get('aceConfig'), x => x.language);
      for (level of Array.from(this.levels.models)) {
        if (classLanguage && (classLanguage === level.get('primerLanguage'))) { continue; }
        sessions.push(factories.makeLevelSession(
            {state: {complete: true}, playtime: 60},
            {level, creator: this.finishedStudent})
        );
      }
      sessions.push(factories.makeLevelSession(
          {state: {complete: true}, playtime: 60},
          {level: this.levels.first(), creator: this.unfinishedStudent})
      );
      this.levelSessions = new LevelSessions(sessions);

      this.view = new TeacherClassView({}, this.courseInstances.first().id);
      this.view.classroom.fakeRequests[0].respondWith({ status: 200, responseText: this.classroom.stringify() });
      this.view.courses.fakeRequests[0].respondWith({ status: 200, responseText: this.courses.stringify() });
      this.view.courseInstances.fakeRequests[0].respondWith({ status: 200, responseText: this.courseInstances.stringify() });
      this.view.students.fakeRequests[0].respondWith({ status: 200, responseText: this.students.stringify() });
      this.view.classroom.sessions.fakeRequests[0].respondWith({ status: 200, responseText: this.levelSessions.stringify() });
      this.view.levels.fakeRequests[0].respondWith({ status: 200, responseText: this.levels.stringify() });
      this.view.prepaids.fakeRequests[0].respondWith({ status: 200, responseText: this.prepaids.stringify() });

      jasmine.demoEl(this.view.$el);
      return _.defer(done);
    });

    describe('when no course instance exists for the given course', function() {
      beforeEach(function(done) {
        this.view.courseInstances.reset();
        this.view.assignCourse(this.courses.first().id, this.students.pluck('_id').slice(0, 1));
        return this.view.courseInstances.wait('add').then(done);
      });

      it('creates the missing course instance', function() {
        const request = jasmine.Ajax.requests.mostRecent();
        expect(request.method).toBe('POST');
        return expect(request.url).toBe('/db/course_instance');
      });

      return it('shows a noty if the course instance request fails', function(done) {
        this.notySpy.and.callFake(done);
        const request = jasmine.Ajax.requests.mostRecent();
        return request.respondWith({
          status: 500,
          responseText: JSON.stringify({ message: "Internal Server Error" })
        });
      });
    });

    describe('when the course is not free and some students are not enrolled', function() {
      beforeEach(function(done) {
        // first two students are unenrolled
        this.view.assignCourse(this.courses.first().id, this.students.pluck('_id').slice(0, 2));
        return this.view.wait('begin-redeem-for-assign-course').then(done);
      });

      it('enrolls all unenrolled students', function(done) {
        const numberOfRequests = _(this.view.prepaids.models)
        .map(prepaid => prepaid.fakeRequests.length)
        .reduce((num, value) => num + value);
        expect(numberOfRequests).toBe(2);
        return done();
      });

      return it('shows a noty if a redeem request fails', function(done) {
        this.notySpy.and.callFake(done);
        const request = jasmine.Ajax.requests.mostRecent();
        return request.respondWith({
          status: 500,
          responseText: JSON.stringify({ message: "Internal Server Error" })
        });
      });
    });

    describe('when there are not enough licenses available', function() {
      beforeEach(function(done) {
        // first four students are unenrolled, but only two licenses are available
        this.view.assignCourse(this.courses.first().id, this.students.pluck('_id'));
        return spyOn(this.view, 'openModalView').and.callFake(done);
      });

      return it('shows CoursesNotAssignedModal', function() {
        return expect(this.view.openModalView).toHaveBeenCalled();
      });
    });


    return describe('when there is nothing else to do first', function() {

      beforeEach(function(done) {
        this.courseInstance = this.view.courseInstances.first();
        this.courseInstance.set('members', []);
        this.view.assignCourse(this.courseInstance.get('courseID'), this.students.pluck('_id').slice(2, 3));
        return this.view.wait('begin-assign-course').then(done);
      });

      it('adds students to the course instances', function() {
        expect(this.courseInstance.fakeRequests.length).toBe(1);
        const request = this.courseInstance.fakeRequests[0];
        expect(request.url).toBe(`/db/course_instance/${this.courseInstance.id}/members`);
        return expect(request.method).toBe('POST');
      });

      return it('shows a noty if POSTing students fails', function(done) {
        this.notySpy.and.callFake(done);
        expect(this.courseInstance.fakeRequests.length).toBe(1);
        const request = this.courseInstance.fakeRequests[0];
        return request.respondWith({
          status: 500,
          responseText: JSON.stringify({ message: "Internal Server Error" })
        });
      });
    });
  });
}));

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}