APIClient = require '../../../server/models/APIClient'
request = require '../request'
utils = require '../utils'
Promise = require 'bluebird'


describe 'POST /db/api-clients', ->
  url = utils.getURL('/db/api-clients')
  json = { name: '3rd party' }

  it 'allows admins to create new clients', utils.wrap (done) ->
    admin = yield utils.initAdmin()
    yield utils.loginUser(admin)
    [res, body] = yield request.postAsync({ url, json })
    expect(res.statusCode).toBe(201)
    expect(res.body.name).toBe('3rd party')
    expect(res.body.slug).toBe('3rd-party')
    expect(res.body.secret).toBeUndefined()
    [res, body] = yield request.postAsync({ url, json })
    expect(res.statusCode).toBe(409)
    [res, body] = yield request.postAsync({ url, json: {name: 'other name'} })
    expect(res.statusCode).toBe(201)
    done()
    
  it 'returns 403 for non-admins', utils.wrap (done) ->
    user = yield utils.initUser()
    yield utils.loginUser(user)
    [res, body] = yield request.postAsync({ url, json })
    expect(res.statusCode).toBe(403)
    done()

    
describe 'POST /db/clients/:handle/new-secret', ->
  
  it 'creates a new secret key, saving a hashed value to the db', utils.wrap (done) ->
    client = new APIClient()
    yield client.save()
    expect(client.get('secret')).toBeUndefined()
    admin = yield utils.initAdmin()
    yield utils.loginUser(admin)
    url = utils.getURL("/db/api-clients/#{client.id}/new-secret")
    [res, body] = yield request.postAsync({ url, json: true })
    expect(res.statusCode).toBe(200)
    expect(res.body.secret).toBeDefined()
    client = yield APIClient.findById(client.id)
    expect(client.get('secret')).toBeDefined()
    expect(client.get('secret')).not.toBe(res.body.secret)
    done()

  it 'creates a new secret key, saving a hashed value to the db', utils.wrap (done) ->
    client = new APIClient()
    yield client.save()
    user = yield utils.initUser()
    yield utils.loginUser(user)
    url = utils.getURL("/db/api-clients/#{client.id}/new-secret")
    [res, body] = yield request.postAsync({ url, json: true })
    expect(res.statusCode).toBe(403)
    done()
    
