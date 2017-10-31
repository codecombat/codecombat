require '../common'
Campaign = require '../../../server/models/Campaign'
Classroom = require '../../../server/models/Classroom'
Course = require '../../../server/models/Course'
CourseInstance = require '../../../server/models/CourseInstance'
Level = require '../../../server/models/Level'
LevelSession = require '../../../server/models/LevelSession'
User = require '../../../server/models/User'
request = require '../request'
utils = require '../utils'
moment = require 'moment'
mongoose = require 'mongoose'

describe 'Level', ->

  level =
    name: 'King\'s Peak 3'
    description: 'Climb a mountain.'
    permissions: simplePermissions
    scripts: []
    thangs: []
    documentation: {specificArticles: [], generalArticles: []}

  urlLevel = '/db/level'

  it 'clears things first', (done) ->
    clearModels [Level, User], (err) ->
      expect(err).toBeNull()
      done()

  it 'can make a Level.', (done) ->
    loginJoe ->
      request.post {uri: getURL(urlLevel), json: level}, (err, res, body) ->
        expect(res.statusCode).toBe(200)
        done()

  it 'get schema', (done) ->
    request.get {uri: getURL(urlLevel+'/schema')}, (err, res, body) ->
      expect(res.statusCode).toBe(200)
      body = JSON.parse(body)
      expect(body.type).toBeDefined()
      done()
      
      
describe 'POST /db/level/:handle', ->
  it 'creates a new version', utils.wrap (done) ->
    yield utils.clearModels([Campaign, Course, CourseInstance, Level, User])
    admin = yield utils.initAdmin()
    yield utils.loginUser(admin)
    @level = yield utils.makeLevel()
    levelJSON = @level.toObject()
    levelJSON.name = 'New name'
    
    url = getURL("/db/level/#{@level.id}")
    [res, body] = yield request.postAsync({url: url, json: levelJSON})
    expect(res.statusCode).toBe(201)
    done()
    
  it 'does not break the target level if a name change would conflict with another level', utils.wrap (done) ->
    yield utils.clearModels([Level, User])
    user = yield utils.initUser()
    yield utils.loginUser(user)
    yield utils.makeLevel({name: 'Taken Name'})
    level = yield utils.makeLevel({name: 'Another Level'})
    json = _.extend({}, level.toObject(), {name: 'Taken Name'})
    [res, body] = yield request.postAsync({url: utils.getURL("/db/level/#{level.id}"), json})
    expect(res.statusCode).toBe(409)
    level = yield Level.findById(level.id)
    # should be unchanged
    expect(level.get('slug')).toBe('another-level')
    expect(level.get('version').isLatestMinor).toBe(true)
    expect(level.get('version').isLatestMajor).toBe(true)
    expect(level.get('index')).toBeDefined()
    done()

  it 'enforces permissions', utils.wrap (done) ->
    yield utils.clearModels([Level, User])
    user = yield utils.initUser()
    yield utils.loginUser(user)
    level = yield utils.makeLevel({description:'Original desc'})
    
    otherUser = yield utils.initUser()
    yield utils.loginUser(otherUser)
    json = _.extend({}, level.toObject(), {description: 'Trollin'})
    [res, body] = yield request.postAsync({url: utils.getURL("/db/level/#{level.id}"), json})
    expect(res.statusCode).toBe(403)
    level = yield Level.findById(level.id)
    expect(level.get('description')).toBe('Original desc')
    done()
    
  it 'updates campaigns that contain that level', utils.wrap (done) ->
    admin = yield utils.initAdmin()
    yield utils.loginUser(admin)
    
    level = yield utils.makeLevel({name: 'First name'})
    campaign = yield utils.makeCampaign({}, {levels: [level]})

    otherLevel = yield utils.makeLevel()
    unrelatedCampaign = yield utils.makeCampaign({}, {levels: [otherLevel]})

    url = getURL("/db/level/#{level.id}")
    levelJSON = level.toObject()
    levelJSON.name = 'New name'
    spyOn(Campaign, 'update').and.callThrough()
    [res, body] = yield request.postAsync({url: url, json: levelJSON})
    expect(Campaign.update.calls.count()).toBe(1)
    yield Campaign.update.calls.mostRecent().returnValue # wait until update is finished
    campaign = yield Campaign.findById(campaign.id)
    expect(_.size(campaign.get('levels'))).toBe(1)
    expect(campaign.get('levels')[level.get('original')].name).toBe('New name')
    unrelatedCampaign = yield Campaign.findById(unrelatedCampaign.id)
    expect(_.size(unrelatedCampaign.get('levels'))).toBe(1)
    expect(unrelatedCampaign.get('levels')[level.get('original')]).not.toBe('New name')
    done()

describe 'GET /db/level/:handle/session', ->

  describe 'when level IS a course level', ->

    beforeEach utils.wrap (done) ->
      yield utils.clearModels([Campaign, Course, CourseInstance, Level, User, LevelSession])
      admin = yield utils.initAdmin()
      yield utils.loginUser(admin)
      @level = yield utils.makeLevel({type: 'course'})
      
      # To ensure test compares original, not id, make them different. TODO: Make factories do this normally?
      @level.set('original', new mongoose.Types.ObjectId())
      @level.save()
      
      @primerLevel = yield utils.makeLevel({type: 'course', primerLanguage: 'javascript'})
      @campaign = yield utils.makeCampaign({}, {levels: [@level, @primerLevel]})
      @course = yield utils.makeCourse({free: true, releasePhase: 'released'}, {campaign: @campaign})
      @student = yield utils.initUser({
        role: 'student'
        coursePrepaid: {
          _id: {}
          startDate: moment().subtract(1, 'month').toISOString()
          endDate: moment().add(1, 'month').toISOString()
        }
      })
      @members = [@student]
      @teacher = yield utils.initUser({role: 'teacher'})
      yield utils.loginUser(@teacher)
      @classroom = yield utils.makeClassroom({aceConfig: { language: 'javascript' }}, { @members })
      @courseInstance = yield utils.makeCourseInstance({}, { @course, @classroom, @members })
      @url = getURL("/db/level/#{@level.id}/session")
      yield utils.loginUser(@student)
      done()
      
    it 'creates a new session if the user is in a course with that level', utils.wrap (done) ->
      [res, body] = yield request.getAsync { uri: @url, json: true }
      expect(res.statusCode).toBe(201)
      expect(body.codeLanguage).toBe('javascript')
      done()
      
    it 'works if the classroom has no aceConfig', utils.wrap (done) ->
      @classroom.set('aceConfig', undefined)
      yield @classroom.save()
      [res, body] = yield request.getAsync { uri: @url, json: true }
      expect(res.statusCode).toBe(201)
      expect(body.codeLanguage).toBe('python')
      done()
      
    it 'does not break if the user has a courseInstance without an associated classroom', utils.wrap (done) ->
      yield @courseInstance.update({$unset: {classroomID: ''}})
      [res, body] = yield request.getAsync { uri: @url, json: true }
      expect(res.statusCode).toBe(402)
      done()

    it 'returns 402 if the user is not in a course with that level', utils.wrap (done) ->
      otherStudent = yield utils.initUser({role: 'student'})
      yield utils.loginUser(otherStudent)
      [res, body] = yield request.getAsync({ uri: @url, json: true })
      expect(res.statusCode).toBe(402)
      expect(res.body.message).toBe('You must be in a course which includes this level to play it')
      done()
      
    describe 'when courseInstance is included in the query', ->
      it 'sets the language based on the level primerLanguage and classroom language setting', utils.wrap (done) ->
        
        # make python classroom
        yield utils.loginUser(@teacher)
        @pythonClassroom = yield utils.makeClassroom({aceConfig: { language: 'python' }}, { @members })
        @pythonCourseInstance = yield utils.makeCourseInstance({}, { @course, classroom: @pythonClassroom, @members })
        
        # try making javascript classroom session, make sure it is idempotent
        yield utils.loginUser(@student)
        [res, body] = yield request.getAsync { uri: @url, qs: {courseInstance: @courseInstance.id}, json: true }
        expect(res.statusCode).toBe(201)
        javascriptSession = res.body
        expect(javascriptSession.codeLanguage).toBe('javascript')
        [res, body] = yield request.getAsync { uri: @url, qs: {courseInstance: @courseInstance.id}, json: true }
        expect(res.statusCode).toBe(200)
        expect(res.body._id).toBe(javascriptSession._id)
        
        # try python course
        [res, body] = yield request.getAsync { uri: @url, qs: {courseInstance: @pythonCourseInstance.id}, json: true }
        expect(res.statusCode).toBe(201)
        pythonSession = res.body
        expect(pythonSession.codeLanguage).toBe('python')
        expect(pythonSession._id).not.toBe(javascriptSession._id)
        [res, body] = yield request.getAsync { uri: @url, qs: {courseInstance: @pythonCourseInstance.id}, json: true }
        expect(res.statusCode).toBe(200)
        expect(res.body._id).toBe(pythonSession._id)
        
        # try primer level, which ta
        primerUrl = getURL("/db/level/#{@primerLevel.id}/session")
        [res, body] = yield request.getAsync { uri: primerUrl, qs: {courseInstance: @pythonCourseInstance.id}, json: true }
        expect(res.statusCode).toBe(201)
        primerSession = res.body
        expect(primerSession.codeLanguage).toBe('javascript')
        [res, body] = yield request.getAsync { uri: primerUrl, qs: {courseInstance: @pythonCourseInstance.id}, json: true }
        expect(res.statusCode).toBe(200)
        expect(res.body._id).toBe(primerSession._id)
        done()
      
    describe 'when the course is not free', ->
  
      beforeEach utils.wrap (done) ->
        @course.set({free: false})
        yield @course.save()
        done()
      
      it 'returns 402 if the user is not enrolled', utils.wrap (done) ->
        @student.set({
          coursePrepaid: {
            _id: {}
            startDate: moment().subtract(2, 'month').toISOString()
            endDate: moment().subtract(1, 'month').toISOString()
          }
        })
        yield @student.save()
        [res, body] = yield request.getAsync({ uri: @url, json: true })
        expect(res.statusCode).toBe(402)
        expect(res.body.message).toBe('You must be enrolled to access this content')
        done()
        
      it 'creates the session if the user is enrolled', utils.wrap (done) ->
        [res, body] = yield request.getAsync({ uri: @url, json: true })
        expect(res.statusCode).toBe(201)
        done()

      it 'returns 402 if the user\'s license is expired', utils.wrap (done) ->
        @student.set({
          coursePrepaid: {
            _id: {}
            startDate: moment().subtract(2, 'month').toISOString()
            endDate: moment().subtract(1, 'month').toISOString()
          }
        })
        yield @student.save()
        [res, body] = yield request.getAsync({ uri: @url, json: true })
        expect(res.statusCode).toBe(402)
        expect(res.body.message).toBe('You must be enrolled to access this content')
        done()
      
      
  describe 'when the level is NOT a course level', ->
    
    beforeEach utils.wrap (done) ->
      yield utils.clearModels([Level, User])
      @admin = yield utils.initAdmin()
      yield utils.loginUser(@admin)
      @level = yield utils.makeLevel()
      
      @player = yield utils.initUser()
      yield utils.loginUser(@player)
      @url = getURL("/db/level/#{@level.id}/session")
      done()
      
    it 'idempotently creates and returns a session for that level', utils.wrap (done) ->
      [res, body] = yield request.getAsync { uri: @url, json: true }
      expect(res.statusCode).toBe(201)
      sessionID = body._id
      [res, body] = yield request.getAsync { uri: @url, json: true }
      expect(body._id).toBe(sessionID)
      done()
      
    describe 'when the level is not free', ->
      beforeEach utils.wrap (done) ->
        yield @level.update({$set: {requiresSubscription: true}})
        done()
        
      it 'returns 402 for normal users', utils.wrap (done) ->
        [res, body] = yield request.getAsync { uri: @url, json: true }
        expect(res.statusCode).toBe(402)
        done()
        
      it 'returns 201 for admins', utils.wrap (done) ->
        yield @player.update({$set: {permissions: ['admin']}})
        [res, body] = yield request.getAsync { uri: @url, json: true }
        expect(res.statusCode).toBe(201)
        done()

      it 'returns 201 for adventurer levels', utils.wrap (done) ->
        yield @level.update({$set: {adventurer: true}})
        [res, body] = yield request.getAsync { uri: @url, json: true }
        expect(res.statusCode).toBe(201)
        done()

      it 'returns 201 for subscribed users', utils.wrap (done) ->
        yield @player.update({$set: {stripe: {free: true}}})
        [res, body] = yield request.getAsync { uri: @url, json: true }
        expect(res.statusCode).toBe(201)
        done()
        
      it 'returns 201 if the campaign included in the campaign is type "hoc" and the level is in that campaign', utils.wrap ->
        yield utils.loginUser(@admin)
        @otherLevel = yield utils.makeLevel({requiresSubscription: true})
        @campaign = yield utils.makeCampaign({}, {levels: [@level]})
        @gameDevHocCampaign = yield utils.makeCampaign({type: 'hoc'}, {levels: [@otherLevel]})
        yield utils.loginUser(@player)
        otherLevelUrl = getURL("/db/level/#{@otherLevel.id}/session")
        
        # test using the wrong campaign
        [res, body] = yield request.getAsync { uri: otherLevelUrl, json: true, qs: { campaign: @campaign.id } }
        expect(res.statusCode).toBe(402)

        # test using the right campaign and level
        [res, body] = yield request.getAsync { uri: otherLevelUrl, json: true, qs: { campaign: @gameDevHocCampaign.id } }
        expect(res.statusCode).toBe(201)

        # test using the wrong level
        [res, body] = yield request.getAsync { uri: @url, json: true, qs: { campaign: @gameDevHocCampaign.id } }
        expect(res.statusCode).toBe(402)

        # test trying to use a campaign that isn't the game dev hoc campaign
        [res, body] = yield request.getAsync { uri: @url, json: true, qs: { campaign: @campaign.id } }
        expect(res.statusCode).toBe(402)
        
        
describe 'POST /db/level/names', ->
  
  it 'returns names of levels whose ids have been POSTed', utils.wrap (done) ->
    levels = yield _.times(5, utils.makeLevel)
    levelIDs = _.map(levels, (level) -> level.id)
    [res, body] = yield request.postAsync { url: utils.getURL('/db/level/names'), json: { ids: levelIDs } }
    expect(res.statusCode).toBe(200)
    expect(res.body.length).toBe(5)
    aLevel = levels[2]
    expect(_.find(body, (l) -> l._id is aLevel.id).name).toBe(aLevel.get('name'))
    done()

    
describe 'POST /db/level/:handle/patch', ->
  
  it 'accepts the patch based on the latest version, not the version given', utils.wrap (done) ->
    user = yield utils.initUser()
    yield utils.loginUser(user)
    level = yield utils.makeLevel()
    original = level.toObject()
    changed = _.clone(original)
    changed.i18n = {'de': {name:'German translation #1'}}
    delta = jsondiffpatch.diff(original, changed)
    
    json = {
      delta: delta
      target: {
        collection: 'level'
        id: level.id
      }
      commitMessage: 'Server test commit'
    }
    url = utils.getURL("/db/level/#{level.id}/patch")
    [res, body] = yield request.postAsync({url, json})
    expect(res.body.status).toBe('accepted')
    
    changed = _.clone(original)
    changed.i18n = {'de': {name:'German translation #2'}}
    delta = jsondiffpatch.diff(original, changed)
    json.delta = delta
    
    [res, body] = yield request.postAsync({url, json})
    expect(res.body.status).toBe('pending')
    expect(res.body.target.original).toBe(level.get('original').toString())
    done()
    
  it 'throws an error if there would be no change', utils.wrap (done) ->
    user = yield utils.initUser()
    yield utils.loginUser(user)
    level = yield utils.makeLevel()
    original = level.toObject()
    changed = _.clone(original)
    changed.i18n = {'de': {name:'German translation #1'}}
    delta = jsondiffpatch.diff(original, changed)

    json = {
      delta: delta
      target: {
        collection: 'level'
        id: level.id
      }
      commitMessage: 'Server test commit'
    }
    url = utils.getURL("/db/level/#{level.id}/patch")
    [res, body] = yield request.postAsync({url, json})
    expect(res.body.status).toBe('accepted')

    # repeat request
    [res, body] = yield request.postAsync({url, json})
    expect(res.statusCode).toBe(422)
    done()

describe 'DELETE /db/level/:handle/i18n-coverage', ->
  it 'removes the i18nCoverage property from the level', utils.wrap ->
    level = yield utils.makeLevel({
      i18nCoverage: []
    })
    level = yield Level.findById(level.id)
    expect(level.get('i18nCoverage')).toDeepEqual([])
    
    admin = yield utils.initAdmin()
    yield utils.loginUser(admin)

    url = utils.getURL("/db/level/#{level.id}/i18n-coverage")
    [res] = yield request.delAsync({url, json: true})
    expect(res.statusCode).toBe(200)
    level = yield Level.findById(level.id)
    expect(level.get('i18nCoverage')).toBeUndefined()

  it 'returns 403 unless you are an admin or artisan', utils.wrap ->
    level = yield utils.makeLevel()
    
    user = yield utils.initUser()
    yield utils.loginUser(user)

    url = utils.getURL("/db/level/#{level.id}/i18n-coverage")
    [res] = yield request.delAsync({url, json: true})
    expect(res.statusCode).toBe(403)
