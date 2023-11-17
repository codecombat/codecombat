/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS205: Consider reworking code to avoid use of IIFEs
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
const helper = require('lib/coursesHelper');
const Campaigns = require('collections/Campaigns');
const Users = require('collections/Users');
const Courses = require('collections/Courses');
const CourseInstances = require('collections/CourseInstances');
const Classrooms = require('collections/Classrooms');
const Levels = require('collections/Levels');
const LevelSessions = require('collections/LevelSessions');
const factories = require('test/app/factories');

describe('CoursesHelper', function() {

  describe('calculateAllProgress', function() {

    beforeEach(function() {
      // classrooms, courses, campaigns, courseInstances, students
      this.course = factories.makeCourse();
      this.courses = new Courses([this.course]);
      this.members = new Users(_.times(2, () => factories.makeUser()));
      this.levels = new Levels(_.times(2, () => factories.makeLevel()));
      this.practiceLevel = factories.makeLevel({practice: true});
      this.levels.push(this.practiceLevel);
      
      this.classroom = factories.makeClassroom({}, { courses: this.courses, members: this.members, levels: [this.levels] });
      this.classrooms = new Classrooms([ this.classroom ]);
      
      const courseInstance = factories.makeCourseInstance({}, { course: this.course, classroom: this.classroom, members: this.members });
      return this.courseInstances = new CourseInstances([courseInstance]);
    });

    describe('when all students have completed a course', function() {
      beforeEach(function() {
        const sessions = [];
        for (var level of Array.from(this.levels.models)) {
          if (level === this.practiceLevel) { continue; }
          for (var creator of Array.from(this.members.models)) {
            sessions.push(factories.makeLevelSession({state: {complete: true}}, { level, creator }));
          }
        }
        return this.classroom.sessions = new LevelSessions(sessions);
      });
      
      describe('progressData.get({classroom, course})', () => it('returns object with .completed=true and .started=true', function() {
        const progressData = helper.calculateAllProgress(this.classrooms, this.courses, this.courseInstances, this.members);
        const progress = progressData.get({classroom: this.classroom, course: this.course});
        expect(progress.completed).toBe(true);
        return expect(progress.started).toBe(true);
      }));

      describe('progressData.get({classroom, course, level, user})', () => it('returns object with .completed=true and .started=true', function() {
        return (() => {
          const result = [];
          for (var student of Array.from(this.members.models)) {
            var progressData = helper.calculateAllProgress(this.classrooms, this.courses, this.courseInstances, this.members);
            var progress = progressData.get({classroom: this.classroom, course: this.course, user: student});
            expect(progress.completed).toBe(true);
            result.push(expect(progress.started).toBe(true));
          }
          return result;
        })();
      }));

      describe('progressData.get({classroom, course, level, user})', () => it('returns object with .completed=true and .started=true', function() {
        const progressData = helper.calculateAllProgress(this.classrooms, this.courses, this.courseInstances, this.members);
        return (() => {
          const result = [];
          for (var level of Array.from(this.levels.models)) {
            if (level === this.practiceLevel) { continue; }
            var progress = progressData.get({classroom: this.classroom, course: this.course, level});
            expect(progress.completed).toBe(true);
            result.push(expect(progress.started).toBe(true));
          }
          return result;
        })();
      }));

      return describe('progressData.get({classroom, course, level, user})', () => it('returns object with .completed=true and .started=true', function() {
        const progressData = helper.calculateAllProgress(this.classrooms, this.courses, this.courseInstances, this.members);
        return (() => {
          const result = [];
          for (var level of Array.from(this.levels.models)) {
            if (level === this.practiceLevel) { continue; }
            result.push((() => {
              const result1 = [];
              for (var user of Array.from(this.members.models)) {
                var progress = progressData.get({classroom: this.classroom, course: this.course, level, user});
                expect(progress.completed).toBe(true);
                result1.push(expect(progress.started).toBe(true));
              }
              return result1;
            })());
          }
          return result;
        })();
      }));
    });

    describe('when NOT all students have completed a course', function() {

      beforeEach(function() {
        let level;
        const sessions = [];
        this.finishedMember = this.members.first();
        this.unfinishedMember = this.members.last();
        for (level of Array.from(this.levels.models)) {
          if (level === this.practiceLevel) { continue; }
          sessions.push(factories.makeLevelSession(
            {state: {complete: true}}, 
            {level, creator: this.finishedMember})
          );
        }
        sessions.push(factories.makeLevelSession(
          {state: {complete: false}}, 
          {level: this.levels.first(), creator: this.unfinishedMember})
        );
        return this.classroom.sessions = new LevelSessions(sessions);
      });

      it('progressData.get({classroom, course}) returns object with .completed=false', function() {
        const progressData = helper.calculateAllProgress(this.classrooms, this.courses, this.courseInstances, this.members);
        const progress = progressData.get({classroom: this.classroom, course: this.course});
        return expect(progress.completed).toBe(false);
      });

      describe('when NOT all students have completed a level', () => it('progressData.get({classroom, course, level}) returns object with .completed=false and .started=true', function() {
        const progressData = helper.calculateAllProgress(this.classrooms, this.courses, this.courseInstances, this.members);
        return (() => {
          const result = [];
          for (var level of Array.from(this.levels.models)) {
            if (level.get('practice')) { continue; }
            var progress = progressData.get({classroom: this.classroom, course: this.course, level});
            result.push(expect(progress.completed).toBe(false));
          }
          return result;
        })();
      }));

      describe('when the student has completed the course', () => it('progressData.get({classroom, course, user}) returns object with .completed=true and .started=true', function() {
        const progressData = helper.calculateAllProgress(this.classrooms, this.courses, this.courseInstances, this.members);
        const progress = progressData.get({classroom: this.classroom, course: this.course, user: this.finishedMember});
        expect(progress.completed).toBe(true);
        return expect(progress.started).toBe(true);
      }));

      describe('when the student has NOT completed the course', () => it('progressData.get({classroom, course, user}) returns object with .completed=false and .started=true', function() {
        const progressData = helper.calculateAllProgress(this.classrooms, this.courses, this.courseInstances, this.members);
        const progress = progressData.get({classroom: this.classroom, course: this.course, user: this.unfinishedMember});
        expect(progress.completed).toBe(false);
        return expect(progress.started).toBe(true);
      }));

      describe('when the student has completed the level', () => it('progressData.get({classroom, course, level, user}) returns object with .completed=true and .started=true', function() {
        const progressData = helper.calculateAllProgress(this.classrooms, this.courses, this.courseInstances, this.members);
        return (() => {
          const result = [];
          for (var level of Array.from(this.levels.models)) {
            if (level.get('practice')) { continue; }
            var progress = progressData.get({classroom: this.classroom, course: this.course, level, user: this.finishedMember});
            expect(progress.completed).toBe(true);
            result.push(expect(progress.started).toBe(true));
          }
          return result;
        })();
      }));

      describe('when the student has NOT completed the level but has started', () => it('progressData.get({classroom, course, level, user}) returns object with .completed=true and .started=true', function() {
        const progressData = helper.calculateAllProgress(this.classrooms, this.courses, this.courseInstances, this.members);
        const level = this.levels.first();
        const progress = progressData.get({classroom: this.classroom, course: this.course, level, user: this.unfinishedMember});
        expect(progress.completed).toBe(false);
        return expect(progress.started).toBe(true);
      }));

      return describe('when the student has NOT started the level', () => it('progressData.get({classroom, course, level, user}) returns object with .completed=false and .started=false', function() {
        const progressData = helper.calculateAllProgress(this.classrooms, this.courses, this.courseInstances, this.members);
        const level = this.levels.last();
        const progress = progressData.get({classroom: this.classroom, course: this.course, level, user: this.unfinishedMember});
        expect(progress.completed).toBe(false);
        return expect(progress.started).toBe(false);
      }));
    });
    
    return describe('progressData.get({classroom, course, level:practiceLevel})', () => it('returns an object with .completed=true if there\'s at least one completed session and no incomplete sessions', function() {
      this.classroom.sessions = new LevelSessions();
      let progressData = helper.calculateAllProgress(this.classrooms, this.courses, this.courseInstances, this.members);
      let progress = progressData.get({classroom: this.classroom, course: this.course, level: this.practiceLevel});
      expect(progress.completed).toBe(false);
      expect(progress.started).toBe(false);

      this.classroom.sessions.push(factories.makeLevelSession(
          {state: {complete: true}},
          {level: this.practiceLevel, creator: this.members.first()})
      );
      progressData = helper.calculateAllProgress(this.classrooms, this.courses, this.courseInstances, this.members);
      progress = progressData.get({classroom: this.classroom, course: this.course, level: this.practiceLevel});
      expect(progress.completed).toBe(false);
      expect(progress.started).toBe(true);
      progress = progressData.get({classroom: this.classroom, course: this.course, level: this.practiceLevel});

      this.classroom.sessions.push(factories.makeLevelSession(
          {state: {complete: false}},
          {level: this.practiceLevel, creator: this.members.last()})
      );
      progressData = helper.calculateAllProgress(this.classrooms, this.courses, this.courseInstances, this.members);
      progress = progressData.get({classroom: this.classroom, course: this.course, level: this.practiceLevel});
      expect(progress.completed).toBe(false);
      return expect(progress.started).toBe(true);
    }));
  });

  return describe('hasUserCompletedCourse', function() {
    it('user completed a single level but hasn\'t completed all levels', function() {
      const [userStarted, allComplete, levelsCompleted] = Array.from(helper.hasUserCompletedCourse({'a': true}, new Set(['a', 'b'])));
      expect(userStarted).toBe(true);
      expect(allComplete).toBe(false);
      return expect(levelsCompleted).toEqual(1);
    });

    it('user completed all levels', function() {
      const [userStarted, allComplete, levelsCompleted] = Array.from(helper.hasUserCompletedCourse({'a': true, 'b': true}, new Set(['a', 'b'])));
      expect(userStarted).toBe(true);
      expect(allComplete).toBe(true);
      return expect(levelsCompleted).toEqual(2);
    });

    it('undefined user state passed in', function() {
      const [userStarted, allComplete, levelsCompleted] = Array.from(helper.hasUserCompletedCourse(undefined, new Set(['a'])));
      expect(userStarted).toBe(false);
      expect(allComplete).toBe(false);
      return expect(levelsCompleted).toEqual(0);
    });

    it("User hasn't completed all levels", function() {
      const [userStarted, allComplete, levelsCompleted] = Array.from(helper.hasUserCompletedCourse({'a': true, 'b': false}, new Set(['a', 'b'])));
      expect(userStarted).toBe(true);
      expect(allComplete).toBe(false);
      return expect(levelsCompleted).toEqual(1);
    });

    it("User has completed required levels", function() {
      const [userStarted, allComplete, levelsCompleted] = Array.from(helper.hasUserCompletedCourse({'a': true, 'b': false}, new Set(['a'])));
      expect(userStarted).toBe(true);
      expect(allComplete).toBe(true);
      return expect(levelsCompleted).toEqual(1);
    });

    return it("User has completed different levels", function() {
      const [userStarted, allComplete, levelsCompleted] = Array.from(helper.hasUserCompletedCourse({'a': true, 'b': true}, new Set(['c'])));
      expect(userStarted).toBe(false);
      expect(allComplete).toBe(false);
      return expect(levelsCompleted).toEqual(0);
    });
  });
});
