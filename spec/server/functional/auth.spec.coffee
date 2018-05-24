require '../common'
User = require '../../../server/models/User'
utils = require '../utils'
_ = require 'lodash'
Promise = require 'bluebird'
nock = require 'nock'
request = require '../request'
sendgrid = require '../../../server/sendgrid'
mongoose = require 'mongoose'
LevelSession = require '../../../server/models/LevelSession'
OAuthProvider = require '../../../server/models/OAuthProvider'
config = require '../../../server_config'
querystring = require 'querystring'

urlLogin = getURL('/auth/login')
urlReset = getURL('/auth/reset')

describe 'GET /auth/whoami', ->
  it 'returns 200', utils.wrap (done) ->
    yield utils.logout()
    [res, body] = yield request.getAsync(getURL('/auth/whoami'), {json: true})
    expect(res.body.createdOnHost).toBeTruthy()
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
    spyOn(sendgrid.api, 'send').and.callFake (options, cb) ->
      expect(options.to.email).toBe('some@email.com')
      cb()
    [res, body] = yield request.postAsync(
      {uri: urlReset, json: {email: 'some@email.com'}}
    )
    expect(res.statusCode).toBe(200)
    expect(sendgrid.api.send).toHaveBeenCalled()
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
    spyOn(sendgrid.api, 'send').and.callFake (options, cb) ->
      expect(options.to.email).toBe('some@email.com')
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

    it 'unsubscribes the user from all marketing emails, leaves notification emails intact', utils.wrap (done) ->
      yield @user.update({ $set: {'emails.anyNotes.enabled': true}})
      url = getURL("/auth/unsubscribe?email=#{@user.get('email')}")
      [res, body] = yield request.getAsync(url)
      expect(res.statusCode).toBe(200)
      user = yield User.findOne(@user._id)
      expect(user.get('emails').generalNews.enabled).toBe(false)
      expect(user.get('emails').anyNotes.enabled).toBe(true)
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
    fields = ['email', 'first_name', 'last_name', 'gender'].join(',')
    @facebookRequest = nock('https://graph.facebook.com').get('/v2.8/me').query({access_token: 'abcd', fields})
    done()

  afterEach ->
    nock.cleanAll()

  url = getURL('/auth/login-facebook')
  it 'takes facebookID and facebookAccessToken and logs the user in', utils.wrap (done) ->
    @facebookRequest.reply(200, { id: '1234' })
    yield new User({name: 'someone', facebookID: '1234'}).save()
    [res, body] = yield request.postAsync url, { json: { facebookID: '1234', facebookAccessToken: 'abcd' }}
    expect(res.statusCode).toBe(200)
    done()

  it 'returns 422 if no token or id is provided', utils.wrap (done) ->
    [res, body] = yield request.postAsync url
    expect(res.statusCode).toBe(422)
    done()

  it 'returns 422 if the token is invalid', utils.wrap (done) ->
    @facebookRequest.reply(400, {})
    yield new User({name: 'someone', facebookID: '1234'}).save()
    [res, body] = yield request.postAsync url, { json: { facebookID: '1234', facebookAccessToken: 'abcd' }}
    expect(res.statusCode).toBe(422)
    done()

  it 'returns 404 if the user does not already exist', utils.wrap (done) ->
    @facebookRequest.reply(200, { id: '1234' })
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


describe 'GET /auth/login-clever', ->
  originalCleverConfig = null

  beforeEach utils.wrap (done) ->
    yield utils.clearModels([User])
    originalCleverConfig = config.clever
    config.clever = { client_id: 'x', client_secret: 'y' }
    @tokenRequest = nock('https://clever.com').post('/oauth/tokens')
    @tokenSuccessResponse = { access_token: 'abc' }
    @meRequest = nock('https://api.clever.com').get('/me')
    @meSuccessResponse = { data: { type: 'student', id: 'xyz' } }
    @lookupRequest = nock("https://api.clever.com").get("/v1.1/#{@meSuccessResponse.data.type}s/#{@meSuccessResponse.data.id}")
    @lookupSuccessResponse = { data: { name: { first: 'first', last: 'last' }, email: 'clever@email.com' }}
    @url = utils.getURL("/auth/login-clever")
    @qs = { code: 'code', scope: 'all' }
    done()

  afterEach ->
    config.clever = originalCleverConfig

  it 'creates and logs the user in, and redirects to "/students" if they are a student', utils.wrap (done) ->
    @tokenRequest.reply(200, @tokenSuccessResponse)
    @meRequest.reply(200, @meSuccessResponse)
    @lookupRequest.reply(200, @lookupSuccessResponse)
    [res, body] = yield request.getAsync({ @url, @qs, followRedirect:false })
    expect(res.statusCode).toBe(302)
    expect(res.headers.location).toBe('/students')
    [res, body] = yield request.getAsync({ url: utils.getURL('/auth/whoami'), json: true })
    expect(body.lastName).toBe('last')
    expect(body.firstName).toBe('first')
    expect(body.role).toBe('student')
    expect(body.cleverID).toBe('xyz')
    expect(body.email).toBe('clever@email.com')

    userID = body._id
    userCount = yield User.count()

    # make sure another user is not created
    yield utils.logout()
    @tokenRequest.reply(200, @tokenSuccessResponse)
    @meRequest.reply(200, @meSuccessResponse)
    @lookupRequest.reply(200, @lookupSuccessResponse)
    [res, body] = yield request.getAsync({ @url, @qs, followRedirect:false })
    expect(res.statusCode).toBe(302)
    expect(res.headers.location).toBe('/students')
    [res, body] = yield request.getAsync({ url: utils.getURL('/auth/whoami'), json: true })
    expect(body._id).toBe(userID)
    expect(yield User.count()).toBe(userCount)
    done()

  it 'redirects to the teacher dashboard if they are a teacher', utils.wrap (done) ->
    @tokenRequest.reply(200, @tokenSuccessResponse)
    @meRequest.reply(200, { data: { type: 'teacher', id: 'xyz' } })
    @lookupRequest = nock("https://api.clever.com").get("/v1.1/teachers/xyz")
    @lookupRequest.reply(200, @lookupSuccessResponse)
    [res, body] = yield request.getAsync({ @url, @qs, followRedirect:false })
    expect(res.statusCode).toBe(302)
    expect(res.headers.location).toBe('/teachers/classes')
    done()


describe 'GET /auth/login-o-auth', ->

  beforeEach utils.wrap (done) ->
    yield utils.clearModels([User])
    @provider = new OAuthProvider({
      lookupUrlTemplate: 'https://oauth.provider/user?t=<%= accessToken %>'
      tokenUrl: 'https://oauth.provider/oauth2/token'
    })
    @provider.save()
    @user = yield utils.initUser({oAuthIdentities: [{provider: @provider._id, id: 'abcd'}]})
    @providerNock = nock('https://oauth.provider')
    @providerLookupRequest = @providerNock.get('/user?t=1234')
    @url = utils.getURL("/auth/login-o-auth")
    @qs = { provider: @provider.id, accessToken: '1234' }
    done()

  it 'logs the user in, and redirects to "/play" if they are a "Home" version user', utils.wrap (done) ->
    @providerLookupRequest.reply(200, {id: 'abcd'})
    [res, body] = yield request.getAsync({ @url, @qs, json:true, followRedirect:false })
    expect(res.statusCode).toBe(302)
    expect(res.headers.location).toBe('/play')
    [res, body] = yield request.getAsync({ url: utils.getURL('/auth/whoami'), json: true })
    expect(res.body._id).toBe(@user.id)
    done()

  it 'redirects to the given "redirect" GET query argument', utils.wrap (done) ->
    @providerLookupRequest.reply(200, {id: 'abcd'})
    @qs.redirect = '/some/arbitrary/url?test=ing'
    [res, body] = yield request.getAsync({ @url, @qs, json:true, followRedirect:false })
    expect(res.statusCode).toBe(302)
    expect(res.headers.location).toBe(@qs.redirect)
    done()

  it 'logs the user in, and redirects to an arbitrary url if the provider specifies', utils.wrap (done) ->
    redirectAfterLogin = 'https://somewhere-else.com/'
    yield @provider.update({$set: {redirectAfterLogin}})
    @providerLookupRequest.reply(200, {id: 'abcd'})
    [res, body] = yield request.getAsync({ @url, @qs, json:true, followRedirect:false })
    expect(res.statusCode).toBe(302)
    expect(res.headers.location).toBe(redirectAfterLogin)
    done()

  it 'redirects the user to "/students" if their role is "student"', utils.wrap (done) ->
    @providerLookupRequest.reply(200, {id: 'abcd'})
    yield @user.update({$set: {role:'student'}})
    [res, body] = yield request.getAsync({ @url, @qs, json:true, followRedirect:false })
    expect(res.statusCode).toBe(302)
    expect(res.headers.location).toBe('/students')
    done()

  it 'redirects the user to "/teachers/classes" if their role is anything but "student"', utils.wrap (done) ->
    @providerLookupRequest.reply(200, {id: 'abcd'})
    yield @user.update({$set: {role:'teacher'}})
    [res, body] = yield request.getAsync({ @url, @qs, json:true, followRedirect:false })
    expect(res.statusCode).toBe(302)
    expect(res.headers.location).toBe('/teachers/classes')
    done()

  it 'can take a code and do a token lookup', utils.wrap (done) ->
    @providerNock.get('/oauth2/token').reply(200, {access_token: '1234'})
    @providerLookupRequest.reply(200, {id: 'abcd'})
    qs =  { provider: @provider.id, code: 'xyzzy' }
    [res, body] = yield request.getAsync({ @url, qs, json:true, followRedirect:false })
    expect(res.statusCode).toBe(302)
    done()

  it 'returns 422 if "provider" and "accessToken" are not provided', utils.wrap (done) ->
    qs = {}
    [res, body] = yield request.getAsync({ @url, qs })
    expect(res.statusCode).toBe(422)
    done()

  it 'returns 404 if the provider is not found', utils.wrap (done) ->
    qs = { provider: new mongoose.Types.ObjectId() + '', accessToken: '1234' }
    [res, body] = yield request.getAsync({ @url, qs })
    expect(res.statusCode).toBe(404)
    done()

  it 'returns 422 if the token lookup fails', utils.wrap (done) ->
    @providerNock.get('/oauth2/token').reply(400, {access_token: '1234'})
    qs =  { provider: @provider.id, code: 'xyzzy' }
    [res, body] = yield request.getAsync({ @url, qs, json:true, followRedirect:false })
    expect(res.statusCode).toBe(422)
    done()

  it 'redirects the user on error when errorRedirect param is provided', utils.wrap (done) ->
    errorRedirect = 'http://source.com/error-happened'
    [res, body] = yield request.getAsync({ @url, qs: { errorRedirect }, followRedirect: false })
    expect(res.statusCode).toBe(302)
    expect(_.startsWith(res.headers.location, errorRedirect)).toBe(true)
    qs = querystring.parse(_.last(res.headers.location.split('?')))
    expect(qs.code).toBe('422')
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
