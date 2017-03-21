common = require '../common'
request = require '../request'
utils = require '../utils'
User = require '../../../server/models/User'

url = getURL('/healthcheck')

describe 'GET /healthcheck', ->
  it 'returns 500 if there are no users in the db', utils.wrap (done) ->
    yield utils.clearModels([User])
    [res, body] = yield request.getAsync url, {json: true}
    expect(res.statusCode).toBe(500)
    done()

  it 'returns 200 if there is at least one user in the db', utils.wrap (done) ->
    yield utils.clearModels([User])
    yield utils.initUser()
    [res, body] = yield request.getAsync url, {json: true}
    expect(res.statusCode).toBe(200)
    done()

  it 'produces a healthcheck user and tracks how often it is healthchecked', utils.wrap (done) ->
    yield utils.clearModels([User])
    user = yield User.findOne({slug: 'healthcheck'})
    expect(user).toBeNull()

    yield utils.initUser()
    [res, body] = yield request.getAsync url, {json: true}
    expect(res.statusCode).toBe(200)
    user = yield User.findOne({slug: 'healthcheck'})
    expect(user).toBeTruthy()
    expect(user.get('activity').healthcheck.count).toBe(1)
    
    [res, body] = yield request.getAsync url, {json: true}
    expect(res.statusCode).toBe(200)
    user = yield User.findOne({slug: 'healthcheck'})
    expect(user.get('activity').healthcheck.count).toBe(2)
    done()
