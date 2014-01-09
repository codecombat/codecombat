require '../common'

describe 'LevelSystem', ->

  raw =
    name:'Bashing'
    description:'Performs Thang bashing updates for Bashes Thangs.'
    code: """class Bashing extends System
      constructor: (world) ->
        super world
    """
    language: 'coffeescript'
    official: true
    permissions:simplePermissions

  systems = {}

  url = getURL('/db/level.system')

  it 'clears things first', (done) ->
    clearModels [Level, LevelSystem], (err) ->
      expect(err).toBeNull()
      done()

  it 'can make a LevelSystem, without setting official.', (done) ->
    loginJoe (joe) ->
      request.post {uri:url, json:systems}, (err, res, body) ->
        expect(res.statusCode).toBe(200)
        expect(body.official).toBeUndefined()
        systems[0] = body
        done()

  it 'can allows admins to edit the official property.', (done) ->
    systems[0].official = true
    loginAdmin (joe) ->
      request.post {uri:url, json:systems[0]}, (err, res, body) ->
        expect(body.official).toBe(true)
        expect(res.statusCode).toBe(200)
        done()
