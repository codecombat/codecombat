require '../common'
LevelSession = require '../../../server/models/LevelSession'
mongoose = require 'mongoose'
request = require '../request'

describe '/db/level.session', ->

  url = getURL('/db/level.session/')
  session =
    permissions: simplePermissions

  it 'get schema', (done) ->
    request.get {uri: url+'schema'}, (err, res, body) ->
      expect(res.statusCode).toBe(200)
      body = JSON.parse(body)
      expect(body.type).toBeDefined()
      done()

  it 'clears things first', (done) ->
    clearModels [LevelSession], (err) ->
      expect(err).toBeNull()
      done()

  # TODO Tried to mimic what happens on the site. Why is this even so hard to do.
  # Right now it's even possible to create ownerless sessions through POST
#  xit 'allows users to create level sessions through PATCH', (done) ->
#    loginJoe (joe) ->
#      request {method: 'patch', uri: url + mongoose.Types.ObjectId(), json: session}, (err, res, body) ->
#        expect(err).toBeNull()
#        expect(res.statusCode).toBe 200
#        console.log body
#        expect(body.creator).toEqual joe.get('_id').toHexString()
#        done()

  # Should remove this as soon as the PATCH test case above works
  it 'create a level session', (done) ->
    unittest.getNormalJoe (joe) ->
      session.creator = joe.get('_id').toHexString()
      session = new LevelSession session
      session.save (err) ->
        expect(err).toBeNull()
        done()

  it 'GET /db/user/<ID>/level.sessions gets a user\'s level sessions', (done) ->
    unittest.getNormalJoe (joe) ->
      request.get {uri: getURL "/db/user/#{joe.get '_id'}/level.sessions"}, (err, res, body) ->
        expect(err).toBeNull()
        expect(res.statusCode).toBe 200
        sessions = JSON.parse body
        expect(sessions.length).toBe 1
        done()

  it 'GET /db/user/<SLUG>/level.sessions gets a user\'s level sessions', (done) ->
    unittest.getNormalJoe (joe) ->
      request.get {uri: getURL "/db/user/#{joe.get 'slug'}/level.sessions"}, (err, res, body) ->
        expect(err).toBeNull()
        expect(res.statusCode).toBe 200
        sessions = JSON.parse body
        expect(sessions.length).toBe 1
        done()

  it 'GET /db/user/<IDorSLUG>/level.sessions returns 404 if user not found', (done) ->
    request.get {uri: getURL "/db/user/misterschtroumpf/level.sessions"}, (err, res) ->
      expect(err).toBeNull()
      expect(res.statusCode).toBe 404
      done()
