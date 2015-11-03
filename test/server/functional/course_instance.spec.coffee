async = require 'async'
config = require '../../../server_config'
require '../common'
stripe = require('stripe')(config.stripe.secretKey)
init = require '../init'

describe 'POST /db/course_instance', ->

  beforeEach (done) -> clearModels([CourseInstance, Course, User, Classroom], done)
  beforeEach (done) -> loginJoe (@joe) => done()
  beforeEach init.course()
  beforeEach init.classroom()
  
  it 'creates a CourseInstance', (done) ->
    test = @
    url = getURL('/db/course_instance')
    data = {
      name: 'Some Name'
      courseID: test.course.id
      classroomID: test.classroom.id
    }
    request.post {uri: url, json: data}, (err, res, body) ->
      expect(res.statusCode).toBe(200)
      expect(body.classroomID).toBeDefined()
      done()
      
  it 'fails if the Course does not exist', (done) ->
    test = @
    url = getURL('/db/course_instance')
    data = {
      name: 'Some Name'
      courseID: '123456789012345678901234'
      classroomID: test.classroom.id
    }
    request.post {uri: url, json: data}, (err, res, body) ->
      expect(res.statusCode).toBe(404)
      done()

  it 'fails if the Classroom does not exist', (done) ->
    test = @
    url = getURL('/db/course_instance')
    data = {
      name: 'Some Name'
      courseID: test.course.id
      classroomID: '123456789012345678901234'
    }
    request.post {uri: url, json: data}, (err, res, body) ->
      expect(res.statusCode).toBe(404)
      done()