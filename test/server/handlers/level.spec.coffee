require '../common'

describe 'Level', ->

  level =
    name: "King's Peak 3"
    description: 'Climb a mountain.'
    permissions: simplePermissions

  url = getURL('/db/level')

  it 'clears things first', (done) ->
    clearModels [Level], (err) ->
      expect(err).toBeNull()
      done()

  it 'can make a Level.', (done) ->
    loginJoe (joe) ->
      request.post {uri:url, json:level}, (err, res, body) ->
        expect(res.statusCode).toBe(200)
        done()