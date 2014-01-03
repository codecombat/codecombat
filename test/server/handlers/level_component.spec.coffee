require '../common'

describe 'LevelComponent', ->

  component =
    name:'Bashes Everything'
    description:'Makes the unit uncontrollably bash anything bashable, using the bash system.'
    code: 'bash();'
    language: 'javascript'
    official: true
    permissions:simplePermissions

  components = {}

  url = getURL('/db/level.component')

  it 'clears things first', (done) ->
    clearModels [Level, LevelComponent], (err) ->
      expect(err).toBeNull()
      done()

  it 'can make a LevelComponent, without setting official.', (done) ->
    loginJoe (joe) ->
      request.post {uri:url, json:component}, (err, res, body) ->
        expect(res.statusCode).toBe(200)
        expect(body.official).toBeUndefined()
        components[0] = body
        done()

  it 'can allows admins to edit the official property.', (done) ->
    components[0].official = true
    loginAdmin (joe) ->
      request.post {uri:url, json:components[0]}, (err, res, body) ->
        expect(body.official).toBe(true)
        expect(res.statusCode).toBe(200)
        done()
