common = require '../common'

describe 'recalculate statistics', ->
  url = getURL '/admin/user/recalculate/'

  it 'does not allow regular users', (done) ->
    loginJoe ->
      request.post {uri:url + 'gamesCompleted'}, (err, res, body) ->
        expect(res.statusCode).toBe 403
        done()

  it 'responds with a 202 Accepted', (done) ->
    loginAdmin ->
      request.post {uri:url + 'gamesCompleted'}, (err, res, body) ->
        expect(res.statusCode).toBe 202
        done()

  it 'responds with a 404 if handler not found', (done) ->
    loginAdmin ->
      request.post {uri:getURL '/admin/blobfish/swim'}, (err, res, body) ->
        expect(res.statusCode).toBe 404
        done()

  it 'responds with a 404 if handler method not found', (done) ->
    loginAdmin ->
      request.post {uri:getURL '/admin/user/hammertime'}, (err, res, body) ->
        expect(res.statusCode).toBe 404
        done()

  it 'responds with a 404 if recalculate method not found', (done) ->
    loginAdmin ->
      request.post {uri:url + 'ballsKicked'}, (err, res, body) ->
        expect(res.statusCode).toBe 404
        done()





