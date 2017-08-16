request = require '../request'
utils = require '../utils'
ThangType = require '../../../server/models/ThangType'
User = require '../../../server/models/User'

describe 'GET /db/thang.type/schema', ->

  it 'returns the ThangType schema', utils.wrap (done) ->
    url = utils.getURL('/db/thang.type/schema')
    [res, body] = yield request.getAsync { url, json: true }
    expect(res.statusCode).toBe(200)
    expect(body.type).toBeDefined()
    done()

describe 'GET /db/thang.type', ->
  
  beforeEach utils.wrap (done) ->
    yield utils.clearModels([ThangType, User])
    @admin = yield utils.initAdmin()
    yield utils.loginUser(@admin)
    done()
  
  it 'returns thang types given a search term', utils.wrap (done) ->
    yield [
      utils.makeThangType({name: 'Well'})
      utils.makeThangType({name: 'Chair'})
    ]
    url = utils.getURL('/db/thang.type')
    json = true
    qs = { term: 'well' }
    [res, body] = yield request.getAsync({url, json, qs})
    expect(body.length).toBe(1)
    expect(body[0].name).toBe('Well')
    done()
    
  it 'does not return those restricted to code-play unless you are an admin or are on cp.codecombat.com', utils.wrap (done) ->
    yield [
      utils.makeThangType({name: 'Well', restricted: 'code-play' })
    ]
    url = utils.getURL('/db/thang.type')
    json = true
    qs = { term: 'well' }
    
    [res, body] = yield request.getAsync({url, json, qs})
    expect(body.length).toBe(1)
    expect(body[0].name).toBe('Well')
    
    yield utils.becomeAnonymous()
    [res, body] = yield request.getAsync({url, json, qs})
    expect(body.length).toBe(0)

    headers = { host: 'cp.codecombat.com' }
    [res, body] = yield request.getAsync({url, json, qs, headers})
    expect(body.length).toBe(1)
    
    done()
    
describe 'GET /db/thang.type/:handle/version', ->

  beforeEach utils.wrap (done) ->
    yield utils.clearModels([ThangType, User])
    @admin = yield utils.initAdmin()
    yield utils.loginUser(@admin)
    done()

  it 'returns 403 if restricted and you are neither on the correct domain nor an admin', utils.wrap (done) ->
    thangType = yield utils.makeThangType({name: 'Well', restricted: 'code-play' })
    url = utils.getURL("/db/thang.type/#{thangType.id}/version")
    json = true
    [res, body] = yield request.getAsync({url, json})
    expect(res.statusCode).toBe(200)
    
    user = yield utils.initUser()
    yield utils.loginUser(user)
    [res, body] = yield request.getAsync({url, json})
    expect(res.statusCode).toBe(403)

    headers = { host: 'cp.codecombat.com' }
    [res, body] = yield request.getAsync({url, json, headers})
    expect(res.statusCode).toBe(200)
    done()

describe 'GET /db/thang.type?view=heroes', ->

  beforeEach utils.wrap (done) ->
    yield utils.clearModels([ThangType, User])
    @admin = yield utils.initAdmin()
    yield utils.loginUser(@admin)
    done()

  it 'returns ThangTypes of type hero', utils.wrap (done) ->
    yield [
      utils.makeThangType({ kind: 'Hero' })
      utils.makeThangType({ kind: 'Hero' })
      utils.makeThangType({ kind: 'Item' })
      utils.makeThangType({ kind: 'Unit' })
      utils.makeThangType({ kind: 'Wall' })
      utils.makeThangType({ kind: 'Doodad' })
    ]
    url = utils.getURL('/db/thang.type?view=heroes')
    [res, body] = yield request.getAsync({url, json: true})
    expect(res.statusCode).toBe(200)
    expect(res.body.length).toBe(2)
    done()
    
  it 'does not return restricted ThangTypes unless user is an admin or on cp.codecombat.com', utils.wrap (done) ->
    yield utils.makeThangType({ kind: 'Hero', restricted: 'code-play' })
    url = utils.getURL('/db/thang.type?view=heroes')
    [res, body] = yield request.getAsync({url, json: true})
    expect(res.statusCode).toBe(200)
    expect(res.body.length).toBe(1)

    user = yield utils.initUser()
    yield utils.loginUser(user)
    [res, body] = yield request.getAsync({url, json: true})
    expect(res.body.length).toBe(0)

    headers = { host: 'cp.codecombat.com' }
    [res, body] = yield request.getAsync({url, json: true, headers})
    expect(res.statusCode).toBe(200)
    expect(res.body.length).toBe(1)
    
    done()
