User = require '../../../server/models/User'
APIClient = require '../../../server/models/APIClient'
OAuthProvider = require '../../../server/models/OAuthProvider'
utils = require '../utils'
nock = require 'nock'
request = require '../request'
mongoose = require 'mongoose'
moment = require 'moment'
Prepaid = require '../../../server/models/Prepaid'

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
    json = { name: 'name', email: 'e@mail.com' }
    [res, body] = yield request.postAsync({url, json, @auth})
    expect(res.statusCode).toBe(201)
    expect(body.clientCreator).toBe(@client.id)
    expect(body.name).toBe(json.name)
    expect(body.email).toBe(json.email)
    done()
    
    
describe 'GET /api/users/:handle', ->

  url = utils.getURL('/api/users')

  beforeEach utils.wrap (done) ->
    yield utils.clearModels([User, APIClient])
    @client = new APIClient()
    @secret = @client.setNewSecret()
    @auth = { user: @client.id, pass: @secret }
    yield @client.save()
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

  
describe 'POST /api/users/:handle/o-auth-identities', ->

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
    @url = utils.getURL("/api/users/#{@user.id}/o-auth-identities")
    @provider = new OAuthProvider({
      lookupUrlTemplate: 'https://oauth.provider/user?t=<%= accessToken %>'
      tokenUrl: 'https://oauth.provider/oauth2/token'
    })
    @provider.save()
    @json = { provider: @provider.id, accessToken: '1234' }
    @providerNock = nock('https://oauth.provider')
    @providerLookupRequest = @providerNock.get('/user?t=1234')
    done()

  it 'adds a new identity to the user if everything checks out', utils.wrap (done) ->
    @providerLookupRequest.reply(200, {id: 'abcd'})
    [res, body] = yield request.postAsync({ @url, @json, @auth })
    expect(res.statusCode).toBe(200)
    expect(res.body.oAuthIdentities.length).toBe(1)
    expect(res.body.oAuthIdentities[0].id).toBe('abcd')
    expect(res.body.oAuthIdentities[0].provider).toBe(@provider.id)
    done()

  it 'can take a code and do a token lookup', utils.wrap (done) ->
    @providerNock.get('/oauth2/token').reply(200, {access_token: '1234'})
    @providerLookupRequest.reply(200, {id: 'abcd'})
    json = { provider: @provider.id, code: 'xyzzy' }
    [res, body] = yield request.postAsync({ @url, json, @auth })
    expect(res.statusCode).toBe(200)
    expect(res.body.oAuthIdentities.length).toBe(1)
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
