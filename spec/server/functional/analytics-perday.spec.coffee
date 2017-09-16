utils = require '../utils'
Promise = require 'bluebird'
AnalyticsString = require '../../../server/models/AnalyticsString'
AnalyticsPerDay = require '../../../server/models/AnalyticsPerDay'
slack = require '../../../server/slack'
request = require '../request'
mongoose = require 'mongoose'

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

  it 'returns all perday entries for active class events', utils.wrap ->
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
