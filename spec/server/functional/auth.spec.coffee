require '../common'
utils = require '../utils'
_ = require 'lodash'
Promise = require 'bluebird'
nock = require 'nock'

urlLogin = getURL('/auth/login')
urlReset = getURL('/auth/reset')

describe '/auth/whoami', ->
  it 'returns 200', (done) ->
    request.get(getURL('/auth/whoami'), (err, response) ->
      expect(response).toBeDefined()
      expect(response.statusCode).toBe(200)
      done()
    )

describe '/auth/login', ->

  it 'clears Users', (done) ->
    clearModels [User], (err) ->
      throw err if err
      request.get getURL('/auth/whoami'), ->
        throw err if err
        done()

  it 'allows logging in by iosIdentifierForVendor', (done) ->
    req = request.post(getURL('/db/user'),
    (error, response) ->
      expect(response).toBeDefined()
      expect(response.statusCode).toBe(200)
      req = request.post(urlLogin, (error, response) ->
        expect(response.statusCode).toBe(200)
        done()
      )
      form = req.form()
      form.append('username', '012345678901234567890123456789012345')
      form.append('password', '12345')
    )
    form = req.form()
    form.append('iosIdentifierForVendor', '012345678901234567890123456789012345')
    form.append('password', '12345')
  
  it 'clears Users', (done) ->
    clearModels [User], (err) ->
      throw err if err
      request.get getURL('/auth/whoami'), ->
        throw err if err
        done()

  it 'finds no user', (done) ->
    req = request.post(urlLogin, (error, response) ->
      expect(response).toBeDefined()
      expect(response.statusCode).toBe(401)
      done()
    )
    form = req.form()
    form.append('username', 'scott@gmail.com')
    form.append('password', 'nada')

  it 'creates a user', (done) ->
    req = request.post(getURL('/db/user'),
      (error, response) ->
        expect(response).toBeDefined()
        expect(response.statusCode).toBe(200)
        done()
    )
    form = req.form()
    form.append('email', 'scott@gmail.com')
    form.append('password', 'nada')

  it 'finds that created user', (done) ->
    req = request.post(urlLogin, (error, response) ->
      expect(response).toBeDefined()
      expect(response.statusCode).toBe(200)
      done()
    )
    form = req.form()
    form.append('username', 'scott@gmail.com')
    form.append('password', 'nada')

  it 'rejects wrong passwords', (done) ->
    req = request.post(urlLogin, (error, response) ->
      expect(response.statusCode).toBe(401)
      expect(response.body.indexOf('wrong')).toBeGreaterThan(-1)
      done()
    )
    form = req.form()
    form.append('username', 'scott@gmail.com')
    form.append('password', 'blahblah')

  it 'is completely case insensitive', (done) ->
    req = request.post(urlLogin, (error, response) ->
      expect(response.statusCode).toBe(200)
      done()
    )
    form = req.form()
    form.append('username', 'scoTT@gmaIL.com')
    form.append('password', 'NaDa')

describe '/auth/reset', ->
  passwordReset = ''

  it 'emails require', (done) ->
    req = request.post(urlReset, (error, response) ->
      expect(response).toBeDefined()
      expect(response.statusCode).toBe(422)
      done()
    )
    form = req.form()
    form.append('username', 'scott@gmail.com')

  it 'can\'t reset an unknown user', (done) ->
    req = request.post(urlReset, (error, response) ->
      expect(response).toBeDefined()
      expect(response.statusCode).toBe(404)
      done()
    )
    form = req.form()
    form.append('email', 'unknow')

  it 'resets user password', (done) ->
    req = request.post(urlReset, (error, response) ->
      expect(response).toBeDefined()
      expect(response.statusCode).toBe(200)
      expect(response.body).toBeDefined()
      passwordReset = response.body
      done()
    )
    form = req.form()
    form.append('email', 'scott@gmail.com')

  it 'can login after resetting', (done) ->
    req = request.post(urlLogin, (error, response) ->
      expect(response).toBeDefined()
      expect(response.statusCode).toBe(200)
      done()
    )
    form = req.form()
    form.append('username', 'scott@gmail.com')
    form.append('password', passwordReset)

  it 'resetting password is not permanent', (done) ->
    req = request.post(urlLogin, (error, response) ->
      expect(response).toBeDefined()
      expect(response.statusCode).toBe(401)
      done()
    )
    form = req.form()
    form.append('username', 'scott@gmail.com')
    form.append('password', passwordReset)


  it 'can still login with old password', (done) ->
    req = request.post(urlLogin, (error, response) ->
      expect(response).toBeDefined()
      expect(response.statusCode).toBe(200)
      done()
    )
    form = req.form()
    form.append('username', 'scott@gmail.com')
    form.append('password', 'nada')

describe '/auth/unsubscribe', ->
  it 'clears Users first', (done) ->
    clearModels [User], (err) ->
      throw err if err
      request.get getURL('/auth/whoami'), ->
        throw err if err
        done()

  it 'removes just recruitment emails if you include ?recruitNotes=1', (done) ->
    loginJoe (joe) ->
      url = getURL('/auth/unsubscribe?recruitNotes=1&email='+joe.get('email'))
      request.get url, (error, response) ->
        expect(response.statusCode).toBe(200)
        user = User.findOne(joe.get('_id')).exec (err, user) ->
          expect(user.get('emails').recruitNotes.enabled).toBe(false)
          expect(user.isEmailSubscriptionEnabled('generalNews')).toBeTruthy()
          done()

describe '/auth/name', ->
  url = '/auth/name'

  it 'must provide a name to check with', (done) ->
    request.get {url: getURL(url + '/'), json: {}}, (err, response) ->
      expect(err).toBeNull()
      expect(response.statusCode).toBe 422
      done()

  it 'can GET a non-conflicting name', (done) ->
    request.get {url: getURL(url + '/Gandalf'), json: {}}, (err, response) ->
      expect(err).toBeNull()
      expect(response.statusCode).toBe 200
      expect(response.body.name).toBe 'Gandalf'
      done()

  it 'can GET a new name in case of conflict', (done) ->
    request.get {url: getURL(url + '/joe'), json: {}}, (err, response) ->
      expect(err).toBeNull()
      expect(response.statusCode).toBe 409
      expect(response.body.name).not.toBe 'joe'
      expect(response.body.name.length).toBe 4 # 'joe' and a random number
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