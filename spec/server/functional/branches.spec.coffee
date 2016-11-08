require '../common'
Branch = require '../../../server/models/Branch'
utils = require '../utils'
request = require '../request'

describe 'POST and PUT /db/branches', ->

  beforeEach utils.wrap (done) ->
    yield utils.clearModels([Branch])
    done()

  it 'sets updated and updatedBy', utils.wrap (done) ->
    admin1 = yield utils.initAdmin()
    yield utils.loginUser(admin1)
    json = { name: 'Test' }
    [res, body] = yield request.postAsync({url: utils.getURL('/db/branches'), json })
    expect(res.statusCode).toBe(201)
    expect(res.body.updatedBy).toBe(admin1.id)
    expect(res.body.updatedByName).toBe(admin1.get('name'))
    expect(res.body.updated).toBeDefined()
    previousUpdated = res.body.updated
    branchId = res.body._id

    admin2 = yield utils.initAdmin()
    yield utils.loginUser(admin2)
    json = { name: 'Rename' }
    [res, body] = yield request.putAsync({url: utils.getURL("/db/branches/#{branchId}"), json })
    expect(res.statusCode).toBe(200)
    expect(res.body.updatedBy).toBe(admin2.id)
    expect(res.body.updatedByName).toBe(admin2.get('name'))
    expect(res.body.updated).toBeDefined()
    expect(res.body.updated).not.toBe(previousUpdated)
    done()
