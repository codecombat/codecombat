require '../common'
Campaign = require '../../../server/models/Campaign'
Classroom = require '../../../server/models/Classroom'
Course = require '../../../server/models/Course'
CourseInstance = require '../../../server/models/CourseInstance'
Level = require '../../../server/models/Level'
User = require '../../../server/models/User'
request = require '../request'
utils = require '../utils'
moment = require 'moment'

describe 'Level', ->

  level =
    name: 'King\'s Peak 3'
    description: 'Climb a mountain.'
    permissions: simplePermissions
    scripts: []
    thangs: []
    documentation: {specificArticles: [], generalArticles: []}

  urlLevel = '/db/level'

  it 'clears things first', (done) ->
    clearModels [Level, User], (err) ->
      expect(err).toBeNull()
      done()

  it 'can make a Level.', (done) ->
    loginJoe ->
      request.post {uri: getURL(urlLevel), json: level}, (err, res, body) ->
        expect(res.statusCode).toBe(200)
        done()

  it 'get schema', (done) ->
    request.get {uri: getURL(urlLevel+'/schema')}, (err, res, body) ->
      expect(res.statusCode).toBe(200)
      body = JSON.parse(body)
      expect(body.type).toBeDefined()
      done()


describe 'GET /db/level/:handle/session', ->

  describe 'when level is a course level', ->

    beforeEach utils.wrap (done) ->
      yield utils.clearModels([Campaign, Course, CourseInstance, Level, User])
      admin = yield utils.initAdmin()
      yield utils.loginUser(admin)
      @level = yield utils.makeLevel({type: 'course'})
      @campaign = yield utils.makeCampaign({}, {levels: [@level]})
      @course = yield utils.makeCourse({free: true}, {campaign: @campaign})
      @student = yield utils.initUser({role: 'student'})
      members = [@student]
      teacher = yield utils.initUser({role: 'teacher'})
      yield utils.loginUser(teacher)
      @classroom = yield utils.makeClassroom({aceConfig: { language: 'javascript' }}, { members })
      @courseInstance = yield utils.makeCourseInstance({}, { @course, @classroom, members })
      @url = getURL("/db/level/#{@level.id}/session")
      yield utils.loginUser(@student)
      done()
      
    it 'creates a new session if the user is in a course with that level', utils.wrap (done) ->
      [res, body] = yield request.getAsync { uri: @url, json: true }
      expect(res.statusCode).toBe(200)
      expect(body.codeLanguage).toBe('javascript')
      done()

    it 'returns 402 if the user is not in a course with that level', utils.wrap (done) ->
      otherStudent = yield utils.initUser({role: 'student'})
      yield utils.loginUser(otherStudent)
      [res, body] = yield request.getAsync({ uri: @url, json: true })
      expect(res.statusCode).toBe(402)
      expect(res.body.message).toBe('You must be in a course which includes this level to play it')
      done()
      
    describe 'when the course is not free', ->
  
      beforeEach utils.wrap (done) ->
        @course.set({free: false})
        yield @course.save()
        done()
      
      it 'returns 402 if the user is not enrolled', utils.wrap (done) ->
        [res, body] = yield request.getAsync({ uri: @url, json: true })
        expect(res.statusCode).toBe(402)
        expect(res.body.message).toBe('You must be enrolled to access this content')
        done()
        
      it 'creates the session if the user is enrolled', utils.wrap (done) ->
        @student.set({
          coursePrepaid: { 
            _id: {}
            startDate: moment().subtract(1, 'month').toISOString()
            endDate: moment().add(1, 'month').toISOString()
          }
        })
        @student.save()
        [res, body] = yield request.getAsync({ uri: @url, json: true })
        expect(res.statusCode).toBe(200)
        done()

      it 'returns 402 if the user\'s enrollment is expired', utils.wrap (done) ->
        @student.set({
          coursePrepaid: {
            _id: {}
            startDate: moment().subtract(2, 'month').toISOString()
            endDate: moment().subtract(1, 'month').toISOString()
          }
        })
        @student.save()
        [res, body] = yield request.getAsync({ uri: @url, json: true })
        expect(res.statusCode).toBe(402)
        expect(res.body.message).toBe('You must be enrolled to access this content')
        done()
      
      
  describe 'when the level is NOT a course level', ->
    
    beforeEach utils.wrap (done) ->
      yield utils.clearModels([Level, User])
      admin = yield utils.initAdmin()
      yield utils.loginUser(admin)
      @level = yield utils.makeLevel()
      
      @player = yield utils.initUser()
      yield utils.loginUser(@player)
      @url = getURL("/db/level/#{@level.id}/session")
      done()
      
    it 'idempotently creates and returns a session for that level', utils.wrap (done) ->
      [res, body] = yield request.getAsync { uri: @url, json: true }
      expect(res.statusCode).toBe(200)
      sessionID = body._id
      [res, body] = yield request.getAsync { uri: @url, json: true }
      expect(body._id).toBe(sessionID)
      done()
