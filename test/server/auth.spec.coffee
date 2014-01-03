require './common'

describe '/auth/whoami', ->
  http = require 'http'
  it 'returns 200', (done) ->
    http.get(getURL('/auth/whoami'), (response) ->
      expect(response).toBeDefined()
      expect(response.statusCode).toBe(200)
      done()
    )

describe '/auth/login', ->
  url = getURL('/auth/login')
  request = require 'request'

  it 'clears Users first', (done) ->
    User.remove {}, (err) ->
      throw err if err
      done()

  it 'finds no user', (done) ->
    req = request.post(url, (error, response) ->
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
    req = request.post(url, (error, response) ->
      expect(response).toBeDefined()
      expect(response.statusCode).toBe(200)
      done()
    )
    form = req.form()
    form.append('username', 'scott@gmail.com')
    form.append('password', 'nada')

  it 'rejects wrong passwords', (done) ->
    req = request.post(url, (error, response) ->
      expect(response.statusCode).toBe(401)
      expect(response.body.indexOf("wrong, wrong")).toBeGreaterThan(-1)
      done()
    )
    form = req.form()
    form.append('username', 'scott@gmail.com')
    form.append('password', 'blahblah')

  it 'is completely case insensitive', (done) ->
    req = request.post(url, (error, response) ->
      expect(response.statusCode).toBe(200)
      done()
    )
    form = req.form()
    form.append('username', 'scoTT@gmaIL.com')
    form.append('password', 'NaDa')