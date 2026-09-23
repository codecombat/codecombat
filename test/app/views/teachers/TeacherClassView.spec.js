/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__, or convert again using --optional-chaining
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
const TeacherClassView = require('views/courses/TeacherClassView')
const storage = require('core/storage')
const forms = require('core/forms')
const factories = require('test/app/factories')
const Users = require('collections/Users')
const Courses = require('collections/Courses')
const Levels = require('collections/Levels')
const LevelSessions = require('collections/LevelSessions')
const CourseInstances = require('collections/CourseInstances')
const Prepaids = require('collections/Prepaids')
const clansApi = require('core/api/clans')
const studentProgressCalculator = require('lib/studentProgressCalculator')
const utils = require('core/utils')
const Classroom = require('models/Classroom')

describe('/teachers/classes/:handle', function () {})

describe('TeacherClassView', () => // describe 'when logged out', ->
//   it 'responds with 401 error'
//   it 'shows Log In and Create Account buttons'

// describe "when you don't own the class", ->
//   it 'responds with 403 error'
//   it 'shows Log Out button'

  describe('when logged in', function () {
    beforeEach(function (done) {
      window.spyOn(clansApi, 'getMyClans').and.returnValue(Promise.resolve([]))
      const me = factories.makeUser({})

      this.courses = new Courses([
        factories.makeCourse({ name: 'First Course', _id: '5632661322961295f9428638' }),
        factories.makeCourse({ name: 'Second Course' }),
        factories.makeCourse({ name: 'Beta Course', releasePhase: 'beta' }),
      ])
      this.releasedCourses = new Courses(this.courses.where({ releasePhase: 'released' }))
      this.available1 = factories.makePrepaid({ maxRedeemers: 1 })
      this.available2 = factories.makePrepaid({ maxRedeemers: 1, type: 'starter_license', includedCourseIDs: [this.courses.at(0).id] })
      const expired = factories.makePrepaid({ endDate: moment().subtract(1, 'day').toISOString() })
      this.prepaids = new Prepaids([this.available1, this.available2, expired])
      this.students = new Users([
        factories.makeUser({ name: 'Abner' }),
        factories.makeUser({ name: 'Abigail' }),
        factories.makeUser({ name: 'Abby' }, { prepaid: this.available1 }),
        factories.makeUser({ name: 'Ben' }, { prepaid: this.available2 }),
        factories.makeUser({ name: 'Ned' }, { prepaid: expired }),
        factories.makeUser({ name: 'Ebner' }, { prepaid: expired }),
      ])
      this.levels = new Levels(_.times(2, () => factories.makeLevel({ concepts: ['basic_syntax', 'arguments', 'functions'] })))
      this.levels.push(factories.makeLevel({ name: 'Practice Level', concepts: ['basic_syntax', 'arguments', 'functions'], practice: true }))
      this.levels.push(factories.makeLevel({ concepts: ['basic_syntax', 'arguments', 'functions'], primerLanguage: 'javascript' }))

      return _.defer(done)
    })

    describe('when python classroom', function () {
      beforeEach(function (done) {
        let level
        this.classroom = factories.makeClassroom({ aceConfig: { language: 'python' } }, { courses: this.releasedCourses, members: this.students, levels: [this.levels, new Levels()] })
        this.courseInstances = new CourseInstances([
          factories.makeCourseInstance({}, { course: this.releasedCourses.first(), classroom: this.classroom, members: this.students }),
          factories.makeCourseInstance({}, { course: this.releasedCourses.last(), classroom: this.classroom, members: this.students }),
        ])

        const sessions = []
        this.finishedStudent = this.students.models[0]
        this.finishedStudentWithPractice = this.students.models[1]
        this.unfinishedStudent = this.students.last()
        for (level of this.levels.models) {
          sessions.push(factories.makeLevelSession(
            { state: { complete: true }, playtime: 60 },
            { level, creator: this.finishedStudentWithPractice }),
          )
          if (level.get('practice')) { continue }
          sessions.push(factories.makeLevelSession(
            { state: { complete: true }, playtime: 60 },
            { level, creator: this.finishedStudent }),
          )
        }
        sessions.push(factories.makeLevelSession(
          { state: { complete: true }, playtime: 60 },
          { level: this.levels.first(), creator: this.unfinishedStudent }),
        )
        this.levelSessions = new LevelSessions(sessions)

        this.view = new TeacherClassView({}, this.courseInstances.first().id)
        this.view.classroom.fakeRequests[0].respondWith({ status: 200, responseText: this.classroom.stringify() })
        this.view.courses.fakeRequests[0].respondWith({ status: 200, responseText: this.courses.stringify() })
        this.view.courseInstances.fakeRequests[0].respondWith({ status: 200, responseText: this.courseInstances.stringify() })
        this.view.students.fakeRequests[0].respondWith({ status: 200, responseText: this.students.stringify() })
        this.view.classroom.sessions.fakeRequests[0].respondWith({ status: 200, responseText: JSON.stringify({ sessions: this.levelSessions }) })
        this.view.levels.fakeRequests[0].respondWith({ status: 200, responseText: this.levels.stringify() })
        this.view.prepaids.fakeRequests[0].respondWith({ status: 200, responseText: this.prepaids.stringify() })

        jasmine.demoEl(this.view.$el)
        return _.defer(done)
      })

      it('has contents', function () {
        return expect(this.view.$el.children().length).toBeGreaterThan(0)
      })

      // it "shows the classroom's name and description"
      // it "shows the classroom's join code"

      describe('the Students tab', function () {
        beforeEach(function (done) {
          this.view.state.set('activeTab', '#students-tab')
          return _.defer(done)
        })

        // it 'shows all of the students'
        // it 'sorts correctly by Name'
        // it 'sorts correctly by Progress'

        return describe('bulk-assign controls', () => it('shows alert when assigning but no students are selected', function (done) {
          expect(this.view.$el.find('.no-students-selected').hasClass('visible')).toBe(false)
          this.view.$el.find('.assign-to-selected-students').click()
          return _.defer(() => {
            expect(this.view.$el.find('.no-students-selected').hasClass('visible')).toBe(true)
            return done()
          })
        }))
      })

      // describe 'the Course Progress tab', ->
      //   it 'shows the correct Course Overview progress'
      //
      //   describe 'when viewing another course'
      //     it 'still shows the correct Course Overview progress'
      //

      describe('the License Status tab', function () {
        beforeEach(function (done) {
          this.view.state.set('activeTab', '#license-status-tab')
          return _.defer(done)
        })

        return describe('Enroll button', () => it('calls enrollStudents with that user when clicked', function () {
          window.spyOn(this.view, 'enrollStudents')
          this.view.$el.find('.enroll-student-button:first').click()
          expect(this.view.enrollStudents).toHaveBeenCalled()
          const users = this.view.enrollStudents.calls.argsFor(0)[0]
          expect(users.size()).toBe(1)
          return expect(users.first().id).toBe(this.view.students.models[0].id)
        }))
      }) // TODO: Make test less brittle

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

      return describe('Export Student Progress (CSV) button', () => it('downloads a CSV file', function () {
        window.spyOn(window, 'saveAs')
        window.spyOn(studentProgressCalculator, 'exportStudentProgress').and.callThrough()
        this.view.calculateProgressAndLevelsAux()
        this.view.$el.find('.export-student-progress-btn').click()
        const progressData = studentProgressCalculator.exportStudentProgress.calls.mostRecent().returnValue
        const lines = progressData.split('\n')
        expect(lines.length).toBe(this.students.length + 1)
        for (const line of lines) {
          const simplerLine = line.replace(/"[^"]+"/g, '""')
          // Name, Username,Email,Total Levels,Total Playtime(humanize), Total Playtime(seconds), [CS1 Levels, CS1 Playtime, ...], Concepts
          expect(simplerLine.match(/[^,]+/g).length).toBe(6 + (this.releasedCourses.length * 3) + 1)
          if (simplerLine.match(new RegExp(this.finishedStudent.get('email')))) {
            expect(simplerLine).toMatch(/3,3 minutes,180,3,3 minutes,180,0/)
          } else if (simplerLine.match(new RegExp(this.finishedStudentWithPractice.get('email')))) {
            expect(simplerLine).toMatch(/3,3 minutes,180,3,3 minutes,180,0/)
          } else if (simplerLine.match(new RegExp(this.unfinishedStudent.get('email')))) {
            expect(simplerLine).toMatch(/1,a minute,60,1,a minute,60,0/)
          } else if (simplerLine.match(/@/)) {
            expect(simplerLine).toMatch(/0,0,0,0,0/)
          }
        }
      }))
    })

    describe('when javascript classroom', function () {
      beforeEach(function (done) {
        let level
        this.classroom = factories.makeClassroom({ aceConfig: { language: 'javascript' } }, { courses: this.releasedCourses, members: this.students, levels: [this.levels, new Levels()] })
        this.courseInstances = new CourseInstances([
          factories.makeCourseInstance({}, { course: this.releasedCourses.first(), classroom: this.classroom, members: this.students }),
          factories.makeCourseInstance({}, { course: this.releasedCourses.last(), classroom: this.classroom, members: this.students }),
        ])

        const sessions = []
        this.finishedStudent = this.students.first()
        this.unfinishedStudent = this.students.last()
        const classLanguage = __guard__(this.classroom.get('aceConfig'), x => x.language)
        for (level of this.levels.models) {
          if (classLanguage && (classLanguage === level.get('primerLanguage'))) { continue }
          if (level.get('practice')) { continue }
          sessions.push(factories.makeLevelSession(
            { state: { complete: true }, playtime: 60 },
            { level, creator: this.finishedStudent }),
          )
        }
        sessions.push(factories.makeLevelSession(
          { state: { complete: true }, playtime: 60 },
          { level: this.levels.first(), creator: this.unfinishedStudent }),
        )
        this.levelSessions = new LevelSessions(sessions)

        this.view = new TeacherClassView({}, this.courseInstances.first().id)
        this.view.classroom.fakeRequests[0].respondWith({ status: 200, responseText: this.classroom.stringify() })
        this.view.courses.fakeRequests[0].respondWith({ status: 200, responseText: this.courses.stringify() })
        this.view.courseInstances.fakeRequests[0].respondWith({ status: 200, responseText: this.courseInstances.stringify() })
        this.view.students.fakeRequests[0].respondWith({ status: 200, responseText: this.students.stringify() })
        this.view.classroom.sessions.fakeRequests[0].respondWith({ status: 200, responseText: JSON.stringify({ sessions: this.levelSessions }) })
        this.view.levels.fakeRequests[0].respondWith({ status: 200, responseText: this.levels.stringify() })
        this.view.prepaids.fakeRequests[0].respondWith({ status: 200, responseText: this.prepaids.stringify() })

        jasmine.demoEl(this.view.$el)
        return _.defer(done)
      })

      return describe('Export Student Progress (CSV) button', () => it('downloads a CSV file', function () {
        window.spyOn(window, 'saveAs')
        window.spyOn(studentProgressCalculator, 'exportStudentProgress').and.callThrough()
        this.view.calculateProgressAndLevelsAux()
        this.view.$el.find('.export-student-progress-btn').click()
        const progressData = studentProgressCalculator.exportStudentProgress.calls.mostRecent().returnValue
        const lines = progressData.split('\n')
        expect(lines.length).toBe(this.students.length + 1)
        for (const line of lines) {
          const simplerLine = line.replace(/"[^"]+"/g, '""')
          // Name, Username,Email,Total Levels,Total Playtime(humanize), Total Playtime(seconds), [CS1 Levels, CS1 Playtime, ...], Concepts
          expect(simplerLine.match(/[^,]+/g).length).toBe(6 + (this.releasedCourses.length * 3) + 1)
          if (simplerLine.match(new RegExp(this.finishedStudent.get('email')))) {
            expect(simplerLine).toMatch(/2,2 minutes,120,2,2 minutes,120,0/)
          } else if (simplerLine.match(new RegExp(this.unfinishedStudent.get('email')))) {
            expect(simplerLine).toMatch(/1,a minute,60,1,a minute,60,0/)
          } else if (simplerLine.match(/@/)) {
            expect(simplerLine).toMatch(/0,0,0,0/)
          }
        }
      }))
    })

    describe('.assignCourse(courseID, members)', function () {
      beforeEach(function (done) {
        let level
        this.classroom = factories.makeClassroom({ aceConfig: { language: 'javascript' } }, { courses: this.releasedCourses, members: this.students, levels: [this.levels, new Levels()] })
        this.courseInstances = new CourseInstances([
          factories.makeCourseInstance({}, { course: this.releasedCourses.first(), classroom: this.classroom, members: new Users() }),
          factories.makeCourseInstance({}, { course: this.releasedCourses.last(), classroom: this.classroom, members: new Users() }),
        ])

        const sessions = []
        this.finishedStudent = this.students.first()
        this.unfinishedStudent = this.students.last()
        const classLanguage = __guard__(this.classroom.get('aceConfig'), x => x.language)
        for (level of this.levels.models) {
          if (classLanguage && (classLanguage === level.get('primerLanguage'))) { continue }
          sessions.push(factories.makeLevelSession(
            { state: { complete: true }, playtime: 60 },
            { level, creator: this.finishedStudent }),
          )
        }
        sessions.push(factories.makeLevelSession(
          { state: { complete: true }, playtime: 60 },
          { level: this.levels.first(), creator: this.unfinishedStudent }),
        )
        this.levelSessions = new LevelSessions(sessions)

        this.view = new TeacherClassView({}, this.courseInstances.first().id)
        this.view.classroom.fakeRequests[0].respondWith({ status: 200, responseText: this.classroom.stringify() })
        this.view.courses.fakeRequests[0].respondWith({ status: 200, responseText: this.courses.stringify() })
        this.view.courseInstances.fakeRequests[0].respondWith({ status: 200, responseText: this.courseInstances.stringify() })
        this.view.students.fakeRequests[0].respondWith({ status: 200, responseText: this.students.stringify() })
        this.view.classroom.sessions.fakeRequests[0].respondWith({ status: 200, responseText: JSON.stringify({ sessions: this.levelSessions }) })
        this.view.levels.fakeRequests[0].respondWith({ status: 200, responseText: this.levels.stringify() })
        this.view.prepaids.fakeRequests[0].respondWith({ status: 200, responseText: this.prepaids.stringify() })

        jasmine.demoEl(this.view.$el)
        return _.defer(done)
      })

      return describe('when the student has a starter license', () => describe('and the course is NOT covered by starter licenses', function () {
        beforeEach(function (done) {
          window.spyOn(this.view.prepaids.at(1), 'redeem')
          const starterId = this.available2.get('_id')
          this.starterStudent = this.students.find(s => s.get('products').length && (s.get('products')[0].prepaid === starterId))
          this.view.assignCourse(this.courses.at(1).id, [this.starterStudent.id])
          return this.view.wait('begin-redeem-for-assign-course').then(done)
        })

        return it('replaces their license with a full license', function (done) {
          expect(this.view.prepaids.at(1).redeem).toHaveBeenCalled()
          return done()
        })
      }))
    })

    return describe('.assignCourse(courseID, members)', function () {
      beforeEach(function (done) {
        let level
        this.classroom = factories.makeClassroom({ aceConfig: { language: 'javascript' } }, { courses: this.releasedCourses, members: this.students, levels: [this.levels, new Levels()] })
        this.courseInstances = new CourseInstances([
          factories.makeCourseInstance({}, { course: this.releasedCourses.first(), classroom: this.classroom, members: this.students }),
          factories.makeCourseInstance({}, { course: this.releasedCourses.last(), classroom: this.classroom, members: this.students }),
        ])

        const sessions = []
        this.finishedStudent = this.students.first()
        this.unfinishedStudent = this.students.last()
        const classLanguage = __guard__(this.classroom.get('aceConfig'), x => x.language)
        for (level of this.levels.models) {
          if (classLanguage && (classLanguage === level.get('primerLanguage'))) { continue }
          sessions.push(factories.makeLevelSession(
            { state: { complete: true }, playtime: 60 },
            { level, creator: this.finishedStudent }),
          )
        }
        sessions.push(factories.makeLevelSession(
          { state: { complete: true }, playtime: 60 },
          { level: this.levels.first(), creator: this.unfinishedStudent }),
        )
        this.levelSessions = new LevelSessions(sessions)

        this.view = new TeacherClassView({}, this.courseInstances.first().id)
        this.view.classroom.fakeRequests[0].respondWith({ status: 200, responseText: this.classroom.stringify() })
        this.view.courses.fakeRequests[0].respondWith({ status: 200, responseText: this.courses.stringify() })
        this.view.courseInstances.fakeRequests[0].respondWith({ status: 200, responseText: this.courseInstances.stringify() })
        this.view.students.fakeRequests[0].respondWith({ status: 200, responseText: this.students.stringify() })
        this.view.classroom.sessions.fakeRequests[0].respondWith({ status: 200, responseText: JSON.stringify({ sessions: this.levelSessions }) })
        this.view.levels.fakeRequests[0].respondWith({ status: 200, responseText: this.levels.stringify() })
        this.view.prepaids.fakeRequests[0].respondWith({ status: 200, responseText: this.prepaids.stringify() })

        jasmine.demoEl(this.view.$el)
        return _.defer(done)
      })

      describe('when no course instance exists for the given course', function () {
        beforeEach(function (done) {
          this.view.courseInstances.reset()
          this.view.assignCourse(this.courses.first().id, this.students.pluck('_id').slice(0, 1))
          return this.view.courseInstances.wait('add').then(done)
        })

        it('creates the missing course instance', function () {
          const request = jasmine.Ajax.requests.mostRecent()
          expect(request.method).toBe('POST')
          return expect(request.url).toBe('/db/course_instance')
        })

        return it('shows a noty if the course instance request fails', function (done) {
          this.notySpy.and.callFake(done)
          const request = jasmine.Ajax.requests.mostRecent()
          return request.respondWith({
            status: 500,
            responseText: JSON.stringify({ message: 'Internal Server Error' }),
          })
        })
      })

      describe('when the course is not free and some students are not enrolled', function () {
        beforeEach(function (done) {
        // first two students are unenrolled
          this.view.assignCourse(this.courses.first().id, this.students.pluck('_id').slice(0, 2))
          return this.view.wait('begin-redeem-for-assign-course').then(done)
        })

        it('enrolls all unenrolled students', function (done) {
          const numberOfRequests = _(this.view.prepaids.models)
            .map(prepaid => prepaid.fakeRequests.length)
            .reduce((num, value) => num + value)
          expect(numberOfRequests).toBe(2)
          return done()
        })

        return it('shows a noty if a redeem request fails', function (done) {
          this.notySpy.and.callFake(done)
          const request = jasmine.Ajax.requests.mostRecent()
          return request.respondWith({
            status: 500,
            responseText: JSON.stringify({ message: 'Internal Server Error' }),
          })
        })
      })

      describe('when there are not enough licenses available', function () {
        beforeEach(function (done) {
        // first four students are unenrolled, but only two licenses are available
          this.view.assignCourse(this.courses.first().id, this.students.pluck('_id'))
          return window.spyOn(this.view, 'openModalView').and.callFake(done)
        })

        return it('shows CoursesNotAssignedModal', function () {
          return expect(this.view.openModalView).toHaveBeenCalled()
        })
      })

      return describe('when there is nothing else to do first', function () {
        beforeEach(function (done) {
          this.courseInstance = this.view.courseInstances.first()
          this.courseInstance.set('members', [])
          this.view.assignCourse(this.courseInstance.get('courseID'), this.students.pluck('_id').slice(2, 4))
          return this.view.wait('begin-assign-course').then(done)
        })

        it('adds students to the course instances', function () {
          expect(this.courseInstance.fakeRequests.length).toBe(1)
          const request = this.courseInstance.fakeRequests[0]
          expect(request.url).toBe(`/db/course_instance/${this.courseInstance.id}/members`)
          return expect(request.method).toBe('POST')
        })

        return it('shows a noty if POSTing students fails', function (done) {
          this.notySpy.and.callFake(done)
          expect(this.courseInstance.fakeRequests.length).toBe(1)
          const request = this.courseInstance.fakeRequests[0]
          return request.respondWith({
            status: 500,
            responseText: JSON.stringify({ message: 'Internal Server Error' }),
          })
        })
      })
    })
  }))

describe('lib/studentProgressCalculator', function () {
  describe('exportStudentProgress with a HackStack course', function () {
    beforeEach(function () {
      this.hsCourseId = utils.HACKSTACK_COURSE_IDS[1]
      this.student = factories.makeUser({ name: 'Student One' })
      this.otherStudent = factories.makeUser({ name: 'Student Two' })
      this.students = new Users([this.student, this.otherStudent])
      this.classroom = new Classroom({
        _id: _.uniqueId('classroom_'),
        name: 'HS Class',
        aceConfig: { language: 'python' },
        members: [this.student.id, this.otherStudent.id],
        courses: [{
          _id: this.hsCourseId,
          levels: [{ original: 'scenario-a' }, { original: 'scenario-b' }],
        }],
      })
      this.classroom.sessions = new LevelSessions([])
      this.courses = new Courses([factories.makeCourse({ _id: this.hsCourseId })])
      this.sortedCourses = this.classroom.getSortedCourses()
      this.courseInstances = new CourseInstances([])
      this.levels = new Levels([])
      this.progressData = { get: () => null }
      this.aiProjects = [
        { user: this.student.id, scenario: 'scenario-a', playtime: 100 },
        { user: this.student.id, scenario: 'scenario-a', playtime: 200 }, // duplicate scenario, playtime still accumulates
        { user: this.student.id, scenario: 'scenario-b' }, // missing playtime, treated as 0
        { user: this.student.id, scenario: 'scenario-elsewhere', playtime: 999 }, // scenario not in this classroom's courses
      ]
    })

    it('counts distinct scenarios and sums project playtime into the HS course columns', function () {
      window.spyOn(window, 'saveAs')
      const csv = studentProgressCalculator.exportStudentProgress({
        classroom: this.classroom,
        sortedCourses: this.sortedCourses,
        students: this.students,
        courses: this.courses,
        courseInstances: this.courseInstances,
        levels: this.levels,
        progressData: this.progressData,
        aiProjects: this.aiProjects,
      })
      const lines = csv.split('\n')
      expect(lines.length).toBe(this.students.length + 1)
      const studentLine = lines.find(line => line.indexOf(this.student.get('email')) !== -1)
      // Total Levels, Total Playtime(humanize), Total Playtime(seconds), then the same three for the HS course.
      // Playtime = 100 + 200 (dup on scenario-a) + 0 (missing on scenario-b); the out-of-classroom project contributes nothing.
      expect(studentLine).toMatch(/2,5 minutes,300,2,5 minutes,300,/)
      const otherLine = lines.find(line => line.indexOf(this.otherStudent.get('email')) !== -1)
      expect(otherLine).toMatch(/0,0,0,0,0,0/)
    })

    it('exports zeroes for HS columns when no aiProjects are provided', function () {
      window.spyOn(window, 'saveAs')
      const csv = studentProgressCalculator.exportStudentProgress({
        classroom: this.classroom,
        sortedCourses: this.sortedCourses,
        students: this.students,
        courses: this.courses,
        courseInstances: this.courseInstances,
        levels: this.levels,
        progressData: this.progressData,
      })
      const lines = csv.split('\n')
      const studentLine = lines.find(line => line.indexOf(this.student.get('email')) !== -1)
      expect(studentLine).toMatch(/0,0,0,0,0,0/)
    })
  })

  describe('exportStudentProgress with a scenario shared across two HackStack courses', function () {
    beforeEach(function () {
      this.hsCourseIdA = utils.HACKSTACK_COURSE_IDS[1]
      this.hsCourseIdB = utils.HACKSTACK_COURSE_IDS[2]
      this.student = factories.makeUser({ name: 'Student One' })
      this.otherStudent = factories.makeUser({ name: 'Student Two' })
      this.students = new Users([this.student, this.otherStudent])
      this.classroom = new Classroom({
        _id: _.uniqueId('classroom_'),
        name: 'HS Class two courses',
        aceConfig: { language: 'python' },
        members: [this.student.id, this.otherStudent.id],
        courses: [{
          _id: this.hsCourseIdA,
          levels: [{ original: 'scenario-a' }, { original: 'scenario-b' }],
        }, {
          _id: this.hsCourseIdB,
          levels: [{ original: 'scenario-a' }],
        }],
      })
      this.classroom.sessions = new LevelSessions([])
      this.courses = new Courses([
        factories.makeCourse({ _id: this.hsCourseIdA }),
        factories.makeCourse({ _id: this.hsCourseIdB }),
      ])
      this.sortedCourses = this.classroom.getSortedCourses()
      this.courseInstances = new CourseInstances([])
      this.levels = new Levels([])
      this.progressData = { get: () => null }
      this.aiProjects = [
        { user: this.student.id, scenario: 'scenario-a', playtime: 100 },
        { user: this.student.id, scenario: 'scenario-a', playtime: 200 }, // duplicate, playtime accumulates
        { user: this.student.id, scenario: 'scenario-b' }, // missing playtime
        { user: this.student.id, scenario: 'scenario-elsewhere', playtime: 999 }, // not in either HS course
      ]
    })

    it('credits every matching course while counting the scenario once in the total', function () {
      window.spyOn(window, 'saveAs')
      const csv = studentProgressCalculator.exportStudentProgress({
        classroom: this.classroom,
        sortedCourses: this.sortedCourses,
        students: this.students,
        courses: this.courses,
        courseInstances: this.courseInstances,
        levels: this.levels,
        progressData: this.progressData,
        aiProjects: this.aiProjects,
      })
      const lines = csv.split('\n')
      const studentLine = lines.find(line => line.indexOf(this.student.get('email')) !== -1)
      // Total: 2 levels (a + b), 300s (100 + 200 + 0). Course A (has a + b): 2 levels, 300s. Course B (has a only): 1 level, 300s.
      // Course columns come out in the order sortedCourses returns them.
      const courseAFirst = this.sortedCourses[0]._id === this.hsCourseIdA
      if (courseAFirst) {
        expect(studentLine).toMatch(/,2,5 minutes,300,2,5 minutes,300,1,5 minutes,300,/)
      } else {
        expect(studentLine).toMatch(/,2,5 minutes,300,1,5 minutes,300,2,5 minutes,300,/)
      }
      const otherLine = lines.find(line => line.indexOf(this.otherStudent.get('email')) !== -1)
      expect(otherLine).toMatch(/0,0,0,0,0,0,0,0,0/)
    })
  })
})

function __guard__ (value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined
}