request = require '../request'
require '../common'

describe 'languages', ->
  url = getURL('/languages')
  allowHeader = 'GET'

  it 'can\'t be requested with HTTP POST method', (done) ->
    request.post {uri: url}, (err, res, body) ->
      expect(res.statusCode).toBe(405)
      expect(res.headers.allow).toBe(allowHeader)
      done()

  it 'can\'t be requested with HTTP PUT method', (done) ->
    request.put {uri: url}, (err, res, body) ->
      expect(res.statusCode).toBe(405)
      expect(res.headers.allow).toBe(allowHeader)
      done()

  it 'can\'t be requested with HTTP PATCH method', (done) ->
    request {method: 'patch', uri: url}, (err, res, body) ->
      expect(res.statusCode).toBe(405)
      expect(res.headers.allow).toBe(allowHeader)
      done()

  it 'can\'t be requested with HTTP HEAD method', (done) ->
    request.head {uri: url}, (err, res, body) ->
      expect(res.statusCode).toBe(405)
      expect(res.headers.allow).toBe(allowHeader)
      done()

  it 'can\'t be requested with HTTP DELETE method', (done) ->
    request.del {uri: url}, (err, res, body) ->
      expect(res.statusCode).toBe(405)
      expect(res.headers.allow).toBe(allowHeader)
      done()
