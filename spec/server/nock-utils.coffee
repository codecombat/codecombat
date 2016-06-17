nock = require('nock')
nockBack = nock.back
nockBack.fixtures = 'spec/fixtures/'
Promise = require 'bluebird'

module.exports.setupNock = (fixtureFilename, options, done) ->
  if _.isFunction(options)
    done = options
    options = {}
    
  keep = {
    has_more: true
    email: true
    subscription: true
    description: true
    current_period_end: true
    current_period_start: true
    cancel_at_period_end: true
    productID: true
    amount: true
    customer: true
    gems: true
    id: true
    product_id: true
    proration: true
    paid: true
    quantity: true
    timestamp: true
    total: true
    transaction_id: true
    type: true
    months: true
  }
    
  if options.keep
    _.extend(keep, options.keep)
     
  afterRecord = (scopes) ->
    scopes = _.filter scopes, (scope) -> not _.contains(scope.scope, '//localhost:')
    for scope in scopes
      delete scope['body']
      delete scope['headers']
      clean(scope.response)
    return scopes

  clean = (obj) ->
    for key, value of obj
      unless keep[key] or _.isArray(value) or _.isObject(value)
        delete obj[key]
      if _.isNull(value)
        delete obj[key]
      if _.isArray(value)
        for child in value
          clean(child)
        if _.isEmpty(value)
          delete obj[key]
      if _.isObject(value)
        clean(value)
        if _.isEmpty(value)
          delete obj[key]

  nockBack.setMode('record')
  nockBack fixtureFilename, {afterRecord: afterRecord, before: before}, (nockDone) ->
    nock.enableNetConnect('localhost')
    done(null, nockDone)
      
module.exports.teardownNock = ->
  nockBack.setMode('wild')
  nock.cleanAll()
  
# payment.spec.coffee needs this, because each test creates new Users with new _ids which
# are sent to Stripe as metadata. This messes up the tests which expect inputs to be
# uniform. This scope-preprocessor makes nock ignore body for matching requests.
# Ideally we would not do this; perhaps a better system would be to figure out a way
# to create users with consistent _id values.

before = (scope) ->
  scope.body = (body) -> true
  
Promise.promisifyAll(module.exports)
