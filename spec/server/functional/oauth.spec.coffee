OAuthProvider = require '../../../server/models/OAuthProvider'
request = require '../request'
utils = require '../utils'

describe 'POST /db/o-auth', ->
  url = utils.getURL('/db/o-auth')
  json = { name: '3rd party' }
  beforeEach utils.wrap ->
    yield utils.clearModels([OAuthProvider])

  it 'allows admin to create new OAuthProvider', utils.wrap ->
    user = yield utils.initAdmin()
    yield utils.loginUser(user)
    [res, body] = yield request.postAsync({ url, json })
    expect(res.statusCode).toBe(201)
    expect(res.body.name).toEqual(json.name)
    expect(res.body.creator).toEqual(user.id)

  it 'allows licensor to create new OAuthProvider', utils.wrap ->
    user = yield utils.initLicensor()
    yield utils.loginUser(user)
    [res, body] = yield request.postAsync({ url, json })
    expect(res.statusCode).toBe(201)
    expect(res.body.name).toEqual(json.name)
    expect(res.body.creator).toEqual(user.id)

  it 'returns 403 for normal users', utils.wrap ->
    user = yield utils.initUser()
    yield utils.loginUser(user)
    [res, body] = yield request.postAsync({ url, json })
    expect(res.statusCode).toBe(403)

describe 'PUT /db/o-auth', ->
  url = utils.getURL('/db/o-auth')
  json = { name: '3rd party' }
  beforeEach utils.wrap ->
    yield utils.clearModels([OAuthProvider])

  it 'allows licensor to update an OAuthProvider', utils.wrap ->
    user = yield utils.initLicensor()
    yield utils.loginUser(user)
    [res, body] = yield request.postAsync({ url, json })
    expect(res.statusCode).toBe(201)
    expect(res.body.name).toEqual(json.name)
    expect(res.body.creator).toEqual(user.id)

    updateJson = {id: res.body._id, name: '3rd party licensor new'}
    [res, body] = yield request.putAsync({ url, json: updateJson })
    expect(res.statusCode).toBe(200)
    expect(res.body.name).toEqual(updateJson.name)
    expect(res.body.creator).toEqual(user.id)

describe 'GET /db/o-auth/name', ->
  url = utils.getURL('/db/o-auth')
  json = { name: '3rd party' }
  beforeEach utils.wrap ->
    yield utils.clearModels([OAuthProvider])

  it 'allows licensor to update an OAuthProvider', utils.wrap ->
    user = yield utils.initLicensor()
    yield utils.loginUser(user)
    [res, body] = yield request.postAsync({ url, json })
    expect(res.statusCode).toBe(201)
    expect(res.body.name).toEqual(json.name)
    expect(res.body.creator).toEqual(user.id)

    [res, body] = yield request.getAsync({ url: url + "/name?name=#{json.name}" })
    expect(res.statusCode).toBe(200)
    data = JSON.parse(res.body)
    expect(data.length).toEqual(1)
    expect(data[0].name).toEqual(json.name)
    expect(data[0].creator).toEqual(user.id)
