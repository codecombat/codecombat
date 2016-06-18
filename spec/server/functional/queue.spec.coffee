#require '../common'
#request = require '../request'
#
#describe 'queue', ->
#  someURL = getURL('/queue/')
#  allowHeader = 'GET, POST, PUT'
#
#  xit 'can\'t be requested with HTTP PATCH method', (done) ->
#    request {method: 'patch', uri: someURL}, (err, res, body) ->
#      expect(res.statusCode).toBe(405)
#      expect(res.headers.allow).toBe(allowHeader)
#      done()
#
#  xit 'can\'t be requested with HTTP HEAD method', (done) ->
#    request.head {uri: someURL}, (err, res, body) ->
#      expect(res.statusCode).toBe(405)
#      expect(res.headers.allow).toBe(allowHeader)
#      done()
#
#  xit 'can\'t be requested with HTTP DELETE method', (done) ->
#    request.del {uri: someURL}, (err, res, body) ->
#      expect(res.statusCode).toBe(405)
#      expect(res.headers.allow).toBe(allowHeader)
#      done()
