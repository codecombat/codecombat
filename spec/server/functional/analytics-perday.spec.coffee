utils = require '../utils'
Promise = require 'bluebird'
AnalyticsString = require '../../../server/models/AnalyticsString'
AnalyticsPerDay = require '../../../server/models/AnalyticsPerDay'
slack = require '../../../server/slack'
request = require '../request'
mongoose = require 'mongoose'

describe 'GET /db/analytics_perday/-/active_classes', ->
  it 'returns 403 unless you are an admin', utils.wrap ->
    user = yield utils.initUser()
    yield utils.loginUser(user)
    url = utils.getUrl('/db/analytics_perday/-/active_classes')
    [res] = yield request.getAsync({url, json: true})
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
    [res] = yield request.getAsync({url, json: true})
    expect(res.body).toEqual([{
      day: '20150101',
      classes: { 
        'Active classes paid': 100,
        'Active classes trial': 101,
        'Active classes free': 102 
      }
    }])
    
    
