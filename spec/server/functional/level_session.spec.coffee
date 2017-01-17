LevelSession = require '../../../server/models/LevelSession'
User = require '../../../server/models/User'
mongoose = require 'mongoose'
request = require '../request'
utils = require '../utils'
moment = require 'moment'

describe 'GET /db/level.session/:handle', ->

  beforeEach utils.wrap ->
    yield utils.clearModels([User, LevelSession])
    @user = yield utils.initUser()
    @session = yield utils.makeLevelSession({code: '# some code'}, {creator: @user})
  
  it 'returns the level session', utils.wrap ->
    
    [res, body] = yield request.getAsync({url: utils.getURL("/db/level.session/#{@session.id}"), json: true})
    expect(res.statusCode).toBe(200)
    expect(res.body._id).toBe(@session.id)

  it 'prevents users without permissions', utils.wrap ->
    @session.set('permissions', _.filter(@session.get('permissions'), (p) -> p.target isnt 'public'))
    @session.set('submittedCode', '...')
    yield @session.save()
    [res, body] = yield request.getAsync({url: utils.getURL("/db/level.session/#{@session.id}"), json: true})
    expect(res.statusCode).toBe(403)
    yield utils.loginUser(@user)
    [res, body] = yield request.getAsync({url: utils.getURL("/db/level.session/#{@session.id}"), json: true})
    expect(res.statusCode).toBe(200)

  describe 'recording views', ->
    
    beforeEach utils.wrap ->
      yield @session.update({$set: {'dateFirstCompleted': moment().subtract(1, 'days').toISOString()}})

    it 'records views if within the first four days of session completion', utils.wrap ->
      expect(@session.get('fourDayViewCount')).toBeUndefined()
      anotherUser = yield utils.initUser()
      yield utils.loginUser(anotherUser)
      [res, body] = yield request.getAsync({url: utils.getURL("/db/level.session/#{@session.id}"), json: true})
      expect(res.statusCode).toBe(200)
      session = yield LevelSession.findById(@session.id)
      expect(session.get('fourDayViewCount')).toBe(1)

      [res, body] = yield request.getAsync({url: utils.getURL("/db/level.session/#{@session.id}"), json: true})
      expect(res.statusCode).toBe(200)
      session = yield LevelSession.findById(@session.id)
      expect(session.get('fourDayViewCount')).toBe(2)

      yield @session.update({$set: {'dateFirstCompleted': moment().subtract(5, 'days').toISOString()}})
      [res, body] = yield request.getAsync({url: utils.getURL("/db/level.session/#{@session.id}"), json: true})
      expect(res.statusCode).toBe(200)
      session = yield LevelSession.findById(@session.id)
      expect(session.get('fourDayViewCount')).toBe(2)
      
    it 'does not record views by the creator', utils.wrap ->
      yield utils.loginUser(@user)
      [res, body] = yield request.getAsync({url: utils.getURL("/db/level.session/#{@session.id}"), json: true})
      expect(res.statusCode).toBe(200)
      session = yield LevelSession.findById(@session.id)
      expect(session.get('fourDayViewCount')).toBeUndefined()
    
    it 'does not record views by teachers', utils.wrap ->
      @session.set('dateFirstCompleted', moment().subtract(1, 'day').toISOString())
      yield @session.save()
      teacher = yield utils.initUser({role: 'teacher'})
      yield utils.loginUser(teacher)
      [res, body] = yield request.getAsync({url: utils.getURL("/db/level.session/#{@session.id}"), json: true})
      expect(res.statusCode).toBe(200)
      session = yield LevelSession.findById(@session.id)
      expect(session.get('fourDayViewCount')).toBeUndefined()
  
    
