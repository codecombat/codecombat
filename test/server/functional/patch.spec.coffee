require '../common'

describe '/db/patch', ->
  request = require 'request'
  it 'clears the db first', (done) ->
    clearModels [User, Article, Patch], (err) ->
      throw err if err
      done()

  article = {name: 'Yo', body:'yo ma'}
  articleURL = getURL('/db/article')
  articles = {}

  patchURL = getURL('/db/patch')
  patches = {}
  patch =
    commitMessage: 'Accept this patch!'
    delta: {name:['test']}
    editPath: '/who/knows/yes'
    target:
      id:null
      collection: 'article'

  it 'creates an Article to patch', (done) ->
    loginAdmin ->
      request.post {uri:articleURL, json:article}, (err, res, body) ->
        articles[0] = body
        patch.target.id = articles[0]._id
        done()

  it "allows someone to submit a patch to something they don't control", (done) ->
    loginJoe (joe) ->
      request.post {uri: patchURL, json: patch}, (err, res, body) ->
        expect(res.statusCode).toBe(200)
        expect(body.target.original).toBeDefined()
        expect(body.target.version.major).toBeDefined()
        expect(body.target.version.minor).toBeDefined()
        expect(body.status).toBe('pending')
        expect(body.created).toBeDefined()
        expect(body.creator).toBe(joe.id)
        patches[0] = body
        done()
      
  it 'adds a patch to the target document', (done) ->
    Article.findOne({}).exec (err, article) ->
      expect(article.toObject().patches[0]).toBeDefined()
      done()
      
  it 'shows up in patch requests', (done) ->
    patchesURL = getURL("/db/article/#{articles[0]._id}/patches")
    request.get {uri: patchesURL}, (err, res, body) ->
      body = JSON.parse(body)
      expect(res.statusCode).toBe(200)
      expect(body.length).toBe(1)
      done() 
      
  it 'allows you to set yourself as watching', (done) ->
    watchingURL = getURL("/db/article/#{articles[0]._id}/watch")
    request.put {uri: watchingURL, json: {on:true}}, (err, res, body) ->
      expect(body.watchers[1]).toBeDefined()
      done()

  it 'added the watcher to the target document', (done) ->
    Article.findOne({}).exec (err, article) ->
      expect(article.toObject().watchers[1]).toBeDefined()
      done()

  it 'does not add duplicate watchers', (done) ->
    watchingURL = getURL("/db/article/#{articles[0]._id}/watch")
    request.put {uri: watchingURL, json: {on:true}}, (err, res, body) ->
      expect(body.watchers.length).toBe(2)
      done()
      
  it 'allows removing yourself', (done) ->
    watchingURL = getURL("/db/article/#{articles[0]._id}/watch")
    request.put {uri: watchingURL, json: {on:false}}, (err, res, body) ->
      expect(body.watchers.length).toBe(1)
      done()
      
  it 'allows the submitter to withdraw the pull request', (done) ->
    statusURL = getURL("/db/patch/#{patches[0]._id}/status")
    request.put {uri: statusURL, json: {status:'withdrawn'}}, (err, res, body) ->
      expect(res.statusCode).toBe(200)
      Patch.findOne({}).exec (err, article) ->
        expect(article.get('status')).toBe 'withdrawn'
        Article.findOne({}).exec (err, article) ->
          expect(article.toObject().patches.length).toBe(0)
          done()
  
  it 'does not allow the submitter to reject or accept the pull request', (done) ->
    statusURL = getURL("/db/patch/#{patches[0]._id}/status")
    request.put {uri: statusURL, json: {status:'rejected'}}, (err, res, body) ->
      expect(res.statusCode).toBe(403)
      request.put {uri: statusURL, json: {status:'accepted'}}, (err, res, body) ->
        expect(res.statusCode).toBe(403)
        Patch.findOne({}).exec (err, article) ->
          expect(article.get('status')).toBe 'withdrawn'
          done()
  
  it 'allows the recipient to accept or reject the pull request', (done) ->
    statusURL = getURL("/db/patch/#{patches[0]._id}/status")
    loginAdmin ->
      request.put {uri: statusURL, json: {status:'rejected'}}, (err, res, body) ->
        expect(res.statusCode).toBe(200)
        Patch.findOne({}).exec (err, article) ->
          expect(article.get('status')).toBe 'rejected'
          request.put {uri: statusURL, json: {status:'accepted'}}, (err, res, body) ->
            expect(res.statusCode).toBe(200)
            Patch.findOne({}).exec (err, article) ->
              expect(article.get('status')).toBe 'accepted'
              done()

  it 'does not allow the recipient to withdraw the pull request', (done) ->
    statusURL = getURL("/db/patch/#{patches[0]._id}/status")
    request.put {uri: statusURL, json: {status:'withdrawn'}}, (err, res, body) ->
      expect(res.statusCode).toBe(403)
      Patch.findOne({}).exec (err, article) ->
        expect(article.get('status')).toBe 'accepted'
        done()