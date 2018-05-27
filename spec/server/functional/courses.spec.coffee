require '../common'
utils = require '../utils'
_ = require 'lodash'
Promise = require 'bluebird'
request = require '../request'
requestAsync = Promise.promisify(request, {multiArgs: true})
Course = require '../../../server/models/Course'
User = require '../../../server/models/User'
Classroom = require '../../../server/models/Classroom'
Campaign = require '../../../server/models/Campaign'
Level = require '../../../server/models/Level'
Patch = require '../../../server/models/Patch'
User = require '../../../server/models/User'

courseFixture = {
  name: 'Unnamed course'
  campaignID: ObjectId("55b29efd1cd6abe8ce07db0d")
  concepts: ['basic_syntax', 'arguments', 'while_loops', 'strings', 'variables']
  description: "Learn basic syntax, while loops, and the CodeCombat environment."
  screenshot: "/images/pages/courses/101_info.png"
}

describe 'GET /db/course', ->
  beforeEach utils.wrap (done) ->
    yield utils.clearModels([Course, User])
    yield new Course({ name: 'Course 1', releasePhase: 'released' }).save()
    yield new Course({ name: 'Course 2', releasePhase: 'released' }).save()
    yield utils.becomeAnonymous()
    done()


  it 'returns an array of Course objects', utils.wrap (done) ->
    [res, body] = yield request.getAsync { uri: getURL('/db/course'), json: true }
    expect(body.length).toBe(2)
    done()

describe 'GET /db/course/:handle', ->

  beforeEach utils.wrap (done) ->
    yield utils.clearModels([Course, User])
    @course = yield new Course({ name: 'Some Name', releasePhase: 'released' }).save()
    yield utils.becomeAnonymous()
    done()


  it 'returns Course by id', utils.wrap (done) ->
    [res, body] = yield request.getAsync {uri: getURL("/db/course/#{@course.id}"), json: true}
    expect(res.statusCode).toBe(200)
    expect(body._id).toBe(@course.id)
    done()


  it 'returns Course by slug', utils.wrap (done) ->
    [res, body] = yield request.getAsync {uri: getURL("/db/course/some-name"), json: true}
    expect(res.statusCode).toBe(200)
    expect(body._id).toBe(@course.id)
    done()


  it 'returns not found if handle does not exist in the db', utils.wrap (done) ->
    [res, body] = yield request.getAsync {uri: getURL("/db/course/dne"), json: true}
    expect(res.statusCode).toBe(404)
    done()
    
describe 'PUT /db/course/:handle', ->
  beforeEach utils.wrap (done) ->
    yield utils.clearModels([Course, User])
    @course = yield new Course({ name: 'Some Name', releasePhase: 'released' }).save()
    yield utils.becomeAnonymous()
    @url = getURL("/db/course/#{@course.id}")
    done()

  it 'allows changes to i18n and i18nCoverage', utils.wrap (done) ->
    admin = yield utils.initAdmin()
    yield utils.loginUser(admin)
    json = { 
      i18n: { de: { name: 'German translation' } }
      i18nCoverage: ['de']
    }
    [res, body] = yield request.putAsync { @url, json }
    expect(res.statusCode).toBe(200)
    expect(body._id).toBe(@course.id)
    course = yield Course.findById(@course.id)
    expect(course.get('i18n').de.name).toBe('German translation')
    expect(course.get('i18nCoverage')).toBeDefined()
    done()
    
  it 'returns 403 to non-admins', utils.wrap (done) ->
    user = yield utils.initUser()
    yield utils.loginUser(user)
    json = { i18n: { es: { name: 'Spanish translation' } } }
    [res, body] = yield request.putAsync { @url, json }
    expect(res.statusCode).toBe(403)
    course = yield Course.findById(@course.id)
    expect(course.get('i18n')).toBeUndefined()
    expect(course.get('i18nCoverage').length).toBe(0)
    done()
    


describe 'GET /db/course/:handle/levels/:levelOriginal/next', ->

  beforeEach utils.wrap ->
    yield utils.clearModels [User, Classroom, Course, Level, Campaign]
    admin = yield utils.initAdmin()
    yield utils.loginUser(admin)

    levelJSON = { name: 'A', permissions: [{access: 'owner', target: admin.id}], type: 'course' }
    [res, body] = yield request.postAsync({uri: getURL('/db/level'), json: levelJSON})
    expect(res.statusCode).toBe(200)
    @levelA = yield Level.findById(res.body._id)
    paredLevelA = _.pick(res.body, 'name', 'original', 'type')

    levelJSON = { name: 'A-assessment', assessment: true, permissions: [{access: 'owner', target: admin.id}], type: 'course' }
    [res, body] = yield request.postAsync({uri: getURL('/db/level'), json: levelJSON})
    expect(res.statusCode).toBe(200)
    @assessmentA = yield Level.findById(res.body._id)
    paredAssessmentA = _.pick(res.body, 'name', 'original', 'type', 'assessment')

    levelJSON = { name: 'B', permissions: [{access: 'owner', target: admin.id}], type: 'course' }
    [res, body] = yield request.postAsync({uri: getURL('/db/level'), json: levelJSON})
    expect(res.statusCode).toBe(200)
    @levelB = yield Level.findById(res.body._id)
    paredLevelB = _.pick(res.body, 'name', 'original', 'type')

    levelJSON = { name: 'C', permissions: [{access: 'owner', target: admin.id}], type: 'course' }
    [res, body] = yield request.postAsync({uri: getURL('/db/level'), json: levelJSON})
    expect(res.statusCode).toBe(200)
    @levelC = yield Level.findById(res.body._id)
    paredLevelC = _.pick(res.body, 'name', 'original', 'type')

    campaignJSONA = { name: 'Campaign A', levels: {} }
    campaignJSONA.levels[paredLevelA.original] = paredLevelA
    campaignJSONA.levels[paredAssessmentA.original] = paredAssessmentA
    campaignJSONA.levels[paredLevelB.original] = paredLevelB
    [res, body] = yield request.postAsync({uri: getURL('/db/campaign'), json: campaignJSONA})
    @campaignA = yield Campaign.findById(res.body._id)

    campaignJSONB = { name: 'Campaign B', levels: {} }
    campaignJSONB.levels[paredLevelC.original] = paredLevelC
    [res, body] = yield request.postAsync({uri: getURL('/db/campaign'), json: campaignJSONB})
    @campaignB = yield Campaign.findById(res.body._id)

    @courseA = Course({name: 'Course A', campaignID: @campaignA._id, releasePhase: 'released'})
    yield @courseA.save()

    @courseB = Course({name: 'Course B', campaignID: @campaignB._id, releasePhase: 'released'})
    yield @courseB.save()

    @teacher = yield utils.initUser({role: 'teacher', permissions:['assessments']})
    yield utils.loginUser(@teacher)
    data = { name: 'Classroom 1' }
    classroomsURL = getURL('/db/classroom')
    [res, body] = yield request.postAsync {uri: classroomsURL, json: data }
    expect(res.statusCode).toBe(201)
    @classroom = yield Classroom.findById(res.body._id)

    url = getURL('/db/course')

  it 'returns the next level for the course in the linked classroom', utils.wrap ->
    [res, body] = yield request.getAsync { uri: utils.getURL("/db/course/#{@courseA.id}/levels/#{@levelA.id}/next"), json: true }
    expect(res.statusCode).toBe(200)
    expect(res.body.level.original).toBe(@levelB.original.toString())
    expect(res.body.assessment.original).toBe(@assessmentA.original.toString())

  it 'does not return the assessment if the teacher is not verified', utils.wrap ->
    yield @teacher.update({$set: {permissions: []}})
    [res, body] = yield request.getAsync { uri: utils.getURL("/db/course/#{@courseA.id}/levels/#{@levelA.id}/next"), json: true }
    expect(res.statusCode).toBe(200)
    expect(res.body.level.original).toBe(@levelB.original.toString())
    expect(res.body.assessment).toEqual({})

  it 'returns empty object if the given level is the last level in its course', utils.wrap ->
    [res, body] = yield request.getAsync { uri: utils.getURL("/db/course/#{@courseA.id}/levels/#{@levelB.id}/next"), json: true }
    expect(res.statusCode).toBe(200)
    expect(res.body.level).toEqual({})
    expect(res.body.assessment).toEqual({})

  it 'returns 404 if the given level is not in the course instance\'s course', utils.wrap ->
    [res, body] = yield request.getAsync { uri: utils.getURL("/db/course/#{@courseB.id}/levels/#{@levelA.id}/next"), json: true }
    expect(res.statusCode).toBe(404)

describe 'GET /db/course/:handle/level-solutions', ->
  beforeEach utils.wrap (done) ->
    yield utils.clearModels [User, Classroom, Course, Level, Campaign]
    admin = yield utils.initAdmin()
    yield utils.loginUser(admin)

    levelJSON = { name: 'A', permissions: [{access: 'owner', target: admin.id}], type: 'course' }
    [res, body] = yield request.postAsync({uri: getURL('/db/level'), json: levelJSON})
    expect(res.statusCode).toBe(200)
    @levelA = yield Level.findById(res.body._id)
    paredLevelA = _.pick(res.body, 'name', 'original', 'type')

    levelJSON = { name: 'B', permissions: [{access: 'owner', target: admin.id}], type: 'course' }
    [res, body] = yield request.postAsync({uri: getURL('/db/level'), json: levelJSON})
    expect(res.statusCode).toBe(200)
    @levelB = yield Level.findById(res.body._id)
    paredLevelB = _.pick(res.body, 'name', 'original', 'type')

    campaignJSONA = { name: 'Campaign A', levels: {} }
    campaignJSONA.levels[paredLevelB.original] = paredLevelB
    campaignJSONA.levels[paredLevelA.original] = paredLevelA
    [res, body] = yield request.postAsync({uri: getURL('/db/campaign'), json: campaignJSONA})
    @campaignA = yield Campaign.findById(res.body._id)

    @courseA = Course({name: 'Course A', campaignID: @campaignA._id, releasePhase: 'released'})
    yield @courseA.save()

    done()

  describe 'when admin', ->

    it 'returns level solutions', utils.wrap (done) ->
      [res, body] = yield request.getAsync { uri: utils.getURL("/db/course/#{@courseA.id}/level-solutions"), json: true }
      expect(res.statusCode).toBe(200)
      expect(body.length).toEqual(2)
      expect(body[0].slug).toEqual('a')
      done()

  describe 'when teacher', ->
    beforeEach utils.wrap (done) ->
      teacher = yield utils.initUser({role: 'teacher'})
      yield utils.loginUser(teacher)
      done()

    it 'returns level solutions', utils.wrap (done) ->
      [res, body] = yield request.getAsync { uri: utils.getURL("/db/course/#{@courseA.id}/level-solutions"), json: true }
      expect(res.statusCode).toBe(200)
      expect(body.length).toEqual(2)
      expect(body[1].slug).toEqual('b')
      done()

  describe 'when anonymous', ->
    beforeEach utils.wrap (done) ->
      yield utils.logout()
      done()

    it 'returns 403', utils.wrap (done) ->
      [res, body] = yield request.getAsync { uri: utils.getURL("/db/course/#{@courseA.id}/level-solutions"), json: true }
      expect(res.statusCode).toBe(403)
      done()


describe 'POST /db/course/:handle/patch', ->
  beforeEach utils.wrap (done) ->
    yield utils.clearModels [User, Course]
    @admin = yield utils.initAdmin()
    yield utils.loginUser(@admin)
    
    @course = yield utils.makeCourse({
      name: 'Test Course'
      description: 'A test course'
      i18n: {
        de: { name: 'existing translation' }
      }
    })
    @url = utils.getURL("/db/course/#{@course.id}/patch")
    @json = {
      commitMessage: 'Server test commit'
      target: {
        collection: 'course'
        id: @course.id
      }
    } 
    done()
    
  it 'accepts the patch immediately if just adding new translations to existing language', utils.wrap (done) ->
    originalCourse = _.cloneDeep(@course.toObject())
    changedCourse = _.cloneDeep(@course.toObject())
    changedCourse.i18n.de.description = 'German translation!'
    @json.delta = jsondiffpatch.diff(originalCourse, changedCourse)
    [res, body] = yield request.postAsync({ @url, @json })
    expect(res.statusCode).toBe(201)
    expect(res.body.status).toBe('accepted')
    course = yield Course.findById(@course.id)
    expect(course.get('i18n').de.description).toBe('German translation!')
    expect(course.get('patches')).toBeUndefined()
    expect(_.contains(course.get('i18nCoverage'),'de')).toBe(true)
    yield new Promise((resolve) -> setTimeout(resolve, 10))
    admin = yield User.findById(@admin.id)
    expected = { 
      patchesSubmitted: 1,
      courseTranslationPatches: 1,
      totalTranslationPatches: 1,
      patchesContributed: 1 
    }
    expect(_.isEqual(admin.get('stats'), expected)).toBe(true)
    done()

  it 'accepts the patch immediately if translations are for a new language', utils.wrap (done) ->
    originalCourse = _.cloneDeep(@course.toObject())
    changedCourse = _.cloneDeep(@course.toObject())
    changedCourse.i18n.fr = { description: 'French translation!' }
    @json.delta = jsondiffpatch.diff(originalCourse, changedCourse)
    [res, body] = yield request.postAsync({ @url, @json })
    expect(res.statusCode).toBe(201)
    expect(res.body.status).toBe('accepted')
    course = yield Course.findById(@course.id)
    expect(course.get('i18n').fr.description).toBe('French translation!')
    expect(course.get('patches')).toBeUndefined()
    done()
    
  it 'saves a patch if it has some replacement translations', utils.wrap (done) ->
    originalCourse = _.cloneDeep(@course.toObject())
    changedCourse = _.cloneDeep(@course.toObject())
    changedCourse.i18n.de.name = 'replacement'
    @json.delta = jsondiffpatch.diff(originalCourse, changedCourse)
    [res, body] = yield request.postAsync({ @url, @json })
    expect(res.statusCode).toBe(201)
    expect(res.body.status).toBe('pending')
    course = yield Course.findById(@course.id)
    expect(course.get('i18n').de.name).toBe('existing translation')
    expect(course.get('patches').length).toBe(1)
    patch = yield Patch.findById(course.get('patches')[0])
    expect(_.isEqual(patch.get('delta'), @json.delta)).toBe(true)
    expect(patch.get('reasonNotAutoAccepted')).toBe('Adding to existing translations.')
    [res, body] = yield request.getAsync({ url: utils.getURL("/db/course/#{@course.id}/patches?status=pending"), json: true })
    expect(res.body[0]._id).toBe(patch.id)
    yield new Promise((resolve) -> setTimeout(resolve, 10))
    admin = yield User.findById(@admin.id)
    expected = {
      patchesSubmitted: 1
    }
    expect(_.isEqual(admin.get('stats'), expected)).toBe(true)
    done()
    
  it 'saves a patch if applying the patch would invalidate the course data', utils.wrap (done) ->
    originalCourse = _.cloneDeep(@course.toObject())
    changedCourse = _.cloneDeep(@course.toObject())
    changedCourse.notAProperty = 'this should not get saved to the course'
    @json.delta = jsondiffpatch.diff(originalCourse, changedCourse)
    [res, body] = yield request.postAsync({ @url, @json })
    expect(res.statusCode).toBe(201)
    expect(res.body.status).toBe('pending')
    course = yield Course.findById(@course.id)
    expect(course.get('notAProperty')).toBeUndefined()
    expect(course.get('patches').length).toBe(1)
    patch = yield Patch.findById(course.get('patches')[0])
    expect(_.isEqual(patch.get('delta'), @json.delta)).toBe(true)
    expect(patch.get('reasonNotAutoAccepted')).toBe('Did not pass json schema.')
    done()
    
  it 'saves a patch if submission loses race with another translator', utils.wrap (done) ->
    originalCourse = _.cloneDeep(@course.toObject())
    changedCourse = _.cloneDeep(@course.toObject())
    changedCourse.i18n.de.description = 'German translation!'
    yield @course.update({$set: {'i18n.de.description': 'Race condition'}}) # another change got saved first
    @json.delta = jsondiffpatch.diff(originalCourse, changedCourse)
    [res, body] = yield request.postAsync({ @url, @json })
    expect(res.body.status).toBe('pending')
    expect(res.statusCode).toBe(201)
    course = yield Course.findById(@course.id)
    expect(course.get('i18n').de.description).toBe('Race condition')
    expect(course.get('patches').length).toBe(1)
    patch = yield Patch.findById(course.get('patches')[0])
    # will have been normalized to include that it has been modified from "Race condition"
    expectedDelta = {"i18n":{"de":{"description":["Race condition","German translation!"]}}}
    expect(_.isEqual(patch.get('delta'), expectedDelta)).toBe(true)
    expect(patch.get('reasonNotAutoAccepted')).toBe('Adding to existing translations.')
    done()
