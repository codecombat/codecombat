require '../common'
utils = require '../utils'
_ = require 'lodash'
Promise = require 'bluebird'

fixture = {
  type: 'subscription'
  properties:
    location: 'SF, CA'
    age: '14-17'
    numStudents: 14
    heardAbout: 'magical interwebs'
}

describe 'POST /db/trial.request', ->
  URL = getURL('/db/trial.request')
  ownURL = getURL('/db/trial.request/-/own')
  

  beforeEach utils.wrap (done) ->
    yield utils.clearModels([User, TrialRequest])
    @user = yield utils.initUser()
    yield utils.loginUser(@user)
    fixture.properties.email = @user.get('email')
    [res, body] = yield request.postAsync(getURL('/db/trial.request'), { json: fixture })
    expect(res.statusCode).toBe(201)
    expect(body._id).toBeDefined()
    @trialRequest = yield TrialRequest.findById(body._id)
    done()
  
  it 'sets type and properties given', ->
    expect(@trialRequest.get('type')).toBe('subscription')
    expect(@trialRequest.get('properties').location).toBe('SF, CA')
    
  it 'sets applicant to the user\'s id', ->
    expect(@trialRequest.get('applicant').equals(@user._id)).toBe(true)

describe 'GET /db/trial.request', ->

  beforeEach utils.wrap (done) ->
    yield utils.clearModels([User, TrialRequest])
    @user = yield utils.initUser()
    yield utils.loginUser(@user)
    fixture.properties.email = @user.get('email')
    [res, body] = yield request.postAsync(getURL('/db/trial.request'), { json: fixture })
    @trialRequest = yield TrialRequest.findById(body._id)
    done()
  
  it 'returns 403 to non-admins', utils.wrap (done) ->
    [res, body] = yield request.getAsync(getURL('/db/trial.request'))
    expect(res.statusCode).toEqual(403)
    done()

  it 'returns trial requests to admins', utils.wrap (done) ->
    @admin = yield utils.initAdmin()
    yield utils.loginUser(@admin)
    [res, body] = yield request.getAsync(getURL('/db/trial.request'), { json: true })
    expect(res.statusCode).toEqual(200)
    expect(body.length).toBe(1)
    done()

describe 'GET /db/trial.request?applicant=:userID', ->

  beforeEach utils.wrap (done) ->
    yield utils.clearModels([User, TrialRequest])
    @user1 = yield utils.initUser()
    @user2 = yield utils.initUser()
    yield utils.loginUser(@user1)
    @trialRequest1 = new TrialRequest({applicant: @user1._id})
    yield @trialRequest1.save()
    @trialRequest2 = yield new TrialRequest({applicant: @user2._id}).save()
    done()

  it 'returns trial requests for the given applicant', utils.wrap (done) ->
    [res, body] = yield request.getAsync(getURL('/db/trial.request?applicant='+@user1.id), { json: true })
    expect(res.statusCode).toEqual(200)
    expect(body.length).toBe(1)
    expect(body[0]._id).toBe(@trialRequest1.id)
    done()
    
  it 'returns 403 when non-admins request other people\'s trial requests', utils.wrap (done) ->
    [res, body] = yield request.getAsync(getURL('/db/trial.request?applicant='+@user2.id), { json: true })
    expect(res.statusCode).toEqual(403)
    done()

    
describe 'PUT /db/trial.request/:handle', ->
  putURL = null

  beforeEach utils.wrap (done) ->
    yield utils.clearModels([User, TrialRequest])
    @user = yield utils.initUser()
    yield utils.loginUser(@user)
    fixture.properties.email = @user.get('email')
    [res, body] = yield request.postAsync(getURL('/db/trial.request'), { json: fixture })
    @trialRequest = yield TrialRequest.findById(body._id)
    putURL = getURL('/db/trial.request/'+@trialRequest.id)
    done()
    
  it 'returns 403 to non-admins', ->
    [res, body] = yield request.putAsync(getURL("/db/trial.request/#{@trialRequest.id}"))
    expect(res.statusCode).toEqual(403)
    done()
    
  describe 'set status to "approved"', ->
    
    beforeEach utils.wrap (done) ->
      @admin = yield utils.initAdmin()
      yield utils.loginUser(@admin)
      [res, body] = yield request.putAsync(putURL, { json: { status: 'approved' } })
      expect(res.statusCode).toBe(200)
      expect(body.status).toBe('approved')
      setTimeout done, 10 # let changes propagate
    
    it 'sets reviewDate and reviewer', utils.wrap (done) ->
      trialRequest = yield TrialRequest.findById(@trialRequest.id)
      expect(trialRequest.get('reviewDate')).toBeDefined()
      expect(trialRequest.get('reviewer').equals(@admin._id))
      expect(new Date(trialRequest.get('reviewDate'))).toBeLessThan(new Date())
      done()
    
    it 'gives the user two enrollments', utils.wrap (done) ->
      prepaids = yield Prepaid.find({'properties.trialRequestID': @trialRequest._id})
      expect(prepaids.length).toEqual(1)
      prepaid = prepaids[0]
      expect(prepaid.get('type')).toEqual('course')
      expect(prepaid.get('creator')).toEqual(@user.get('_id'))
      expect(prepaid.get('maxRedeemers')).toEqual(2)
      done()
      
    it 'enables teacherNews for the user', utils.wrap (done) ->
      user = yield User.findById(@user._id)
      expect(user.get('emails')?.teacherNews?.enabled).toEqual(true)
      done()

  describe 'set status to "denied"', ->

    beforeEach utils.wrap (done) ->
      @admin = yield utils.initAdmin()
      yield utils.loginUser(@admin)
      [res, body] = yield request.putAsync(putURL, { json: { status: 'denied' } })
      expect(res.statusCode).toBe(200)
      expect(body.status).toBe('denied')
      setTimeout done, 10 # let changes propagate

    it 'sets reviewDate and reviewer', utils.wrap (done) ->
      trialRequest = yield TrialRequest.findById(@trialRequest.id)
      expect(trialRequest.get('reviewDate')).toBeDefined()
      expect(trialRequest.get('reviewer').equals(@admin._id))
      expect(new Date(trialRequest.get('reviewDate'))).toBeLessThan(new Date())
      done()
      
    it 'does not give the user two enrollments', utils.wrap (done) ->
      prepaids = yield Prepaid.find({'properties.trialRequestID': @trialRequest._id})
      expect(prepaids.length).toEqual(0)
      done()
