require '../common'

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


describe 'GET /db/campaign', ->

  beforeEach utils.wrap (done) ->
    yield utils.clearModels([Campaign])
    @heroCampaign1 = yield new Campaign({name: 'Hero Campaign 1', type: 'hero'}).save()
    @heroCampaign2 = yield new Campaign({name: 'Hero Campaign 2', type: 'hero'}).save()
    @courseCampaign1 = yield new Campaign({name: 'Course Campaign 1', type: 'course'}).save()
    @courseCampaign2 = yield new Campaign({name: 'Course Campaign 2', type: 'course'}).save()
    done()

  it 'returns all campaigns', utils.wrap (done) ->
    [res, body] =  yield request.getAsync getURL('/db/campaign'), { json: true }
    expect(res.statusCode).toBe(200)
    expect(body.length).toBe(4)
    done()
    
  describe 'with GET query param type', ->
    it 'returns campaigns of that type', utils.wrap (done) ->
      [res, body] =  yield request.getAsync getURL('/db/campaign?type=course'), { json: true }
      expect(res.statusCode).toBe(200)
      expect(body.length).toBe(2)
      for campaign in body
        expect(campaign.type).toBe('course')
      done()


describe 'POST /db/campaign', ->
  beforeEach utils.wrap (done) ->
    yield utils.clearModels [Campaign, Level, User]
    admin = yield utils.initAdmin()
    yield utils.loginUser(admin)
    @levels = (level.toObject() for level in [yield utils.makeLevel(), yield utils.makeLevel()])
    done()

  it 'can create campaigns', utils.wrap (done) ->
    campaign = {
      levels: {}
    }
    for level in @levels.reverse()
      campaign.levels[level.original.valueOf()] = _.pick level, campaignLevelProperties
    [res, body] = yield request.postAsync {uri: campaignURL, json: campaign}
    expect(res.statusCode).toBe(201)
    campaign = body
    done()

describe 'PUT /db/campaign/:handle', ->
  beforeEach utils.wrap (done) ->
    yield utils.clearModels [Achievement, Campaign, Level, User]
    admin = yield utils.initAdmin()
    yield utils.loginUser(admin)
    @campaign = yield utils.makeCampaign()
    @levelsUpdated = @campaign.get('levelsUpdated').toISOString()
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
    yield utils.logout()
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
    
    
describe 'GET, POST /db/campaign/names', ->
  beforeEach utils.wrap (done) ->
    yield utils.clearModels [Achievement, Campaign, Level, User]
    admin = yield utils.initAdmin()
    yield utils.loginUser(admin)
    @campaignA = yield utils.makeCampaign()
    @campaignB = yield utils.makeCampaign()
    done()
    
  it 'returns names of campaigns by for given ids', utils.wrap (done) ->
    [res, body] = yield request.getAsync({url: getURL("/db/campaign/names?ids=#{@campaignA.id},#{@campaignB.id}"), json: true})
    expect(res.statusCode).toBe(200)
    expect(body.length).toBe(2)
    [res, body] = yield request.postAsync({url: getURL('/db/campaign/names'), json: { ids: [@campaignA.id, @campaignB.id] }})
    expect(res.statusCode).toBe(200)
    expect(body.length).toBe(2)
    done()
    

describe 'GET /db/campaign/:handle/levels', ->
  beforeEach utils.wrap (done) ->
    yield utils.clearModels [Campaign, Level, User]
    admin = yield utils.initAdmin()
    yield utils.loginUser(admin)
    @level1 = yield utils.makeLevel()
    @level2 = yield utils.makeLevel()
    @campaign = yield utils.makeCampaign({}, {levels: [@level1, @level2]})
    done()
    
  it 'fetches the levels in a campaign', utils.wrap (done) ->
    url = getURL("/db/campaign/#{@campaign._id}/levels")
    [res, body] = yield request.getAsync {uri: url, json: true}
    expect(res.statusCode).toBe(200)
    expect(body.length).toBe(2)
    expect(_.difference([@level1.get('slug'), @level2.get('slug')], _.pluck(body, 'slug')).length).toBe(0)
    done()

describe 'GET /db/campaign/:handle/achievements', ->
  beforeEach utils.wrap (done) ->
    yield utils.clearModels [Achievement, Campaign, Level, User]
    admin = yield utils.initAdmin()
    yield utils.loginUser(admin)
    level = yield utils.makeLevel()
    @achievement = yield utils.makeAchievement({}, {related: level})
    @campaign = yield utils.makeCampaign({}, {levels: [level]})
    done()
  
  it 'fetches the achievements in the levels in a campaign', utils.wrap (done) ->
    url = getURL("/db/campaign/#{@campaign.id}/achievements")
    [res, body] = yield request.getAsync {uri: url, json: true}
    expect(res.statusCode).toBe(200)
    expect(body.length).toBe(1)
    done()

describe 'GET /db/campaign/-/overworld', ->
  beforeEach utils.wrap (done) ->
    yield utils.clearModels [Campaign, Level, User]
    admin = yield utils.initAdmin()
    yield utils.loginUser(admin)
    level = yield utils.makeLevel()
    @campaignA = yield utils.makeCampaign({type: 'hero', hidesHUD: true})
    @campaignB = yield utils.makeCampaign({type: 'hero'}, {
      levels: [level]
      adjacentCampaigns: [@campaignA]
    })
    @campaignC = yield utils.makeCampaign({type: 'course'})
    done()

  it 'fetches campaigns of type "hero", returning projected level and adjacentCampaign children', utils.wrap (done) ->
    url = getURL("/db/campaign/-/overworld")
    [res, body] = yield request.getAsync {uri: url, json: true}
    expect(res.statusCode).toBe(200)
    expect(body.length).toBe(2)
    for campaign in body
      expect(campaign.type).toBe('hero')
      
    campaign = _.findWhere(body, {_id: @campaignB.id})
    expect(_.size(campaign.levels)).toBeGreaterThan(0)
    for level in _.values(campaign.levels)
      expect(level.slug).toBeDefined()
    expect(_.size(campaign.adjacentCampaigns)).toBeGreaterThan(0)
    for campaign in _.values(campaign.adjacentCampaigns)
      expect(campaign.name).toBeDefined()
    done()

  it 'takes a project query param', utils.wrap (done) ->
    url = getURL("/db/campaign/-/overworld?project=name")
    [res, body] = yield request.getAsync {uri: url, json: true}
    expect(res.statusCode).toBe(200)
    expect(body.length).toBe(2)
    for campaign in body
      expect(campaign.type).toBeUndefined()
      expect(campaign.name).toBeDefined()
    done()
