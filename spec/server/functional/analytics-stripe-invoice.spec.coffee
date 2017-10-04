utils = require '../utils'
Promise = require 'bluebird'
AnalyticsStripeInvoice = require '../../../server/models/AnalyticsStripeInvoice'
request = require '../request'
mongoose = require 'mongoose'
middleware = require '../../../server/middleware'

describe 'GET /db/analytics.stripe.invoice/-/all', ->
  it 'returns 403 unless you are an admin', utils.wrap ->
    user = yield utils.initUser()
    yield utils.loginUser(user)
    url = utils.getUrl('/db/analytics.stripe.invoice/-/all')
    [res] = yield request.getAsync({url, json: true})
    expect(res.statusCode).toBe(403)

  it 'returns all analytics stripe invoice documents', utils.wrap ->
    doc = new AnalyticsStripeInvoice({
      _id: '0'
      date: 1,
      properties: {
        anything: 'goes!'
      }
    })
    yield doc.save()

    admin = yield utils.initAdmin()
    yield utils.loginUser(admin)
    url = utils.getUrl('/db/analytics.stripe.invoice/-/all')
    [res] = yield request.getAsync({url, json: true})
    expect(res.body.length).toBe(1)
    expect(res.statusCode).toBe(200)
    expect(res.body[0]._id).toBe('0')
