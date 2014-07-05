require '../common'

describe 'Level', ->

  level =
    name: 'King\'s Peak 3'
    description: 'Climb a mountain.'
    permissions: simplePermissions
    scripts: []
    thangs: []
    documentation: {specificArticles: [], generalArticles: []}

  urlLevel = '/db/level'

  it 'clears things first', (done) ->
    clearModels [Level], (err) ->
      expect(err).toBeNull()
      done()

  it 'can make a Level.', (done) ->
    loginJoe ->
      request.post {uri: getURL(urlLevel), json: level}, (err, res, body) ->
        expect(res.statusCode).toBe(200)
        done()

  it 'get schema', (done) ->
    request.get {uri: getURL(urlLevel+'/schema')}, (err, res, body) ->
      expect(res.statusCode).toBe(200)
      body = JSON.parse(body)
      expect(body.type).toBeDefined()
      done()
