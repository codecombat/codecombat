helper = require 'lib/coursesHelper'
Campaigns = require 'collections/Campaigns'
Users = require 'collections/Users'
Courses = require 'collections/Courses'
CourseInstances = require 'collections/CourseInstances'
Classrooms = require 'collections/Classrooms'
Levels = require 'collections/Levels'
LevelSessions = require 'collections/LevelSessions'
factories = require 'test/app/factories'

describe 'CoursesHelper', ->

  describe 'calculateAllProgress', ->

    beforeEach ->
      # classrooms, courses, campaigns, courseInstances, students
      @course = factories.makeCourse()
      @courses = new Courses([@course])
      @members = new Users(_.times(2, -> factories.makeUser()))
      @levels = new Levels(_.times(2, -> factories.makeLevel()))
      @practiceLevel = factories.makeLevel({practice: true})
      @levels.push(@practiceLevel)
      
      @classroom = factories.makeClassroom({}, { @courses, @members, levels: [@levels] })
      @classrooms = new Classrooms([ @classroom ])
      
      courseInstance = factories.makeCourseInstance({}, { @course, @classroom, @members })
      @courseInstances = new CourseInstances([courseInstance])

    describe 'when all students have completed a course', ->
      beforeEach ->
        sessions = []
        for level in @levels.models
          continue if level is @practiceLevel
          for creator in @members.models
            sessions.push(factories.makeLevelSession({state: {complete: true}}, { level, creator }))
        @classroom.sessions = new LevelSessions(sessions)
      
      describe 'progressData.get({classroom, course})', ->
        it 'returns object with .completed=true and .started=true', ->
          progressData = helper.calculateAllProgress(@classrooms, @courses, @courseInstances, @members)
          progress = progressData.get {@classroom, @course}
          expect(progress.completed).toBe true
          expect(progress.started).toBe true

      describe 'progressData.get({classroom, course, level, user})', ->
        it 'returns object with .completed=true and .started=true', ->
          for student in @members.models
            progressData = helper.calculateAllProgress(@classrooms, @courses, @courseInstances, @members)
            progress = progressData.get {@classroom, @course, user: student}
            expect(progress.completed).toBe true
            expect(progress.started).toBe true

      describe 'progressData.get({classroom, course, level, user})', ->
        it 'returns object with .completed=true and .started=true', ->
          progressData = helper.calculateAllProgress(@classrooms, @courses, @courseInstances, @members)
          for level in @levels.models
            continue if level is @practiceLevel
            progress = progressData.get {@classroom, @course, level}
            expect(progress.completed).toBe true
            expect(progress.started).toBe true

      describe 'progressData.get({classroom, course, level, user})', ->
        it 'returns object with .completed=true and .started=true', ->
          progressData = helper.calculateAllProgress(@classrooms, @courses, @courseInstances, @members)
          for level in @levels.models
            continue if level is @practiceLevel
            for user in @members.models
              progress = progressData.get {@classroom, @course, level, user}
              expect(progress.completed).toBe true
              expect(progress.started).toBe true

    describe 'when NOT all students have completed a course', ->

      beforeEach ->
        sessions = []
        @finishedMember = @members.first()
        @unfinishedMember = @members.last()
        for level in @levels.models
          continue if level is @practiceLevel
          sessions.push(factories.makeLevelSession(
            {state: {complete: true}}, 
            {level, creator: @finishedMember})
          )
        sessions.push(factories.makeLevelSession(
          {state: {complete: false}}, 
          {level: @levels.first(), creator: @unfinishedMember})
        )
        @classroom.sessions = new LevelSessions(sessions)

      it 'progressData.get({classroom, course}) returns object with .completed=false', ->
        progressData = helper.calculateAllProgress(@classrooms, @courses, @courseInstances, @members)
        progress = progressData.get {@classroom, @course}
        expect(progress.completed).toBe false

      describe 'when NOT all students have completed a level', ->
        it 'progressData.get({classroom, course, level}) returns object with .completed=false and .started=true', ->
          progressData = helper.calculateAllProgress(@classrooms, @courses, @courseInstances, @members)
          for level in @levels.models
            continue if level.get('practice')
            progress = progressData.get {@classroom, @course, level}
            expect(progress.completed).toBe false

      describe 'when the student has completed the course', ->
        it 'progressData.get({classroom, course, user}) returns object with .completed=true and .started=true', ->
          progressData = helper.calculateAllProgress(@classrooms, @courses, @courseInstances, @members)
          progress = progressData.get {@classroom, @course, user: @finishedMember}
          expect(progress.completed).toBe true
          expect(progress.started).toBe true

      describe 'when the student has NOT completed the course', ->
        it 'progressData.get({classroom, course, user}) returns object with .completed=false and .started=true', ->
          progressData = helper.calculateAllProgress(@classrooms, @courses, @courseInstances, @members)
          progress = progressData.get {@classroom, @course, user: @unfinishedMember}
          expect(progress.completed).toBe false
          expect(progress.started).toBe true

      describe 'when the student has completed the level', ->
        it 'progressData.get({classroom, course, level, user}) returns object with .completed=true and .started=true', ->
          progressData = helper.calculateAllProgress(@classrooms, @courses, @courseInstances, @members)
          for level in @levels.models
            continue if level.get('practice')
            progress = progressData.get {@classroom, @course, level, user: @finishedMember}
            expect(progress.completed).toBe true
            expect(progress.started).toBe true

      describe 'when the student has NOT completed the level but has started', ->
        it 'progressData.get({classroom, course, level, user}) returns object with .completed=true and .started=true', ->
          progressData = helper.calculateAllProgress(@classrooms, @courses, @courseInstances, @members)
          level = @levels.first()
          progress = progressData.get {@classroom, @course, level, user: @unfinishedMember}
          expect(progress.completed).toBe false
          expect(progress.started).toBe true

      describe 'when the student has NOT started the level', ->
        it 'progressData.get({classroom, course, level, user}) returns object with .completed=false and .started=false', ->
          progressData = helper.calculateAllProgress(@classrooms, @courses, @courseInstances, @members)
          level = @levels.last()
          progress = progressData.get {@classroom, @course, level, user: @unfinishedMember}
          expect(progress.completed).toBe false
          expect(progress.started).toBe false
    
    describe 'progressData.get({classroom, course, level:practiceLevel})', ->
      it 'returns an object with .completed=true if there\'s at least one completed session and no incomplete sessions', ->
        @classroom.sessions = new LevelSessions()
        progressData = helper.calculateAllProgress(@classrooms, @courses, @courseInstances, @members)
        progress = progressData.get {@classroom, @course, level: @practiceLevel}
        expect(progress.completed).toBe false
        expect(progress.started).toBe false

        @classroom.sessions.push(factories.makeLevelSession(
            {state: {complete: true}},
            {level: @practiceLevel, creator: @members.first()})
        )
        progressData = helper.calculateAllProgress(@classrooms, @courses, @courseInstances, @members)
        progress = progressData.get {@classroom, @course, level: @practiceLevel}
        expect(progress.completed).toBe false
        expect(progress.started).toBe true
        progress = progressData.get {@classroom, @course, level: @practiceLevel}

        @classroom.sessions.push(factories.makeLevelSession(
            {state: {complete: false}},
            {level: @practiceLevel, creator: @members.last()})
        )
        progressData = helper.calculateAllProgress(@classrooms, @courses, @courseInstances, @members)
        progress = progressData.get {@classroom, @course, level: @practiceLevel}
        expect(progress.completed).toBe false
        expect(progress.started).toBe true

  describe 'hasUserCompletedCourse', ->
    it 'user completed a single level but hasn\'t completed all levels', ->
      [userStarted, allComplete, levelsCompleted] = helper.hasUserCompletedCourse({'a': true}, new Set(['a', 'b']))
      expect(userStarted).toBe true
      expect(allComplete).toBe false
      expect(levelsCompleted).toEqual 1

    it 'user completed all levels', ->
      [userStarted, allComplete, levelsCompleted] = helper.hasUserCompletedCourse({'a': true, 'b': true}, new Set(['a', 'b']))
      expect(userStarted).toBe true
      expect(allComplete).toBe true
      expect(levelsCompleted).toEqual 2

    it 'undefined user state passed in', ->
      [userStarted, allComplete, levelsCompleted] = helper.hasUserCompletedCourse(undefined, new Set(['a']))
      expect(userStarted).toBe false
      expect(allComplete).toBe false
      expect(levelsCompleted).toEqual 0

    it "User hasn't completed all levels", ->
      [userStarted, allComplete, levelsCompleted] = helper.hasUserCompletedCourse({'a': true, 'b': false}, new Set(['a', 'b']))
      expect(userStarted).toBe true
      expect(allComplete).toBe false
      expect(levelsCompleted).toEqual 1

    it "User has completed required levels", ->
      [userStarted, allComplete, levelsCompleted] = helper.hasUserCompletedCourse({'a': true, 'b': false}, new Set(['a']))
      expect(userStarted).toBe true
      expect(allComplete).toBe true
      expect(levelsCompleted).toEqual 1

    it "User has completed different levels", ->
      [userStarted, allComplete, levelsCompleted] = helper.hasUserCompletedCourse({'a': true, 'b': true}, new Set(['c']))
      expect(userStarted).toBe false
      expect(allComplete).toBe false
      expect(levelsCompleted).toEqual 0
