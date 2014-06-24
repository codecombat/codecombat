require '../common'
request = require 'request'
User = require '../../../server/users/User'

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

  it 'clears Users first', (done) ->
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
      expect(response.body.indexOf("wrong")).toBeGreaterThan(-1)
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

  it 'can\'t reset an unknow user', (done) ->
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
