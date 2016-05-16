require '../common'
utils = require '../utils'
_ = require 'lodash'
Promise = require 'bluebird'
User = require '../../../server/models/User'
TrialRequest = require '../../../server/models/TrialRequest'
Prepaid = require '../../../server/models/Prepaid'
request = require '../request'
delighted = require '../../../server/delighted'

fixture = {
  type: 'subscription'
  properties:
    location: 'SF, CA'
    age: '14-17'
    numStudents: 14
    heardAbout: 'magical interwebs'
    firstName: 'First'
    lastName: 'Last'
}

describe 'POST /db/trial.request', ->
  
  beforeEach utils.wrap (done) ->
    yield utils.clearModels([User, TrialRequest])
    spyOn(delighted, 'postPeople')
    done()

  it 'sets type and properties given', utils.wrap (done) ->
    @user = yield utils.initUser()
    yield utils.loginUser(@user)
    fixture.properties.email = @user.get('email')
    [res, body] = yield request.postAsync(getURL('/db/trial.request'), { json: fixture })
    expect(res.statusCode).toBe(201)
    expect(body._id).toBeDefined()
    @trialRequest = yield TrialRequest.findById(body._id)
    expect(@trialRequest.get('type')).toBe('subscription')
    expect(@trialRequest.get('properties').location).toBe('SF, CA')
    done()

  it 'sets applicant to the user\'s id', utils.wrap (done) ->
    @user = yield utils.initUser()
    yield utils.loginUser(@user)
    fixture.properties.email = @user.get('email')
    [res, body] = yield request.postAsync(getURL('/db/trial.request'), { json: fixture })
    expect(res.statusCode).toBe(201)
    expect(body._id).toBeDefined()
    @trialRequest = yield TrialRequest.findById(body._id)
    expect(@trialRequest.get('applicant').equals(@user._id)).toBe(true)
    done()

  it 'creates trial request for anonymous user', utils.wrap (done) ->
    @user = yield utils.initUser({anonymous: true})
    yield utils.loginUser(@user)
    email = 'someone@test.com'
    fixture.properties.email = email
    [res, body] = yield request.postAsync(getURL('/db/trial.request'), { json: fixture })
    expect(res.statusCode).toBe(201)
    expect(body._id).toBeDefined()
    @trialRequest = yield TrialRequest.findById(body._id)
    expect(@trialRequest.get('properties')?.email).toEqual(email)
    done()

  it 'prevents trial request for anonymous user with conflicting email', utils.wrap (done) ->
    @otherUser = yield utils.initUser()
    @user = yield utils.initUser({anonymous: true})
    yield utils.loginUser(@user)
    [res, body] = yield request.postAsync(getURL('/db/trial.request'), { json: true })
    expect(res.statusCode).toBe(422)
    done()

  it 'updates an existing TrialRequest if there is one', utils.wrap (done) ->
    @user = yield utils.initUser()
    yield utils.loginUser(@user)
    fixture.properties.email = @user.get('email')
    [res, body] = yield request.postAsync(getURL('/db/trial.request'), { json: fixture })
    expect(res.statusCode).toBe(201)
    expect(body._id).toBeDefined()
    trialRequest = yield TrialRequest.findById(body._id)

    update = {
      type: 'course'
      properties:
        location: 'Bahamas'
    }
    [res, body] = yield request.postAsync(getURL('/db/trial.request'), { json: update })
    expect(body.type).toBe('course')
    expect(body.properties.location).toBe('Bahamas')
    expect(body._id).toBe(trialRequest.id)
    count = yield TrialRequest.count()
    expect(count).toBe(1)
    done()
    
  it 'creates a delighted profile', utils.wrap (done) ->
    @user = yield utils.initUser({gender: 'male', lastLevel: 'abcd', preferredLanguage: 'de', testGroupNumber: 1})
    yield utils.loginUser(@user)
    fixture.properties.email = @user.get('email')
    [res, body] = yield request.postAsync(getURL('/db/trial.request'), { json: fixture })
    expect(delighted.postPeople).toHaveBeenCalled()
    args = delighted.postPeople.calls.argsFor(0)
    expect(args[0].email).toBe(@user.get('email'))
    expect(args[0].name).toBe('First Last')
    done()

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

