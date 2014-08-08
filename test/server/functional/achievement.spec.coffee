require '../common'

unlockable =
  name: 'Dungeon Arena Started'
  description: 'Started playing Dungeon Arena.'
  worth: 3
  collection: 'level.sessions'
  query: "{\"level.original\":\"dungeon-arena\"}"
  userField: 'creator'
  recalculable: true

unlockable2 = _.clone unlockable
unlockable2.name = 'This one is obsolete'

repeatable =
  name: 'Simulated'
  description: 'Simulated Games.'
  worth: 1
  collection: 'users'
  query: "{\"simulatedBy\":{\"$gt\":0}}"
  userField: '_id'
  proportionalTo: 'simulatedBy'
  recalculable: true

diminishing =
  name: 'Simulated2'
  worth: 1.5
  collection: 'users'
  query: "{\"simulatedBy\":{\"$gt\":0}}"
  userField: '_id'
  proportionalTo: 'simulatedBy'
  function:
    kind: 'logarithmic'
    parameters: {a: 1, b: .5, c: .5, d: 1}
  recalculable: true

url = getURL('/db/achievement')

describe 'Achievement', ->
  allowHeader = 'GET, POST, PUT, PATCH, DELETE'

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
      request.put {uri: url, json: unlockable}, (err, res, body) ->
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

  it 'allows admins to delete achievements using DELETE', (done) ->
    loginAdmin ->
      request.post {uri: url, json: unlockable2}, (err, res, body) ->
        expect(res.statusCode).toBe(200)
        unlockable2._id = body._id

        request.del {uri: url + '/' + unlockable2._id}, (err, res, body) ->
          expect(res.statusCode).toBe(204)

          request.del {uri: url + '/' + unlockable2._id}, (err, res, body) ->
            expect(res.statusCode).toBe(404)
            done()

  it 'get schema', (done) ->
    request.get {uri: url + '/schema'}, (err, res, body) ->
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
      session = new LevelSession
        permissions: simplePermissions
        creator: joe._id
        level: original: 'dungeon-arena'
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
        expect(achievement).toBeDefined()

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

describe 'Recalculate Achievements', ->
  EarnedAchievementHandler = require '../../../server/achievements/earned_achievement_handler'

  it 'remove earned achievements', (done) ->
    clearModels [EarnedAchievement], (err) ->
      expect(err).toBeNull()
      EarnedAchievement.find {}, (err, earned) ->
        expect(earned.length).toBe 0

        User.update {}, {$set: {points: 0}}, {multi:true}, (err) ->
          expect(err).toBeNull()
          done()

  it 'can not be accessed by regular users', (done) ->
    loginJoe -> request.post {uri:getURL '/admin/earned_achievement/recalculate'}, (err, res, body) ->
      expect(res.statusCode).toBe 403
      done()

  it 'can recalculate a selection of achievements', (done) ->
    loginAdmin ->
      EarnedAchievementHandler.constructor.recalculate ['dungeon-arena-started'], ->
        EarnedAchievement.find {}, (err, earnedAchievements) ->
          expect(earnedAchievements.length).toBe 1

          # Recalculate again, doesn't change a thing
          EarnedAchievementHandler.constructor.recalculate ['dungeon-arena-started'], ->
            EarnedAchievement.find {}, (err, earnedAchievements) ->
              expect(earnedAchievements.length).toBe 1

              unittest.getNormalJoe (joe) ->
                User.findById joe.get('id'), (err, guy) ->
                  expect(err).toBeNull()
                  expect(guy.get 'points').toBe unlockable.worth
                  done()

  it 'can recalculate all achievements', (done) ->
    loginAdmin ->
      Achievement.count {}, (err, count) ->
        expect(count).toBe 3
        EarnedAchievementHandler.constructor.recalculate ->
          EarnedAchievement.find {}, (err, earnedAchievements) ->
            expect(earnedAchievements.length).toBe 3
            unittest.getNormalJoe (joe) ->
              User.findById joe.get('id'), (err, guy) ->
                expect(err).toBeNull()
                expect(guy.get 'points').toBe unlockable.worth + 2 * repeatable.worth + (Math.log(.5 * (2 + .5)) + 1) * diminishing.worth
                done()

  it 'cleaning up test: deleting all Achievements and related', (done) ->
    clearModels [Achievement, EarnedAchievement, LevelSession], (err) ->
      expect(err).toBeNull()

      # reset achievements in memory as well
      Achievement.resetAchievements()
      loadedAchievements = Achievement.getLoadedAchievements()
      expect(Object.keys(loadedAchievements).length).toBe(0)

      done()
