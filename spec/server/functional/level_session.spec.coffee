require '../common'
LevelSession = require '../../../server/models/LevelSession'
mongoose = require 'mongoose'
request = require '../request'
utils = require('../utils')

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

      
describe 'POST /db/level.session/:handle/submit-to-ladder AND POST /queue/scoring', ->
  url = utils.getUrl('/queue/scoring')

  it 'updates the session so that it appears in the main ladder and any league/classroom ladders', utils.wrap ->
    @player = yield utils.initUser()
    @level = yield utils.makeLevel({ type: 'hero-ladder' })
    @session = yield utils.makeLevelSession({code: '...'}, { @level, creator: @player })
    yield utils.loginUser(@player)
    json = { session: @session.id }
    [res] = yield request.postAsync(url, { json })
    expect(res.statusCode).toBe(200)
    @session = yield LevelSession.findById(@session.id)
    expected = {
      leagues: [],
      isRanking: true,
      numberOfLosses: 0,
      numberOfWinsAndTies: 0,
      submittedCodeLanguage: 'javascript',
      submittedCode: @session.get('code'),
      submitted: true
    }
    expect(_.pick(@session.toObject(), _.keys(expected))).toDeepEqual(expected)
    for key in ['randomSimulationIndex', 'standardDeviation', 'submitDate']
      expect(@session.get(key)).toBeTruthy()
    
  it 'returns 401 when you are anonymous', utils.wrap ->
    yield utils.logout()
    [res] = yield request.postAsync(url)
    expect(res.statusCode).toBe(401)
    yield utils.becomeAnonymous()
    [res] = yield request.postAsync(url)
    expect(res.statusCode).toBe(401)
    
  it 'returns 403 if you are not the creator of the session', utils.wrap ->
    @player = yield utils.initUser()
    @otherPlayer = yield utils.initUser()
    @level = yield utils.makeLevel({ type: 'hero-ladder' })
    @session = yield utils.makeLevelSession({}, { @level, creator: @player })
    yield utils.loginUser(@otherPlayer)
    json = { session: @session.id }
    [res] = yield request.postAsync(url, { json })
    expect(res.statusCode).toBe(403)

  it 'returns 404 if the level session is not found', utils.wrap ->
    @player = yield utils.initUser()
    @level = yield utils.makeLevel({ type: 'hero-ladder' })
    @session = yield utils.makeLevelSession({}, { @level, creator: @player })
    yield utils.loginUser(@player)
    json = { session: @level.id }
    [res] = yield request.postAsync(url, { json })
    expect(res.statusCode).toBe(404)
    
  it 'adds leagues from user clans and courseInstances', utils.wrap ->
    @player = yield utils.initUser({
      clans: [mongoose.Types.ObjectId()]
      courseInstances: [mongoose.Types.ObjectId()]
    })
    @level = yield utils.makeLevel({ type: 'hero-ladder' })
    @session = yield utils.makeLevelSession({}, { @level, creator: @player })
    yield utils.loginUser(@player)
    json = { session: @session.id }
    [res] = yield request.postAsync(url, { json })
    expect(res.statusCode).toBe(200)
    expect(res.body.leagues.length).toBe(2)
    expectedLeagueIds = [@player.get('clans')[0].toString(), @player.get('courseInstances')[0].toString()]
    f = (l) -> l.leagueID
    actualLeagueIds = _.map(res.body.leagues, f).sort()
    expect(expectedLeagueIds).toDeepEqual(actualLeagueIds)
    
  it 'includes courseInstances handed in manually', utils.wrap ->
    @teacher = yield utils.initUser({role: 'teacher'})
    @admin = yield utils.initAdmin()
    yield utils.loginUser(@admin)
    @course = yield utils.makeCourse({free: true, releasePhase: 'released'})
    yield utils.loginUser(@teacher)
    @player = yield utils.initUser({ role: 'student' })
    @members = [@player]
    @classroom = yield utils.makeClassroom({aceConfig: { language: 'javascript' }}, { @members })
    @courseInstance = yield utils.makeCourseInstance({}, { @course, @classroom, @members })
    @level = yield utils.makeLevel({ type: 'hero-ladder' })
    @session = yield utils.makeLevelSession({}, { @level, creator: @player })
    yield @player.update({$set: {courseInstances: []}})
    yield utils.loginUser(@player)
    json = { session: @session.id, courseInstanceId: @courseInstance.id }
    [res] = yield request.postAsync(url, { json })
    expect(res.statusCode).toBe(200)
    expect(res.body.leagues[0].leagueID).toBe(@courseInstance.id)
    
    # test 404, 403
    json = { session: @session.id, courseInstanceId: @session.id }
    [res] = yield request.postAsync(url, { json })
    expect(res.statusCode).toBe(404)
    
    @otherPlayer = yield utils.initUser()
    yield utils.loginUser(@otherPlayer)
    json = { session: @session.id, courseInstanceId: @courseInstance.id }
    [res] = yield request.postAsync(url, { json })
    expect(res.statusCode).toBe(403)
    
    # test persistence
    yield utils.loginUser(@player)
    json = { session: @session.id }
    [res] = yield request.postAsync(url, { json })
    expect(res.statusCode).toBe(200)
    expect(res.body.leagues[0].leagueID).toBe(@courseInstance.id)
    expect(res.body.leagues.length).toBe(1)
