require '../common'
utils = require '../utils'
Promise = require 'bluebird'
Achievement = require '../../../server/models/Achievement'
EarnedAchievement = require '../../../server/models/EarnedAchievement'
LevelSession = require '../../../server/models/LevelSession'
User = require '../../../server/models/User'
request = require '../request'
mongoose = require 'mongoose'
co = require 'co'

url = getURL('/db/achievement')


# Fixtures

lockedLevelID = new mongoose.Types.ObjectId().toString()
lockedLevelID2 = new mongoose.Types.ObjectId().toString()

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
    
  it 'touches "updated" if query, proportionalTo, worth, rewards or function change', utils.wrap (done) ->
    lastUpdated = @unlockable.get('updated')
    expect(lastUpdated).toBeDefined()
    [res, body] = yield request.putAsync {uri: url + '/'+@unlockable.id, json: {
      name: 'whatev'
      rewards: @unlockable.get('rewards')
      query: @unlockable.get('query')
      proportionalTo: @unlockable.get('proportionalTo')
    }}
    achievement = yield Achievement.findById(@unlockable.id)
    expect(achievement.get('updated')).toBeDefined()
    expect(achievement.get('updated')).toBe(lastUpdated) # unchanged

    newRewards = _.assign({}, @unlockable.get('rewards'), {gems: 1000})
    [res, body] = yield request.putAsync {uri: url + '/'+@unlockable.id, json: {rewards: newRewards}}
    expect(res.body.updated).not.toBe(lastUpdated)
    lastUpdated = res.body.updated
    
    newQuery = _.assign({}, @unlockable.get('query'), {'state.complete': true})
    [res, body] = yield request.putAsync {uri: url + '/'+@unlockable.id, json: {query: newQuery}}
    expect(res.body.updated).not.toBe(lastUpdated)
    lastUpdated = res.body.updated

    newProportionalTo = 'playtime'
    [res, body] = yield request.putAsync {uri: url + '/'+@unlockable.id, json: {proportionalTo: newProportionalTo}}
    expect(res.body.updated).not.toBe(lastUpdated)
    lastUpdated = res.body.updated

    newWorth = 1000
    [res, body] = yield request.putAsync {uri: url + '/'+@unlockable.id, json: {worth: newWorth}}
    expect(res.body.updated).not.toBe(lastUpdated)
    lastUpdated = res.body.updated
    
    newFunction = { kind: 'logarithmic', parameters: { a: 1, b: 2, c: 3 } }
    [res, body] = yield request.putAsync {uri: url + '/'+@unlockable.id, json: {function: newFunction}}
    expect(res.body.updated).not.toBe(lastUpdated)
    done()
    
    
describe 'GET /db/achievement', ->
  beforeEach addAllAchievements
  
  it 'returns all achievements', utils.wrap (done) ->
    user = yield utils.initUser()
    yield utils.loginUser(user)
    [res, body] = yield request.getAsync {uri: url, json: true}
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

  it 'returns the achievement', utils.wrap (done) ->
    user = yield utils.initUser()
    yield utils.loginUser(user)
    [res, body] = yield request.getAsync { uri: url+'/'+@unlockable.id, json: true }
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
    user = yield utils.becomeAnonymous()
    session = new LevelSession({
      permissions: simplePermissions
      creator: user._id
      level: original: 'dungeon-arena'
    })
    yield session.save()
    earnedAchievements = yield EarnedAchievement.find()
    expect(earnedAchievements.length).toBe(0)
    json = {achievement: @unlockable.id, triggeredBy: session._id, collection: 'level.sessions'}
    [res, body] = yield request.postAsync { url: eaURL, json }
    expect(res.statusCode).toBe(201)
    expect(body.achievement).toBe @unlockable.id
    expect(body.user).toBe user.id
    expect(body.notified).toBeFalsy()
    expect(body.earnedPoints).toBe @unlockable.get('worth')
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
    
  it 'updates the user\'s gems if the achievement gems changed', utils.wrap (done) ->
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

    # change the achievement
    yield @unlockable.update({ $set: { 'rewards.gems': 100 } })

    # hit the endpoint again, make sure gems were updated
    [res, body] = yield request.postAsync { url: eaURL, json }
    user = yield User.findById(user.id)
    expect(user.get('earned').gems).toBe(100)
    done()
    
  it 'handles if the achievement previously did not have any rewards', utils.wrap (done) ->
    # make unlockable have no rewards
    yield @unlockable.update({$unset: {rewards: ''}})
    
    user = yield utils.initUser()
    yield utils.loginUser(user)

    # get the User the unlockable achievement, check that they got NO reward
    session = new LevelSession({
      permissions: simplePermissions
      creator: user._id
      level: original: 'dungeon-arena'
    })
    yield session.save()
    json = {achievement: @unlockable.id, triggeredBy: session._id, collection: 'level.sessions'}
    [res, body] = yield request.postAsync { url: eaURL, json }
    user = yield User.findById(user.id)
    expect(user.get('earned.gems')).toBe(0)

    # change the achievement
    yield @unlockable.update({ $set: { 'rewards': {gems:100} } })

    # hit the endpoint again, make sure gems were added
    [res, body] = yield request.postAsync { url: eaURL, json }
    user = yield User.findById(user.id)
    expect(user.get('earned').gems).toBe(100)
    done()

describe 'automatically achieving achievements', ->
  beforeEach addAllAchievements

  xit 'happens when an object\'s properties meet achievement goals', utils.wrap (done) ->
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
    yield user.achievementsEarning
    
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

  xit 'recalculates for a single achievement idempotently', utils.wrap (done) ->
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
    expect(user.get 'points').toBe @unlockable.get('worth')
    done()

  it 'can recalculate all achievements idempotently', utils.wrap (done) ->
    # satisfy achievement requirements
    session = new LevelSession({
      permissions: simplePermissions
      creator: @admin._id
      level: original: 'dungeon-arena'
    })
    yield session.save()
    @admin.set('simulatedBy', 4)
    yield @admin.save()
    
    # remove all evidence
    yield utils.clearModels([EarnedAchievement])
    yield User.update {}, {$set: {points: 0}}, {multi:true}
      
    # recalculate
    [res, body] = yield request.postAsync { uri:getURL '/admin/earned_achievement/recalculate' }
    expect(res.statusCode).toBe 202

    earnedAchievements = yield EarnedAchievement.find({})
    expect(earnedAchievements.length).toBe 3
    user = yield User.findById(@admin.id)
    expect(user.get 'points').toBe @unlockable.get('worth') + 4 * @repeatable.get('worth') + (Math.log(.5 * (4 + .5)) + 1) * @diminishing.get('worth')
    expect(user.get('earned').gems).toBe 4 * @repeatable.get('rewards').gems

    [res, body] = yield request.postAsync { uri:getURL '/admin/earned_achievement/recalculate' }
    expect(res.statusCode).toBe 202
    
    earnedAchievements = yield EarnedAchievement.find({})
    expect(earnedAchievements.length).toBe 3
    user = yield User.findById(@admin.id)
    expect(user.get 'points').toBe @unlockable.get('worth') + 4 * @repeatable.get('worth') + (Math.log(.5 * (4 + .5)) + 1) * @diminishing.get('worth')
    expect(user.get('earned').gems).toBe 4 * @repeatable.get('rewards').gems

    done()
    
  it 'accepts a list of achievements to recalculate', utils.wrap ->
    # satisfy achievement requirements
    session = new LevelSession({
      permissions: simplePermissions
      creator: @admin._id
      level: original: 'dungeon-arena'
    })
    yield session.save()
    @admin.set('simulatedBy', 4)
    yield @admin.save()
    
    # remove all evidence
    yield utils.clearModels([EarnedAchievement])
    yield User.update {}, {$set: {points: 0}}, {multi:true}

    [res, body] = yield request.postAsync {
      url:getURL('/admin/earned_achievement/recalculate'),
      json: { achievements: [@repeatable.id]}
    }
    expect(res.statusCode).toBe 202
    earnedAchievements = yield EarnedAchievement.find({})
    expect(earnedAchievements.length).toBe 1
    user = yield User.findById(@admin.id)
    expect(user.get 'points').toBe 4 * @repeatable.get('worth')
    expect(user.get('earned').gems).toBe 4 * @repeatable.get('rewards').gems

    [res, body] = yield request.postAsync {
      uri:getURL('/admin/earned_achievement/recalculate'),
      json: { achievements: [@diminishing.id]}
    }
    expect(res.statusCode).toBe 202
    earnedAchievements = yield EarnedAchievement.find({})
    expect(earnedAchievements.length).toBe 2
    user = yield User.findById(@admin.id)
    expect(user.get 'points').toBe 4 * @repeatable.get('worth') + (Math.log(.5 * (4 + .5)) + 1) * @diminishing.get('worth')
    expect(user.get('earned').gems).toBe 4 * @repeatable.get('rewards').gems

    [res, body] = yield request.postAsync {
      uri:getURL('/admin/earned_achievement/recalculate'),
      json: { achievements: [@unlockable.id]}
    }
    expect(res.statusCode).toBe 202
    earnedAchievements = yield EarnedAchievement.find({})
    expect(earnedAchievements.length).toBe 3
    user = yield User.findById(@admin.id)
    expect(user.get 'points').toBe @unlockable.get('worth') + 4 * @repeatable.get('worth') + (Math.log(.5 * (4 + .5)) + 1) * @diminishing.get('worth')
    expect(user.get('earned').gems).toBe 4 * @repeatable.get('rewards').gems
    
    
  it 'handles achievement gem reward changes', utils.wrap ->
    @admin.set('simulatedBy', 4)
    yield @admin.save()
    
    # remove all evidence
    yield utils.clearModels([EarnedAchievement])
    yield User.update {}, {$set: {points: 0}}, {multi:true}

    [res, body] = yield request.postAsync {
      url:getURL('/admin/earned_achievement/recalculate'),
      json: { achievements: [@repeatable.id]}
    }
    expect(res.statusCode).toBe 202
    earnedAchievements = yield EarnedAchievement.find({})
    expect(earnedAchievements.length).toBe 1
    user = yield User.findById(@admin.id)
    expect(user.get 'points').toBe 4 * @repeatable.get('worth')
    expect(user.get('earned').gems).toBe 4 * @repeatable.get('rewards').gems

    @repeatable.set({worth: 2})
    yield @repeatable.save()
    [res, body] = yield request.postAsync {
      url:getURL('/admin/earned_achievement/recalculate'),
      json: { achievements: [@repeatable.id]}
    }
    expect(res.statusCode).toBe 202
    earnedAchievements = yield EarnedAchievement.find({})
    expect(earnedAchievements.length).toBe 1
    user = yield User.findById(@admin.id)
    expect(user.get 'points').toBe 4 * @repeatable.get('worth')
    expect(user.get('earned').gems).toBe 4 * @repeatable.get('rewards').gems

  it 'handles achievement earned level changes', utils.wrap ->
    session = new LevelSession({
      permissions: simplePermissions
      creator: @admin._id
      level: original: 'dungeon-arena'
    })
    yield session.save()
    
    [res, body] = yield request.postAsync {
      uri:getURL('/admin/earned_achievement/recalculate'),
      json: { achievements: [@unlockable.id]}
    }
    expect(res.statusCode).toBe 202
    earnedAchievements = yield EarnedAchievement.find({})
    expect(earnedAchievements.length).toBe 1
    user = yield User.findById(@admin.id)
    expect(user.get 'points').toBe @unlockable.get('worth')
    expect(user.get('earned.levels').length).toBe(1)
    expect(user.get('earned.levels')[0]).toBe(lockedLevelID.toString())
    
    @unlockable.set({
      rewards: {
        levels: [lockedLevelID2]
      }
    })
    yield @unlockable.save()
    [res, body] = yield request.postAsync {
      uri:getURL('/admin/earned_achievement/recalculate'),
      json: { achievements: [@unlockable.id]}
    }
    expect(res.statusCode).toBe 202
    earnedAchievements = yield EarnedAchievement.find({})
    expect(earnedAchievements.length).toBe 1
    user = yield User.findById(@admin.id)
    expect(user.get 'points').toBe @unlockable.get('worth')
    expect(user.get('earned.levels').length).toBe(1)
    expect(user.get('earned.levels')[0]).toBe(lockedLevelID2.toString())
    

  afterEach utils.wrap (done) ->
    # cleaning up test: deleting all Achievements and related
    yield utils.clearModels [Achievement, EarnedAchievement, LevelSession]
    Achievement.resetAchievements()
    loadedAchievements = Achievement.getLoadedAchievements()
    expect(Object.keys(loadedAchievements).length).toBe(0)
    done()

    
describe 'GET /db/earned_achievements?view=get-by-achievement-ids', ->
  beforeEach addAllAchievements
  
  it 'gets earned achievements by the user for the given achievements', utils.wrap ->
    # satisfy achievement requirements
    session = new LevelSession({
      permissions: simplePermissions
      creator: @admin._id
      level: original: 'dungeon-arena'
    })
    yield session.save()
    @admin.set('simulatedBy', 4)
    yield @admin.save()

    # recalculate
    [res, body] = yield request.postAsync { uri:getURL '/admin/earned_achievement/recalculate' }
    expect(res.statusCode).toBe 202

    earnedAchievements = yield EarnedAchievement.find({})
    expect(earnedAchievements.length).toBe 3

    @url = utils.getUrl('/db/earned_achievement')
    qs = {
      view: 'get-by-achievement-ids',
      achievementIDs: [ @unlockable.id ].join(',')
    }
    [res, body] = yield request.getAsync({@url, qs, json: true})
    expect(res.statusCode).toBe(200)
    expect(res.body.length).toBe(1)
    expect(res.body[0].achievement).toBe(@unlockable.id)
    
    
describe 'GET /db/earned_achievements', ->
  
  beforeEach utils.wrap -> 
    yield utils.clearModels [Achievement, EarnedAchievement, LevelSession, User]
  
  beforeEach addAllAchievements
  beforeEach utils.wrap ->
    @user = yield utils.initUser()
    yield utils.loginUser(@user)

    session = new LevelSession({
      permissions: simplePermissions
      creator: @admin._id
      level: original: 'dungeon-arena'
    })
    yield session.save()
    @user.set('simulatedBy', 4)
    yield @user.save()

    # recalculate
    yield utils.loginUser(@admin)
    [res, body] = yield request.postAsync { uri:getURL '/admin/earned_achievement/recalculate' }
    expect(res.statusCode).toBe 202

    earnedAchievements = yield EarnedAchievement.find({})
    expect(earnedAchievements.length).toBe 3
    @url = utils.getUrl('/db/earned_achievement')

  it 'returns the logged in user\'s earned achievements', utils.wrap ->
    yield utils.loginUser(@user)
    [res] = yield request.getAsync({@url, json:true})
    expect(res.body.length).toBe(2)
    expect(_.find(res.body, {achievement: @repeatable.id})).toBeTruthy()
    expect(_.find(res.body, {achievement: @diminishing.id})).toBeTruthy()
    expect(_.find(res.body, {achievement: @unlockable.id})).toBeFalsy()

    yield utils.loginUser(@admin)
    [res] = yield request.getAsync({@url, json:true})
    expect(res.body.length).toBe(1)
    expect(_.find(res.body, {achievement: @repeatable.id})).toBeFalsy()
    expect(_.find(res.body, {achievement: @diminishing.id})).toBeFalsy()
    expect(_.find(res.body, {achievement: @unlockable.id})).toBeTruthy()
    
  it 'accepts project, skip and limit parameters', utils.wrap ->
    yield utils.loginUser(@user)
    [res] = yield request.getAsync({@url, json:true, qs: {limit: 1}})
    expect(res.body.length).toBe(1)
    firstEarnedAchievement = res.body[0]._id

    [res] = yield request.getAsync({@url, json:true, qs: {skip: 1}})
    expect(res.body.length).toBe(1)
    secondEarnedAchievement = res.body[0]._id
    expect(firstEarnedAchievement).not.toBe(secondEarnedAchievement)

    [res] = yield request.getAsync({@url, json:true, qs: {project: 'achievement'}})
    expect(res.body.length).toBe(2)
    keys = _.keys(res.body[0])
    expect(_.without(keys, '_id', 'achievement').length).toBe(0)
    expect(res.body[0].achievement).toBeDefined()

    
describe 'PUT /db/earned_achievement/:handle', ->
  beforeEach utils.wrap ->
    yield utils.clearModels [Achievement, EarnedAchievement, LevelSession, User]

  beforeEach addAllAchievements
  beforeEach utils.wrap ->
    @user = yield utils.initUser()
    yield utils.loginUser(@user)

    session = new LevelSession({
      permissions: simplePermissions
      creator: @admin._id
      level: original: 'dungeon-arena'
    })
    yield session.save()
    @user.set('simulatedBy', 4)
    yield @user.save()

    # recalculate
    yield utils.loginUser(@admin)
    [res, body] = yield request.postAsync { uri:getURL '/admin/earned_achievement/recalculate' }
    expect(res.statusCode).toBe 202

    @earnedAchievements = yield EarnedAchievement.find({})
    expect(@earnedAchievements.length).toBe 3

  it 'allows setting the "notified" properties by anyone', utils.wrap ->
    otherUser = yield utils.initUser()
    yield utils.loginUser(otherUser)
    expect(@earnedAchievements[0].notified).toBeFalsy()
    @url = utils.getUrl("/db/earned_achievement/#{@earnedAchievements[0].id}")
    [res] = yield request.putAsync({@url, json: {notified:true}})
    expect(res.statusCode).toBe(200)
    expect(res.body.notified).toBe(true)
    earnedAchievement = yield EarnedAchievement.findById(@earnedAchievements[0].id)
    expect(earnedAchievement.notified).toBe(true)
