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

diminishing =
  name: 'Simulated2'
  worth: 1.5
  collection: 'User'
  query: "{\"simulatedBy\":{\"$gt\":\"0\"}}"
  userField: '_id'
  proportionalTo: 'simulatedBy'
  function:
    kind: 'logarithmic'
    parameters: {a: 1, b: .5, c: .5, d: 1}

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

          request.post {uri: url, json: diminishing}, (err, res, body) ->
            expect(res.statusCode).toBe(200)
            diminishing._id = body._id

            Achievement.find {}, (err, docs) ->
              expect(docs.length).toBe 3
            done()

  it 'can get all for ordinary users', (done) ->
    loginJoe ->
      request.get {uri: url, json: unlockable}, (err, res, body) ->
        expect(res.statusCode).toBe(200)
        expect(body.length).toBe 3
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


  it 'saving an object that should trigger an unlockable achievement', (done) ->
    unittest.getNormalJoe (joe) ->
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


  it 'verify that an unlockable achievement has been earned', (done) ->
    unittest.getNormalJoe (joe) ->
      EarnedAchievement.find {}, (err, docs) ->
        expect(err).toBeNull()
        expect(docs.length).toBe(1)
        achievement = docs[0]

        expect(achievement.get 'achievement').toBe unlockable._id
        expect(achievement.get 'user').toBe joe._id.toHexString()
        expect(achievement.get 'notified').toBeFalsy()
        expect(achievement.get 'earnedPoints').toBe unlockable.worth
        expect(achievement.get 'achievedAmount').toBeUndefined()
        expect(achievement.get 'previouslyAchievedAmount').toBeUndefined()

        done()

  it 'saving an object that should trigger a repeatable achievement', (done) ->
    unittest.getNormalJoe (joe) ->
      expect(joe.get 'simulatedBy').toBeFalsy()
      joe.set('simulatedBy', 2)
      joe.save (err, doc) ->
        expect(err).toBeNull()
        done()

  it 'verify that a repeatable achievement has been earned', (done) ->
    unittest.getNormalJoe (joe) ->
      EarnedAchievement.find {achievementName: repeatable.name}, (err, docs) ->
        expect(err).toBeNull()
        expect(docs.length).toBe(1)
        achievement = docs[0]

        expect(achievement.get 'achievement').toBe repeatable._id
        expect(achievement.get 'user').toBe joe._id.toHexString()
        expect(achievement.get 'notified').toBeFalsy()
        expect(achievement.get 'earnedPoints').toBe 2 * repeatable.worth
        expect(achievement.get 'achievedAmount').toBe 2
        expect(achievement.get 'previouslyAchievedAmount').toBeFalsy()
        done()


  it 'verify that the repeatable achievement with complex exp has been earned', (done) ->
    unittest.getNormalJoe (joe) ->
      EarnedAchievement.find {achievementName: diminishing.name}, (err, docs) ->
        expect(err).toBeNull()
        expect(docs.length).toBe 1
        achievement = docs[0]

        expect(achievement.get 'achievedAmount').toBe 2
        expect(achievement.get 'earnedPoints').toBe (Math.log(.5 * (2 + .5)) + 1) * diminishing.worth

        done()

  it 'cleaning up test: deleting all Achievements and relates', (done) ->
    clearModels [Achievement, EarnedAchievement, LevelSession], (err) ->
      expect(err).toBeNull()

      # reset achievements in memory as well
      Achievement.resetAchievements()
      loadedAchievements = Achievement.getLoadedAchievements()
      expect(Object.keys(loadedAchievements).length).toBe(0)

      done()







