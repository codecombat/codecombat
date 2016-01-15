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
  rewards:
    gems: 1

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

  it 'can\'t be updated by ordinary users', (done) ->
    loginJoe ->
      unlockable3 = _.clone(unlockable)
      unlockable3.description = 'alsdfkhasdkfhajksdhfjkasdhfj'
      request.put {uri: url, json: unlockable3}, (err, res, body) ->
        expect(res.statusCode).toBe(403)

        request {method: 'patch', uri: url, json: unlockable}, (err, res, body) ->
          expect(res.statusCode).toBe(403)
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

# TODO: Took level achievements out of this auto achievement business, so fix these tests

describe 'Level Session Achievement', ->
  it 'does not generate earned achievements automatically, they need to be created manually', (done) ->
    unittest.getNormalJoe (joe) ->
      session = new LevelSession
        permissions: simplePermissions
        creator: joe._id
        level: original: 'dungeon-arena'
      session.save (err, session) ->
        expect(err).toBeNull()
        expect(session).toBeDefined()
        expect(session.creator).toBe(session.creator)

        EarnedAchievement.find {}, (err, earnedAchievements) ->
          expect(err).toBeNull()
          expect(earnedAchievements.length).toBe(0)

          json = {achievement: unlockable._id, triggeredBy: session._id, collection: 'level.sessions'}
          request.post {uri: getURL('/db/earned_achievement'), json: json}, (err, res, body) ->
            expect(res.statusCode).toBe(201)
            expect(body.achievement).toBe unlockable._id+''
            expect(body.user).toBe joe._id.toHexString()
            expect(body.notified).toBeFalsy()
            expect(body.earnedPoints).toBe unlockable.worth
            expect(body.achievedAmount).toBeUndefined()
            expect(body.previouslyAchievedAmount).toBeUndefined()
            done()


describe 'Achieving Achievements', ->
  it 'wait for achievements to be loaded', (done) ->
    Achievement.loadAchievements (achievements) ->
      expect(Object.keys(achievements).length).toBe(1)

      loadedAchievements = Achievement.getLoadedAchievements()
      expect(Object.keys(loadedAchievements).length).toBe(1)
      done()

  it 'saving an object that should trigger a repeatable achievement', (done) ->
    unittest.getNormalJoe (joe) ->
      expect(joe.get 'simulatedBy').toBeFalsy()
      joe.set('simulatedBy', 2)
      joe.save (err, doc) ->
        expect(err).toBeNull()
        done()

  it 'verify that a repeatable achievement has been earned', (done) ->
    func = ->
      unittest.getNormalJoe (joe) ->
  
        User.findById(joe.get('_id')).exec (err, joe2) ->
          expect(joe2.get('earned').gems).toBe(2)
  
          EarnedAchievement.find {achievementName: repeatable.name}, (err, docs) ->
            expect(err).toBeNull()
            expect(docs.length).toBe(1)
            achievement = docs[0]
  
            if achievement
              expect(achievement.get 'achievement').toBe repeatable._id
              expect(achievement.get 'user').toBe joe._id.toHexString()
              expect(achievement.get 'notified').toBeFalsy()
              expect(achievement.get 'earnedPoints').toBe 2 * repeatable.worth
              expect(achievement.get 'achievedAmount').toBe 2
              expect(achievement.get 'previouslyAchievedAmount').toBeFalsy()
            done()
    setTimeout(func, 500) # give server time to apply achievement 

  it 'verify that the repeatable achievement with complex exp has been earned', (done) ->
    unittest.getNormalJoe (joe) ->
      EarnedAchievement.find {achievementName: diminishing.name}, (err, docs) ->
        expect(err).toBeNull()
        expect(docs.length).toBe 1
        achievement = docs[0]

        if achievement
          expect(achievement.get 'achievedAmount').toBe 2
          expect(achievement.get 'earnedPoints').toBe (Math.log(.5 * (2 + .5)) + 1) * diminishing.worth

        done()

  it 'increases gems proportionally to changes made', (done) ->
    unittest.getNormalJoe (joe) ->
      User.findById(joe.get('_id')).exec (err, joe2) ->
        joe2.set('simulatedBy', 4)
        expect(joe2.get('earned').gems).toBe(2)
        joe2.save (err, joe3) ->
          expect(err).toBeNull()
          User.findById(joe3.get('_id')).exec (err, joe4) ->
            #expect(joe4.get('earned').gems).toBe(4)   # ... this sometimes gives 4, sometimes 2. Race condition? TODO
            done()


describe 'Recalculate Achievements', ->
  EarnedAchievementHandler = require '../../../server/achievements/earned_achievement_handler'

  it 'remove earned achievements', (done) ->
    f = ->
      clearModels [EarnedAchievement], (err) ->
        expect(err).toBeNull()
        EarnedAchievement.find {}, (err, earned) ->
          expect(earned.length).toBe 0
  
          User.update {}, {$set: {points: 0}}, {multi:true}, (err) ->
            expect(err).toBeNull()
            done()
    setTimeout f, 100 # wait for previous tests to wrap up to avoid race condition

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
                expect(guy.get 'points').toBe unlockable.worth + 4 * repeatable.worth + (Math.log(.5 * (4 + .5)) + 1) * diminishing.worth
                expect(guy.get('earned').gems).toBe 4 * repeatable.rewards.gems
                done()

  it 'cleaning up test: deleting all Achievements and related', (done) ->
    clearModels [Achievement, EarnedAchievement, LevelSession], (err) ->
      expect(err).toBeNull()

      # reset achievements in memory as well
      Achievement.resetAchievements()
      loadedAchievements = Achievement.getLoadedAchievements()
      expect(Object.keys(loadedAchievements).length).toBe(0)

      done()
