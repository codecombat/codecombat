helper = require 'lib/coursesHelper'
Campaigns = require 'collections/Campaigns'
Users = require 'collections/Users'
Courses = require 'collections/Courses'
CourseInstances = require 'collections/CourseInstances'
Classrooms = require 'collections/Classrooms'

# These got broken by changes to fixtures :(
describe 'CoursesHelper', ->

  describe 'calculateAllProgress', ->

    beforeEach ->
      # classrooms, courses, campaigns, courseInstances, students
      @classroom = require 'test/app/fixtures/classrooms/active-classroom'
      @classrooms = new Classrooms([ @classroom ])
      @courses = require 'test/app/fixtures/courses'
      @course = @courses.models[0]
      @campaigns = require 'test/app/fixtures/campaigns'
      @campaign = @campaigns.models[0]
      @students = require 'test/app/fixtures/students'

    describe 'when all students have completed a course', ->
      beforeEach ->
        @classroom.sessions = require 'test/app/fixtures/level-sessions-completed'
        @courseInstances = require 'test/app/fixtures/course-instances'
      
      describe 'progressData.get({classroom, course})', ->
        it 'returns object with .completed=true and .started=true', ->
          progressData = helper.calculateAllProgress(@classrooms, @courses, @courseInstances, @students)
          progress = progressData.get {@classroom, @course}
          expect(progress.completed).toBe true
          expect(progress.started).toBe true

      describe 'progressData.get({classroom, course, level, user})', ->
        it 'returns object with .completed=true and .started=true', ->
          for student in @students.models
            progressData = helper.calculateAllProgress(@classrooms, @courses, @courseInstances, @students)
            progress = progressData.get {@classroom, @course, user: student}
            expect(progress.completed).toBe true
            expect(progress.started).toBe true

      describe 'progressData.get({classroom, course, level, user})', ->
        it 'returns object with .completed=true and .started=true', ->
          progressData = helper.calculateAllProgress(@classrooms, @courses, @courseInstances, @students)
          for level in @campaign.getLevels().models
            progress = progressData.get {@classroom, @course, level}
            expect(progress.completed).toBe true
            expect(progress.started).toBe true

      describe 'progressData.get({classroom, course, level, user})', ->
        it 'returns object with .completed=true and .started=true', ->
          progressData = helper.calculateAllProgress(@classrooms, @courses, @courseInstances, @students)
          for level in @campaign.getLevels().models
            for user in @students.models
              progress = progressData.get {@classroom, @course, level, user}
              expect(progress.completed).toBe true
              expect(progress.started).toBe true

    describe 'when NOT all students have completed a course', ->

      beforeEach ->
        @classroom.sessions = require 'test/app/fixtures/level-sessions-partially-completed'
        @courseInstances = require 'test/app/fixtures/course-instances'

      it 'progressData.get({classroom, course}) returns object with .completed=false', ->
        progressData = helper.calculateAllProgress(@classrooms, @courses, @courseInstances, @students)
        progress = progressData.get {@classroom, @course}
        expect(progress.completed).toBe false

      describe 'when NOT all students have completed a level', ->
        it 'progressData.get({classroom, course, level}) returns object with .completed=false and .started=true', ->
          progressData = helper.calculateAllProgress(@classrooms, @courses, @courseInstances, @students)
          for level in @campaign.getLevels().models
            progress = progressData.get {@classroom, @course, level}
            expect(progress.completed).toBe false

      describe 'when the student has completed the course', ->
        it 'progressData.get({classroom, course, user}) returns object with .completed=true and .started=true', ->
          progressData = helper.calculateAllProgress(@classrooms, @courses, @courseInstances, @students)
          student = @students.get('student0')
          progress = progressData.get {@classroom, @course, user: student}
          expect(progress.completed).toBe true
          expect(progress.started).toBe true

      describe 'when the student has NOT completed the course', ->
        it 'progressData.get({classroom, course, user}) returns object with .completed=false and .started=true', ->
          progressData = helper.calculateAllProgress(@classrooms, @courses, @courseInstances, @students)
          student = @students.get('student1')
          progress = progressData.get {@classroom, @course, user: student}
          expect(progress.completed).toBe false
          expect(progress.started).toBe true

      describe 'when the student has completed the level', ->
        it 'progressData.get({classroom, course, level, user}) returns object with .completed=true and .started=true', ->
          progressData = helper.calculateAllProgress(@classrooms, @courses, @courseInstances, @students)
          student = @students.get('student0')
          for level in @campaign.getLevels().models
            progress = progressData.get {@classroom, @course, level, user: student}
            expect(progress.completed).toBe true
            expect(progress.started).toBe true

      describe 'when the student has NOT completed the level but has started', ->
        it 'progressData.get({classroom, course, level, user}) returns object with .completed=true and .started=true', ->
          progressData = helper.calculateAllProgress(@classrooms, @courses, @courseInstances, @students)
          user = @students.get('student2')
          level = @campaign.getLevels().get('level0_0')
          progress = progressData.get {@classroom, @course, level, user}
          expect(progress.completed).toBe false
          expect(progress.started).toBe true

      describe 'when the student has NOT started the level', ->
        it 'progressData.get({classroom, course, level, user}) returns object with .completed=false and .started=false', ->
          progressData = helper.calculateAllProgress(@classrooms, @courses, @courseInstances, @students)
          user = @students.get('student3')
          level = @campaign.getLevels().get('level0_0')
          progress = progressData.get {@classroom, @course, level, user}
          expect(progress.completed).toBe false
          expect(progress.started).toBe false
