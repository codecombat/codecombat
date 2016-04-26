require '../common'
utils = require '../utils'

Promise = require 'bluebird'
request = require '../request'
requestAsync = Promise.promisify(request, {multiArgs: true})

CodeLog = require '../../../server/models/CodeLog'
User = require '../../../server/models/User'

testLog1 = {
  'sessionID': ObjectId("55b29efd1cd6abe8ce07db0d")
  'level': {
    'original': ObjectId("55b29efd1cd6abe8ce07db0d")
    'majorVersion': 0
  }
  'levelSlug': "d"
  'userID': ObjectId("55b29efd1cd6abe8ce07db0d")
  'userName': "b"
  'log': "a"
}

testLog2 = {
  'sessionID': ObjectId("55b29efd1cd6abe8ce07db0d")
  'level': {
    'original': ObjectId("55b29efd1cd6abe8ce07db0d")
    'majorVersion': 0
  }
  'levelSlug': "dbbb"
  'userID': ObjectId("55b29efd1cd6abe8ce07db0d")
  'userName': "bbbb"
  'log': "abbb"
}

describe 'POST /db/codelogs', ->
  beforeEach utils.wrap (done) ->
    yield utils.clearModels([CodeLog])
    user = yield utils.initUser({})
    yield utils.loginUser(user)
    done()
  it 'allows logged in users to create codelogs', utils.wrap (done) ->
    [res, body] = yield request.postAsync {
      uri: getURL('/db/codelogs'), json: testLog1
    }
    expect(res.statusCode).toBe(201)
    done()
  it 'does allow anonymous users to create codelogs', utils.wrap (done) ->
    yield utils.becomeAnonymous()
    [res, body] = yield request.postAsync {
      uri: getURL('/db/codelogs'), json: testLog1
    }
    expect(res.statusCode).toBe(201)
    done()
  it 'does not allow unauthenticated users to create codelogs', utils.wrap (done) ->
    yield utils.logout()
    [res, body] = yield request.postAsync {
      uri: getURL('/db/codelogs'), json: testLog1
    }
    expect(res.statusCode).toBe(401)
    done()

describe 'GET /db/codelogs', ->
  beforeEach utils.wrap (done) ->
    yield utils.clearModels([CodeLog])
    # Fill database
    @admin = yield utils.initAdmin({})
    yield utils.loginUser(@admin)
    yield request.postAsync(getURL('/db/codelogs'), {json: testLog1})
    yield request.postAsync(getURL('/db/codelogs'), {json: testLog2})
    yield utils.logout()
    done()

  it 'does not allow unauthenticated users to get codelogs', utils.wrap (done) ->
    [res, body] = yield request.getAsync {uri:getURL('/db/codelogs'), json:true}
    expect(res.statusCode).toBe(401)
    done()

  it 'does not allow non-admins to get codelogs', utils.wrap (done) ->
    user = yield utils.initUser({})
    yield utils.loginUser(user)
    [res, body] = yield request.getAsync {uri:getURL('/db/codelogs'), json:true}
    expect(res.statusCode).toBe(403)
    done()

  it 'allows admins to get codelogs', utils.wrap (done) ->
    admin = yield utils.initAdmin({})
    yield utils.loginUser(admin)
    [res, body] = yield request.getAsync {uri:getURL('/db/codelogs'), json:true}
    expect(body.length).toBe(2)
    done()
