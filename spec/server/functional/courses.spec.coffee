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
    yield new Course({ name: 'Course 1' }).save()
    yield new Course({ name: 'Course 2' }).save()
    yield utils.becomeAnonymous()
    done()


  it 'returns an array of Course objects', utils.wrap (done) ->
    [res, body] = yield request.getAsync { uri: getURL('/db/course'), json: true }
    expect(body.length).toBe(2)
    done()

describe 'GET /db/course/:handle', ->

  beforeEach utils.wrap (done) ->
    yield utils.clearModels([Course, User])
    @course = yield new Course({ name: 'Some Name' }).save()
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

describe 'GET /db/course/:handle/levels/:levelOriginal/next', ->

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

    levelJSON = { name: 'C', permissions: [{access: 'owner', target: admin.id}], type: 'course' }
    [res, body] = yield request.postAsync({uri: getURL('/db/level'), json: levelJSON})
    expect(res.statusCode).toBe(200)
    @levelC = yield Level.findById(res.body._id)
    paredLevelC = _.pick(res.body, 'name', 'original', 'type')

    campaignJSONA = { name: 'Campaign A', levels: {} }
    campaignJSONA.levels[paredLevelA.original] = paredLevelA
    campaignJSONA.levels[paredLevelB.original] = paredLevelB
    [res, body] = yield request.postAsync({uri: getURL('/db/campaign'), json: campaignJSONA})
    @campaignA = yield Campaign.findById(res.body._id)

    campaignJSONB = { name: 'Campaign B', levels: {} }
    campaignJSONB.levels[paredLevelC.original] = paredLevelC
    [res, body] = yield request.postAsync({uri: getURL('/db/campaign'), json: campaignJSONB})
    @campaignB = yield Campaign.findById(res.body._id)

    @courseA = Course({name: 'Course A', campaignID: @campaignA._id})
    yield @courseA.save()

    @courseB = Course({name: 'Course B', campaignID: @campaignB._id})
    yield @courseB.save()

    teacher = yield utils.initUser({role: 'teacher'})
    yield utils.loginUser(teacher)
    data = { name: 'Classroom 1' }
    classroomsURL = getURL('/db/classroom')
    [res, body] = yield request.postAsync {uri: classroomsURL, json: data }
    expect(res.statusCode).toBe(201)
    @classroom = yield Classroom.findById(res.body._id)
    
    url = getURL('/db/course')
    
    done()

  it 'returns the next level for the course in the linked classroom', utils.wrap (done) ->
    [res, body] = yield request.getAsync { uri: utils.getURL("/db/course/#{@courseA.id}/levels/#{@levelA.id}/next"), json: true }
    expect(res.statusCode).toBe(200)
    expect(res.body.original).toBe(@levelB.original.toString())
    done()
    
  it 'returns empty object if the given level is the last level in its course', utils.wrap (done) ->
    [res, body] = yield request.getAsync { uri: utils.getURL("/db/course/#{@courseA.id}/levels/#{@levelB.id}/next"), json: true }
    expect(res.statusCode).toBe(200)
    expect(res.body).toEqual({})
    done()

  it 'returns 404 if the given level is not in the course instance\'s course', utils.wrap (done) ->
    [res, body] = yield request.getAsync { uri: utils.getURL("/db/course/#{@courseB.id}/levels/#{@levelA.id}/next"), json: true }
    expect(res.statusCode).toBe(404)
    done()
