User = require '../../../server/models/User'
APIClient = require '../../../server/models/APIClient'
OAuthProvider = require '../../../server/models/OAuthProvider'
utils = require '../utils'
nock = require 'nock'
request = require '../request'
mongoose = require 'mongoose'
moment = require 'moment'
Prepaid = require '../../../server/models/Prepaid'
Classroom = require '../../../server/models/Classroom'
Course = require '../../../server/models/Course'
CourseInstance = require '../../../server/models/CourseInstance'
LevelSession = require '../../../server/models/LevelSession'
Campaign = require '../../../server/models/Campaign'
Level = require '../../../server/models/Level'

describe 'POST /api/users', ->

  url = utils.getURL('/api/users')

  beforeEach utils.wrap (done) ->
    yield utils.clearModels([User, APIClient])
    @client = new APIClient()
    @secret = @client.setNewSecret()
    @auth = { user: @client.id, pass: @secret }
    yield @client.save()
    done()

  it 'creates a user that is marked as having been created by the API client', utils.wrap (done) ->
    json = { name: 'name', email: 'e@mail.com', role: 'teacher' }
    [res, body] = yield request.postAsync({url, json, @auth})
    expect(res.statusCode).toBe(201)
    expect(body.clientCreator).toBe(@client.id)
    expect(body.name).toBe(json.name)
    expect(body.email).toBe(json.email)
    expect(body.role).toBe('teacher')
    done()
    
    
describe 'PUT /api/users/:handle/hero-config', ->

  beforeEach utils.wrap ->
    yield utils.clearModels([User, APIClient])

    @client = yield utils.makeAPIClient()
    @user = yield utils.initUser({clientCreator: @client._id})
    @url = utils.getURL("/api/users/#{@user.id}/hero-config")
    
    admin = yield utils.initAdmin()
    yield utils.loginUser(admin)
    @hero = yield utils.makeThangType({kind: 'Hero'})
    @unit = yield utils.makeThangType({kind: 'Unit'})
    yield utils.logout()
 
  it 'edits the user\'s heroConfig thangType', utils.wrap ->
    json = { thangType: @hero.get('original') }
    [res, body] = yield request.putAsync({@url, json, auth: @client.auth})
    expect(res.statusCode).toBe(200)
    expect(res.body.heroConfig.thangType).toBe(@hero.get('original').toString())
    
  it 'returns 404 if the thangType is not found', utils.wrap ->
    json = { thangType: mongoose.Types.ObjectId() }
    [res, body] = yield request.putAsync({@url, json, auth: @client.auth})
    expect(res.statusCode).toBe(404)
    
  it 'returns 403 if the thangType is NOT a hero', utils.wrap ->
    json = { thangType: @unit.get('original') }
    [res, body] = yield request.putAsync({@url, json, auth: @client.auth})
    expect(res.statusCode).toBe(403)
    
describe 'GET /api/users/:handle', ->

  beforeEach utils.wrap (done) ->
    yield utils.clearModels([User, APIClient])
    
    @client = new APIClient()
    @secret = @client.setNewSecret()
    @auth = { user: @client.id, pass: @secret }
    yield @client.save()

    @otherClient = new APIClient()
    secret = @otherClient.setNewSecret()
    @otherClientAuth = { user: @otherClient.id, pass: secret }
    yield @otherClient.save()

    url = utils.getURL('/api/users')
    json = { name: 'name', email: 'e@mail.com' }
    [res, body] = yield request.postAsync({url, json, @auth})
    @user = yield User.findById(res.body._id)
    done()

  it 'returns the user, including stats', utils.wrap (done) ->
    yield @user.update({$set: {'stats.gamesCompleted':1}})
    url = utils.getURL("/api/users/#{@user.id}")
    [res, body] = yield request.getAsync({url, json: true, @auth})
    expect(res.statusCode).toBe(200)
    expect(body._id).toBe(@user.id)
    expect(body.name).toBe(@user.get('name'))
    expect(body.email).toBe(@user.get('email'))
    expect(body.stats.gamesCompleted).toBe(1)
    done()
    
  it 'returns 403 if the user was not created by the client', utils.wrap (done) ->
    url = utils.getURL("/api/users/#{@user.id}")
    [res, body] = yield request.getAsync({url, json: true, auth: @otherClientAuth})
    expect(res.statusCode).toBe(403)
    done()
    
  it 'returns 200 if the client is Israel and the user has an israelId', utils.wrap (done) ->
    israelClient = new APIClient({_id: new mongoose.Types.ObjectId('582a134eb9bce324006210e7')})
    secret = israelClient.setNewSecret()
    israelAuth = { user: israelClient.id, pass: secret }
    yield israelClient.save()

    url = utils.getURL("/api/users/#{@user.id}")
    
    # when user does not have an israel id
    [res, body] = yield request.getAsync({url, json: true, auth: israelAuth})
    expect(res.statusCode).toBe(403)

    # when the client is not israel
    yield @user.update({$set: {israelId: '12345'}})
    [res, body] = yield request.getAsync({url, json: true, auth: @otherClientAuth})
    expect(res.statusCode).toBe(403)

    # when both conditions are met
    [res, body] = yield request.getAsync({url, json: true, auth: israelAuth})
    expect(res.statusCode).toBe(200)
    done()
    
  it 'gives Snowplow read access to all users', utils.wrap (done) ->
    snowplowClient = new APIClient({_id: new mongoose.Types.ObjectId('5876a40d19b82624002cf18d')})
    secret = snowplowClient.setNewSecret()
    snowplowAuth = { user: snowplowClient.id, pass: secret }
    yield snowplowClient.save()

    url = utils.getURL("/api/users/#{@user.id}")

    # when snowplow
    [res, body] = yield request.getAsync({url, json: true, auth: snowplowAuth})
    expect(res.statusCode).toBe(200)

    # when not snowplow
    [res, body] = yield request.getAsync({url, json: true, auth: @otherClientAuth})
    expect(res.statusCode).toBe(403)

    done()
    
  it 'returns playtime if query param `includePlayTime` is truthy', utils.wrap ->
    admin = yield utils.initAdmin()
    yield utils.loginUser(admin)
    @client = yield utils.makeAPIClient()
    @user = yield utils.initUser({
      clientCreator: @client._id
      oAuthIdentities: [{ provider: '1', id: '2' }] # these are included in search for efficiency
      dateCreated: new Date(2016,1,15)
      country: 'united-states'
    })

    @session1 = yield utils.makeLevelSession({playtime: 30}, {creator: @user})

    @url = utils.getUrl("/api/users/#{@user.id}")
    qs = { includePlayTime: '1' }
    [res] = yield request.getAsync({ @url, json: true, auth: @client.auth, qs })
    expect(res.statusCode).toBe(200)
    expect(res.body.stats.playTime).toBe(30)
    
    
describe 'GET /api/users/:handle/classrooms', ->
  
  beforeEach utils.wrap ->
    yield utils.clearModels([User, Classroom, APIClient, Course, CourseInstance])

    admin = yield utils.initAdmin()
    yield utils.loginUser(admin)
    @course = yield utils.makeCourse({free: true})

    @client = yield utils.makeAPIClient()
    @teacher = yield utils.initUser({role: 'teacher', clientCreator: @client._id})
    yield utils.loginUser(@teacher)
    @student = yield utils.initUser({role: 'student', clientCreator: @client._id})
    @classroom = yield utils.makeClassroom({}, {members: [@student]})
    yield utils.makeCourseInstance({}, {@course, @classroom, members: [@student]})
    @otherTeacher = yield utils.initUser({role: 'teacher', clientCreator: @client._id})
    yield utils.loginUser(@otherTeacher)
    @classroom2 = yield utils.makeClassroom({}, {members: [@student]})
    @classroom3 = yield utils.makeClassroom()
    yield utils.logout()
  
  it 'returns a list of classrooms a student is in', utils.wrap ->
    url = utils.getURL("/api/users/#{@student.id}/classrooms")
    [res, body] = yield request.getAsync({url, json: true, auth: @client.auth})
    expect(res.statusCode).toBe(200)
    expect(res.body[0]._id).toBe(@classroom.id)
    expect(res.body[1]._id).toBe(@classroom2.id)
    expect(res.body[0].courses[0].enrolled.length).toBe(1)
    expect(res.body.length).toBe(2)

  it 'returns a list of classrooms a teacher owns', utils.wrap ->
    url = utils.getURL("/api/users/#{@teacher.id}/classrooms")
    [res, body] = yield request.getAsync({url, json: true, auth: @client.auth})
    expect(res.statusCode).toBe(200)
    expect(res.body[0]._id).toBe(@classroom.id)
    expect(res.body[0].courses[0].enrolled.length).toBe(1)
    expect(res.body.length).toBe(1)

    url = utils.getURL("/api/users/#{@otherTeacher.id}/classrooms")
    [res, body] = yield request.getAsync({url, json: true, auth: @client.auth})
    expect(res.statusCode).toBe(200)
    difference = _.difference((classroom._id for classroom in res.body), [@classroom2.id, @classroom3.id])
    expect(difference.length).toBe(0)
    
  it 'returns 403 if the teacher or student is not created by the client', utils.wrap ->
    yield @student.update({$unset: {clientCreator:''}})
    url = utils.getURL("/api/users/#{@student.id}/classrooms")
    [res, body] = yield request.getAsync({url, json: true, auth: @client.auth})
    expect(res.statusCode).toBe(403)

    yield @teacher.update({$unset: {clientCreator:''}})
    url = utils.getURL("/api/users/#{@teacher.id}/classrooms")
    [res, body] = yield request.getAsync({url, json: true, auth: @client.auth})
    expect(res.statusCode).toBe(403)
  
describe 'POST /api/users/:handle/o-auth-identities', ->

  beforeEach utils.wrap ->
    yield utils.clearModels([User, APIClient])
    @client = new APIClient()
    @secret = @client.setNewSecret()
    yield @client.save()
    @auth = { user: @client.id, pass: @secret }
    url = utils.getURL('/api/users')
    json = { name: 'name', email: 'e@mail.com' }
    [res, body] = yield request.postAsync({url, json, @auth})
    @user = yield User.findById(res.body._id)
    @url = utils.getURL("/api/users/#{@user.id}/o-auth-identities")
    @provider = new OAuthProvider({
      lookupUrlTemplate: 'https://oauth.provider/user?t=<%= accessToken %>'
      tokenUrl: 'https://oauth.provider/oauth2/token'
    })
    yield @provider.save()
    @json = { provider: @provider.id, accessToken: '1234' }
    @providerNock = nock('https://oauth.provider')
    @providerLookupRequest = @providerNock.get('/user?t=1234')

  it 'idempotently adds a new identity to the user if everything checks out', utils.wrap ->
    @providerLookupRequest.reply(200, {id: 'abcd'})
    [res, body] = yield request.postAsync({ @url, @json, @auth })
    expect(res.statusCode).toBe(200)
    expect(res.body.oAuthIdentities.length).toBe(1)
    expect(res.body.oAuthIdentities[0].id).toBe('abcd')
    expect(res.body.oAuthIdentities[0].provider).toBe(@provider.id)

    @providerLookupRequest.reply(200, {id: 'abcd'})
    [res, body] = yield request.postAsync({ @url, @json, @auth })
    expect(res.statusCode).toBe(200)

  it 'can take a code and do a token lookup', utils.wrap (done) ->
    @providerNock.get('/oauth2/token').reply(200, {access_token: '1234'})
    @providerLookupRequest.reply(200, ->
      expect(@req.headers.authorization).toBeUndefined() # should only be provided if tokenAuth is set
      return {id: 'abcd'}
    )
    json = { provider: @provider.id, code: 'xyzzy' }
    [res, body] = yield request.postAsync({ @url, json, @auth })
    expect(res.statusCode).toBe(200)
    expect(res.body.oAuthIdentities.length).toBe(1)
    done()
    
  it 'can send basic http auth if specified in OAuthProvider tokenAuth property', utils.wrap (done) ->
    yield @provider.update({$set: {tokenAuth: { user: 'abcd', pass: '1234' }}})
    @providerNock.get('/oauth2/token').reply(200, ->
      expect(@req.headers.authorization).toBeDefined()
      return {access_token: '1234'}
    )
    @providerLookupRequest.reply(200, {id: 'abcd'})
    json = { provider: @provider.id, code: 'xyzzy' }
    [res, body] = yield request.postAsync({ @url, json, @auth })
    expect(res.statusCode).toBe(200)
    expect(res.body.oAuthIdentities.length).toBe(1)
    done()
    
  it 'sends the token request POST if tokenMethod is set to "post" on provider', utils.wrap (done) ->
    yield @provider.update({$set: {tokenMethod: 'post'}})
    @providerNock.post('/oauth2/token').reply(200, {access_token: '1234'})
    @providerLookupRequest.reply(200, {id: 'abcd'})
    json = { provider: @provider.id, code: 'xyzzy' }
    [res, body] = yield request.postAsync({ @url, json, @auth })
    expect(res.statusCode).toBe(200)
    expect(res.body.oAuthIdentities.length).toBe(1)
    done()
    
  it 'uses the property specified by lookupIdProperty to get the user id from the response', utils.wrap (done) ->
    yield @provider.update({$set: {lookupIdProperty: 'custom_user_ID'}})
    @providerLookupRequest.reply(200, {custom_user_ID: 'abcd'})
    [res, body] = yield request.postAsync({ @url, @json, @auth })
    expect(res.statusCode).toBe(200)
    expect(res.body.oAuthIdentities.length).toBe(1)
    expect(res.body.oAuthIdentities[0].id).toBe('abcd')
    expect(res.body.oAuthIdentities[0].provider).toBe(@provider.id)
    done()

  it 'returns 404 if the user is not found', utils.wrap (done) ->
    url = utils.getURL("/api/users/dne/o-auth-identities")
    [res, body] = yield request.postAsync({ url, @json, @auth })
    expect(res.statusCode).toBe(404)
    done()

  it 'returns 403 if the client did not create the given user', utils.wrap (done) ->
    user = yield utils.initUser()
    url = utils.getURL("/api/users/#{user.id}/o-auth-identities")
    [res, body] = yield request.postAsync({ url, @json, @auth })
    expect(res.statusCode).toBe(403)
    done()

  it 'returns 422 if "provider" and "accessToken" are not provided', utils.wrap (done) ->
    json = {}
    [res, body] = yield request.postAsync({ @url, json, @auth })
    expect(res.statusCode).toBe(422)
    done()

  it 'returns 404 if the provider is not found', utils.wrap (done) ->
    json = { provider: new mongoose.Types.ObjectId() + '', accessToken: '1234' }
    [res, body] = yield request.postAsync({ @url, json, @auth })
    expect(res.statusCode).toBe(404)
    done()

  it 'returns 422 if the token lookup fails', utils.wrap (done) ->
    @providerLookupRequest.reply(400, {})
    [res, body] = yield request.postAsync({ @url, @json, @auth })
    expect(res.statusCode).toBe(422)
    done()
    
  it 'returns 422 if the token lookup does not return an object with an id', utils.wrap (done) ->
    @providerLookupRequest.reply(200, {id: null})
    [res, body] = yield request.postAsync({ @url, @json, @auth })
    expect(res.statusCode).toBe(422)
    done()

  it 'returns 409 if a user already exists with the given id/provider', utils.wrap (done) ->
    yield utils.initUser({oAuthIdentities: [{ provider: @provider._id, id: 'abcd'}]})
    @providerLookupRequest.reply(200, {id: 'abcd'})
    [res, body] = yield request.postAsync({ @url, @json, @auth })
    expect(res.statusCode).toBe(409)
    done()

    
describe 'PUT /api/users/:handle/subscription', ->

  beforeEach utils.wrap (done) ->
    yield utils.clearModels([User, APIClient])
    yield utils.populateProducts()
    @client = new APIClient()
    @secret = @client.setNewSecret()
    yield @client.save()
    @auth = { user: @client.id, pass: @secret }
    url = utils.getURL('/api/users')
    json = { name: 'name', email: 'e@mail.com' }
    [res, body] = yield request.postAsync({url, json, @auth})
    @user = yield User.findById(res.body._id)
    @url = utils.getURL("/api/users/#{@user.id}/subscription")
    @ends = moment().add(12, 'months').toISOString()
    @json = { @ends }
    done()

  it 'provides the user with premium access until the given end date, and creates a prepaid', utils.wrap (done) ->
    expect(@user.hasSubscription()).toBe(false)
    t0 = new Date().toISOString()
    [res, body] = yield request.putAsync({ @url, @json, @auth })
    t1 = new Date().toISOString()
    expect(res.body.subscription.ends).toBe(@ends)
    expect(res.statusCode).toBe(200)
    prepaid = yield Prepaid.findOne({'redeemers.userID': @user._id})
    expect(prepaid).toBeDefined()
    expect(prepaid.get('clientCreator').equals(@client._id)).toBe(true)
    expect(prepaid.get('redeemers')[0].userID.equals(@user._id)).toBe(true)
    expect(prepaid.get('startDate')).toBeGreaterThan(t0)
    expect(prepaid.get('startDate')).toBeLessThan(t1)
    expect(prepaid.get('endDate')).toBe(@ends)
    user = yield User.findById(@user.id)
    expect(user.hasSubscription()).toBe(true)
    done()

  it 'returns 404 if the user is not found', utils.wrap (done) ->
    url = utils.getURL('/api/users/dne/subscription')
    [res, body] = yield request.putAsync({ url, @json, @auth })
    expect(res.statusCode).toBe(404)
    done()

  it 'returns 403 if the user was not created by the client', utils.wrap (done) ->
    yield @user.update({$unset: {clientCreator:1}})
    [res, body] = yield request.putAsync({ @url, @json, @auth })
    expect(res.statusCode).toBe(403)
    done()

  it 'works if the user\'s country is "brazil" and the client is the Brazil client.', utils.wrap ->
    brazilClient = new APIClient({_id: new mongoose.Types.ObjectId('5930b75dee776800313fefca')})
    secret = brazilClient.setNewSecret()
    brazilAuth = { user: brazilClient.id, pass: secret }
    yield brazilClient.save()
    yield @user.update({$set: {country: 'brazil'}})

    [res, body] = yield request.putAsync({ @url, @json, auth: brazilAuth })
    t1 = new Date().toISOString()
    expect(res.body.subscription.ends).toBe(@ends)
    expect(res.statusCode).toBe(200)

  it 'returns 422 if ends is not provided or incorrectly formatted', utils.wrap (done) ->
    json = {}
    [res, body] = yield request.putAsync({ @url, json, @auth })
    expect(res.statusCode).toBe(422)

    json = { ends: '2014-01-01T00:00:00.00Z'}
    [res, body] = yield request.putAsync({ @url, json, @auth })
    expect(res.statusCode).toBe(422)
    
    done()

  it 'returns 422 if the user already has free premium access', utils.wrap (done) ->
    yield @user.update({$set: {stripe: {free:true}}})
    [res, body] = yield request.putAsync({ @url, @json, @auth })
    expect(res.statusCode).toBe(422)
    done()

  describe 'when the user has a terminal subscription already', ->
    it 'returns 422 if the user has access beyond the ends', utils.wrap (done) ->
      free = moment().add(13, 'months').toISOString()
      yield @user.update({$set: {stripe: {free}}})
      [res, body] = yield request.putAsync({ @url, @json, @auth })
      expect(res.statusCode).toBe(422)
      done()
  
    it 'sets the prepaid startDate to the user\'s old terminal subscription end date', utils.wrap (done) ->
      originalFreeUntil = moment().add(6, 'months').toISOString()
      yield @user.update({$set: {stripe: {free: originalFreeUntil}}})
      [res, body] = yield request.putAsync({ @url, @json, @auth })
      expect(res.statusCode).toBe(200)
      prepaid = yield Prepaid.findOne({'redeemers.userID': @user._id})
      expect(prepaid.get('startDate')).toBe(originalFreeUntil)
      done()

    it 'sets the prepaid startDate to now if the user\'s subscription ended already', utils.wrap (done) ->
      originalFreeUntil = moment().subtract(6, 'months').toISOString()
      yield @user.update({$set: {stripe: {free: originalFreeUntil}}})
      t0 = new Date().toISOString()
      [res, body] = yield request.putAsync({ @url, @json, @auth })
      t1 = new Date().toISOString()
      expect(res.statusCode).toBe(200)
      prepaid = yield Prepaid.findOne({'redeemers.userID': @user._id})
      expect(prepaid.get('startDate')).not.toBe(originalFreeUntil)
      expect(prepaid.get('startDate')).toBeGreaterThan(t0)
      expect(prepaid.get('startDate')).toBeLessThan(t1)
      done()


describe 'PUT /api/users/:handle/license', ->

  beforeEach utils.wrap (done) ->
    yield utils.clearModels([User, APIClient])
    @client = new APIClient()
    @secret = @client.setNewSecret()
    yield @client.save()
    @auth = { user: @client.id, pass: @secret }
    url = utils.getURL('/api/users')
    json = { name: 'name', email: 'e@mail.com' }
    [res, body] = yield request.postAsync({url, json, @auth})
    @user = yield User.findById(res.body._id)
    @url = utils.getURL("/api/users/#{@user.id}/license")
    @ends = moment().add(12, 'months').toISOString()
    @json = { @ends }
    done()

  it 'provides the user with premium access until the given end date, and creates a prepaid', utils.wrap (done) ->
    expect(@user.isEnrolled()).toBe(false)
    t0 = new Date().toISOString()
    [res, body] = yield request.putAsync({ @url, @json, @auth })
    t1 = new Date().toISOString()
    expect(res.body.license.ends).toBe(@ends)
    expect(res.statusCode).toBe(200)
    prepaid = yield Prepaid.findOne({'redeemers.userID': @user._id})
    expect(prepaid).toBeDefined()
    expect(prepaid.get('clientCreator').equals(@client._id)).toBe(true)
    expect(prepaid.get('redeemers')[0].userID.equals(@user._id)).toBe(true)
    expect(prepaid.get('startDate')).toBeGreaterThan(t0)
    expect(prepaid.get('startDate')).toBeLessThan(t1)
    expect(prepaid.get('type')).toBe('course')
    expect(prepaid.get('endDate')).toBe(@ends)
    user = yield User.findById(@user.id)
    expect(user.isEnrolled()).toBe(true)
    expect(user.get('role')).toBe('student')
    done()

  it 'returns 404 if the user is not found', utils.wrap (done) ->
    url = utils.getURL('/api/users/dne/license')
    [res, body] = yield request.putAsync({ url, @json, @auth })
    expect(res.statusCode).toBe(404)
    done()

  it 'returns 403 if the user was not created by the client', utils.wrap (done) ->
    yield @user.update({$unset: {clientCreator:1}})
    [res, body] = yield request.putAsync({ @url, @json, @auth })
    expect(res.statusCode).toBe(403)
    done()
    
  it 'works if the user\'s country is "brazil" and the client is the Brazil client.', utils.wrap ->
    brazilClient = new APIClient({_id: new mongoose.Types.ObjectId('5930b75dee776800313fefca')})
    secret = brazilClient.setNewSecret()
    brazilAuth = { user: brazilClient.id, pass: secret }
    yield brazilClient.save()
    yield @user.update({$set: {country: 'brazil'}})

    [res, body] = yield request.putAsync({ @url, @json, auth: brazilAuth })
    t1 = new Date().toISOString()
    expect(res.body.license?.ends).toBe(@ends)
    expect(res.statusCode).toBe(200)

  it 'returns 422 if ends is not provided or incorrectly formatted or in the past', utils.wrap (done) ->
    json = {}
    [res, body] = yield request.putAsync({ @url, json, @auth })
    expect(res.statusCode).toBe(422)

    json = { ends: '2014-01-01T00:00:00.00Z'}
    [res, body] = yield request.putAsync({ @url, json, @auth })
    expect(res.statusCode).toBe(422)

    json = { ends: moment().subtract(1, 'day').toISOString() }
    [res, body] = yield request.putAsync({ @url, json, @auth })
    expect(res.statusCode).toBe(422)

    done()
    
  it 'returns 422 if the user is already enrolled', utils.wrap (done) ->
    yield @user.update({$set: {coursePrepaid:{
      _id: new mongoose.Types.ObjectId()
      endDate: moment().add(1, 'month').toISOString()
      startDate: moment().subtract(1, 'month').toISOString()
    }}})
    [res, body] = yield request.putAsync({ @url, @json, @auth })
    expect(res.statusCode).toBe(422)

    yield @user.update({$set: {coursePrepaid:{
      _id: new mongoose.Types.ObjectId()
      endDate: moment().subtract(1, 'month').toISOString()
      startDate: moment().subtract(2, 'months').toISOString()
    }}})
    [res, body] = yield request.putAsync({ @url, @json, @auth })
    expect(res.statusCode).toBe(200)
    done()


describe 'GET /api/user-lookup/israel-id/:israelId', ->

  beforeEach utils.wrap (done) ->
    yield utils.clearModels([User, APIClient])
    @client = new APIClient()
    @secret = @client.setNewSecret()
    @auth = { user: @client.id, pass: @secret }
    yield @client.save()
    json = { name: 'name', email: 'e@mail.com' }
    url = utils.getURL('/api/users')
    [res, body] = yield request.postAsync({url, json, @auth})
    @user = yield User.findById(res.body._id)
    @israelId = '12345'
    yield @user.update({ $set: { @israelId }})
    done()

  it 'redirects to the user with the given israelId', utils.wrap (done) ->
    url = utils.getURL("/api/user-lookup/israel-id/#{@israelId}")
    [res, body] = yield request.getAsync({url, json: true, @auth, followRedirect: false })
    expect(res.statusCode).toBe(301)
    expect(res.headers.location).toBe("/api/users/#{@user.id}")
    done()
    
  it 'returns 404 if the user is not found', utils.wrap (done) ->
    url = utils.getURL("/api/user-lookup/israel-id/54321")
    [res, body] = yield request.getAsync({url, json: true, @auth, followRedirect: false })
    expect(res.statusCode).toBe(404)
    done()


describe 'GET /api/user-lookup/israel-id/:israelId', ->

  beforeEach utils.wrap (done) ->
    yield utils.clearModels([User, APIClient])
    @client = new APIClient()
    @secret = @client.setNewSecret()
    @auth = { user: @client.id, pass: @secret }
    yield @client.save()
    @user = yield utils.initUser()
    done()

  it 'redirects to the user with the given israelId', utils.wrap (done) ->
    url = utils.getURL("/api/user-lookup/name/#{@user.get('name')}")
    [res, body] = yield request.getAsync({url, json: true, @auth, followRedirect: false })
    expect(res.statusCode).toBe(301)
    expect(res.headers.location).toBe("/api/users/#{@user.id}")
    done()

  it 'returns 404 if the user is not found', utils.wrap (done) ->
    url = utils.getURL("/api/user-lookup/name/54321")
    [res, body] = yield request.getAsync({url, json: true, @auth, followRedirect: false })
    expect(res.statusCode).toBe(404)
    done()
    

describe 'PUT /api/classrooms/:handle/members', ->
  beforeEach utils.wrap (done) ->
    yield utils.clearModels([User, Classroom, APIClient])
    @client = yield utils.makeAPIClient()
    @teacher = yield utils.initUser({role: 'teacher'})
    yield utils.loginUser(@teacher)
    @classroom = yield utils.makeClassroom()
    @student = yield utils.initUser({clientCreator: @client._id})
    yield utils.logout()
    done()
    
  it 'upserts a user into the classroom members list', utils.wrap (done) ->
    url = utils.getURL("/api/classrooms/#{@classroom.id}/members")
    json = { code: @classroom.get('code'), userId: @student.id }
    [res, body] = yield request.putAsync { url, auth: @client.auth, json }
    expect(res.statusCode).toBe(200)
    expect(res.body.members.length).toBe(1)
    expect(res.body.code).toBeUndefined()
    expect(res.body.codeCamel).toBeUndefined()
    done()
    
  it 'is case insensitive for the code', utils.wrap ->
    url = utils.getURL("/api/classrooms/#{@classroom.id}/members")
    json = { code: @classroom.get('code').toUpperCase(), userId: @student.id }
    [res, body] = yield request.putAsync { url, auth: @client.auth, json }
    expect(res.statusCode).toBe(200)

  it 'accepts user handles', utils.wrap (done) ->
    url = utils.getURL("/api/classrooms/#{@classroom.id}/members")
    json = { code: @classroom.get('code'), userId: @student.get('slug') }
    [res, body] = yield request.putAsync { url, auth: @client.auth, json }
    expect(res.statusCode).toBe(200)
    expect(res.body.members.length).toBe(1)
    done()
    
    
describe 'PUT /api/classrooms/:classroomHandle/courses/:courseHandle/enrolled', ->
  
  beforeEach utils.wrap ->
    yield utils.clearModels([User, Classroom, APIClient, Course, CourseInstance])
    
    admin = yield utils.initAdmin()
    yield utils.loginUser(admin)
    @freeCourse = yield utils.makeCourse({free: true})
    @paidCourse = yield utils.makeCourse({free: false})
    
    @client = yield utils.makeAPIClient()
    @teacher = yield utils.initUser({role: 'teacher', clientCreator: @client._id})
    yield utils.loginUser(@teacher)
    @student = yield utils.initUser({clientCreator: @client._id})
    @classroom = yield utils.makeClassroom({}, {members: [@student]})
    @freeCourse.url = utils.getURL("/api/classrooms/#{@classroom.id}/courses/#{@freeCourse.id}/enrolled")
    @paidCourse.url = utils.getURL("/api/classrooms/#{@classroom.id}/courses/#{@paidCourse.id}/enrolled")
    @json = { userId: @student.id }
    
  it 'upserts the user to the course instance, creating one if necessary', utils.wrap (done) ->
    courseInstanceQuery = {courseID: @freeCourse._id, classroomID: @classroom._id}
    courseInstance = yield CourseInstance.findOne(courseInstanceQuery)
    expect(courseInstance).toBe(null)
    
    [res, body] = yield request.putAsync({url: @freeCourse.url, @json, auth: @client.auth})
    expect(body.courses[0].enrolled.length).toBe(1)
    courseInstance = yield CourseInstance.findOne(courseInstanceQuery)
    expect(courseInstance.get('members').length).toBe(1)
    expect(courseInstance.get('members')[0].equals(@student._id)).toBe(true)
    courseInstanceCount = yield CourseInstance.count()
    expect(courseInstanceCount).toBe(1)

    # check idempotence
    [res, body] = yield request.putAsync({url: @freeCourse.url, @json, auth: @client.auth})
    courseInstance = yield CourseInstance.findOne(courseInstanceQuery)
    expect(courseInstance.get('members').length).toBe(1)
    courseInstanceCount = yield CourseInstance.count()
    expect(courseInstanceCount).toBe(1)
    done()
    
  it 'returns 403 if the client did not create the student', utils.wrap ->
    yield @student.update({$unset: {clientCreator: ''}})
    [res, body] = yield request.putAsync({url: @freeCourse.url, @json, auth: @client.auth})
    expect(res.statusCode).toBe(403)

  it 'returns 403 if the client did not create the classroom owner', utils.wrap ->
    yield @teacher.update({$unset: {clientCreator: ''}})
    [res, body] = yield request.putAsync({url: @freeCourse.url, @json, auth: @client.auth})
    expect(res.statusCode).toBe(403)



describe 'GET /api/classrooms/:classroomHandle/members/:memberHandle/sessions', ->

  beforeEach utils.wrap (done) ->
    yield utils.clearModels([CourseInstance, Course, User, Classroom, Campaign, Level, LevelSession])
    @client = yield utils.makeAPIClient()
    @teacher = yield utils.initUser({role: 'teacher', clientCreator: @client._id})
    admin = yield utils.initAdmin()
    yield utils.loginUser(admin)
    @levelA = yield utils.makeLevel({type: 'course'})
    @levelB = yield utils.makeLevel({type: 'course', primerLanguage: 'python'})
    @campaignA = yield utils.makeCampaign({}, {levels: [@levelA]})
    @campaignB = yield utils.makeCampaign({}, {levels: [@levelB]})
    @courseA = yield utils.makeCourse({free: true, releasePhase: 'released'}, {campaign: @campaignA})
    @courseB = yield utils.makeCourse({free: true, releasePhase: 'released'}, {campaign: @campaignB})
    @student1 = yield utils.initUser({role: 'student', clientCreator: @client._id})
    @student2 = yield utils.initUser({role: 'student', clientCreator: @client._id})
    @session1A = yield utils.makeLevelSession({codeLanguage: 'javascript', state: { complete: true }}, {creator: @student1, level: @levelA})
    @session1B = yield utils.makeLevelSession({codeLanguage: 'python', state: { complete: false }}, {creator: @student1, level: @levelB})
    @session2A = yield utils.makeLevelSession({codeLanguage: 'javascript', state: { complete: true }}, {creator: @student2, level: @levelA})
    @session2B = yield utils.makeLevelSession({codeLanguage: 'python', state: { complete: false }}, {creator: @student2, level: @levelB})
    yield utils.loginUser(@teacher)
    @classroom = yield utils.makeClassroom({aceConfig: {language: 'javascript'}}, { members: [@student1, @student2] })
    @courseInstanceA = yield utils.makeCourseInstance({courseID: @courseA.id, classroomID: @classroom.id}, { members: [@student1, @student2] })
    @courseInstanceB = yield utils.makeCourseInstance({courseID: @courseB.id, classroomID: @classroom.id}, { members: [@student1] })
    yield utils.logout()
    done()

  it 'returns all sessions for a member in the classroom with assigned courses', utils.wrap ->
    url = getURL("/api/classrooms/#{@classroom.id}/members/#{@student1.id}/sessions")
    [res, body] = yield request.getAsync({url, json: true, auth: @client.auth})
    expect(res.statusCode).toBe(200)
    expect(body.length).toBe(2)

    url = getURL("/api/classrooms/#{@classroom.id}/members/#{@student2.id}/sessions")
    [res, body] = yield request.getAsync({url, json: true, auth: @client.auth})
    expect(res.statusCode).toBe(200)
    expect(body.length).toBe(1)

  it 'returns 403 if the client did not create the student', utils.wrap ->
    yield @student1.update({$unset: {clientCreator: ''}})
    url = getURL("/api/classrooms/#{@classroom.id}/members/#{@student1.id}/sessions")
    [res, body] = yield request.getAsync({url, json: true, auth: @client.auth})
    expect(res.statusCode).toBe(403)

  it 'returns 403 if the client did not create the classroom owner', utils.wrap ->
    yield @teacher.update({$unset: {clientCreator: ''}})
    url = getURL("/api/classrooms/#{@classroom.id}/members/#{@student1.id}/sessions")
    [res, body] = yield request.getAsync({url, json: true, auth: @client.auth})
    expect(res.statusCode).toBe(403)

  
describe 'GET /api/playtime-stats', ->
  
  beforeEach utils.wrap ->
    yield utils.clearModels([User, APIClient, LevelSession])

    admin = yield utils.initAdmin()
    yield utils.loginUser(admin)
    @client = yield utils.makeAPIClient()
    @user1 = yield utils.initUser({
      clientCreator: @client._id
      oAuthIdentities: [{ provider: '1', id: '2' }] # these are included in search for efficiency
      dateCreated: new Date(2016,1,15)
      country: 'united-states'
    })

    @user2 = yield utils.initUser({
      clientCreator: @client._id
      oAuthIdentities: [{ provider: '1', id: '3' }]
      dateCreated: new Date(2016,2,15)
      country: 'brazil'
    })

    @session1 = yield utils.makeLevelSession({playtime: 30}, {creator: @user1})
    @session2 = yield utils.makeLevelSession({playtime: 50}, {creator: @user2})

    @url = utils.getUrl('/api/playtime-stats')
  
  it 'returns aggregate LevelSession playtime data for users created by the client', utils.wrap ->
    [res, body] = yield request.getAsync({ @url, json: true, auth: @client.auth })
    expect(res.body).toDeepEqual({ playTime: 80, gamesPlayed: 2 })

  describe 'query parameters startDate and endDate', ->
    it 'only returns data for users created during the given range', utils.wrap ->
      qs = {
        startDate: new Date(2016,1,1).toISOString(),
        endDate: new Date(2016,2,1).toISOString()
      }
      [res, body] = yield request.getAsync({ @url, json: true, auth: @client.auth, qs })
      expect(res.body).toDeepEqual({ playTime: 30, gamesPlayed: 1 })

      qs = {
        startDate: new Date(2016,3,1).toISOString(),
        endDate: new Date(2016,4,1).toISOString()
      }
      [res, body] = yield request.getAsync({ @url, json: true, auth: @client.auth, qs })
      expect(res.body).toDeepEqual({ playTime: 0, gamesPlayed: 0 })

  describe 'query parameter country', ->
    it 'filters results by country', utils.wrap ->
      qs = { country: 'brazil' }
      [res, body] = yield request.getAsync({ @url, json: true, auth: @client.auth, qs })
      expect(res.body).toDeepEqual({ playTime: 50, gamesPlayed: 1 })

describe 'POST /api/classrooms', ->
  url = utils.getURL('/api/classrooms')

  beforeEach utils.wrap (done) ->
    yield utils.clearModels([User, APIClient, Classroom, Course, Level, Campaign])
    @client = new APIClient()
    @secret = @client.setNewSecret()
    @auth = { user: @client.id, pass: @secret }
    yield @client.save()
    @user = yield utils.initAdmin({clientCreator: @client._id, role: 'teacher'})
    yield utils.loginUser(@user)

    levelJSONA = { name: 'Level A', permissions: [{access: 'owner', target: @user.id}], type: 'course' }
    [res, body] = yield request.postAsync({uri: getURL('/db/level'), json: levelJSONA})
    expect(res.statusCode).toBe(200)
    @levelA = yield Level.findById(res.body._id)
    levelJSONB = { name: 'Level B', permissions: [{access: 'owner', target: @user.id}], type: 'course' }
    [res, body] = yield request.postAsync({uri: getURL('/db/level'), json: levelJSONB})
    expect(res.statusCode).toBe(200)
    @levelB = yield Level.findById(res.body._id)
    levelJSONC = { name: 'Level C', permissions: [{access: 'owner', target: @user.id}], type: 'hero', practice: true }
    [res, body] = yield request.postAsync({uri: getURL('/db/level'), json: levelJSONC})
    expect(res.statusCode).toBe(200)
    @levelC = yield Level.findById(res.body._id)
    levelJSONJSPrimer1 = { name: 'JS Primer 1', permissions: [{access: 'owner', target: @user.id}], type: 'hero', primerLanguage: 'javascript' }
    [res, body] = yield request.postAsync({uri: getURL('/db/level'), json: levelJSONJSPrimer1})
    expect(res.statusCode).toBe(200)
    @levelJSPrimer1 = yield Level.findById(res.body._id)

    campaignJSON = { name: 'Campaign', levels: {} }
    paredLevelJSPrimer1 = _.pick(@levelJSPrimer1.toObject(), 'name', 'original', 'type', 'slug', 'primerLanguage')
    paredLevelJSPrimer1.campaignIndex = 3
    campaignJSON.levels[@levelJSPrimer1.get('original').toString()] = paredLevelJSPrimer1
    paredLevelC = _.pick(@levelC.toObject(), 'name', 'original', 'type', 'slug', 'practice')
    paredLevelC.campaignIndex = 2
    campaignJSON.levels[@levelC.get('original').toString()] = paredLevelC
    paredLevelB = _.pick(@levelB.toObject(), 'name', 'original', 'type', 'slug')
    paredLevelB.campaignIndex = 1
    campaignJSON.levels[@levelB.get('original').toString()] = paredLevelB
    paredLevelA = _.pick(@levelA.toObject(), 'name', 'original', 'type', 'slug')
    paredLevelA.campaignIndex = 0
    campaignJSON.levels[@levelA.get('original').toString()] = paredLevelA
    for levelOriginal, level of campaignJSON.levels
      level.position = { x: 10*level.campaignIndex, y: 10*level.campaignIndex }

    [res, body] = yield request.postAsync({uri: getURL('/db/campaign'), json: campaignJSON})
    @campaign = yield Campaign.findById(res.body._id)
    @course = Course({name: 'Course', campaignID: @campaign._id, releasePhase: 'released'})
    yield @course.save()
    done()

  it 'creates an empty classroom given a teacher ID, classroom name, and code language', utils.wrap (done) ->
    json = { name: 'name', ownerID: @user._id, aceConfig: {language: 'python'} }
    [res, body] = yield request.postAsync({url, json, @auth})
    expect(res.statusCode).toBe(201)
    expect(body.name).toBe(json.name)
    expect(body.ownerID).toBe(json.ownerID.toString())
    expect(body.aceConfig).toDeepEqual(json.aceConfig)
    expect(body.members.length).toBe(0)
    expect(body.courses[0].levels[0].position).toBeDefined()
    done()
      
