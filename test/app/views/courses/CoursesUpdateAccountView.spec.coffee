CoursesUpdateAccountView = require 'views/courses/CoursesUpdateAccountView'
factories = require 'test/app/factories'

describe '/students/update-account', ->

  describe 'when logged out', ->
    beforeEach (done) ->
      me.clear()
      @view = new CoursesUpdateAccountView()
      @view.render()
      done()

    it 'shows log in button', ->
      expect(@view.$el.find('.login-btn').length).toEqual(1)

  describe 'when logged in as individual', ->
    beforeEach (done) ->
      me.set(factories.makeUser({}).attributes)
      @view = new CoursesUpdateAccountView()
      @view.render()
      expect(@view.$el.find('.login-btn').length).toEqual(0)
      done()

    it 'shows update to teacher button', ->
      expect(@view.$el.find('.update-teacher-btn').length).toEqual(1)

    it 'shows update to student button and classCode input', ->
      expect(@view.$el.find('.update-student-btn').length).toEqual(1)
      expect(@view.$el.find('input[name="classCode"]').length).toEqual(1)

  describe 'when logged in as student', ->
    beforeEach (done) ->
      me.set(factories.makeUser({role: 'student'}).attributes)
      @view = new CoursesUpdateAccountView()
      @view.render()
      expect(@view.$el.find('.login-btn').length).toEqual(0)
      expect(@view.$el.find('.remain-teacher-btn').length).toEqual(0)
      expect(@view.$el.find('.logout-btn').length).toEqual(1)
      done()

    it 'shows remain a student button', ->
      expect(@view.$el.find('.remain-student-btn').length).toEqual(1)
      expect(@view.$el.find('input[name="classCode"]').length).toEqual(0)

    it 'shows update to teacher button', ->
      expect(@view.$el.find('.update-teacher-btn').length).toEqual(1)

  describe 'when logged in as teacher', ->
    beforeEach (done) ->
      me.set(factories.makeUser({role: 'teacher'}).attributes)
      @view = new CoursesUpdateAccountView()
      @view.render()
      expect(@view.$el.find('.login-btn').length).toEqual(0)
      expect(@view.$el.find('.remain-student-btn').length).toEqual(0)
      done()

    it 'shows remain a teacher button', ->
      expect(@view.$el.find('.remain-teacher-btn').length).toEqual(1)

    it 'shows update to student button', ->
      expect(@view.$el.find('.update-student-btn').length).toEqual(1)
      expect(@view.$el.find('input[name="classCode"]').length).toEqual(1)
