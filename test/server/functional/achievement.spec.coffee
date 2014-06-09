require '../common'

describe 'Achievement', ->

  unlockable =
    name: 'One Time Only'
    description: 'So you did the really cool thing.'
    worth: 6.66
    collection: 'level.session'

  repeatable =
    name: 'Lots of em'
    description: 'Oops you did it again.'
    worth: 1
    collection: 'User'
    proportionalTo: '_id'

  url = getURL('/db/achievement')
  allowHeader = 'GET, POST, PUT, PATCH'

  it 'preparing test: deleting all Achievements first', (done) ->
    clearModels [Achievement], (err) ->
      expect(err).toBeNull()
      done()

  it 'can\'t be created by ordinary users', (done) ->
    loginJoe ->
      request.post {uri: url, json: unlockable}, (err, res, body) ->
        expect(res.statusCode).toBe(403)
        done()

  it 'can\'t be updated by ordinary users', (done) ->
    loginJoe ->
      request.put {uri: url, json:unlockable}, (err, res, body) ->
        expect(res.statusCode).toBe(403)

        request {method: 'patch', uri: url, json: unlockable}, (err, res, body) ->
          expect(res.statusCode).toBe(403)
          done()

  it 'can be created by admins', (done) ->
    loginAdmin ->
      request.post {uri: url, json: unlockable}, (err, res, body) ->
        expect(res.statusCode).toBe(200)
        unlockable._id = body._id
        done()

  it 'can get all for ordinary users', (done) ->
    loginJoe ->
      request.get {uri: url, json: unlockable}, (err, res, body) ->
        expect(res.statusCode).toBe(200)
        expect(body.length).toBe(1)
        done()

  it 'can be read by ordinary users', (done) ->
    loginJoe ->
      request.get {uri: url + '/' + unlockable._id, json: unlockable}, (err, res, body) ->
        expect(res.statusCode).toBe(200)
        expect(body.name).toBe(unlockable.name)
        done()

  it 'can\'t be requested with HTTP HEAD method', (done) ->
    loginJoe ->
      request.head {uri: url + '/' + unlockable._id}, (err, res, body) ->
        expect(res.statusCode).toBe(405)
        expect(res.headers.allow).toBe(allowHeader)
        done()

  it 'can\'t be requested with HTTP DEL method', (done) ->
    loginJoe ->
      request.del {uri: url + '/' + unlockable._id}, (err, res, body) ->
        expect(res.statusCode).toBe(405)
        expect(res.headers.allow).toBe(allowHeader)
        done()

  it 'get schema', (done) ->
    request.get {uri:url + '/schema'}, (err, res, body) ->
      expect(res.statusCode).toBe(200)
      body = JSON.parse(body)
      expect(body.type).toBeDefined()
      done()

  it 'cleaning up test: deleting all Achievements', (done) ->
    clearModels [Achievement], (err) ->
      expect(err).toBeNull()
      done()
