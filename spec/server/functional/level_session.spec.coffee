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
