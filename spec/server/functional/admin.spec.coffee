common = require '../common'
request = require '../request'
utils = require '../utils'

describe 'POST /admin/(handler)/(function-name)/(args)', ->
  url = getURL '/admin/user/recalculate/'

  it 'responds 202 accepted when successful', utils.wrap (done) ->
    admin = yield utils.initAdmin()
    yield utils.loginUser(admin)
    [res, body] = yield request.postAsync {uri:url + 'gamesCompleted'}
    expect(res.statusCode).toBe 202
    done()

  it 'returns 403 for regular users', utils.wrap (done) ->
    user = yield utils.initUser()
    yield utils.loginUser(user)
    [res, body] = yield request.postAsync {uri:url + 'gamesCompleted'}
    expect(res.statusCode).toBe 403
    done()

  it 'responds with a 404 if handler not found', utils.wrap (done) ->
    admin = yield utils.initAdmin()
    yield utils.loginUser(admin)
    [res, body] = yield request.postAsync {uri:getURL '/admin/blobfish/swim'}
    expect(res.statusCode).toBe 404
    done()

  it 'responds with a 404 if handler method not found', utils.wrap (done) ->
    admin = yield utils.initAdmin()
    yield utils.loginUser(admin)
    [res, body] = yield request.postAsync {uri:getURL '/admin/user/hammertime'}
    expect(res.statusCode).toBe 404
    done()

  it 'responds with a 404 if recalculate method not found', utils.wrap (done) ->
    admin = yield utils.initAdmin()
    yield utils.loginUser(admin)
    [res, body] = yield request.postAsync {uri:url + 'gamesContemplated'}
    expect(res.statusCode).toBe 404
    done()





