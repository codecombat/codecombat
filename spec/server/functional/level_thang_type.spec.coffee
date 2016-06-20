require '../common'
request = require '../request'

describe 'Level Thang Type', ->

  url = getURL('/db/thang.type')

  it 'get schema', (done) ->
    request.get {uri: url+'/schema'}, (err, res, body) ->
      expect(res.statusCode).toBe(200)
      body = JSON.parse(body)
      expect(body.type).toBeDefined()
      done()
