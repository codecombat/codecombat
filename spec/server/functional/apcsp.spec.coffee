utils = require '../utils'
request = require '../request'

describe 'GET /apcsp-files/*', ->
  it 'proxies requests to a location based on the server config', utils.wrap ->
    user = yield utils.initUser({verifiedTeacher: true})
    yield utils.loginUser(user)
    url = utils.getUrl('/apcsp-files/index')
    [res] = yield request.getAsync({url, json: true})
    expect(res.statusCode).toBe(200)
    expect(_.str.startsWith(res.body, 'Main page')).toBe(true)

  it 'returns 403 for un-verified teachers', utils.wrap ->
    user = yield utils.initUser({role: 'teacher'})
    yield utils.loginUser(user)
    url = utils.getUrl('/apcsp-files/index')
    [res] = yield request.getAsync({url, json: true})
    expect(res.statusCode).toBe(403)
