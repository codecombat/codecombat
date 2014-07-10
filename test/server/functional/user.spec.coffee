require '../common'
request = require 'request'
User = require '../../../server/users/User'

urlUser = '/db/user'

describe 'Server user object', ->

  it 'uses the schema defaults to fill in email preferences', (done) ->
    user = new User()
    expect(user.isEmailSubscriptionEnabled('generalNews')).toBeTruthy()
    expect(user.isEmailSubscriptionEnabled('anyNotes')).toBeTruthy()
    expect(user.isEmailSubscriptionEnabled('recruitNotes')).toBeTruthy()
    expect(user.isEmailSubscriptionEnabled('archmageNews')).toBeFalsy()
    done()

  it 'uses old subs if they\'re around', (done) ->
    user = new User()
    user.set 'emailSubscriptions', ['tester']
    expect(user.isEmailSubscriptionEnabled('adventurerNews')).toBeTruthy()
    expect(user.isEmailSubscriptionEnabled('generalNews')).toBeFalsy()
    done()

  it 'maintains the old subs list if it\'s around', (done) ->
    user = new User()
    user.set 'emailSubscriptions', ['tester']
    user.setEmailSubscription('artisanNews', true)
    expect(JSON.stringify(user.get('emailSubscriptions'))).toBe(JSON.stringify(['tester', 'level_creator']))
    done()

describe 'User.updateMailChimp', ->
  makeMC = (callback) ->
    GLOBAL.mc =
      lists:
        subscribe: callback

  it 'uses emails to determine what to send to MailChimp', (done) ->
    makeMC (params) ->
      expect(JSON.stringify(params.merge_vars.groupings[0].groups)).toBe(JSON.stringify(['Announcements']))
      done()

    user = new User({emailSubscriptions: ['announcement'], email: 'tester@gmail.com'})
    User.updateMailChimp(user)

describe 'POST /db/user', ->

  createAnonNameUser = (name, done)->
    request.post getURL('/auth/logout'), ->
      request.get getURL('/auth/whoami'), ->
        req = request.post(getURL('/db/user'), (err, response) ->
          expect(response.statusCode).toBe(200)
          request.get getURL('/auth/whoami'), (request, response, body) ->
            res = JSON.parse(response.body)
            expect(res.anonymous).toBeTruthy()
            expect(res.name).toEqual(name)
            done()
        )
        form = req.form()
        form.append('name', name)

  it 'preparing test : clears the db first', (done) ->
    clearModels [User], (err) ->
      throw err if err
      done()

  it 'converts the password into a hash', (done) ->
    unittest.getNormalJoe (user) ->
      expect(user).toBeTruthy()
      expect(user.get('password')).toBeUndefined()
      expect(user?.get('passwordHash')).not.toBeUndefined()
      if user?.get('passwordHash')?
        expect(user.get('passwordHash')[..5]).toBe('31dc3d')
        expect(user.get('permissions').length).toBe(0)
      done()

  it 'serves the user through /db/user/id', (done) ->
    unittest.getNormalJoe (user) ->
      url = getURL(urlUser+'/'+user._id)
      request.get url, (err, res, body) ->
        expect(res.statusCode).toBe(200)
        user = JSON.parse(body)
        expect(user.email).toBe('normal@jo.com')
        expect(user.passwordHash).toBeUndefined()
        done()

  it 'creates admins based on passwords', (done) ->
    request.post getURL('/auth/logout'), ->
      unittest.getAdmin (user) ->
        expect(user).not.toBeUndefined()
        if user
          expect(user.get('permissions').length).toBe(1)
          expect(user.get('permissions')[0]).toBe('admin')
        done()

  it 'does not return the full user object for regular users.', (done) ->
    loginJoe ->
      unittest.getAdmin (user) ->

        url = getURL(urlUser+'/'+user._id)
        request.get url, (err, res, body) ->
          expect(res.statusCode).toBe(200)
          user = JSON.parse(body)
          expect(user.email).toBeUndefined()
          expect(user.passwordHash).toBeUndefined()
          done()

  it 'should allow setting anonymous user name', (done) ->
    createAnonNameUser('Jim', done)

  it 'should allow multiple anonymous users with same name', (done) ->
    createAnonNameUser('Jim', done)

  it 'should allow setting existing user name to anonymous user', (done) ->
    req = request.post(getURL('/db/user'), (err, response, body) ->
      expect(response.statusCode).toBe(200)
      request.get getURL('/auth/whoami'), (request, response, body) ->
        res = JSON.parse(response.body)
        expect(res.anonymous).toBeFalsy()
        createAnonNameUser 'Jim', done
    )
    form = req.form()
    form.append('email', 'new@user.com')
    form.append('password', 'new')

describe 'PUT /db/user', ->

  it 'logs in as normal joe', (done) ->
    request.post getURL('/auth/logout'),
      loginJoe -> done()

  it 'denies requests without any data', (done) ->
    request.put getURL(urlUser),
      (err, res) ->
        expect(res.statusCode).toBe(422)
        expect(res.body).toBe('No input.')
        done()

  it 'denies requests to edit someone who is not joe', (done) ->
    unittest.getAdmin (admin) ->
      req = request.put getURL(urlUser),
      (err, res) ->
        expect(res.statusCode).toBe(403)
        done()
      req.form().append('_id', admin.id)

  it 'denies invalid data', (done) ->
    unittest.getNormalJoe (joe) ->
      req = request.put getURL(urlUser),
      (err, res) ->
        expect(res.statusCode).toBe(422)
        expect(res.body.indexOf('too long')).toBeGreaterThan(-1)
        done()
      form = req.form()
      form.append('_id', joe.id)
      form.append('email', 'farghlarghlfarghlarghlfarghlarghlfarghlarghlfarghlarghlfarghlar
ghlfarghlarghlfarghlarghlfarghlarghlfarghlarghlfarghlarghlfarghlarghlfarghlarghlfarghlarghl')

  it 'logs in as admin', (done) ->
    loginAdmin -> done()

  it 'denies non-existent ids', (done) ->
    req = request.put getURL(urlUser),
    (err, res) ->
      expect(res.statusCode).toBe(404)
      done()
    form = req.form()
    form.append('_id', '513108d4cb8b610000000004')
    form.append('email', 'perfectly@good.com')

  it 'denies if the email being changed is already taken', (done) ->
    unittest.getNormalJoe (joe) ->
      unittest.getAdmin (admin) ->
        req = request.put getURL(urlUser), (err, res) ->
          expect(res.statusCode).toBe(409)
          expect(res.body.indexOf('already used')).toBeGreaterThan(-1)
          done()
        form = req.form()
        form.append('_id', String(admin._id))
        form.append('email', joe.get('email').toUpperCase())

  it 'does not care if you include your existing name', (done) ->
    unittest.getNormalJoe (joe) ->
      req = request.put getURL(urlUser+'/'+joe._id), (err, res) ->
        expect(res.statusCode).toBe(200)
        done()
      form = req.form()
      form.append('_id', String(joe._id))
      form.append('name', 'Joe')

  it 'accepts name and email changes', (done) ->
    unittest.getNormalJoe (joe) ->
      req = request.put getURL(urlUser), (err, res) ->
        expect(res.statusCode).toBe(200)
        unittest.getUser('Wilhelm', 'New@email.com', 'null', (joe) ->
          expect(joe.get('name')).toBe('Wilhelm')
          expect(joe.get('emailLower')).toBe('new@email.com')
          expect(joe.get('email')).toBe('New@email.com')
          done())
      form = req.form()
      form.append('_id', String(joe._id))
      form.append('email', 'New@email.com')
      form.append('name', 'Wilhelm')

  it 'should not allow two users with the same name slug', (done) ->
    loginSam (sam) ->
      samsName = sam.get 'name'
      sam.set 'name', 'admin'
      request.put {uri:getURL(urlUser + '/' + sam.id), json: sam.toObject()}, (err, response) ->
        expect(err).toBeNull()
        expect(response.statusCode).toBe 409

        # Restore Sam
        sam.set 'name', samsName
        done()

  it 'should silently rename an anonymous user if their name conflicts upon signup', (done) ->
    request.post getURL('/auth/logout'), ->
      request.get getURL('/auth/whoami'), ->
        req = request.post getURL('/db/user'), (err, response) ->
          expect(response.statusCode).toBe(200)
          request.get getURL('/auth/whoami'), (err, response) ->
            expect(err).toBeNull()
            guy = JSON.parse(response.body)
            expect(guy.anonymous).toBeTruthy()
            expect(guy.name).toEqual 'admin'

            guy.email = 'blub@blub' # Email means registration
            req = request.post {url: getURL('/db/user'), json: guy}, (err, response) ->
              expect(err).toBeNull()
              finalGuy = response.body
              expect(finalGuy.anonymous).toBeFalsy()
              expect(finalGuy.name).not.toEqual guy.name
              expect(finalGuy.name.length).toBe guy.name.length + 1
              done()
        form = req.form()
        form.append('name', 'admin')

  it 'should be able to unset a slug by setting an empty name', (done) ->
    loginSam (sam) ->
      samsName = sam.get 'name'
      sam.set 'name', ''
      request.put {uri:getURL(urlUser + '/' + sam.id), json: sam.toObject()}, (err, response) ->
        expect(err).toBeNull()
        expect(response.statusCode).toBe 200
        newSam = response.body

        # Restore Sam
        sam.set 'name', samsName
        request.put {uri:getURL(urlUser + '/' + sam.id), json: sam.toObject()}, (err, response) ->
          expect(err).toBeNull()
          done()

describe 'GET /db/user', ->

  it 'logs in as admin', (done) ->
    req = request.post(getURL('/auth/login'), (error, response) ->
      expect(response.statusCode).toBe(200)
      done()
    )
    form = req.form()
    form.append('username', 'admin@afc.com')
    form.append('password', '80yqxpb38j')

  it 'get schema', (done) ->
    request.get {uri: getURL(urlUser+'/schema')}, (err, res, body) ->
      expect(res.statusCode).toBe(200)
      body = JSON.parse(body)
      expect(body.type).toBeDefined()
      done()

  it 'is able to do a sweet query', (done) ->
    conditions = [
      ['limit', 20]
      ['where', 'email']
      ['equals', 'admin@afc.com']
      ['sort', '-dateCreated']
    ]
    options = {
      url: getURL(urlUser)
      qs: {
        conditions: JSON.stringify(conditions)
      }
    }

    req = request.get(options, (error, response) ->
      expect(response.statusCode).toBe(200)
      res = JSON.parse(response.body)
      expect(res.length).toBeGreaterThan(0)
      done()
    )

  it 'rejects bad conditions', (done) ->
    conditions = [
      ['lime', 20]
    ]
    options = {
      url: getURL(urlUser)
      qs: {
        conditions: JSON.stringify(conditions)
      }
    }

    req = request.get(options, (error, response) ->
      expect(response.statusCode).toBe(422)
      done()
    )

  it 'can fetch myself by id completely', (done) ->
    loginSam (sam) ->
      request.get {url: getURL(urlUser + '/' + sam.id)}, (err, response) ->
        expect(err).toBeNull()
        expect(response.statusCode).toBe(200)
        done()

  it 'can fetch myself by slug completely', (done) ->
    loginSam (sam) ->
      request.get {url: getURL(urlUser + '/sam')}, (err, response) ->
        expect(err).toBeNull()
        expect(response.statusCode).toBe(200)
        guy = JSON.parse response.body
        expect(guy._id).toBe sam.get('_id').toHexString()
        expect(guy.name).toBe sam.get 'name'
        done()

  # TODO Ruben should be able to fetch other users but probably with restricted data access
  # Add to the test case above an extra data check

  xit 'can fetch another user with restricted fields'



