require '../common'
User = require '../../../server/models/User'
utils = require '../utils'
_ = require 'lodash'
Promise = require 'bluebird'
nock = require 'nock'
request = require '../request'
sendwithus = require '../../../server/sendwithus'
LevelSession = require '../../../server/models/LevelSession'

urlLogin = getURL('/auth/login')
urlReset = getURL('/auth/reset')

describe 'GET /auth/whoami', ->
  it 'returns 200', utils.wrap (done) ->
    [res, body] = yield request.getAsync(getURL('/auth/whoami'))
    expect(res.statusCode).toBe(200)
    done()

describe 'POST /auth/login', ->
  
  beforeEach utils.wrap (done) ->
    yield utils.clearModels([User])
    yield utils.becomeAnonymous()
    done()

  it 'returns 401 when the user does not exist', utils.wrap (done) ->
    [res, body] = yield request.postAsync({uri: urlLogin, json: {
      username: 'some@email.com'
      password: '12345'
    }})
    expect(res.statusCode).toBe(401)
    done()
    
  it 'returns 200 when the user does exist', utils.wrap (done) ->
    yield utils.initUser({
      'email': 'some@email.com'
      'password': '12345'
    })
    [res, body] = yield request.postAsync({uri: urlLogin, json: {
      username: 'some@email.com'
      password: '12345'
    }})
    expect(res.statusCode).toBe(200)
    done()
    
  it 'allows login by username', utils.wrap (done) ->
    yield utils.initUser({
      name: 'Some name that will be lowercased...'
      'email': 'some@email.com'
      'password': '12345'
    })
    [res, body] = yield request.postAsync({uri: urlLogin, json: {
      username: 'Some name that will be lowercased...'
      password: '12345'
    }})
    expect(res.statusCode).toBe(200)
    done()

  it 'rejects wrong passwords', utils.wrap (done) ->
    yield utils.initUser({
      'email': 'some@email.com'
      'password': '12345'
    })
    [res, body] = yield request.postAsync({uri: urlLogin, json: {
      username: 'some@email.com'
      password: '12346'
    }})
    expect(res.statusCode).toBe(401)
    done()

  it 'is completely case insensitive', utils.wrap (done) ->
    yield utils.initUser({
      'email': 'Some@Email.com'
      'password': 'AbCdE'
    })
    [res, body] = yield request.postAsync({uri: urlLogin, json: {
      username: 'sOmE@eMaIl.com'
      password: 'aBcDe'
    }})
    expect(res.statusCode).toBe(200)
    done()

describe 'POST /auth/reset', ->

  beforeEach utils.wrap (done) ->
    yield utils.clearModels([User])
    @user = yield utils.initUser({
      'email': 'some@email.com'
      'password': '12345'
    })
    done()
  
  it 'returns 422 if no email is included', utils.wrap (done) ->
    [res, body] = yield request.postAsync(
      {uri: urlReset, json: {username: 'some@email.com'}}
    )
    expect(res.statusCode).toBe(422)
    done()

  it 'returns 404 if account not found', utils.wrap (done) ->
    [res, body] = yield request.postAsync(
      {uri: urlReset, json: {email: 'some@other-email.com'}}
    )
    expect(res.statusCode).toBe(404)
    done()

  it 'resets the user password', utils.wrap (done) ->
    spyOn(sendwithus.api, 'send').and.callFake (options, cb) ->
      expect(options.recipient.address).toBe('some@email.com')
      cb()
    [res, body] = yield request.postAsync(
      {uri: urlReset, json: {email: 'some@email.com'}}
    )
    expect(res.statusCode).toBe(200)
    expect(sendwithus.api.send).toHaveBeenCalled()
    user = yield User.findById(@user.id)
    passwordReset = user.get('passwordReset')
    expect(passwordReset).toBeTruthy()
    [res, body] = yield request.postAsync({uri: urlLogin, json: {
      username: 'some@email.com'
      password: passwordReset
    }})
    expect(res.statusCode).toBe(200)
    
    done()
    
  it 'resetting password is not idempotent', utils.wrap (done) ->
    spyOn(sendwithus.api, 'send').and.callFake (options, cb) ->
      expect(options.recipient.address).toBe('some@email.com')
      cb()
    [res, body] = yield request.postAsync(
      {uri: urlReset, json: {email: 'some@email.com'}}
    )
    expect(res.statusCode).toBe(200)
    user = yield User.findById(@user.id)
    passwordReset = user.get('passwordReset')
    expect(passwordReset).toBeTruthy()
    postArgs = {uri: urlLogin, json: {
      username: 'some@email.com'
      password: passwordReset
    }}
    
    [res, body] = yield request.postAsync(postArgs)
    expect(res.statusCode).toBe(200)
    [res, body] = yield request.postAsync(postArgs)
    expect(res.statusCode).toBe(401)
    done()

describe 'GET /auth/unsubscribe', ->

  beforeEach utils.wrap (done) ->
    yield utils.clearModels([User])
    @user = yield utils.initUser()
    done()
    
  it 'returns 422 if email is not included', utils.wrap (done) ->
    url = getURL('/auth/unsubscribe')
    [res, body] = yield request.getAsync(url)
    expect(res.statusCode).toBe(422)
    done()

  it 'returns 404 if email is not found', utils.wrap (done) ->
    url = getURL('/auth/unsubscribe?email=ladeeda')
    [res, body] = yield request.getAsync(url)
    expect(res.statusCode).toBe(404)
    done()
    
  it 'returns 200 even if the email has a + in it', utils.wrap (done) ->
    @user.set('email', 'some+email@address.com')
    yield @user.save()
    url = getURL('/auth/unsubscribe?recruitNotes=1&email='+@user.get('email'))
    [res, body] = yield request.getAsync(url, {json: true})
    expect(res.statusCode).toBe(200)
    done()
    
  describe '?recruitNotes=1', ->

    it 'unsubscribes the user from recruitment emails', utils.wrap (done) ->
      url = getURL('/auth/unsubscribe?recruitNotes=1&email='+@user.get('email'))
      [res, body] = yield request.getAsync(url)
      expect(res.statusCode).toBe(200)
      user = yield User.findOne(@user._id)
      expect(user.get('emails').recruitNotes.enabled).toBe(false)
      expect(user.isEmailSubscriptionEnabled('generalNews')).toBeTruthy()
      done()
    
  describe '?employerNotes=1', ->

    it 'unsubscribes the user from employer emails', utils.wrap (done) ->
      url = getURL('/auth/unsubscribe?employerNotes=1&email='+@user.get('email'))
      [res, body] = yield request.getAsync(url)
      expect(res.statusCode).toBe(200)
      user = yield User.findOne(@user._id)
      expect(user.get('emails').employerNotes.enabled).toBe(false)
      expect(user.isEmailSubscriptionEnabled('generalNews')).toBeTruthy()
      done()

  describe '?session=:id', ->

    it 'sets the given LevelSession\'s unsubscribed property to true', utils.wrap (done) ->
      session = new LevelSession({permissions:[target: @user._id, access: 'owner']})
      yield session.save()
      url = getURL("/auth/unsubscribe?session=#{session.id}&email=#{@user.get('email')}")
      [res, body] = yield request.getAsync(url)
      expect(res.statusCode).toBe(200)
      session = yield LevelSession.findById(session.id)
      expect(session.get('unsubscribed')).toBe(true)
      done()

  describe 'no GET query params', ->
    
    it 'unsubscribes the user from all emails', utils.wrap (done) ->
      url = getURL("/auth/unsubscribe?email=#{@user.get('email')}")
      [res, body] = yield request.getAsync(url)
      expect(res.statusCode).toBe(200)
      user = yield User.findOne(@user._id)
      expect(user.get('emails').generalNews.enabled).toBe(false)
      expect(user.get('emails').anyNotes.enabled).toBe(false)
      done()

describe 'GET /auth/name', ->
  url = '/auth/name'

  beforeEach utils.wrap (done) ->
    yield utils.clearModels([User])
    done()

  it 'returns 422 if no name is provided', utils.wrap (done) ->
    [res, body] = yield request.getAsync {url: getURL(url + '/'), json: true}
    expect(res.statusCode).toBe 422
    done()

  it 'returns an object with properties conflicts, givenName and suggestedName', utils.wrap (done) ->
    [res, body] = yield request.getAsync {url: getURL(url + '/Gandalf'), json: true}
    expect(res.statusCode).toBe 200
    expect(res.body.givenName).toBe 'Gandalf'
    expect(res.body.conflicts).toBe false
    expect(res.body.suggestedName).toBe 'Gandalf'

    yield utils.initUser({name: 'joe'})
    [res, body] = yield request.getAsync {url: getURL(url + '/joe'), json: {}}
    expect(res.statusCode).toBe 200
    expect(res.body.suggestedName).not.toBe 'joe'
    expect(res.body.conflicts).toBe true
    expect(/joe[0-9]/.test(res.body.suggestedName)).toBe(true)

    done()

    
describe 'POST /auth/login-facebook', ->
  beforeEach utils.wrap (done) ->
    yield utils.clearModels([User])
    done()
    
  afterEach -> 
    nock.cleanAll()
  
  url = getURL('/auth/login-facebook')
  it 'takes facebookID and facebookAccessToken and logs the user in', utils.wrap (done) ->
    nock('https://graph.facebook.com').get('/me').query({access_token: 'abcd'}).reply(200, { id: '1234' })
    yield new User({name: 'someone', facebookID: '1234'}).save()
    [res, body] = yield request.postAsync url, { json: { facebookID: '1234', facebookAccessToken: 'abcd' }}
    expect(res.statusCode).toBe(200)
    done()
    
  it 'returns 422 if no token or id is provided', utils.wrap (done) ->
    [res, body] = yield request.postAsync url
    expect(res.statusCode).toBe(422)
    done()
  
  it 'returns 422 if the token is invalid', utils.wrap (done) ->
    nock('https://graph.facebook.com').get('/me').query({access_token: 'abcd'}).reply(400, {})
    yield new User({name: 'someone', facebookID: '1234'}).save()
    [res, body] = yield request.postAsync url, { json: { facebookID: '1234', facebookAccessToken: 'abcd' }}
    expect(res.statusCode).toBe(422)
    done()
  
  it 'returns 404 if the user does not already exist', utils.wrap (done) ->
    nock('https://graph.facebook.com').get('/me').query({access_token: 'abcd'}).reply(200, { id: '1234' })
    [res, body] = yield request.postAsync url, { json: { facebookID: '1234', facebookAccessToken: 'abcd' }}
    expect(res.statusCode).toBe(404)
    done()


describe 'POST /auth/login-gplus', ->
  beforeEach utils.wrap (done) ->
    yield utils.clearModels([User])
    done()

  afterEach ->
    nock.cleanAll()

  url = getURL('/auth/login-gplus')
  it 'takes gplusID and gplusAccessToken and logs the user in', utils.wrap (done) ->
    nock('https://www.googleapis.com').get('/oauth2/v2/userinfo').query({access_token: 'abcd'}).reply(200, { id: '1234' })
    yield new User({name: 'someone', gplusID: '1234'}).save()
    [res, body] = yield request.postAsync url, { json: { gplusID: '1234', gplusAccessToken: 'abcd' }}
    expect(res.statusCode).toBe(200)
    done()

  it 'returns 422 if no token or id is provided', utils.wrap (done) ->
    [res, body] = yield request.postAsync url
    expect(res.statusCode).toBe(422)
    done()

  it 'returns 422 if the token is invalid', utils.wrap (done) ->
    nock('https://www.googleapis.com').get('/oauth2/v2/userinfo').query({access_token: 'abcd'}).reply(400, {})
    yield new User({name: 'someone', gplusID: '1234'}).save()
    [res, body] = yield request.postAsync url, { json: { gplusID: '1234', gplusAccessToken: 'abcd' }}
    expect(res.statusCode).toBe(422)
    done()

  it 'returns 404 if the user does not already exist', utils.wrap (done) ->
    nock('https://www.googleapis.com').get('/oauth2/v2/userinfo').query({access_token: 'abcd'}).reply(200, { id: '1234' })
    [res, body] = yield request.postAsync url, { json: { gplusID: '1234', gplusAccessToken: 'abcd' }}
    expect(res.statusCode).toBe(404)
    done()
          
      
describe 'POST /auth/spy', ->
  beforeEach utils.wrap (done) ->
    yield utils.clearModels([User])
    @admin = yield utils.initAdmin()
    @user1 = yield utils.initUser({name: 'Test User 1'})
    @user2 = yield utils.initUser({name: 'Test User 2'})
    done()
  
  it 'logs in an admin as an arbitrary user', utils.wrap (done) ->
    yield utils.loginUser(@admin)
    [res, body] = yield request.postAsync {uri: getURL('/auth/spy'), json: {user: @user1.id}}
    expect(res.statusCode).toBe(200)
    expect(body._id).toBe(@user1.id)
    [res, body] = yield request.getAsync {uri: getURL('/auth/whoami'), json: true}
    expect(body._id).toBe(@user1.id)
    done()

  it 'accepts the user\'s email as input', utils.wrap (done) ->
    yield utils.loginUser(@admin)
    [res, body] = yield request.postAsync {uri: getURL('/auth/spy'), json: {user: @user1.get('email')}}
    expect(res.statusCode).toBe(200)
    expect(body._id).toBe(@user1.id)
    done()
    
  it 'accepts the user\'s username as input', utils.wrap (done) ->
    yield utils.loginUser(@admin)
    [res, body] = yield request.postAsync {uri: getURL('/auth/spy'), json: {user: @user1.get('name')}}
    expect(res.statusCode).toBe(200)
    expect(body._id).toBe(@user1.id)
    done()
    
  it 'does not work for anonymous users', utils.wrap (done) ->
    [res, body] = yield request.postAsync {uri: getURL('/auth/spy'), json: {user: @user1.get('name')}}
    expect(res.statusCode).toBe(401)
    done()
    
  it 'does not work for non-admins', utils.wrap (done) ->
    yield utils.loginUser(@user1)
    [res, body] = yield request.postAsync {uri: getURL('/auth/spy'), json: {user: @user1.get('name')}}
    expect(res.statusCode).toBe(403)
    done()

describe 'POST /auth/stop-spying', ->
  beforeEach utils.wrap (done) ->
    yield utils.clearModels([User])
    @admin = yield utils.initAdmin()
    @user = yield utils.initUser()
    yield utils.loginUser(@admin)
    [res, body] = yield request.postAsync {uri: getURL('/auth/spy'), json: {user: @user.id}}
    expect(res.statusCode).toBe(200)
    done()
  
  it 'it reverts the spying user back to the admin', utils.wrap (done) ->
    [res, body] = yield request.getAsync {uri: getURL('/auth/whoami'), json: true}
    expect(body._id).toBe(@user.id)
    [res, body] = yield request.postAsync {uri: getURL('/auth/stop-spying'), json: true}
    expect(res.statusCode).toBe(200)
    expect(body._id).toBe(@admin.id)
    [res, body] = yield request.getAsync {uri: getURL('/auth/whoami'), json: true}
    expect(body._id).toBe(@admin.id)
    done()
