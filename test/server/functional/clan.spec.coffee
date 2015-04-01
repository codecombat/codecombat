config = require '../../../server_config'
require '../common'
utils = require '../../../app/core/utils' # Must come after require /common
mongoose = require 'mongoose'

describe 'Clans', ->
  stripe = require('stripe')(config.stripe.secretKey)
  clanURL = getURL('/db/clan')

  createClan = (type, name, done) ->
    requestBody =
      type: type
      name: name
    request.post {uri: clanURL, json: requestBody }, (err, res, body) ->
      expect(err).toBeNull()
      expect(res.statusCode).toBe(200)
      expect(body.type).toEqual(type)
      expect(body.name).toEqual(name)
      Clan.findById body._id, (err, clan) ->
        expect(clan.get('type')).toEqual(type)
        expect(clan.get('name')).toEqual(name)
        done(clan)

  it 'Clear database users and clans', (done) ->
    clearModels [User, Clan], (err) ->
      throw err if err
      done()

  it 'Create clan', (done) ->
    loginNewUser (user1) ->
      createClan 'public', 'myclan1', (clan) ->
        done()

  it 'Anonymous create clan 401', (done) ->
    logoutUser ->
      requestBody =
        type: 'public'
        name: 'myclan1'
      request.post {uri: clanURL, json: requestBody }, (err, res, body) ->
        expect(err).toBeNull()
        expect(res.statusCode).toBe(401)
        done()

  it 'Create clan missing type 422', (done) ->
    loginNewUser (user1) ->
      requestBody =
        name: 'myclan1'
      request.post {uri: clanURL, json: requestBody }, (err, res, body) ->
        expect(err).toBeNull()
        expect(res.statusCode).toBe(422)
        done()

  it 'Create clan missing name 422', (done) ->
    loginNewUser (user1) ->
      requestBody =
        type: 'public'
      request.post {uri: clanURL, json: requestBody }, (err, res, body) ->
        expect(err).toBeNull()
        expect(res.statusCode).toBe(422)
        done()

  it 'Get clans', (done) ->
    loginNewUser (user1) ->
      createClan 'public', 'myclan2', ->
        createClan 'public', 'myclan3', ->
          request.get {uri: clanURL }, (err, res, body) ->
            expect(err).toBeNull()
            expect(res.statusCode).toBe(200)
            expect(body.length).toBeGreaterThan(1)
            done()

  it 'Get clans anonymous', (done) ->
    loginNewUser (user1) ->
      createClan 'public', 'myclan4', ->
        createClan 'public', 'myclan5', ->
          logoutUser ->
            request.get {uri: clanURL }, (err, res, body) ->
              expect(err).toBeNull()
              expect(res.statusCode).toBe(200)
              expect(body.length).toBeGreaterThan(1)
              done()
