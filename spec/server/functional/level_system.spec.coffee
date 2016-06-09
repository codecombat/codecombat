require '../common'
Level = require '../../../server/models/Level'
LevelSystem = require '../../../server/models/LevelSystem'
request = require '../request'

describe 'LevelSystem', ->

  system =
    name: 'Bashing'
    description: 'Performs Thang bashing updates for Bashes Thangs.'
    code: """class Bashing extends System
      constructor: (world) ->
        super world
    """
    codeLanguage: 'coffeescript'
    permissions: simplePermissions
    dependencies: []

  systems = {}

  url = getURL('/db/level.system')

  it 'preparing test : deletes all LevelSystem first', (done) ->
    clearModels [Level, LevelSystem], (err) ->
      expect(err).toBeNull()
      done()

  it 'can\'t be created by ordinary users.', (done) ->
    loginJoe ->
      request.post {uri: url, json: system}, (err, res, body) ->
        expect(res.statusCode).toBe(403)
        done()

  it 'can be created by an admin.', (done) ->
    loginAdmin ->
      request.post {uri: url, json: system}, (err, res, body) ->
        expect(res.statusCode).toBe(200)
        expect(body._id).toBeDefined()
        expect(body.name).toBe(system.name)
        expect(body.description).toBe(system.description)
        expect(body.code).toBe(system.code)
        expect(body.codeLanguage).toBe(system.codeLanguage)
        expect(body.__v).toBe(0)
        expect(body.creator).toBeDefined()
        expect(body.original).toBeDefined()
        expect(body.created).toBeDefined()
        expect(body.version).toBeDefined()
        expect(body.permissions).toBeDefined()
        systems[0] = body
        done()

  it 'have a unique name.', (done) ->
    loginAdmin ->
      request.post {uri: url, json: system}, (err, res, body) ->
        expect(res.statusCode).toBe(409)
        done()

  it 'can be read by an admin.', (done) ->
    loginAdmin ->
      request.get {uri: url+'/'+systems[0]._id}, (err, res, body) ->
        expect(res.statusCode).toBe(200)
        body = JSON.parse(body)
        expect(body._id).toBe(systems[0]._id)
        done()

  it 'can be read by ordinary users.', (done) ->
    loginJoe ->
      request.get {uri: url+'/'+systems[0]._id}, (err, res, body) ->
        expect(res.statusCode).toBe(200)
        body = JSON.parse(body)
        expect(body._id).toBe(systems[0]._id)
        expect(body.name).toBe(systems[0].name)
        expect(body.slug).toBeDefined()
        expect(body.description).toBe(systems[0].description)
        expect(body.code).toBe(systems[0].code)
        expect(body.codeLanguage).toBe(systems[0].codeLanguage)
        expect(body.__v).toBe(0)
        expect(body.creator).toBeDefined()
        expect(body.original).toBeDefined()
        expect(body.created).toBeDefined()
        expect(body.dependencies).toBeDefined()
        expect(body.version.isLatestMajor).toBe(true)
        expect(body.version.isLatestMinor).toBe(true)
        expect(body.permissions).toBeDefined()
        done()

  it 'is unofficial by default', (done) ->
    loginJoe ->
      request.get {uri: url+'/'+systems[0]._id}, (err, res, body) ->
        expect(res.statusCode).toBe(200)
        body = JSON.parse(body)
        expect(body._id).toBe(systems[0]._id)
        expect(body.official).toBeUndefined()
        done()

  it 'official property isn\'t editable by an ordinary user.', (done) ->
    systems[0].official = true
    loginJoe ->
      request.post {uri: url, json: systems[0]}, (err, res, body) ->
        expect(res.statusCode).toBe(403)
        done()

  it 'official property is editable by an admin.', (done) ->
    systems[0].official = true
    loginAdmin ->
      request.post {uri: url, json: systems[0]}, (err, res, body) ->
        expect(res.statusCode).toBe(200)
        expect(body.official).toBe(true)
        expect(body.original).toBe(systems[0].original)
        expect(body.version.isLatestMinor).toBe(true)
        expect(body.version.isLatestMajor).toBe(true)
        systems[1] = body

        request.get {uri: url+'/'+systems[0]._id}, (err, res, body) ->
          expect(res.statusCode).toBe(200)
          body = JSON.parse(body)
          expect(body._id).toBe(systems[0]._id)
          expect(body.official).toBeUndefined()
          expect(body.version.isLatestMinor).toBe(false)
          expect(body.version.isLatestMajor).toBe(false)
          done()

  it ' can\'t be requested with HTTP HEAD method', (done) ->
    request.head {uri: url+'/'+systems[0]._id}, (err, res) ->
      expect(res.statusCode).toBe(405)
      done()

  it ' can\'t be requested with HTTP DEL method', (done) ->
    request.del {uri: url+'/'+systems[0]._id}, (err, res) ->
      expect(res.statusCode).toBe(405)
      done()

  it 'get schema', (done) ->
    request.get {uri: url+'/schema'}, (err, res, body) ->
      expect(res.statusCode).toBe(200)
      body = JSON.parse(body)
      expect(body.type).toBeDefined()
      done()
