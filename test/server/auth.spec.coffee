require './common'
request = require 'request'

urlLogin = getURL('/auth/login')
urlReset = getURL('/auth/reset')

describe '/auth/whoami', ->
  http = require 'http'
  it 'returns 200', (done) ->
    http.get(getURL('/auth/whoami'), (response) ->
      expect(response).toBeDefined()
      expect(response.statusCode).toBe(200)
      done()
    )

describe '/auth/login', ->

  it 'clears Users first', (done) ->
    User.remove {}, (err) ->
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
      expect(response.body.indexOf("wrong, wrong")).toBeGreaterThan(-1)
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

  it 'reset user password', (done) ->
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
