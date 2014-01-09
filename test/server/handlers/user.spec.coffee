require '../common'

describe 'POST /db/user', ->
  request = require 'request'
  it 'clears the db first', (done) ->
    clearModels [User], (err) ->
      throw err if err
      done()

  it 'converts the password into a hash', (done) ->
    unittest.getNormalJoe (user) ->
      expect(user).toBeTruthy()
      expect(user.get('password')).toBeUndefined()
      expect(user?.get('passwordHash')).not.toBeUndefined()
      if user?.get('passwordHash')?
        expect(user.get('passwordHash')[..5]).toBe('948c7e')
        expect(user.get('permissions').length).toBe(0)
      done()

  it 'serves the user through /db/user/id', (done) ->
    unittest.getNormalJoe (user) ->
      url = getURL('/db/user/'+user._id)
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

        url = getURL('/db/user/'+user._id)
        request.get url, (err, res, body) ->
          expect(res.statusCode).toBe(200)
          user = JSON.parse(body)
          expect(user.email).toBeUndefined()
          expect(user.passwordHash).toBeUndefined()
          done()


describe 'PUT /db/user', ->

  it 'denies requests without any data', (done) ->
    req = request.post getURL('/auth/logout'),
      (err, res) ->
        expect(res.statusCode).toBe(200)
        req = request.put getURL('/db/user'),
          (err, res) ->
            expect(res.statusCode).toBe(422)
            expect(res.body).toBe('No input.')
            done()

  it 'logs in as normal joe', (done) ->
    loginJoe -> done()

  it 'denies requests to edit someone who is not joe', (done) ->
    unittest.getAdmin (admin) ->
      req = request.put getURL('/db/user'),
      (err, res) ->
        expect(res.statusCode).toBe(403)
        done()
      req.form().append('_id', admin.id)

  it 'denies invalid data', (done) ->
    unittest.getNormalJoe (joe) ->
      req = request.put getURL('/db/user'),
      (err, res) ->
        expect(res.statusCode).toBe(422)
        expect(res.body.indexOf('too long')).toBeGreaterThan(-1)
        done()
      form = req.form()
      form.append('_id', joe.id)
      form.append('email', "farghlarghlfarghlarghlfarghlarghlfarghlarghlfarghlarghlfarghlar
ghlfarghlarghlfarghlarghlfarghlarghlfarghlarghlfarghlarghlfarghlarghlfarghlarghlfarghlarghl")

  it 'logs in as admin', (done) ->
    loginAdmin -> done()


  it 'denies non-existent ids', (done) ->
    req = request.put getURL('/db/user'),
    (err, res) ->
      expect(res.statusCode).toBe(404)
      expect(res.body).toBe('Resource not found.')
      done()
      done()
    form = req.form()
    form.append('_id', '513108d4cb8b610000000004')
    form.append('email', "perfectly@good.com")

  it 'denies if the email being changed is already taken', (done) ->
    unittest.getNormalJoe (joe) ->
      unittest.getAdmin (admin) ->
        req = request.put getURL('/db/user'), (err, res) ->
          expect(res.statusCode).toBe(409)
          expect(res.body.indexOf('already used')).toBeGreaterThan(-1)
          done()
        form = req.form()
        form.append('_id', String(admin._id))
        form.append('email', joe.get('email').toUpperCase())

  it 'works', (done) ->
    unittest.getNormalJoe (joe) ->
      req = request.put getURL('/db/user'), (err, res) ->
        expect(res.statusCode).toBe(200)
        unittest.getUser('New@email.com', 'null', (joe) ->
          expect(joe.get('name')).toBe('Wilhelm')
          expect(joe.get('emailLower')).toBe('new@email.com')
          expect(joe.get('email')).toBe('New@email.com')
          done())
      form = req.form()
      form.append('_id', String(joe._id))
      form.append('email', 'New@email.com')
      form.append('name', 'Wilhelm')

describe 'GET /db/user', ->
  request = require 'request'
  it 'logs in as admin', (done) ->
    req = request.post(getURL('/auth/login'), (error, response) ->
      expect(response.statusCode).toBe(200)
      done()
    )
    form = req.form()
    form.append('username', 'admin@afc.com')
    form.append('password', '80yqxpb38j')

  it 'is able to do a sweet query', (done) ->
    conditions = [
      ['limit', 20]
      ['where', 'email']
      ['equals', 'admin@afc.com']
      ['sort', '-dateCreated']
    ]
    options = {
      url: getURL('/db/user')
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
      url: getURL('/db/user')
      qs: {
        conditions: JSON.stringify(conditions)
      }
    }

    req = request.get(options, (error, response) ->
      expect(response.statusCode).toBe(422)
      done()
    )
