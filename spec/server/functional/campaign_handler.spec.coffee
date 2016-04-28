require '../common'

levels = [
  {
    name: 'Level 1'
    description: 'This is the first level.'
    disableSpaces: true
    icon: 'somestringyoudontneed.png'
  }
  {
    name: 'Level 2'
    description: 'This is the second level.'
    requiresSubscription: true
    backspaceThrottle: true
  }
]

achievement = {
  name: 'Level 1 Complete'
}

campaign = {
  name: 'Campaign'
  levels: {}
  i18n: {}
}

levelURL = getURL('/db/level')
achievementURL = getURL('/db/achievement')
campaignURL = getURL('/db/campaign')
campaignSchema = require '../../../app/schemas/models/campaign.schema'
campaignLevelProperties = _.keys(campaignSchema.properties.levels.additionalProperties.properties)
Achievement = require '../../../server/models/Achievement'
Campaign = require '../../../server/models/Campaign'
Level = require '../../../server/models/Level'
User = require '../../../server/models/User'
request = require '../request'
utils = require '../utils'
slack = require '../../../server/slack'
Promise = require 'bluebird'

describe 'PUT /db/campaign', ->
  beforeEach utils.wrap (done) ->
    yield utils.clearModels [Achievement, Campaign, Level, User]
    admin = yield utils.initAdmin()
    yield utils.loginUser(admin)
    [res, body] = yield request.postAsync { uri: campaignURL, json: campaign }
    @levelsUpdated = body.levelsUpdated
    @campaign = yield Campaign.findById(body._id)
    done()
  
  it 'saves changes to campaigns', utils.wrap (done) ->
    [res, body] = yield request.putAsync { uri: campaignURL+'/'+@campaign.id, json: { name: 'A new name' } }
    expect(body.name).toBe('A new name')
    c = yield Campaign.findById(body._id)
    expect(c.get('name')).toBe('A new name')
    done()
    
  it 'does not allow normal users to make changes', utils.wrap (done) ->
    user = yield utils.initUser()
    yield utils.loginUser(user)
    [res, body] = yield request.putAsync { uri: campaignURL+'/'+@campaign.id, json: { name: 'A new name' } }
    expect(res.statusCode).toBe(403)
    done()
    
  it 'allows normal users to put translation changes', utils.wrap (done) ->
    user = yield utils.initUser()
    yield utils.loginUser(user)
    json = _.clone @campaign.toObject()
    json.i18n = { de: { name: 'A new name' } }
    [res, body] = yield request.putAsync { uri: campaignURL+'/'+@campaign.id, json: json }
    expect(res.statusCode).toBe(200)
    done()
    
  it 'sends a slack message', utils.wrap (done) ->
    spyOn(slack, 'sendSlackMessage')
    [res, body] = yield request.putAsync { uri: campaignURL+'/'+@campaign.id, json: { name: 'A new name' } }
    expect(slack.sendSlackMessage).toHaveBeenCalled()
    done()
    
  it 'sets campaign.levelsUpdated to now iff levels are changed', utils.wrap (done) ->
    data = {name: 'whatever'}
    [res, body] = yield request.putAsync { uri: campaignURL+'/'+@campaign.id, json: data }
    expect(body.levelsUpdated).toBe(@levelsUpdated)
    yield new Promise((resolve) -> setTimeout(resolve, 10))
    data = {levels: {'a': {original: 'a'}}}
    [res, body] = yield request.putAsync { uri: campaignURL+'/'+@campaign.id, json: data }
    expect(body.levelsUpdated).not.toBe(@levelsUpdated)
    done()

describe '/db/campaign', ->
  it 'prepares the db first', (done) ->
    clearModels [Achievement, Campaign, Level, User], (err) ->
      expect(err).toBeNull()
      loginAdmin (admin) ->
        levels[0].permissions = levels[1].permissions = [{target: admin._id, access: 'owner'}]
        request.post {uri: levelURL, json: levels[0]}, (err, res, body) ->
          expect(res.statusCode).toBe(200)
          levels[0] = body
          request.post {uri: levelURL, json: levels[1]}, (err, res, body) ->
            expect(res.statusCode).toBe(200)
            levels[1] = body
            achievement.related = levels[0].original
            achievement.rewards = { levels: [levels[1].original] }
            request.post {uri: achievementURL, json: achievement}, (err, res, body) ->
              achievement = body
              done()

  it 'can create campaigns', (done) ->
    for level in levels.reverse()
      campaign.levels[level.original] = _.pick level, campaignLevelProperties
    request.post {uri: campaignURL, json: campaign}, (err, res, body) ->
      expect(res.statusCode).toBe(200)
      campaign = body
      done()

describe '/db/campaign/.../levels', ->
  it 'fetches the levels in a campaign', (done) ->
    url = getURL("/db/campaign/#{campaign._id}/levels")
    request.get {uri: url}, (err, res, body) ->
      expect(res.statusCode).toBe(200)
      body = JSON.parse(body)
      expect(body.length).toBe(2)
      expect(_.difference(['level-1', 'level-2'],(level.slug for level in body)).length).toBe(0)
      done()

describe '/db/campaign/.../achievements', ->
  it 'fetches the achievements in the levels in a campaign', (done) ->
    url = getURL("/db/campaign/#{campaign._id}/achievements")
    request.get {uri: url}, (err, res, body) ->
      expect(res.statusCode).toBe(200)
      body = JSON.parse(body)
      expect(body.length).toBe(1)
      done()
