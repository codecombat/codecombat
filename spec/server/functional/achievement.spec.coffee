require '../common'
utils = require '../utils'
Promise = require 'bluebird'
Achievement = require '../../../server/models/Achievement'
EarnedAchievement = require '../../../server/models/EarnedAchievement'
LevelSession = require '../../../server/models/LevelSession'
User = require '../../../server/models/User'
request = require '../request'
EarnedAchievementHandler = require '../../../server/handlers/earned_achievement_handler'
mongoose = require 'mongoose'

url = getURL('/db/achievement')


# Fixtures

lockedLevelID = new mongoose.Types.ObjectId().toString()

unlockable =
  name: 'Dungeon Arena Started'
  description: 'Started playing Dungeon Arena.'
  worth: 3
  collection: 'level.sessions'
  query: {'level.original':'dungeon-arena'}
  userField: 'creator'
  recalculable: true
  related: 'a'
  rewards: {
    levels: [lockedLevelID]
  }

unlockable2 = _.clone unlockable
unlockable2.name = 'This one is obsolete'

repeatable =
  name: 'Simulated'
  description: 'Simulated Games.'
  worth: 1
  collection: 'users'
  query: {'simulatedBy':{'$gt':0}}
  userField: '_id'
  proportionalTo: 'simulatedBy'
  recalculable: true
  rewards:
    gems: 1
  related: 'b'

diminishing =
  name: 'Simulated2'
  worth: 1.5
  collection: 'users'
  query: {'simulatedBy':{'$gt':0}}
  userField: '_id'
  proportionalTo: 'simulatedBy'
  function:
    kind: 'logarithmic'
    parameters: {a: 1, b: .5, c: .5, d: 1}
  recalculable: true
  related: 'b'
  
addAllAchievements = utils.wrap (done) ->
  yield utils.clearModels [Achievement, EarnedAchievement, LevelSession, User]
  @admin = yield utils.initAdmin()
  yield utils.loginUser(@admin)
  [res, body] = yield request.postAsync {uri: url, json: unlockable}
  expect(res.statusCode).toBe(201)
  @unlockable = yield Achievement.findById(body._id)
  [res, body] = yield request.postAsync {uri: url, json: repeatable}
  expect(res.statusCode).toBe(201)
  @repeatable = yield Achievement.findById(body._id)
  [res, body] = yield request.postAsync {uri: url, json: diminishing}
  expect(res.statusCode).toBe(201)
  @diminishing = yield Achievement.findById(body._id)
  done()

  
describe 'POST /db/achievement', ->
  beforeEach utils.wrap (done) ->
    yield utils.clearModels [Achievement, EarnedAchievement, LevelSession, User]
    done()
    
  it 'returns 403 for ordinary users', utils.wrap (done) ->
    user = yield utils.initUser()
    yield utils.loginUser(user)
    [res, body] = yield request.postAsync {uri: url, json: unlockable}
    expect(res.statusCode).toBe(403)
    done()
    
  it 'works for admins', utils.wrap (done) ->
    admin = yield utils.initAdmin()
    yield utils.loginUser(admin)
    [res, body] = yield request.postAsync {uri: url, json: unlockable}
    expect(res.statusCode).toBe(201)
    done()
    
describe 'PUT /db/achievement', ->
  beforeEach addAllAchievements
    
  it 'return 403 for ordinary users', utils.wrap (done) ->
    user = yield utils.initUser()
    yield utils.loginUser(user)
    [res, body] = yield request.putAsync {uri: url + '/'+@unlockable.id, json: {name: 'whatev'}}
    expect(res.statusCode).toBe(403)
    done()
    
  it 'works for admins', utils.wrap (done) ->
    [res, body] = yield request.putAsync {uri: url + '/'+@unlockable.id, json: {name: 'whatev'}}
    expect(res.statusCode).toBe(200)
    expect(res.body.name).toBe('whatev')
    done()
    
describe 'GET /db/achievement', ->
  beforeEach addAllAchievements
  
  it 'returns all achievements', ->
    user = yield utils.initUser()
    yield utils.loginUser(user)
    [res, body] = request.getAsync {uri: url}
    expect(res.statusCode).toBe(200)
    expect(body.length).toBe 3
    done()

describe 'GET /db/achievement?related=:id', ->
  beforeEach addAllAchievements
  
  it 'returns all achievements related to a given doc', utils.wrap (done) ->
    [res, body] = yield request.getAsync {uri: url+'?related=b', json: true}
    expect(res.statusCode).toBe(200)
    expect(res.body.length).toBe(2)
    expect(_.difference([@repeatable.id, @diminishing.id], (doc._id for doc in res.body)).length).toBe(0)
    done()
    
describe 'GET /db/achievement/:handle', ->
  beforeEach addAllAchievements

  it 'returns the achievement', ->
    user = yield utils.initUser()
    yield utils.loginUser(user)
    [res, body] = request.getAsync {uri: url+'/'+@unlockable.id}
    expect(res.statusCode).toBe(200)
    expect(body._id).toBe(@unlockable.id)
    done()
    
describe 'DELETE /db/achievement/:handle', ->
  beforeEach addAllAchievements
    
  it 'deletes the given achievement', utils.wrap (done) ->
    achievement = Achievement.findById(@unlockable.id)
    expect(achievement).toBeTruthy()
    [res, body] = yield request.delAsync {uri: url + '/' + @unlockable.id}
    expect(res.statusCode).toBe(204)
    achievement = yield Achievement.findById(@unlockable.id)
    expect(achievement).toBeFalsy()
    [res, body] = yield request.delAsync {uri: url + '/' + @unlockable.id}
    expect(res.statusCode).toBe(404)
    done()
    
  it 'returns 403 unless you are an admin or artisan', utils.wrap (done) ->
    user = yield utils.initUser()
    yield utils.loginUser(user)
    [res, body] = yield request.delAsync {uri: url + '/' + @unlockable.id}
    expect(res.statusCode).toBe(403)
    artisan = yield utils.initArtisan()
    yield utils.loginUser(artisan)
    [res, body] = yield request.delAsync {uri: url + '/' + @unlockable.id}
    expect(res.statusCode).toBe(204)
    done()


describe 'POST /db/earned_achievement', ->
  beforeEach addAllAchievements
  eaURL = getURL('/db/earned_achievement')
  
  it 'manually creates earned achievements for level achievements, which do not happen automatically', utils.wrap (done) ->
    session = new LevelSession({
      permissions: simplePermissions
      creator: @admin._id
      level: original: 'dungeon-arena'
    })
    yield session.save()
    earnedAchievements = yield EarnedAchievement.find()
    expect(earnedAchievements.length).toBe(0)
    json = {achievement: @unlockable.id, triggeredBy: session._id, collection: 'level.sessions'}
    [res, body] = yield request.postAsync { url: eaURL, json }
    expect(res.statusCode).toBe(201)
    expect(body.achievement).toBe @unlockable.id
    expect(body.user).toBe @admin.id
    expect(body.notified).toBeFalsy()
    expect(body.earnedPoints).toBe unlockable.worth
    expect(body.achievedAmount).toBeUndefined()
    expect(body.previouslyAchievedAmount).toBeUndefined()
    earnedAchievements = yield EarnedAchievement.find()
    expect(earnedAchievements.length).toBe(1)
    done()
    
  it 'works for proportional achievements', utils.wrap (done) ->
    user = yield utils.initUser()
    yield utils.loginUser(user)
    yield user.update({simulatedBy: 10})
    json = {achievement: @repeatable.id, triggeredBy: user.id, collection: 'users'}
    [res, body] = yield request.postAsync { url: eaURL, json }
    expect(res.statusCode).toBe(201)
    expect(body.earnedPoints).toBe(10)
    yield user.update({simulatedBy: 30})
    [res, body] = yield request.postAsync { url: eaURL, json }
    expect(res.statusCode).toBe(201)
    expect(body.earnedPoints).toBe(20) # this is kinda weird, TODO: just return total amounts
    done()
    
  it 'ensures the user has the rewards they earned', utils.wrap (done) ->
    user = yield utils.initUser()
    yield utils.loginUser(user)
    
    # get the User the unlockable achievement, check they got their reward
    session = new LevelSession({
      permissions: simplePermissions
      creator: user._id
      level: original: 'dungeon-arena'
    })
    yield session.save()
    json = {achievement: @unlockable.id, triggeredBy: session._id, collection: 'level.sessions'}
    [res, body] = yield request.postAsync { url: eaURL, json }
    user = yield User.findById(user.id)
    expect(user.get('earned').levels[0]).toBe(lockedLevelID)
    
    # mess with the user's earned levels, make sure they don't have it anymore
    yield user.update({$unset: {earned:1}})
    user = yield User.findById(user.id)
    expect(user.get('earned')).toBeUndefined()

    # hit the endpoint again, make sure the level was restored
    [res, body] = yield request.postAsync { url: eaURL, json }
    user = yield User.findById(user.id)
    expect(user.get('earned').levels[0]).toBe(lockedLevelID)
    done()

describe 'automatically achieving achievements', ->
  beforeEach addAllAchievements

  it 'happens when an object\'s properties meet achievement goals', utils.wrap (done) ->
    # load achievements on server
    @achievements = yield Achievement.loadAchievements()
    expect(@achievements.users.length).toBe(2)
    loadedAchievements = Achievement.getLoadedAchievements()
    expect(Object.keys(loadedAchievements).length).toBe(1)
    
    user = yield utils.initUser()
    yield utils.loginUser(user)
    expect(user.get('simulatedBy')).toBeFalsy()
    user.set('simulatedBy', 2)
    yield user.save()
    yield new Promise((resolve) -> setTimeout(resolve, 100)) # give server time to apply achievement
    
    # check 'repeatable' achievement
    user = yield User.findById(user._id)
    expect(user.get('earned').gems).toBe(2)
    docs = yield EarnedAchievement.find({achievementName: @repeatable.get('name')})
    expect(docs.length).toBe(1)
    ea = docs[0]
    expect(ea.get 'achievement').toBe @repeatable.id
    expect(ea.get 'user').toBe user.id
    expect(ea.get 'notified').toBeFalsy()
    expect(ea.get 'earnedPoints').toBe 2 * @repeatable.get('worth')
    expect(ea.get 'achievedAmount').toBe 2
    expect(ea.get 'previouslyAchievedAmount').toBeFalsy()
    
    # check 'diminishing' achievement
    docs = yield EarnedAchievement.find({achievementName: diminishing.name})
    expect(docs.length).toBe 1
    ea = docs[0]
    expect(ea.get 'achievedAmount').toBe 2
    expect(ea.get 'earnedPoints').toBe (Math.log(.5 * (2 + .5)) + 1) * diminishing.worth

    user.set('simulatedBy', 4)
    expect(user.get('earned').gems).toBe(2)
    yield user.save()
    yield new Promise((resolve) -> setTimeout(resolve, 100))
    user = yield User.findById(user._id)
    expect(user.get('earned').gems).toBe(4)
    done()


describe 'POST /admin/earned_achievement/recalculate', ->
  beforeEach addAllAchievements

  it 'cannot be accessed by regular users', utils.wrap (done) ->
    user = yield utils.initUser({anonymous: false})
    yield utils.loginUser(user)
    [res, body] = yield request.postAsync {uri:getURL '/admin/earned_achievement/recalculate'}
    expect(res.statusCode).toBe 403
    done()

  it 'recalculates for a single achievement idempotently', utils.wrap (done) ->
    session = new LevelSession({
      permissions: simplePermissions
      creator: @admin._id
      level: original: 'dungeon-arena'
    })
    yield session.save()
    earnedAchievements = yield EarnedAchievement.find()
    expect(earnedAchievements.length).toBe(0)
    
    [res, body] = yield request.postAsync {
      uri:getURL '/admin/earned_achievement/recalculate'
      json: { achievements: ['dungeon-arena-started'] }
    }
    expect(res.statusCode).toBe 202
    yield new Promise((resolve) -> setTimeout(resolve, 100))
    earnedAchievements = yield EarnedAchievement.find()
    expect(earnedAchievements.length).toBe(1)
    [res, body] = yield request.postAsync {
      uri:getURL '/admin/earned_achievement/recalculate'
      json: { achievements: ['dungeon-arena-started'] }
    }
    expect(res.statusCode).toBe 202
    yield new Promise((resolve) -> setTimeout(resolve, 100))
    earnedAchievements = yield EarnedAchievement.find()
    expect(earnedAchievements.length).toBe(1)
    
    user = yield User.findById(@admin.id)
    expect(user.get 'points').toBe unlockable.worth
    done()

  it 'can recalculate all achievements', utils.wrap (done) ->
    # satisfy achievement requirements
    session = new LevelSession({
      permissions: simplePermissions
      creator: @admin._id
      level: original: 'dungeon-arena'
    })
    yield session.save()
    @admin.set('simulatedBy', 4)
    yield @admin.save()
    yield new Promise((resolve) -> setTimeout(resolve, 100)) # give server time to apply achievement
    
    # remove all evidence
    yield utils.clearModels([EarnedAchievement])
    yield User.update {}, {$set: {points: 0}}, {multi:true}
      
    # recalculate
    [res, body] = yield request.postAsync { uri:getURL '/admin/earned_achievement/recalculate' }
    expect(res.statusCode).toBe 202
    yield new Promise((resolve) -> setTimeout(resolve, 500))

    earnedAchievements = yield EarnedAchievement.find({})
    expect(earnedAchievements.length).toBe 3
    user = yield User.findById(@admin.id)
    expect(user.get 'points').toBe unlockable.worth + 4 * repeatable.worth + (Math.log(.5 * (4 + .5)) + 1) * diminishing.worth
    expect(user.get('earned').gems).toBe 4 * repeatable.rewards.gems
    done()

  afterEach utils.wrap (done) ->
    # cleaning up test: deleting all Achievements and related
    yield utils.clearModels [Achievement, EarnedAchievement, LevelSession]
    Achievement.resetAchievements()
    loadedAchievements = Achievement.getLoadedAchievements()
    expect(Object.keys(loadedAchievements).length).toBe(0)
    done()
