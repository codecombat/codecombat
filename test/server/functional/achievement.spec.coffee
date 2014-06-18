require '../common'

unlockable =
  name: 'Dungeon Arena Started'
  description: 'Started playing Dungeon Arena.'
  worth: 3
  collection: 'level.session'
  query: "{\"level.original\":\"dungeon-arena\"}"
  userField: 'creator'

repeatable =
  name: 'Simulated'
  description: 'Simulated Games.'
  worth: 1
  collection: 'User'
  query: "{\"simulatedBy\":{\"$gt\":\"0\"}}"
  userField: '_id'
  proportionalTo: 'simulatedBy'

url = getURL('/db/achievement')

describe 'Achievement', ->
  allowHeader = 'GET, POST, PUT, PATCH'

  it 'preparing test: deleting all Achievements first', (done) ->
    clearModels [Achievement, EarnedAchievement, LevelSession, User], (err) ->
      expect(err).toBeNull()
      done()

  it 'can\'t be created by ordinary users', (done) ->
    loginJoe ->
      request.post {uri: url, json: unlockable}, (err, res, body) ->
        expect(res.statusCode).toBe(403)
        done()

  it 'can\'t be updated by ordinary users', (done) ->
    loginJoe ->
      request.put {uri: url, json:unlockable}, (err, res, body) ->
        expect(res.statusCode).toBe(403)

        request {method: 'patch', uri: url, json: unlockable}, (err, res, body) ->
          expect(res.statusCode).toBe(403)
          done()

  it 'can be created by admins', (done) ->
    loginAdmin ->
      request.post {uri: url, json: unlockable}, (err, res, body) ->
        expect(res.statusCode).toBe(200)
        unlockable._id = body._id

        request.post {uri: url, json: repeatable}, (err, res, body) ->
          expect(res.statusCode).toBe(200)
          repeatable._id = body._id

          Achievement.find {}, (err, docs) ->
            expect(docs.length).toBe(2)
          done()

  it 'can get all for ordinary users', (done) ->
    loginJoe ->
      request.get {uri: url, json: unlockable}, (err, res, body) ->
        expect(res.statusCode).toBe(200)
        expect(body.length).toBe(2)
        done()

  it 'can be read by ordinary users', (done) ->
    loginJoe ->
      request.get {uri: url + '/' + unlockable._id, json: unlockable}, (err, res, body) ->
        expect(res.statusCode).toBe(200)
        expect(body.name).toBe(unlockable.name)
        done()

  it 'can\'t be requested with HTTP HEAD method', (done) ->
    loginJoe ->
      request.head {uri: url + '/' + unlockable._id}, (err, res, body) ->
        expect(res.statusCode).toBe(405)
        expect(res.headers.allow).toBe(allowHeader)
        done()

  it 'can\'t be requested with HTTP DEL method', (done) ->
    loginJoe ->
      request.del {uri: url + '/' + unlockable._id}, (err, res, body) ->
        expect(res.statusCode).toBe(405)
        expect(res.headers.allow).toBe(allowHeader)
        done()

  it 'get schema', (done) ->
    request.get {uri:url + '/schema'}, (err, res, body) ->
      expect(res.statusCode).toBe(200)
      body = JSON.parse(body)
      expect(body.type).toBeDefined()
      done()


describe 'Achieving Achievements', ->
  it 'wait for achievements to be loaded', (done) ->
    Achievement.loadAchievements (achievements) ->
      expect(Object.keys(achievements).length).toBe(2)

      loadedAchievements = Achievement.getLoadedAchievements()
      expect(Object.keys(loadedAchievements).length).toBe(2)

      done()


  it 'allows users to unlock one-time Achievements', (done) ->
    loginJoe (joe) ->
      session = new LevelSession(
        permissions: simplePermissions
        creator: joe._id
        level: original: 'dungeon-arena'
      )

      session.save (err, doc) ->
        expect(err).toBeNull()
        expect(doc).toBeDefined()
        expect(doc.creator).toBe(session.creator)
        done()

  it 'check if the earned achievement was already saved', (done) ->
    EarnedAchievement.find {}, (err, docs) ->
      expect(err).toBeNull()
      expect(docs.length).toBe(1)
      done()

  it 'cleaning up test: deleting all Achievements and relates', (done) ->
    clearModels [Achievement, EarnedAchievement, LevelSession], (err) ->
      expect(err).toBeNull()

      Achievement.resetAchievements()
      loadedAchievements = Achievement.getLoadedAchievements()
      expect(Object.keys(loadedAchievements).length).toBe(0)

      done()






