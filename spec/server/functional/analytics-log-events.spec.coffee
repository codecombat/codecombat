utils = require '../utils'
Promise = require 'bluebird'
AnalyticsLogEvent = require '../../../server/models/AnalyticsLogEvent'
slack = require '../../../server/slack'
request = require '../request'
mongoose = require 'mongoose'

describe 'POST /db/analytics.log.event/-/log_event', ->
  it 'posts an event to the log db', utils.wrap ->
    user = yield utils.initUser()
    yield utils.loginUser(user)
    json = {
      event: 'Some Name'
      properties: {
        'some': 'property'
        number: 1234
      }
    }
    url = utils.getUrl('/db/analytics.log.event/-/log_event')
    [res] = yield request.postAsync({url, json})
    expect(res.statusCode).toBe(201)
    yield new Promise((resolve) -> setTimeout(resolve, 50)) # make sure event gets created
    events = yield AnalyticsLogEvent.find({user: user._id})
    expect(events.length).toBe(1)
    expect(events[0].event).toBe(json.event)
    expect(events[0].properties).toDeepEqual(json.properties)
    expect(events[0].user).toBe(user.id)

  it 'ignores invalid events', utils.wrap ->
    user = yield utils.initUser()
    yield utils.loginUser(user)
    json = {
      event: false
      properties: 1
    }
    url = utils.getUrl('/db/analytics.log.event/-/log_event')
    [res] = yield request.postAsync({url, json})
    expect(res.statusCode).toBe(422)
    yield new Promise((resolve) -> setTimeout(resolve, 50))
    events = yield AnalyticsLogEvent.find({user: user._id})
    expect(events.length).toBe(0)

  it 'sends a slack message if the event fails to save', utils.wrap ->
    AnalyticsLogEvent.errorOnSave = true
    spyOn(slack, 'sendSlackMessage')
    user = yield utils.initUser()
    yield utils.loginUser(user)
    json = {
      event: 'Some Name'
      properties: {
        'some': 'property'
        number: 1234
      }
    }
    url = utils.getUrl('/db/analytics.log.event/-/log_event')
    [res] = yield request.postAsync({url, json})
    expect(res.statusCode).toBe(201)
    yield new Promise((resolve) -> setTimeout(resolve, 50)) # make sure event gets created
    events = yield AnalyticsLogEvent.find({user: user._id})
    expect(events.length).toBe(0)
    expect(slack.sendSlackMessage).toHaveBeenCalled()
    AnalyticsLogEvent.errorOnSave = false
