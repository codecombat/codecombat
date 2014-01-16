require '../common'

describe '/db/campaign', ->
  request = require 'request'
  it 'clears the db first', (done) ->
    clearModels [User, Campaign], (err) ->
      throw err if err
      done()

  campaign = {name: 'A', description:'B'}
  url = getURL('/db/campaign')
  campaigns = {}

  it 'allows making Campaigns.', (done) ->
    loginJoe (user) ->
      campaign.permissions = [access: 'owner', target: user._id]
      request.post {uri:url, json:campaign}, (err, res, body) ->
        expect(res.statusCode).toBe(200)
        expect(body.permissions).toBeDefined()
        campaigns[0] = body
        done()
  
  it 'does not allow other users access', (done) ->
    loginSam ->
      request.get {uri:url+'/'+campaigns[0]._id}, (err, res, body) ->
        expect(res.statusCode).toBe(403)
        done()

  it 'allows editing permissions.', (done) ->
    loginJoe ->
      campaigns[0].permissions.push(access: 'read', target: 'public')
      request.put {uri:url, json:campaigns[0]}, (err, res, body) ->
        expect(res.statusCode).toBe(200)
        expect(body.permissions.length).toBe(2)
        campaigns[0] = body
        done()

  it 'allows anyone to access it through public permissions', (done) ->
    loginSam ->
      request.get {uri:url+'/'+campaigns[0]._id}, (err, res, body) ->
        expect(res.statusCode).toBe(200)
        done()
