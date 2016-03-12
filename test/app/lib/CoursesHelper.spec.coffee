helper = require 'lib/coursesHelper'
Campaigns = require 'collections/Campaigns'
Users = require 'collections/Users'
Courses = require 'collections/Courses'
CourseInstances = require 'collections/CourseInstances'
Classrooms = require 'collections/Classrooms'

describe 'CoursesHelper', ->
  
  describe 'calculateAllProgress', ->
    
    beforeEach ->
      # classrooms, courses, campaigns, courseInstances, students
      @classrooms = require 'test/app/fixtures/classrooms'
      @classroom = @classrooms.models[0]
      @courses = require 'test/app/fixtures/courses'
      @course = @courses.models[0]
      @campaigns = require 'test/app/fixtures/campaigns'
      @campaign = @campaigns.models[0]
      @students = require 'test/app/fixtures/students'
        
    describe 'when all students have completed a course', ->
      
      beforeEach ->
        @classroom.sessions = require 'test/app/fixtures/level-sessions-completed'
        @courseInstances = require 'test/app/fixtures/course-instances'
      
      it 'returns object with .completed=true', ->
        progressData = helper.calculateAllProgress(@classrooms, @courses, @campaigns, @courseInstances, @students)
        progress = progressData.get {@classroom, @course}
        expect(progress.completed).toBe true

    # describe 'when not all students have completed a course', ->
