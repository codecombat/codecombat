require '../common'
User = require '../../../server/models/User'
Article = require '../../../server/models/Article'
request = require '../request'

describe '/db/<id>/version', ->
  it 'clears the db first', (done) ->
    clearModels [User, Article], (err) ->
      throw err if err
      done()

  article = {name: 'Yo', body: 'yo ma'}
  url = getURL('/db/article')
  articles = {}

  it 'sets up', (done) ->
    loginAdmin ->
      request.post {uri: url, json: article}, (err, res, body) ->
        expect(res.statusCode).toBe(201)
        articles[0] = body
        new_article = _.clone(articles[0])
        new_article.body = '...'
        newVersionURL = "#{url}/#{new_article._id}/new-version"
        request.post {uri: newVersionURL, json: new_article}, (err, res, body) ->
          expect(res.statusCode).toBe(201)
          articles[1] = body
          new_article = _.clone(articles[1])
          delete new_article.version
          request.post {uri: newVersionURL, json: new_article}, (err, res, body) ->
            expect(res.statusCode).toBe(201)
            articles[2] = body
            done()

  createVersionUrl = (versionString=null) ->
    original = articles[0]._id
    url = getURL("/db/article/#{original}/version")
    url += ('/' + versionString) if versionString?
    url

  it 'can fetch the latest absolute version', (done) ->
    baseUrl = createVersionUrl()
    request.get {uri: baseUrl}, (err, res, body) ->
      body = JSON.parse(body)
      expect(res.statusCode).toBe(200)
      expect(body.version.major).toBe(1)
      expect(body.version.minor).toBe(0)
      done()

  it 'can fetch the latest major version', (done) ->
    baseUrl = createVersionUrl('0')
    request.get {uri: baseUrl}, (err, res, body) ->
      body = JSON.parse(body)
      expect(res.statusCode).toBe(200)
      expect(body.version.major).toBe(0)
      expect(body.version.minor).toBe(1)
      done()

  it 'can fetch a particular version', (done) ->
    baseUrl = createVersionUrl('0.0')
    request.get {uri: baseUrl}, (err, res, body) ->
      body = JSON.parse(body)
      expect(res.statusCode).toBe(200)
      expect(body.version.major).toBe(0)
      expect(body.version.minor).toBe(0)
      done()

  it 'returns 404 when no doc is found', (done) ->
    baseUrl = createVersionUrl('3.14')
    request.get {uri: baseUrl}, (err, res, body) ->
      expect(res.statusCode).toBe(404)
      done()
