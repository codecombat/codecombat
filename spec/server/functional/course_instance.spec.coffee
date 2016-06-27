async = require 'async'
config = require '../../../server_config'
require '../common'
stripe = require('stripe')(config.stripe.secretKey)
utils = require '../utils'
CourseInstance = require '../../../server/models/CourseInstance'
Course = require '../../../server/models/Course'
User = require '../../../server/models/User'
Classroom = require '../../../server/models/Classroom'
Campaign = require '../../../server/models/Campaign'
Level = require '../../../server/models/Level'
LevelSession = require '../../../server/models/LevelSession'
Prepaid = require '../../../server/models/Prepaid'
request = require '../request'
moment = require 'moment'

courseFixture = {
  name: 'Unnamed course'
  campaignID: ObjectId("55b29efd1cd6abe8ce07db0d")
  concepts: ['basic_syntax', 'arguments', 'while_loops', 'strings', 'variables']
  description: "Learn basic syntax, while loops, and the CodeCombat environment."
  screenshot: "/images/pages/courses/101_info.png"
}

classroomFixture = {
  name: 'Unnamed classroom'
  members: []
}

describe 'POST /db/course_instance', ->
  url = getURL('/db/course_instance')

  beforeEach utils.wrap (done) ->
    yield utils.clearModels([CourseInstance, Course, User, Classroom])
    @teacher = yield utils.initUser({role: 'teacher'})
    yield utils.loginUser(@teacher)
    @course = yield new Course(courseFixture).save()
    classroomData = _.extend({ownerID: @teacher._id}, classroomFixture)
    @classroom = yield new Classroom(classroomData).save()
    done()

  it 'creates a CourseInstance', utils.wrap (done) ->
    data = {
      name: 'Some Name'
      courseID: @course.id
      classroomID: @classroom.id
    }
    [res, body] = yield request.postAsync {uri: url, json: data}
    expect(res.statusCode).toBe(200)
    expect(body.classroomID).toBeDefined()
    done()

  it 'returns the same CourseInstance if you POST twice', utils.wrap (done) ->
    data = {
      name: 'Some Name'
      courseID: @course.id
      classroomID: @classroom.id
    }
    [res, body] = yield request.postAsync {uri: url, json: data}
    expect(res.statusCode).toBe(200)
    expect(body.classroomID).toBeDefined()
    firstID = body._id
    [res, body] = yield request.postAsync {uri: url, json: data}
    expect(res.statusCode).toBe(200)
    expect(body.classroomID).toBeDefined()
    secondID = body._id
    expect(firstID).toBe(secondID)
    done()

  it 'returns 404 if the Course does not exist', utils.wrap (done) ->
    data = {
      name: 'Some Name'
      courseID: '123456789012345678901234'
      classroomID: @classroom.id
    }
    [res, body] = yield request.postAsync {uri: url, json: data}
    expect(res.statusCode).toBe(404)
    done()

  it 'returns 404 if the Classroom does not exist', utils.wrap (done) ->
    data = {
      name: 'Some Name'
      courseID: @course.id
      classroomID: '123456789012345678901234'
    }
    [res, body] = yield request.postAsync {uri: url, json: data}
    expect(res.statusCode).toBe(404)
    done()

  it 'return 403 if the logged in user does not own the Classroom', utils.wrap (done) ->
    user = yield utils.initUser()
    yield utils.loginUser(user)
    data = {
      name: 'Some Name'
      courseID: @course.id
      classroomID: @classroom.id
    }
    [res, body] = yield request.postAsync {uri: url, json: data}
    expect(res.statusCode).toBe(403)
    done()


describe 'POST /db/course_instance/:id/members', ->

  beforeEach utils.wrap (done) ->
    yield utils.clearModels([CourseInstance, Course, User, Classroom, Prepaid, Campaign, Level])
    @teacher = yield utils.initUser({role: 'teacher'})
    admin = yield utils.initAdmin()
    yield utils.loginUser(admin)
    @level = yield utils.makeLevel({type: 'course'})
    @campaign = yield utils.makeCampaign({}, {levels: [@level]})
    @course = yield utils.makeCourse({free: true}, {campaign: @campaign})
    @student = yield utils.initUser({role: 'student'})
    @prepaid = yield utils.makePrepaid({creator: @teacher.id})
    members = [@student]
    yield utils.loginUser(@teacher)
    @classroom = yield utils.makeClassroom({aceConfig: { language: 'javascript' }}, { members })
    @courseInstance = yield utils.makeCourseInstance({}, { @course, @classroom })
    done()

  it 'adds an array of members to the given CourseInstance', utils.wrap (done) ->
    @classroom.set('members', [@student._id])
    yield @classroom.save()
    url = getURL("/db/course_instance/#{@courseInstance.id}/members")
    [res, body] = yield request.postAsync {uri: url, json: {userIDs: [@student.id]}}
    expect(res.statusCode).toBe(200)
    expect(body.members.length).toBe(1)
    expect(body.members[0]).toBe(@student.id)
    done()

  it 'adds a member to the given CourseInstance', utils.wrap (done) ->
    url = getURL("/db/course_instance/#{@courseInstance.id}/members")
    [res, body] = yield request.postAsync {uri: url, json: {userID: @student.id}}
    expect(res.statusCode).toBe(200)
    expect(res.body.members.length).toBe(1)
    expect(res.body.members[0]).toBe(@student.id)
    done()

  it 'adds the CourseInstance id to the user', utils.wrap (done) ->
    url = getURL("/db/course_instance/#{@courseInstance.id}/members")
    [res, body] = yield request.postAsync {uri: url, json: {userID: @student.id}}
    user = yield User.findById(@student.id)
    expect(_.size(user.get('courseInstances'))).toBe(1)
    done()

  it 'return 403 if the member is not in the classroom', utils.wrap (done) ->
    @classroom.set('members', [])
    yield @classroom.save()
    url = getURL("/db/course_instance/#{@courseInstance.id}/members")
    [res, body] = yield request.postAsync {uri: url, json: {userID: @student.id}}
    expect(res.statusCode).toBe(403)
    done()

  it 'returns 403 if the user does not own the course instance and is not adding self', utils.wrap (done) ->
    otherUser = yield utils.initUser()
    yield utils.loginUser(otherUser)
    url = getURL("/db/course_instance/#{@courseInstance.id}/members")
    [res, body] = yield request.postAsync {uri: url, json: {userID: @student.id}}
    expect(res.statusCode).toBe(403)
    done()

  it 'returns 200 if the user is a member of the classroom and is adding self', ->

  it 'return 402 if the course is not free and the user is not enrolled', utils.wrap (done) ->
    @course.set('free', false)
    yield @course.save()
    url = getURL("/db/course_instance/#{@courseInstance.id}/members")
    [res, body] = yield request.postAsync {uri: url, json: {userID: @student.id}}
    expect(res.statusCode).toBe(402)
    done()

  it 'works if the course is not free and the user is enrolled', utils.wrap (done) ->
    @course.set('free', false)
    yield @course.save()
    @student.set('coursePrepaid', _.pick(@prepaid.toObject(), '_id', 'startDate', 'endDate'))
    yield @student.save()
    url = getURL("/db/course_instance/#{@courseInstance.id}/members")
    [res, body] = yield request.postAsync {uri: url, json: {userID: @student.id}}
    expect(res.statusCode).toBe(200)
    done()

  it 'works if the course is not free and the user is enrolled but is not migrated', utils.wrap (done) ->
    @course.set('free', false)
    yield @course.save()
    @student.set('coursePrepaidID', @prepaid._id)
    yield @student.save()
    url = getURL("/db/course_instance/#{@courseInstance.id}/members")
    [res, body] = yield request.postAsync {uri: url, json: {userID: @student.id}}
    expect(res.statusCode).toBe(200)
    done()

describe 'DELETE /db/course_instance/:id/members', ->

  beforeEach utils.wrap (done) ->
    utils.clearModels([CourseInstance, Course, User, Classroom, Prepaid])

    # create, login user
    @teacher = yield utils.initUser({role: 'teacher'})
    yield utils.loginUser(@teacher)

    # create student, course, classroom and course instance
    @student = yield utils.initUser()
    courseData = _.extend({free: true}, courseFixture)
    @course = yield new Course(courseData).save()
    classroomData = _.extend({}, classroomFixture, {ownerID: @teacher._id, members: [@student._id]})
    @classroom = yield new Classroom(classroomData).save()
    url = getURL('/db/course_instance')
    data = {
      name: 'Some Name'
      courseID: @course.id
      classroomID: @classroom.id
    }
    [res, body] = yield request.postAsync {uri: url, json: data}
    @courseInstance = yield CourseInstance.findById res.body._id

    # add user to course instance
    url = getURL("/db/course_instance/#{@courseInstance.id}/members")
    [res, body] = yield request.postAsync {uri: url, json: {userID: @student.id}}
    @prepaid = yield new Prepaid({
      type: 'course'
      maxRedeemers: 10
      redeemers: []
    }).save()
    done()

  it 'removes a member to the given CourseInstance', utils.wrap (done) ->
    url = getURL("/db/course_instance/#{@courseInstance.id}/members")
    [res, body] = yield request.delAsync {uri: url, json: {userID: @student.id}}
    expect(res.statusCode).toBe(200)
    expect(res.body.members.length).toBe(0)
    done()

  it 'removes the CourseInstance from the User.courseInstances', utils.wrap (done) ->
    url = getURL("/db/course_instance/#{@courseInstance.id}/members")
    user = yield User.findById(@student.id)
    expect(_.size(user.get('courseInstances'))).toBe(1)
    [res, body] = yield request.delAsync {uri: url, json: {userID: @student.id}}
    expect(res.statusCode).toBe(200)
    expect(res.body.members.length).toBe(0)
    user = yield User.findById(@student.id)
    expect(_.size(user.get('courseInstances'))).toBe(0)
    done()

describe 'GET /db/course_instance/:handle/levels/:levelOriginal/next', ->

  beforeEach utils.wrap (done) ->
    yield utils.clearModels [User, Classroom, Course, Level, Campaign]
    admin = yield utils.initAdmin()
    yield utils.loginUser(admin)
    teacher = yield utils.initUser({role: 'teacher'})

    levelJSON = { name: 'A', permissions: [{access: 'owner', target: admin.id}], type: 'course' }
    [res, body] = yield request.postAsync({uri: getURL('/db/level'), json: levelJSON})
    expect(res.statusCode).toBe(200)
    @levelA = yield Level.findById(res.body._id)
    paredLevelA = _.pick(res.body, 'name', 'original', 'type')

    @sessionA = new LevelSession
      creator: teacher.id
      level: original: @levelA.get('original').toString()
      permissions: simplePermissions
      state: complete: true
    yield @sessionA.save()

    levelJSON = { name: 'B', permissions: [{access: 'owner', target: admin.id}], type: 'course' }
    [res, body] = yield request.postAsync({uri: getURL('/db/level'), json: levelJSON})
    expect(res.statusCode).toBe(200)
    @levelB = yield Level.findById(res.body._id)
    paredLevelB = _.pick(res.body, 'name', 'original', 'type')

    @sessionB = new LevelSession
      creator: teacher.id
      level: original: @levelB.get('original').toString()
      permissions: simplePermissions
    yield @sessionB.save()

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

    yield utils.loginUser(teacher)
    data = { name: 'Classroom 1' }
    classroomsURL = getURL('/db/classroom')
    [res, body] = yield request.postAsync {uri: classroomsURL, json: data }
    expect(res.statusCode).toBe(201)
    @classroom = yield Classroom.findById(res.body._id)

    url = getURL('/db/course_instance')

    dataA = { name: 'Some Name', courseID: @courseA.id, classroomID: @classroom.id }
    [res, body] = yield request.postAsync {uri: url, json: dataA}
    expect(res.statusCode).toBe(200)
    @courseInstanceA = yield CourseInstance.findById(res.body._id)

    dataB = { name: 'Some Other Name', courseID: @courseB.id, classroomID: @classroom.id }
    [res, body] = yield request.postAsync {uri: url, json: dataB}
    expect(res.statusCode).toBe(200)
    @courseInstanceB = yield CourseInstance.findById(res.body._id)

    done()

  it 'returns the next level for the course in the linked classroom', utils.wrap (done) ->
    [res, body] = yield request.getAsync { uri: utils.getURL("/db/course_instance/#{@courseInstanceA.id}/levels/#{@levelA.id}/sessions/#{@sessionA.id}/next"), json: true }
    expect(res.statusCode).toBe(200)
    expect(res.body.original).toBe(@levelB.original.toString())
    done()

  it 'returns empty object if the given level is the last level in its course', utils.wrap (done) ->
    [res, body] = yield request.getAsync { uri: utils.getURL("/db/course_instance/#{@courseInstanceA.id}/levels/#{@levelB.id}/sessions/#{@sessionB.id}/next"), json: true }
    expect(res.statusCode).toBe(200)
    expect(res.body).toEqual({})
    done()

  it 'returns 404 if the given level is not in the course instance\'s course', utils.wrap (done) ->
    [res, body] = yield request.getAsync { uri: utils.getURL("/db/course_instance/#{@courseInstanceB.id}/levels/#{@levelA.id}/sessions/#{@sessionA.id}/next"), json: true }
    expect(res.statusCode).toBe(404)
    done()


describe 'GET /db/course_instance/:handle/classroom', ->

  beforeEach utils.wrap (done) ->
    yield utils.clearModels [User, CourseInstance, Classroom]
    @owner = yield utils.initUser()
    yield @owner.save()
    @member = yield utils.initUser()
    yield @member.save()
    @classroom = new Classroom({
      ownerID: @owner._id
      members: [@member._id]
    })
    yield @classroom.save()
    @courseInstance = new CourseInstance({classroomID: @classroom._id})
    yield @courseInstance.save()
    @url = getURL("/db/course_instance/#{@courseInstance.id}/classroom")
    done()

  it 'returns the course instance\'s referenced classroom', utils.wrap (done) ->
    yield utils.loginUser @owner
    [res, body] = yield request.getAsync(@url, {json: true})
    expect(res.statusCode).toBe(200)
    expect(body.code).toBeDefined()
    done()

  it 'works if you are the owner or member', utils.wrap (done) ->
    yield utils.loginUser @member
    [res, body] = yield request.getAsync(@url, {json: true})
    expect(res.statusCode).toBe(200)
    expect(body.code).toBeUndefined()
    done()

  it 'does not work if you are not the owner or a member', utils.wrap (done) ->
    @user = yield utils.initUser()
    yield utils.loginUser @user
    [res, body] = yield request.getAsync(@url, {json: true})
    expect(res.statusCode).toBe(403)
    done()

describe 'POST /db/course_instance/-/recent', ->

  url = getURL('/db/course_instance/-/recent')

  beforeEach utils.wrap (done) ->
    yield utils.clearModels([CourseInstance, Course, User, Classroom, Prepaid, Campaign, Level])
    @teacher = yield utils.initUser({role: 'teacher'})
    @admin = yield utils.initAdmin()
    yield utils.loginUser(@admin)
    @campaign = yield utils.makeCampaign()
    @course = yield utils.makeCourse({free: true}, {campaign: @campaign})
    @student = yield utils.initUser({role: 'student'})
    @prepaid = yield utils.makePrepaid({creator: @teacher.id})
    members = [@student]
    yield utils.loginUser(@teacher)
    @classroom = yield utils.makeClassroom({aceConfig: { language: 'javascript' }}, { members })
    @courseInstance = yield utils.makeCourseInstance({}, { @course, @classroom, members })
    [res, body] = yield request.postAsync({url: getURL("/db/prepaid/#{@prepaid.id}/redeemers"), json: { userID: @student.id} })
    yield utils.loginUser(@admin)
    done()

  it 'returns all non-HoC course instances and their related users and prepaids', utils.wrap (done) ->
    [res, body] = yield request.postAsync(url, { json: true })
    expect(res.statusCode).toBe(200)
    expect(res.body.courseInstances[0]._id).toBe(@courseInstance.id)
    expect(res.body.students[0]._id).toBe(@student.id)
    expect(res.body.prepaids[0]._id).toBe(@prepaid.id)
    done()

  it 'returns course instances within a specified range', utils.wrap (done) ->
    startDay = moment().subtract(1, 'day').format('YYYY-MM-DD')
    endDay = moment().add(1, 'day').format('YYYY-MM-DD')
    [res, body] = yield request.postAsync(url, { json: { startDay, endDay } })
    expect(res.body.courseInstances.length).toBe(1)

    startDay = moment().add(1, 'day').format('YYYY-MM-DD')
    endDay = moment().add(2, 'day').format('YYYY-MM-DD')
    [res, body] = yield request.postAsync(url, { json: { startDay, endDay } })
    expect(res.body.courseInstances.length).toBe(0)

    startDay = moment().subtract(2, 'day').format('YYYY-MM-DD')
    endDay = moment().subtract(1, 'day').format('YYYY-MM-DD')
    [res, body] = yield request.postAsync(url, { json: { startDay, endDay } })
    expect(res.body.courseInstances.length).toBe(0)

    done()

  it 'returns 403 if not an admin', utils.wrap (done) ->
    yield utils.loginUser(@teacher)
    [res, body] = yield request.postAsync(url, { json: true })
    expect(res.statusCode).toBe(403)
    done()
