require '../common'
request = require '../request'

describe 'Level Thang Component', ->

  url = getURL('/db/thang.component')

  it 'get schema', (done) ->
    request.get {uri: url+'/schema'}, (err, res, body) ->
      expect(res.statusCode).toBe(200)
      body = JSON.parse(body)
      expect(body.type).toBeDefined()
      done()
