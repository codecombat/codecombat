require '../common'
LevelSession = require '../../../server/models/LevelSession'
mongoose = require 'mongoose'
request = require '../request'
utils = require('../utils')

describe 'GET /db/level.session/schema', ->
  it 'returns the level session schema', utils.wrap ->
    [res] = yield request.getAsync {uri: utils.getURL('/db/level.session/schema'), json: true}
    expect(res.statusCode).toBe(200)
    expect(res.body.type).toBeDefined()


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

    
describe 'PUT /db/level.session/:handle/key-value-db/:key', ->
  
  beforeEach utils.wrap ->
    @player = yield utils.initUser()
    @player2 = yield utils.initUser()
    @level = yield utils.makeLevel({ type: 'game-dev' })
    @session = yield utils.makeLevelSession({}, { @level, creator: @player })
    yield utils.loginUser(@player2)
    
  it 'upserts and updates the value to the session keyValueDb', utils.wrap ->
    @url = utils.getUrl("/db/level.session/#{@session.id}/key-value-db/foo")
    [res] = yield request.putAsync({ @url, json: 'bar' })
    expect(res.statusCode).toBe(200)
    session = yield LevelSession.findById(@session.id)
    expect(session.get('keyValueDb')).toEqual({ foo: 'bar' })
    
    # make sure we can still edit the session afterward
    [res] = yield request.putAsync({
      url: utils.getUrl("/db/level.session/#{@session.id}")
      json: session.toObject()
    })
    expect(res.statusCode).toBe(200)
  
  it 'returns 404 if the session does not exist', utils.wrap ->
    @url = utils.getUrl("/db/level.session/123456789012345678901234/key-value-db/foo")
    [res] = yield request.putAsync({ @url })
    expect(res.statusCode).toBe(404)

  it 'returns 200 if you are anonymous', utils.wrap ->
    user = yield utils.becomeAnonymous()
    session = yield utils.makeLevelSession({}, { @level, creator: user })
    @url = utils.getUrl("/db/level.session/#{session.id}/key-value-db/foo")
    [res] = yield request.putAsync({ @url, json: 'bar' })
    expect(res.statusCode).toBe(200)

  it 'returns 422 if the level is not of type game-dev', utils.wrap ->
    yield @level.update({$set: { type: 'something-else' }})
    @url = utils.getUrl("/db/level.session/#{@session.id}/key-value-db/foo")
    [res] = yield request.putAsync({ @url, json: 'bar' })
    expect(res.statusCode).toBe(422)
  
  it 'returns 422 if the value is an object, array, or undefined', utils.wrap ->
    @url = utils.getUrl("/db/level.session/#{@session.id}/key-value-db/foo")
    [res] = yield request.putAsync({ @url, json: [] })
    expect(res.statusCode).toBe(422)

    @url = utils.getUrl("/db/level.session/#{@session.id}/key-value-db/foo")
    [res] = yield request.putAsync({ @url, json: {} })
    expect(res.statusCode).toBe(422)

    @url = utils.getUrl("/db/level.session/#{@session.id}/key-value-db/foo")
    [res] = yield request.putAsync({ @url, json: undefined })
    expect(res.statusCode).toBe(422)
    
  it 'returns 422 if the value is a string of length > 1kb', utils.wrap ->
    @url = utils.getUrl("/db/level.session/#{@session.id}/key-value-db/foo")
    [res] = yield request.putAsync({ @url, json: _.times(1025, '1').join('') })
    expect(res.statusCode).toBe(422)
    
  it 'returns 422 if you try to add more than 100 keys', utils.wrap ->
    keyValueDb = {}
    _.times(99, (i) -> keyValueDb[i] = '')
    yield @session.update({ $set: { keyValueDb }})
    
    # add 100th key, should work
    @url = utils.getUrl("/db/level.session/#{@session.id}/key-value-db/hundredth")
    [res] = yield request.putAsync({ @url, json: 'bar' })
    expect(res.statusCode).toBe(200)
    
    # add 101st key, should not work
    @url = utils.getUrl("/db/level.session/#{@session.id}/key-value-db/101")
    [res] = yield request.putAsync({ @url, json: 'bar' })
    expect(res.statusCode).toBe(422)

    # change existing key, should work
    @url = utils.getUrl("/db/level.session/#{@session.id}/key-value-db/hundredth")
    [res] = yield request.putAsync({ @url, json: 'foo' })
    expect(res.statusCode).toBe(200)

  it 'works for numbers, null, and booleans', utils.wrap ->
    @url = utils.getUrl("/db/level.session/#{@session.id}/key-value-db/foo")
    [res] = yield request.putAsync({ @url, json: 12 })
    expect(res.statusCode).toBe(200)
    expect(res.body).toBe(12)

    [res] = yield request.putAsync({ @url, json: true, body: null })
    expect(res.statusCode).toBe(200)
    expect(res.body).toBe(null)

    [res] = yield request.putAsync({ @url, json: true, body: true })
    expect(res.statusCode).toBe(200)
    expect(res.body).toBe(true)


describe 'POST /db/level.session/:handle/key-value-db/:key/increment', ->
  beforeEach utils.wrap ->
    @player = yield utils.initUser()
    @player2 = yield utils.initUser()
    @level = yield utils.makeLevel({ type: 'game-dev' })
    @session = yield utils.makeLevelSession({}, { @level, creator: @player })
    yield utils.loginUser(@player2)

  it 'upserts and increments the value in the session keyValueDb', utils.wrap ->
    @url = utils.getUrl("/db/level.session/#{@session.id}/key-value-db/foo/increment")
    [res] = yield request.postAsync({ @url, json: 1 })
    expect(res.statusCode).toBe(200)
    session = yield LevelSession.findById(@session.id)
    expect(session.get('keyValueDb')).toEqual({ foo: 1 })

    [res] = yield request.postAsync({ @url, json: 3 })
    expect(res.statusCode).toBe(200)
    session = yield LevelSession.findById(@session.id)
    expect(session.get('keyValueDb')).toEqual({ foo: 4 })
    
  it 'returns 404 if the session does not exist', utils.wrap ->
    @url = utils.getUrl("/db/level.session/123456789012345678901234/key-value-db/foo/increment")
    [res] = yield request.postAsync({ @url })
    expect(res.statusCode).toBe(404)

  it 'returns 200 if you are anonymous', utils.wrap ->
    user = yield utils.becomeAnonymous()
    session = yield utils.makeLevelSession({}, { @level, creator: user })
    url = utils.getUrl("/db/level.session/#{@session.id}/key-value-db/foo/increment")
    [res] = yield request.postAsync({ url, json: 1 })
    expect(res.statusCode).toBe(200)

  it 'returns 422 if the level is not of type game-dev', utils.wrap ->
    yield @level.update({$set: { type: 'something-else' }})
    @url = utils.getUrl("/db/level.session/#{@session.id}/key-value-db/foo/increment")
    [res] = yield request.postAsync({ @url, json: 1 })
    expect(res.statusCode).toBe(422)
  
  it 'returns 422 if the value is not a number', utils.wrap ->
    @url = utils.getUrl("/db/level.session/#{@session.id}/key-value-db/foo/increment")
    [res] = yield request.postAsync({ @url, json: 'foo' })
    expect(res.statusCode).toBe(422)
    
  it 'returns 422 if you try to add more than 100 keys', utils.wrap ->
    keyValueDb = {}
    _.times(99, (i) -> keyValueDb[i] = '')
    yield @session.update({ $set: { keyValueDb }})
    
    # add 100th key, should work
    @url = utils.getUrl("/db/level.session/#{@session.id}/key-value-db/hundredth/increment")
    [res] = yield request.postAsync({ @url, json: 1 })
    expect(res.statusCode).toBe(200)
    
    # add 101st key, should not work
    @url = utils.getUrl("/db/level.session/#{@session.id}/key-value-db/101/increment")
    [res] = yield request.postAsync({ @url, json: 1 })
    expect(res.statusCode).toBe(422)

    # change existing key, should work
    @url = utils.getUrl("/db/level.session/#{@session.id}/key-value-db/hundredth/increment")
    [res] = yield request.postAsync({ @url, json: 2 })
    expect(res.statusCode).toBe(200)
    
  it 'works with an invalid session id', utils.wrap ->
    url = utils.getUrl('/db/level.session/A%20Fake%20Session%20ID/key-value-db/fire-trap/increment')
    [res] = yield request.postAsync({ url, json: 2 })
    expect(res.statusCode).toBe(422)

