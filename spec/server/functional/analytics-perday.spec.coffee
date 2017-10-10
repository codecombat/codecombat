utils = require '../utils'
Promise = require 'bluebird'
AnalyticsString = require '../../../server/models/AnalyticsString'
AnalyticsPerDay = require '../../../server/models/AnalyticsPerDay'
Campaign = require '../../../server/models/Campaign'
slack = require '../../../server/slack'
request = require '../request'
mongoose = require 'mongoose'
middleware = require '../../../server/middleware'

describe 'POST /db/analytics_perday/-/active_classes', ->
  it 'returns 403 unless you are an admin', utils.wrap ->
    user = yield utils.initUser()
    yield utils.loginUser(user)
    url = utils.getUrl('/db/analytics_perday/-/active_classes')
    [res] = yield request.postAsync({url, json: true})
    expect(res.statusCode).toBe(403)
  
  it 'returns all perday entries for active class events', utils.wrap ->
    paidString = yield utils.makeAnalyticsString({v:'Active classes paid'})
    trialString = yield utils.makeAnalyticsString({v:'Active classes trial'})
    freeString = yield utils.makeAnalyticsString({v:'Active classes free'})
    
    yield utils.makeAnalyticsPerDay({d:'20150101', c: 100}, {e: paidString})
    yield utils.makeAnalyticsPerDay({d:'20150101', c: 101}, {e: trialString})
    yield utils.makeAnalyticsPerDay({d:'20150101', c: 102}, {e: freeString})
    
    admin = yield utils.initAdmin()
    yield utils.loginUser(admin)
    url = utils.getUrl('/db/analytics_perday/-/active_classes')
    [res] = yield request.postAsync({url, json: true})
    expect(res.body).toEqual([{
      day: '20150101',
      classes: { 
        'Active classes paid': 100,
        'Active classes trial': 101,
        'Active classes free': 102 
      }
    }])


describe 'POST /db/analytics_perday/-/active_users', ->
  it 'returns 403 unless you are an admin', utils.wrap ->
    user = yield utils.initUser()
    yield utils.loginUser(user)
    url = utils.getUrl('/db/analytics_perday/-/active_users')
    [res] = yield request.postAsync({url, json: true})
    expect(res.statusCode).toBe(403)

  it 'returns all perday entries for active user events', utils.wrap ->
    paidString = yield utils.makeAnalyticsString({v:'Active classes paid'})
    trialString = yield utils.makeAnalyticsString({v:'Active classes trial'})
    freeString = yield utils.makeAnalyticsString({v:'Active classes free'})

    i = 100
    for event in ['DAU classroom paid', 'DAU classroom trial', 'DAU classroom free', 'DAU campaign paid', 'DAU campaign free',
                  'MAU classroom paid', 'MAU classroom trial', 'MAU classroom free', 'MAU campaign paid', 'MAU campaign free']
      analyticsString = yield utils.makeAnalyticsString({v:event})
      yield utils.makeAnalyticsPerDay({d:'20150101', c: i++}, {e: analyticsString})

    admin = yield utils.initAdmin()
    yield utils.loginUser(admin)
    url = utils.getUrl('/db/analytics_perday/-/active_users')
    [res] = yield request.postAsync({url, json: true})
    expect(res.body).toEqual([
      {
        day: '20150101',
        events: { 
          'DAU classroom paid': 100,
          'DAU classroom trial': 101,
          'DAU classroom free': 102,
          'DAU campaign paid': 103,
          'DAU campaign free': 104,
          'MAU classroom paid': 105,
          'MAU classroom trial': 106,
          'MAU classroom free': 107,
          'MAU campaign paid': 108,
          'MAU campaign free': 109 
        }
      }
    ])


describe 'POST /db/analytics_perday/-/campaign_completions', ->
  
  beforeEach utils.wrap ->
    admin = yield utils.initAdmin()
    yield utils.loginUser(admin)

    @level = yield utils.makeLevel()
    @campaign = yield utils.makeCampaign({}, {levels:[@level]})
    levelString = yield utils.makeAnalyticsString({v:@level.get('slug')})
    startedString = yield utils.makeAnalyticsString({v:'Started Level'})
    sawString = yield utils.makeAnalyticsString({v:'Saw Victory'})
    allString = yield utils.makeAnalyticsString({v:'all'})
    i = 100
    yield utils.makeAnalyticsPerDay({d: '20150101', c: i++}, {e: startedString, f: allString, l:levelString})
    yield utils.makeAnalyticsPerDay({d: '20150101', c: i++}, {e: sawString, f: allString, l:levelString})

    @url = utils.getUrl('/db/analytics_perday/-/campaign_completions')
    @json = { slug: @campaign.get('slug') }


  it 'returns 403 unless you are an admin', utils.wrap ->
    user = yield utils.initUser()
    yield utils.loginUser(user)
    [res] = yield request.postAsync({@url, @json})
    expect(res.statusCode).toBe(403)

  it 'returns start and finish data for levels in a given campaign, and saves a cache', utils.wrap ->
    spyOn(Campaign, 'find').and.callThrough()
    expect(middleware.analyticsPerDay.campaignCompletionsCache).toBeUndefined()
    [res] = yield request.postAsync({@url, @json})
    expect(res.body).toEqual([
      {
        "level": @level.get('slug'),
        "days": {
          "20150101": {
            "started": 100,
            "finished": 101
          }
        }
      }
    ])
    expect(middleware.analyticsPerDay.campaignCompletionsCache).toBeDefined()
    expect(Campaign.find.calls.count()).toBe(1)
    [res] = yield request.postAsync({@url, @json})
    expect(res.statusCode).toBe(200)
    expect(Campaign.find.calls.count()).toBe(1)
    
  it 'accepts start and date inputs', utils.wrap ->
    json = { 
      slug: @campaign.get('slug')
      startDay: '20140101'
      endDay: '20160101'
    }
    [res] = yield request.postAsync({@url, json})
    expect(res.body.length).toBe(1)

    json = {
      slug: @campaign.get('slug')
      startDay: '20160101'
      endDay: '20180101'
    }
    [res] = yield request.postAsync({@url, json})
    expect(res.body.length).toBe(0)


describe 'POST /db/analytics_perday/-/level_completions', ->
  beforeEach utils.wrap ->
    admin = yield utils.initAdmin()
    yield utils.loginUser(admin)

    @level = yield utils.makeLevel()
    levelString = yield utils.makeAnalyticsString({v:@level.get('slug')})
    startedString = yield utils.makeAnalyticsString({v:'Started Level'})
    sawString = yield utils.makeAnalyticsString({v:'Saw Victory'})
    allString = yield utils.makeAnalyticsString({v:'all'})
    i = 100
    yield utils.makeAnalyticsPerDay({d: '20150101', c: i++}, {e: startedString, f: allString, l:levelString})
    yield utils.makeAnalyticsPerDay({d: '20150101', c: i++}, {e: sawString, f: allString, l:levelString})

    @url = utils.getUrl('/db/analytics_perday/-/level_completions')
    @json = { slug: @level.get('slug') }


  it 'returns 403 unless you are an admin', utils.wrap ->
    user = yield utils.initUser()
    yield utils.loginUser(user)
    [res] = yield request.postAsync({@url, @json})
    expect(res.statusCode).toBe(403)

  it 'returns start and finish data for levels in a given level, and saves a cache', utils.wrap ->
    spyOn(AnalyticsPerDay, 'find').and.callThrough()
    expect(middleware.analyticsPerDay.levelCompletionsCache).toBeUndefined()
    [res] = yield request.postAsync({@url, @json})
    expect(res.body).toEqual([ { created: '20150101', started: 100, finished: 101 } ])
    expect(middleware.analyticsPerDay.levelCompletionsCache).toBeDefined()
    expect(AnalyticsPerDay.find.calls.count()).toBe(1)
    [res] = yield request.postAsync({@url, @json})
    expect(res.statusCode).toBe(200)
    expect(AnalyticsPerDay.find.calls.count()).toBe(1)

  it 'accepts start and date inputs', utils.wrap ->
    json = {
      slug: @level.get('slug')
      startDay: '20140101'
      endDay: '20160101'
    }
    [res] = yield request.postAsync({@url, json})
    expect(res.body.length).toBe(1)

    json = {
      slug: @level.get('slug')
      startDay: '20160101'
      endDay: '20180101'
    }
    [res] = yield request.postAsync({@url, json})
    expect(res.body.length).toBe(0)



describe 'POST /db/analytics_perday/-/level_drops', ->
  beforeEach utils.wrap ->
    admin = yield utils.initAdmin()
    yield utils.loginUser(admin)

    @level = yield utils.makeLevel()
    levelString = yield utils.makeAnalyticsString({v:@level.get('slug')})
    userDroppedString = yield utils.makeAnalyticsString({v:'User Dropped'})
    allString = yield utils.makeAnalyticsString({v:'all'})
    i = 100
    yield utils.makeAnalyticsPerDay({d: '20150101', c: i++}, {e: userDroppedString, f: allString, l:levelString})

    @url = utils.getUrl('/db/analytics_perday/-/level_drops')
    @json = { slugs: [@level.get('slug')] }


  it 'returns 403 unless you are an admin', utils.wrap ->
    user = yield utils.initUser()
    yield utils.loginUser(user)
    [res] = yield request.postAsync({@url, @json})
    expect(res.statusCode).toBe(403)

  it 'returns user dropped info for given levels, and saves a cache', utils.wrap ->
    spyOn(AnalyticsPerDay, 'find').and.callThrough()
    expect(middleware.analyticsPerDay.levelDropsCache).toBeUndefined()
    [res] = yield request.postAsync({@url, @json})
    expect(res.body).toEqual([ { level: @level.get('slug'), dropped: 100 } ])
    expect(middleware.analyticsPerDay.levelDropsCache).toBeDefined()
    expect(AnalyticsPerDay.find.calls.count()).toBe(1)
    [res] = yield request.postAsync({@url, @json})
    expect(res.statusCode).toBe(200)
    expect(AnalyticsPerDay.find.calls.count()).toBe(1)

  it 'accepts start and date inputs', utils.wrap ->
    json = {
      slugs: [@level.get('slug')]
      startDay: '20140101'
      endDay: '20160101'
    }
    [res] = yield request.postAsync({@url, json})
    expect(res.body.length).toBe(1)

    json = {
      slugs: [@level.get('slug')]
      startDay: '20160101'
      endDay: '20180101'
    }
    [res] = yield request.postAsync({@url, json})
    expect(res.body.length).toBe(0)


describe 'POST /db/analytics_perday/-/level_helps', ->
  beforeEach utils.wrap ->
    admin = yield utils.initAdmin()
    yield utils.loginUser(admin)

    @level = yield utils.makeLevel()
    levelString = yield utils.makeAnalyticsString({v:@level.get('slug')})
    alertString = yield utils.makeAnalyticsString({v: 'Problem alert help clicked'})
    paletteString = yield utils.makeAnalyticsString({v: 'Spell palette help clicked'})
    videoString = yield utils.makeAnalyticsString({v: 'Start help video'})
    
    allString = yield utils.makeAnalyticsString({v:'all'})
    i = 100
    yield utils.makeAnalyticsPerDay({d: '20150101', c: i++}, {e: alertString, f: allString, l:levelString})
    yield utils.makeAnalyticsPerDay({d: '20150101', c: i++}, {e: paletteString, f: allString, l:levelString})
    yield utils.makeAnalyticsPerDay({d: '20150101', c: i++}, {e: videoString, f: allString, l:levelString})

    @url = utils.getUrl('/db/analytics_perday/-/level_helps')
    @json = { slugs: [@level.get('slug')] }


  it 'returns 403 unless you are an admin', utils.wrap ->
    user = yield utils.initUser()
    yield utils.loginUser(user)
    [res] = yield request.postAsync({@url, @json})
    expect(res.statusCode).toBe(403)

  it 'returns info on alerts, spell palette clicks and help video starts for given levels, and saves a cache', utils.wrap ->
    spyOn(AnalyticsPerDay, 'find').and.callThrough()
    expect(middleware.analyticsPerDay.levelHelpsCache).toBeUndefined()
    [res] = yield request.postAsync({@url, @json})
    expect(res.body).toEqual([ {
      level: @level.get('slug')
      day: '20150101',
      alertHelps: 100,
      paletteHelps: 101,
      videoStarts: 102
    } ])
    expect(middleware.analyticsPerDay.levelHelpsCache).toBeDefined()
    expect(AnalyticsPerDay.find.calls.count()).toBe(1)
    [res] = yield request.postAsync({@url, @json})
    expect(res.statusCode).toBe(200)
    expect(AnalyticsPerDay.find.calls.count()).toBe(1)

  it 'accepts start and date inputs', utils.wrap ->
    json = {
      slugs: [@level.get('slug')]
      startDay: '20140101'
      endDay: '20160101'
    }
    [res] = yield request.postAsync({@url, json})
    expect(res.body.length).toBe(1)

    json = {
      slugs: [@level.get('slug')]
      startDay: '20160101'
      endDay: '20180101'
    }
    [res] = yield request.postAsync({@url, json})
    expect(res.body.length).toBe(0)

    
describe 'POST /db/analytics_perday/-/level_subscriptions', ->
  beforeEach utils.wrap ->
    admin = yield utils.initAdmin()
    yield utils.loginUser(admin)

    @level = yield utils.makeLevel()
    levelString = yield utils.makeAnalyticsString({v:@level.get('slug')})
    showString = yield utils.makeAnalyticsString({v: 'Show subscription modal'})
    purchasedString = yield utils.makeAnalyticsString({v: 'Finished subscription purchase'})

    allString = yield utils.makeAnalyticsString({v:'all'})
    i = 100
    yield utils.makeAnalyticsPerDay({d: '20150101', c: i++}, {e: showString, f: allString, l:levelString})
    yield utils.makeAnalyticsPerDay({d: '20150101', c: i++}, {e: purchasedString, f: allString, l:levelString})
    
    @url = utils.getUrl('/db/analytics_perday/-/level_subscriptions')
    @json = { slugs: [@level.get('slug')] }


  it 'returns 403 unless you are an admin', utils.wrap ->
    user = yield utils.initUser()
    yield utils.loginUser(user)
    [res] = yield request.postAsync({@url, @json})
    expect(res.statusCode).toBe(403)

  it 'returns start and finish data for subscriptions in given levels, and saves a cache', utils.wrap ->
    spyOn(AnalyticsPerDay, 'find').and.callThrough()
    expect(middleware.analyticsPerDay.levelSubscriptionsCache).toBeUndefined()
    [res] = yield request.postAsync({@url, @json})
    expect(res.body).toEqual([ { level: @level.get('slug'), shown: 100, purchased: 101 } ])
    expect(middleware.analyticsPerDay.levelSubscriptionsCache).toBeDefined()
    expect(AnalyticsPerDay.find.calls.count()).toBe(1)
    [res] = yield request.postAsync({@url, @json})
    expect(res.statusCode).toBe(200)
    expect(AnalyticsPerDay.find.calls.count()).toBe(1)

  it 'accepts start and date inputs', utils.wrap ->
    json = {
      slugs: [@level.get('slug')]
      startDay: '20140101'
      endDay: '20160101'
    }
    [res] = yield request.postAsync({@url, json})
    expect(res.body.length).toBe(1)

    json = {
      slugs: [@level.get('slug')]
      startDay: '20160101'
      endDay: '20180101'
    }
    [res] = yield request.postAsync({@url, json})
    expect(res.body.length).toBe(0)

    
describe 'POST /db/analytics_perday/-/recurring_revenue', ->
  it 'returns 403 unless you are an admin', utils.wrap ->
    user = yield utils.initUser()
    yield utils.loginUser(user)
    url = utils.getUrl('/db/analytics_perday/-/recurring_revenue')
    [res] = yield request.postAsync({url, json: true})
    expect(res.statusCode).toBe(403)

  it 'returns all perday entries for recurring revenue', utils.wrap ->
    gemsString = yield utils.makeAnalyticsString({v:'DRR gems'})
    schoolString = yield utils.makeAnalyticsString({v:'DRR school sales'})
    yearlyString = yield utils.makeAnalyticsString({v:'DRR yearly subs'})
    monthlyString = yield utils.makeAnalyticsString({v:'DRR monthly subs'})
    paypalString = yield utils.makeAnalyticsString({v:'DRR paypal'})

    i = 100
    yield utils.makeAnalyticsPerDay({d:'20150101', c: i++}, {e: gemsString })
    yield utils.makeAnalyticsPerDay({d:'20150101', c: i++}, {e: schoolString })
    yield utils.makeAnalyticsPerDay({d:'20150101', c: i++}, {e: yearlyString })
    yield utils.makeAnalyticsPerDay({d:'20150101', c: i++}, {e: monthlyString })
    yield utils.makeAnalyticsPerDay({d:'20150101', c: i++}, {e: paypalString })

    admin = yield utils.initAdmin()
    yield utils.loginUser(admin)
    url = utils.getUrl('/db/analytics_perday/-/recurring_revenue')
    [res] = yield request.postAsync({url, json: true})
    expect(res.body).toEqual([ { 
        day: '20150101',
        groups: {
          'DRR gems': 100,
          'DRR school sales': 101,
          'DRR yearly subs': 102,
          'DRR monthly subs': 103,
          'DRR paypal': 104
        }
      }
    ])
