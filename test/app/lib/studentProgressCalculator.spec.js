const studentProgressCalculator = require('lib/studentProgressCalculator')
const utils = require('core/utils')
const factories = require('test/app/factories')
const Classroom = require('models/Classroom')
const Users = require('collections/Users')
const Courses = require('collections/Courses')
const CourseInstances = require('collections/CourseInstances')
const Levels = require('collections/Levels')
const LevelSessions = require('collections/LevelSessions')

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
        { user: this.student.id, scenario: 'scenario-a' }, // second project on same scenario, playtime field missing
        { user: this.student.id, scenario: 'scenario-b', playtime: 50 },
        { user: this.student.id, scenario: 'scenario-elsewhere', playtime: 999 }, // scenario not in this classroom's courses
      ]
    })

    it('counts distinct scenarios and sums project playtime into the HS course columns', function (done) {
      window.spyOn(window, 'saveAs').and.callFake((blob) => {
        const reader = new FileReader()
        reader.onload = () => {
          const lines = decodeURI(reader.result).split('\n')
          expect(lines.length).toBe(this.students.length + 1)
          const studentLine = lines.find(line => line.indexOf(this.student.get('email')) !== -1)
          // Total Levels, Total Playtime(humanize), Total Playtime(seconds), then the same three for the HS course
          expect(studentLine).toMatch(/2,3 minutes,150,2,3 minutes,150,/)
          const otherLine = lines.find(line => line.indexOf(this.otherStudent.get('email')) !== -1)
          expect(otherLine).toMatch(/0,0,0,0,0,0/)
          done()
        }
        reader.readAsText(blob)
      })
      studentProgressCalculator.exportStudentProgress({
        classroom: this.classroom,
        sortedCourses: this.sortedCourses,
        students: this.students,
        courses: this.courses,
        courseInstances: this.courseInstances,
        levels: this.levels,
        progressData: this.progressData,
        aiProjects: this.aiProjects,
      })
    })

    it('exports zeroes for HS columns when no aiProjects are provided', function (done) {
      window.spyOn(window, 'saveAs').and.callFake((blob) => {
        const reader = new FileReader()
        reader.onload = () => {
          const lines = decodeURI(reader.result).split('\n')
          const studentLine = lines.find(line => line.indexOf(this.student.get('email')) !== -1)
          expect(studentLine).toMatch(/0,0,0,0,0,0/)
          done()
        }
        reader.readAsText(blob)
      })
      studentProgressCalculator.exportStudentProgress({
        classroom: this.classroom,
        sortedCourses: this.sortedCourses,
        students: this.students,
        courses: this.courses,
        courseInstances: this.courseInstances,
        levels: this.levels,
        progressData: this.progressData,
      })
    })
  })

  describe('exportStudentProgress with a course level missing from the levels collection', function () {
    beforeEach(function () {
      this.course = factories.makeCourse()
      this.student = factories.makeUser({ name: 'Student One' })
      this.students = new Users([this.student])
      this.classroom = new Classroom({
        _id: _.uniqueId('classroom_'),
        name: 'Coco Class',
        aceConfig: { language: 'python' },
        members: [this.student.id],
        courses: [{
          _id: this.course.id,
          levels: [{ original: 'lost-level-original' }],
        }],
      })
      this.classroom.sessions = new LevelSessions([])
      this.courses = new Courses([this.course])
      this.sortedCourses = this.classroom.getSortedCourses()
      this.courseInstances = new CourseInstances([
        factories.makeCourseInstance({}, { course: this.course, classroom: this.classroom, members: this.students }),
      ])
      this.levels = new Levels([]) // level lookup by original will miss
      this.progressData = { get: () => null }
    })

    it('skips the missing level instead of throwing', function (done) {
      window.spyOn(window, 'saveAs').and.callFake(() => done())
      studentProgressCalculator.exportStudentProgress({
        classroom: this.classroom,
        sortedCourses: this.sortedCourses,
        students: this.students,
        courses: this.courses,
        courseInstances: this.courseInstances,
        levels: this.levels,
        progressData: this.progressData,
      })
    })
  })
})
