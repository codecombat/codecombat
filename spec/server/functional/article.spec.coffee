require '../common'
utils = require '../utils'
_ = require 'lodash'
Promise = require 'bluebird'
request = require '../request'
requestAsync = Promise.promisify(request, {multiArgs: true})
Article = require '../../../server/models/Article'
User = require '../../../server/models/User'

describe 'GET /db/article', ->
  articleData1 = { name: 'Article 1', body: 'Article 1 body cow', i18nCoverage: [] }
  articleData2 = { name: 'Article 2', body: 'Article 2 body moo' }
  
  beforeEach utils.wrap (done) ->
    yield utils.clearModels([Article])
    @admin = yield utils.initAdmin()
    yield utils.loginUser(@admin)
    yield request.postAsync(getURL('/db/article'), { json: articleData1 })
    yield request.postAsync(getURL('/db/article'), { json: articleData2 })
    yield utils.becomeAnonymous()
    done()
      
      
  it 'returns an array of Article objects', utils.wrap (done) ->
    [res, body] = yield request.getAsync { uri: getURL('/db/article'), json: true }
    expect(body.length).toBe(2)
    done()
      

  it 'accepts a limit parameter', utils.wrap (done) ->
    [res, body] = yield request.getAsync {uri: getURL('/db/article?limit=1'), json: true}
    expect(body.length).toBe(1)
    done()


  it 'returns 422 for an invalid limit parameter', utils.wrap (done) ->
    [res, body] = yield request.getAsync {uri: getURL('/db/article?limit=word'), json: true}
    expect(res.statusCode).toBe(422)
    done()
  

  it 'accepts a skip parameter', utils.wrap (done) ->
    [res, body] = yield request.getAsync {uri: getURL('/db/article?skip=1'), json: true}
    expect(body.length).toBe(1)
    [res, body] = yield request.getAsync {uri: getURL('/db/article?skip=2'), json: true}
    expect(body.length).toBe(0)
    done()

      
  it 'returns 422 for an invalid skip parameter', utils.wrap (done) ->
    [res, body] = yield request.getAsync {uri: getURL('/db/article?skip=???'), json: true}
    expect(res.statusCode).toBe(422)
    done()
  

  it 'accepts a custom project parameter', utils.wrap (done) ->
    [res, body] = yield request.getAsync {uri: getURL('/db/article?project=name,body'), json: true}
    expect(body.length).toBe(2)
    for doc in body
      expect(_.size(_.xor(_.keys(doc), ['_id', 'name', 'body']))).toBe(0)
    done()


  it 'returns a default projection if project is "true"', utils.wrap (done) ->
    [res, body] = yield request.getAsync {uri: getURL('/db/article?project=true'), json: true}
    expect(res.statusCode).toBe(200)
    expect(body.length).toBe(2)
    expect(body[0].body).toBeUndefined()
    expect(body[0].version).toBeDefined()
    done()
    
      
  it 'accepts custom filter parameters', utils.wrap (done) ->
    yield utils.loginUser(@admin)
    [res, body] = yield request.getAsync {uri: getURL('/db/article?filter[slug]="article-1"'), json: true}
    expect(body.length).toBe(1)
    done()
  

  it 'ignores custom filter parameters for non-admins', utils.wrap (done) ->
    user = yield utils.initUser()
    yield utils.loginUser(user)
    [res, body] = yield request.getAsync {uri: getURL('/db/article?filter[slug]="article-1"'), json: true}
    expect(body.length).toBe(2)
    done()
  
    
  it 'accepts custom condition parameters', utils.wrap (done) ->
    yield utils.loginUser(@admin)
    [res, body] = yield request.getAsync {uri: getURL('/db/article?conditions[select]="slug body"'), json: true}
    expect(body.length).toBe(2)
    for doc in body
      expect(_.size(_.xor(_.keys(doc), ['_id', 'slug', 'body']))).toBe(0)
    done()
  
    
  it 'ignores custom condition parameters for non-admins', utils.wrap (done) ->
    user = yield utils.initUser()
    yield utils.loginUser(user)
    [res, body] = yield request.getAsync {uri: getURL('/db/article?conditions[select]="slug body"'), json: true}
    expect(body.length).toBe(2)
    for doc in body
      expect(doc.name).toBeDefined()
    done()
  
    
  it 'allows non-admins to view by i18n-coverage', utils.wrap (done) ->
    [res, body] = yield request.getAsync {uri: getURL('/db/article?view=i18n-coverage'), json: true}
    expect(body.length).toBe(1)
    expect(body[0].slug).toBe('article-1')
    done()
  

  it 'allows non-admins to search by text', utils.wrap (done) ->
    [res, body] = yield request.getAsync {uri: getURL('/db/article?term=moo'), json: true}
    expect(body.length).toBe(1)
    expect(body[0].slug).toBe('article-2')
    done()


describe 'POST /db/article', ->
  
  articleData = { name: 'Article', body: 'Article', otherProp: 'not getting set' }
  
  beforeEach utils.wrap (done) ->
    yield utils.clearModels([Article])
    @admin = yield utils.initAdmin({})
    yield utils.loginUser(@admin)
    [@res, @body] = yield request.postAsync {
      uri: getURL('/db/article'), json: articleData 
    }
    done()
    
  
  it 'creates a new Article, returning 201', utils.wrap (done) ->
    expect(@res.statusCode).toBe(201)
    article = yield Article.findById(@body._id).exec()
    expect(article).toBeDefined()
    done()
      
  
  it 'sets creator to the user who created it', ->
    expect(@res.body.creator).toBe(@admin.id)
    
  
  it 'sets original to _id', ->
    body = @res.body
    expect(body.original).toBe(body._id)
    
  
  it 'returns 422 when no input is provided', utils.wrap (done) ->
    [res, body] = yield request.postAsync { uri: getURL('/db/article') }
    expect(res.statusCode).toBe(422)
    done()

      
  it 'allows you to set Article\'s editableProperties', ->
    expect(@body.name).toBe('Article')
    
  
  it 'ignores properties not included in editableProperties', ->
    expect(@body.otherProp).toBeUndefined()
  
    
  it 'returns 422 when properties do not pass validation', utils.wrap (done) ->
    [res, body] = yield request.postAsync { 
      uri: getURL('/db/article'), json: { i18nCoverage: 9001 } 
    }
    expect(res.statusCode).toBe(422)
    expect(body.validationErrors).toBeDefined()
    done()

      
  it 'allows admins to create Articles', -> # handled in beforeEach
  
    
  it 'allows artisans to create Articles', utils.wrap (done) ->
    yield utils.clearModels([Article])
    artisan = yield utils.initArtisan({})
    yield utils.loginUser(artisan)
    [res, body] = yield request.postAsync({uri: getURL('/db/article'), json: articleData })
    expect(res.statusCode).toBe(201)
    done()
  
  
  it 'does not allow normal users to create Articles', utils.wrap (done) ->
    yield utils.clearModels([Article])
    user = yield utils.initUser({})
    yield utils.loginUser(user)
    [res, body] = yield request.postAsync({uri: getURL('/db/article'), json: articleData })
    expect(res.statusCode).toBe(403)
    done()
      
    
  it 'does not allow anonymous users to create Articles', utils.wrap (done) ->
    yield utils.clearModels([Article])
    yield utils.becomeAnonymous()
    [res, body] = yield request.postAsync({uri: getURL('/db/article'), json: articleData })
    expect(res.statusCode).toBe(401)
    done()
  
  
  it 'does not allow creating Articles with reserved words', utils.wrap (done) ->
    [res, body] = yield request.postAsync { uri: getURL('/db/article'), json: { name: 'Names' } }
    expect(res.statusCode).toBe(422)
    done()
  
      
  it 'does not allow creating a second article of the same name', utils.wrap (done) ->
    [res, body] = yield request.postAsync { uri: getURL('/db/article'), json: articleData }
    expect(res.statusCode).toBe(409)
    done()
      
      
describe 'GET /db/article/:handle', ->

  articleData = { name: 'Some Name', body: 'Article' }

  beforeEach utils.wrap (done) ->
    yield utils.clearModels([Article])
    @admin = yield utils.initAdmin({})
    yield utils.loginUser(@admin)
    [@res, @body] = yield request.postAsync {
      uri: getURL('/db/article'), json: articleData
    }
    done()
    
    
  it 'returns Article by id', utils.wrap (done) ->
    [res, body] = yield request.getAsync {uri: getURL("/db/article/#{@body._id}"), json: true}
    expect(res.statusCode).toBe(200)
    expect(_.isObject(body)).toBe(true)
    done()
      
      
  it 'returns Article by slug', utils.wrap (done) ->
    [res, body] = yield request.getAsync {uri: getURL("/db/article/some-name"), json: true}
    expect(res.statusCode).toBe(200)
    expect(_.isObject(body)).toBe(true)
    done()
      
      
  it 'returns not found if handle does not exist in the db', utils.wrap (done) ->
    [res, body] = yield request.getAsync {uri: getURL("/db/article/dne"), json: true}
    expect(res.statusCode).toBe(404)
    done()


putTests = (method='PUT') ->
  articleData = { name: 'Some Name', body: 'Article' }

  beforeEach utils.wrap (done) ->
    yield utils.clearModels([Article])
    @admin = yield utils.initAdmin({})
    yield utils.loginUser(@admin)
    [@res, @body] = yield request.postAsync {
      uri: getURL('/db/article'), json: articleData
    }
    done()


  it 'edits editable Article properties', utils.wrap (done) ->
    [res, body] = yield requestAsync {method: method, uri: getURL("/db/article/#{@body._id}"), json: { body: 'New body' }}
    expect(body.body).toBe('New body')
    done()


  it 'updates the slug when the name is changed', utils.wrap (done) ->
    [res, body] = yield requestAsync {method: method, uri: getURL("/db/article/#{@body._id}"), json: json = { name: 'New name' }}
    expect(body.name).toBe('New name')
    expect(body.slug).toBe('new-name')
    done()


  it 'does not allow normal artisan, non-admins to make changes', utils.wrap (done) ->
    artisan = yield utils.initArtisan({})
    yield utils.loginUser(artisan)
    [res, body] = yield requestAsync {method: method, uri: getURL("/db/article/#{@body._id}"), json: { name: 'Another name' }}
    expect(res.statusCode).toBe(403)
    done()


describe 'PUT /db/article/:handle', -> putTests('PUT')
describe 'PATCH /db/article/:handle', -> putTests('PATCH')
    
    
describe 'POST /db/article/:handle/new-version', ->
  articleData = { name: 'Article name', body: 'Article body', i18n: {} }
  articleID = null
  
  beforeEach utils.wrap (done) ->
    yield utils.clearModels([Article])
    @admin = yield utils.initAdmin({})
    yield utils.loginUser(@admin)
    [res, body] = yield request.postAsync { uri: getURL('/db/article'), json: articleData }
    expect(res.statusCode).toBe(201)
    articleID = body._id
    done()
    
  postNewVersion = Promise.promisify (json, expectedStatus=201, done) ->
    if _.isFunction(expectedStatus)
      done = expectedStatus
      expectedStatus = 201
    url = getURL("/db/article/#{articleID}/new-version")
    request.post { uri: url, json: json }, (err, res, body) ->
      expect(res.statusCode).toBe(expectedStatus)
      done(err)
    
  testArrayEqual = (given, expected) ->
    expect(_.isEqual(given, expected)).toBe(true)
    
  
      
  it 'creates a new major version, updating model and version properties', utils.wrap (done) ->
    yield postNewVersion({ name: 'Article name', body: 'New body' })
    yield postNewVersion({ name: 'New name', body: 'New new body' })
    articles = yield Article.find()
    expect(articles.length).toBe(3)
    versions = (article.get('version') for article in articles)
    articles = (article.toObject() for article in articles)
    
    testArrayEqual(_.pluck(versions, 'major'), [0, 1, 2])
    testArrayEqual(_.pluck(versions, 'minor'), [0, 0, 0])
    testArrayEqual(_.pluck(versions, 'isLatestMajor'), [false, false, true])
    testArrayEqual(_.pluck(versions, 'isLatestMinor'), [true, true, true])
    testArrayEqual(_.pluck(articles, 'name'), ['Article name', 'Article name', 'New name'])
    testArrayEqual(_.pluck(articles, 'body'), ['Article body', 'New body', 'New new body'])
    testArrayEqual(_.pluck(articles, 'slug'), [undefined, undefined, 'new-name'])
    testArrayEqual(_.pluck(articles, 'index'), [undefined, undefined, true])
    done()
    
    
  it 'works if there is no document with the appropriate version settings (new major)', utils.wrap (done) ->
    article = yield Article.findById(articleID)
    article.set({ 'version.isLatestMajor': false, 'version.isLatestMinor': false })
    yield article.save()
    yield postNewVersion({ name: 'Article name', body: 'New body' })
    articles = yield Article.find()
    expect(articles.length).toBe(2)

    versions = (article.get('version') for article in articles)
    articles = (article.toObject() for article in articles)

    testArrayEqual(_.pluck(versions, 'major'), [0, 1])
    testArrayEqual(_.pluck(versions, 'minor'), [0, 0])
    testArrayEqual(_.pluck(versions, 'isLatestMajor'), [false, true])
    testArrayEqual(_.pluck(versions, 'isLatestMinor'), [false, true]) # does not fix the old version's value
    testArrayEqual(_.pluck(articles, 'body'), ['Article body', 'New body'])
    testArrayEqual(_.pluck(articles, 'slug'), [undefined, 'article-name'])
    testArrayEqual(_.pluck(articles, 'index'), [undefined, true])
    done()
    
    
  it 'creates a new minor version if version.major is included', utils.wrap (done) ->
    yield postNewVersion({ name: 'Article name', body: 'New body', version: { major: 0 } })
    yield postNewVersion({ name: 'Article name', body: 'New new body', version: { major: 0 } })
    articles = yield Article.find()
    expect(articles.length).toBe(3)

    versions = (article.get('version') for article in articles)
    articles = (article.toObject() for article in articles)

    testArrayEqual(_.pluck(versions, 'major'), [0, 0, 0])
    testArrayEqual(_.pluck(versions, 'minor'), [0, 1, 2])
    testArrayEqual(_.pluck(versions, 'isLatestMajor'), [false, false, true])
    testArrayEqual(_.pluck(versions, 'isLatestMinor'), [false, false, true])
    testArrayEqual(_.pluck(articles, 'name'), ['Article name', 'Article name', 'Article name'])
    testArrayEqual(_.pluck(articles, 'body'), ['Article body', 'New body', 'New new body'])
    testArrayEqual(_.pluck(articles, 'slug'), [undefined, undefined, 'article-name'])
    testArrayEqual(_.pluck(articles, 'index'), [undefined, undefined, true])
    done()


  it 'works if there is no document with the appropriate version settings (new minor)', utils.wrap (done) ->
    article = yield Article.findById(articleID)
    article.set({ 'version.isLatestMajor': false, 'version.isLatestMinor': false })
    yield article.save()
    yield postNewVersion({ name: 'Article name', body: 'New body', version: { major: 0 } })
    articles = yield Article.find()
    expect(articles.length).toBe(2)

    versions = (article.get('version') for article in articles)
    articles = (article.toObject() for article in articles)

    testArrayEqual(_.pluck(versions, 'major'), [0, 0])
    testArrayEqual(_.pluck(versions, 'minor'), [0, 1])
    testArrayEqual(_.pluck(versions, 'isLatestMajor'), [false, false])
    testArrayEqual(_.pluck(versions, 'isLatestMinor'), [false, true])
    testArrayEqual(_.pluck(articles, 'body'), ['Article body', 'New body'])
    testArrayEqual(_.pluck(articles, 'slug'), [undefined, 'article-name'])
    testArrayEqual(_.pluck(articles, 'index'), [undefined, true])
    done()
    
    
  it 'allows adding new minor versions to old major versions', utils.wrap (done) ->
    yield postNewVersion({ name: 'Article name', body: 'New body' })
    yield postNewVersion({ name: 'Article name', body: 'New new body', version: { major: 0 } })
    articles = yield Article.find()
    expect(articles.length).toBe(3)

    versions = (article.get('version') for article in articles)
    articles = (article.toObject() for article in articles)
    
    testArrayEqual(_.pluck(versions, 'major'), [0, 1, 0])
    testArrayEqual(_.pluck(versions, 'minor'), [0, 0, 1])
    testArrayEqual(_.pluck(versions, 'isLatestMajor'), [false, true, false])
    testArrayEqual(_.pluck(versions, 'isLatestMinor'), [false, true, true])
    testArrayEqual(_.pluck(articles, 'name'), ['Article name', 'Article name', 'Article name'])
    testArrayEqual(_.pluck(articles, 'body'), ['Article body', 'New body', 'New new body'])
    testArrayEqual(_.pluck(articles, 'slug'), [undefined, 'article-name', undefined])
    testArrayEqual(_.pluck(articles, 'index'), [undefined, true, undefined])
    done()
    
    
  it 'unsets properties which are not included in the request', utils.wrap (done) ->
    yield postNewVersion({ name: 'Article name', version: { major: 0 } })
    articles = yield Article.find()
    expect(articles.length).toBe(2)
    expect(articles[1].get('body')).toBeUndefined()
    done()
  
  
  it 'works for artisans', utils.wrap (done) ->
    yield utils.logout()
    artisan = yield utils.initArtisan()
    yield utils.loginUser(artisan)
    yield postNewVersion({ name: 'Article name', body: 'New body' })
    articles = yield Article.find()
    expect(articles.length).toBe(2)
    done()
    
    
  it 'works for normal users submitting translations', utils.wrap (done) ->
    yield utils.logout()
    user = yield utils.initUser()
    yield utils.loginUser(user)
    yield postNewVersion({ name: 'Article name', body: 'Article body', i18n: { fr: { name: 'Le Article' }}}, 201)
    articles = yield Article.find()
    expect(articles.length).toBe(2)
    done()


  it 'does not work for normal users', utils.wrap (done) ->
    yield utils.logout()
    user = yield utils.initUser()
    yield utils.loginUser(user)
    yield postNewVersion({ name: 'Article name', body: 'New body' }, 403)
    articles = yield Article.find()
    expect(articles.length).toBe(1)
    done()


  it 'does not work for anonymous users', utils.wrap (done) ->
    yield utils.becomeAnonymous()
    yield postNewVersion({ name: 'Article name', body: 'New body' }, 401)
    articles = yield Article.find()
    expect(articles.length).toBe(1)
    done()

  
  it 'notifies watchers of changes', utils.wrap (done) ->
    sendwithus = require '../../../server/sendwithus'
    spyOn(sendwithus.api, 'send').and.callFake (context, cb) ->
      expect(context.email_id).toBe(sendwithus.templates.change_made_notify_watcher)
      expect(context.recipient.address).toBe('test@gmail.com')
      done()
    user = yield User({email: 'test@gmail.com', name: 'a user'}).save()
    article = yield Article.findById(articleID)
    article.set('watchers', article.get('watchers').concat([user.get('_id')]))
    yield article.save()
    yield postNewVersion({ name: 'Article name', body: 'New body', commitMessage: 'Commit message' })
    
    
  it 'sends a notification to artisan and main Slack channels', utils.wrap (done) ->
    slack = require '../../../server/slack'
    spyOn(slack, 'sendSlackMessage')
    yield postNewVersion({ name: 'Article name', body: 'New body' })
    expect(slack.sendSlackMessage).toHaveBeenCalled()
    done()
  
describe 'version fetching endpoints', ->
  articleData = { name: 'Original version', body: 'Article body' }
  articleOriginal = null

  postNewVersion = Promise.promisify (json, expectedStatus=201, done) ->
    if _.isFunction(expectedStatus)
      done = expectedStatus
      expectedStatus = 201
    url = getURL("/db/article/#{articleOriginal}/new-version")
    request.post { uri: url, json: json }, (err, res) ->
      expect(res.statusCode).toBe(expectedStatus)
      done(err)


  beforeEach utils.wrap (done) ->
    yield utils.clearModels([Article])
    @admin = yield utils.initAdmin({})
    yield utils.loginUser(@admin)
    [res, body] = yield request.postAsync { uri: getURL('/db/article'), json: articleData }
    expect(res.statusCode).toBe(201)
    articleOriginal = body._id
    yield postNewVersion({ name: 'Latest minor version', body: 'New body', version: {major: 0} })
    yield postNewVersion({ name: 'Latest major version', body: 'New new body' })
    done()


  describe 'GET /db/article/:handle/version/:version', ->
  
    it 'returns the latest version for the given original article when :version is empty', utils.wrap (done) ->
      [res, body] = yield request.getAsync { uri: getURL("/db/article/#{articleOriginal}/version"), json: true }
      expect(body.name).toBe('Latest major version')
      done()
    
    it 'returns the latest of a given major version when :version is X', utils.wrap (done) ->
      [res, body] = yield request.getAsync { uri: getURL("/db/article/#{articleOriginal}/version/0"), json: true }
      expect(body.name).toBe('Latest minor version')
      done()
    
    it 'returns a specific version when :version is X.Y', utils.wrap (done) ->
      [res, body] = yield request.getAsync { uri: getURL("/db/article/#{articleOriginal}/version/0.0"), json: true }
      expect(body.name).toBe('Original version')
      done()
      
    it 'returns 422 when the original value is invalid', utils.wrap (done) ->
      [res, body] = yield request.getAsync { uri: getURL('/db/article/dne/version'), json: true }
      expect(res.statusCode).toBe(422)
      done()
  
    it 'returns 404 when the original value cannot be found', utils.wrap (done) ->
      [res, body] = yield request.getAsync { uri: getURL('/db/article/012345678901234567890123/version'), json: true }
      expect(res.statusCode).toBe(404)
      done()
  
  
  describe 'GET /db/article/:handle/versions', ->
    
    it 'returns an array of versions sorted by creation for the given original article', utils.wrap (done) ->
      [res, body] = yield request.getAsync { uri: getURL("/db/article/#{articleOriginal}/versions"), json: true }
      expect(body.length).toBe(3)
      expect(body[0].name).toBe('Latest major version')
      expect(body[1].name).toBe('Latest minor version')
      expect(body[2].name).toBe('Original version')
      done()
      
    it 'projects most properties by default', utils.wrap (done) ->
      [res, body] = yield request.getAsync { uri: getURL("/db/article/#{articleOriginal}/versions"), json: true }
      expect(body[0].body).toBeUndefined()
      done()
  
  
describe 'GET /db/article/:handle/files', ->
  
  it 'returns an array of file metadata for the given original article', utils.wrap (done) ->
    yield utils.clearModels([Article])
    articleData = { name: 'Article', body: 'Article' }
    admin = yield utils.initAdmin({})
    yield utils.loginUser(admin)
    [res, article] = yield request.postAsync { uri: getURL('/db/article'), json: articleData }
    expect(res.statusCode).toBe(201)
    [res, body] = yield request.postAsync(getURL('/file'), { json: {
      url: getURL('/assets/main.html')
      filename: 'test.html'
      path: 'db/article/'+article.original
      mimetype: 'text/html'
    }})
    [res, body] = yield request.getAsync(getURL('/db/article/'+article.original+'/files'), {json: true})
    expect(body.length).toBe(1)
    expect(body[0].filename).toBe('test.html')
    expect(body[0].metadata.path).toBe('db/article/'+article.original)
    done()
  
    
describe 'GET and POST /db/article/:handle/names', ->
  articleData1 = { name: 'Article 1', body: 'Article 1 body' }
  articleData2 = { name: 'Article 2', body: 'Article 2 body' }

  it 'returns an object mapping ids to names', utils.wrap (done) ->
    yield utils.clearModels([Article])
    admin = yield utils.initAdmin({})
    yield utils.loginUser(admin)
    [res, article1] = yield request.postAsync(getURL('/db/article'), { json: articleData1 })
    [res, article2] = yield request.postAsync(getURL('/db/article'), { json: articleData2 })
    yield utils.becomeAnonymous()
    [res, body] = yield request.getAsync { uri: getURL('/db/article/names?ids='+[article1._id, article2._id].join(',')), json: true }
    expect(body.length).toBe(2)
    expect(body[0].name).toBe('Article 1')
    [res, body] = yield request.postAsync { uri: getURL('/db/article/names?ids='+[article1._id, article2._id].join(',')), json: true }
    expect(body.length).toBe(2)
    expect(body[0].name).toBe('Article 1')
    done()
  
  
describe 'GET /db/article/:handle/patches', ->
  
  it 'returns pending patches for the given original article', utils.wrap (done) ->
    yield utils.clearModels([Article])
    articleData = { name: 'Article', body: 'Article' }
    admin = yield utils.initAdmin({})
    yield utils.loginUser(admin)
    [res, article] = yield request.postAsync { uri: getURL('/db/article'), json: articleData }
    expect(res.statusCode).toBe(201)
    [res, patch] = yield request.postAsync { uri: getURL('/db/patch'), json: {
      delta: []
      commitMessage: 'Test commit'
      target: {
        collection: 'article'
        id: article._id
      }
    }}
    [res, patches] = yield request.getAsync getURL("/db/article/#{article._id}/patches"), { json: true }
    expect(res.statusCode).toBe(200)
    expect(patches.length).toBe(1)
    expect(patches[0]._id).toBe(patch._id)
    done()
    
  it 'returns 422 for invalid object ids', utils.wrap (done) ->
    [res, body] = yield request.getAsync getURL("/db/article/invalid/patches"), { json: true }
    expect(res.statusCode).toBe(422)
    done()
  
    
describe 'POST /db/article/:handle/watchers', ->
  
  it 'adds self to the list of watchers, and is idempotent', utils.wrap (done) ->
    # create article
    yield utils.clearModels([Article])
    articleData = { name: 'Article', body: 'Article' }
    admin = yield utils.initAdmin({})
    yield utils.loginUser(admin)
    [res, article] = yield request.postAsync { uri: getURL('/db/article'), json: articleData }
    expect(res.statusCode).toBe(201)
    
    # add new user as watcher
    yield utils.logout()
    user = yield utils.initUser()
    yield utils.loginUser(user)
    [res, article] = yield request.postAsync { uri: getURL("/db/article/#{article._id}/watchers"), json: true }
    expect(res.statusCode).toBe(200)
    expect(_.contains(article.watchers, user.id)).toBe(true)

    # check idempotence, db
    numWatchers = article.watchers.length
    [res, article] = yield request.postAsync { uri: getURL("/db/article/#{article._id}/watchers"), json: true }
    expect(res.statusCode).toBe(200)
    expect(numWatchers).toBe(article.watchers.length)
    article = yield Article.findById(article._id)
    expect(_.last(article.get('watchers')).toString()).toBe(user.id)
    done()
    

describe 'DELETE /db/article/:handle/watchers', ->
  
  it 'removes self from the list of watchers, and is idempotent', utils.wrap (done) ->
    # create article
    yield utils.clearModels([Article])
    articleData = { name: 'Article', body: 'Article' }
    admin = yield utils.initAdmin({})
    yield utils.loginUser(admin)
    [res, article] = yield request.postAsync { uri: getURL('/db/article'), json: articleData }
    expect(res.statusCode).toBe(201)

    # add new user as watcher
    yield utils.logout()
    user = yield utils.initUser()
    yield utils.loginUser(user)
    [res, article] = yield request.postAsync { uri: getURL("/db/article/#{article._id}/watchers"), json: true }
    expect(_.contains(article.watchers, user.id)).toBe(true)

    # remove user as watcher
    [res, article] = yield request.delAsync { uri: getURL("/db/article/#{article._id}/watchers"), json: true }
    expect(res.statusCode).toBe(200)
    expect(_.contains(article.watchers, user.id)).toBe(false)

    # check idempotence, db
    numWatchers = article.watchers.length
    [res, article] = yield request.delAsync { uri: getURL("/db/article/#{article._id}/watchers"), json: true }
    expect(res.statusCode).toBe(200)
    expect(numWatchers).toBe(article.watchers.length)
    article = yield Article.findById(article._id)
    ids = (id.toString() for id in article.get('watchers'))
    expect(_.contains(ids, user.id)).toBe(false)
    done()
