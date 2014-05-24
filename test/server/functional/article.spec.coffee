require '../common'

describe '/db/article', ->
  request = require 'request'
  it 'clears the db first', (done) ->
    clearModels [User, Article], (err) ->
      throw err if err
      done()

  article = {name: 'Yo', body:'yo ma'}
  url = getURL('/db/article')
  articles = {}

  it 'does not allow non-admins to create Articles.', (done) ->
    loginJoe ->
      request.post {uri:url, json:article}, (err, res, body) ->
        expect(res.statusCode).toBe(403)
        done()

  it 'allows admins to create Articles', (done) ->
    loginAdmin ->
      request.post {uri:url, json:article}, (err, res, body) ->
        expect(res.statusCode).toBe(200)
        expect(body.slug).toBeDefined()
        expect(body.body).toBeDefined()
        expect(body.name).toBeDefined()
        expect(body.original).toBeDefined()
        expect(body.creator).toBeDefined()
        articles[0] = body
        done()

  it 'allows admins to make new minor versions', (done) ->
    new_article = _.clone(articles[0])
    new_article.body = '...'
    request.post {uri:url, json:new_article}, (err, res, body) ->
      expect(res.statusCode).toBe(200)
      expect(body.version.major).toBe(0)
      expect(body.version.minor).toBe(1)
      expect(body._id).not.toBe(articles[0]._id)
      expect(body.parent).toBe(articles[0]._id)
      expect(body.creator).toBeDefined()
      articles[1] = body
      done()

  it 'allows admins to make new major versions', (done) ->
    new_article = _.clone(articles[1])
    delete new_article.version
    request.post {uri:url, json:new_article}, (err, res, body) ->
      expect(res.statusCode).toBe(200)
      expect(body.version.major).toBe(1)
      expect(body.version.minor).toBe(0)
      expect(body._id).not.toBe(articles[1]._id)
      expect(body.parent).toBe(articles[1]._id)
      articles[2] = body
      done()

  it 'grants access for regular users', (done) ->
    loginJoe ->
      request.get {uri:url+'/'+articles[0]._id}, (err, res, body) ->
        body = JSON.parse(body)
        expect(res.statusCode).toBe(200)
        expect(body.body).toBe(articles[0].body)
        done()
    
  
  it 'does not allow regular users to make new versions', (done) ->
    new_article = _.clone(articles[2])
    request.post {uri:url, json:new_article}, (err, res, body) ->
      expect(res.statusCode).toBe(403)
      done()

  it 'allows name changes from one version to the next', (done) ->
    loginAdmin ->
      new_article = _.clone(articles[0])
      new_article.name = "Yo mama now is the larger"
      request.post {uri:url, json:new_article}, (err, res, body) ->
        expect(res.statusCode).toBe(200)
        expect(body.name).toBe(new_article.name)
        done()

  it 'get schema', (done) ->
    request.get {uri:url+'/schema'}, (err, res, body) ->
      expect(res.statusCode).toBe(200)
      body = JSON.parse(body)
      expect(body.type).toBeDefined()
      done()

  it 'does not allow naming an article a reserved word', (done) ->
    loginAdmin ->
      new_article = {name: 'Search', body:'is a reserved word'}
      request.post {uri:url, json:new_article}, (err, res, body) ->
        expect(res.statusCode).toBe(422)
        done()
        
       