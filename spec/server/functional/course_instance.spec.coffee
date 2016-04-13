async = require 'async'
config = require '../../../server_config'
require '../common'
stripe = require('stripe')(config.stripe.secretKey)
utils = require '../utils'
CourseInstance = require '../../../server/models/CourseInstance'
Course = require '../../../server/models/Course'
User = require '../../../server/models/User'
Classroom = require '../../../server/models/Classroom'
Prepaid = require '../../../server/models/Prepaid'
request = require '../request'

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
    utils.clearModels([CourseInstance, Course, User, Classroom, Prepaid])
    @teacher = yield utils.initUser({role: 'teacher'})
    yield utils.loginUser(@teacher)
    courseData = _.extend({free: true}, courseFixture)
    @course = yield new Course(courseData).save()
    classroomData = _.extend({ownerID: @teacher._id}, classroomFixture)
    @classroom = yield new Classroom(classroomData).save()
    url = getURL('/db/course_instance')
    data = {
      name: 'Some Name'
      courseID: @course.id
      classroomID: @classroom.id
    }
    [res, body] = yield request.postAsync {uri: url, json: data}
    @courseInstance = yield CourseInstance.findById res.body._id
    @student = yield utils.initUser()
    @prepaid = yield new Prepaid({
      type: 'course'
      maxRedeemers: 10
      redeemers: []
    }).save()
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
    @classroom.set('members', [@student._id])
    yield @classroom.save()
    url = getURL("/db/course_instance/#{@courseInstance.id}/members")
    [res, body] = yield request.postAsync {uri: url, json: {userID: @student.id}}
    expect(res.statusCode).toBe(200)
    expect(res.body.members.length).toBe(1)
    expect(res.body.members[0]).toBe(@student.id)
    done()

  it 'adds the CourseInstance id to the user', utils.wrap (done) ->
    @classroom.set('members', [@student._id])
    yield @classroom.save()
    url = getURL("/db/course_instance/#{@courseInstance.id}/members")
    [res, body] = yield request.postAsync {uri: url, json: {userID: @student.id}}
    user = yield User.findById(@student.id)
    expect(_.size(user.get('courseInstances'))).toBe(1)
    done()

  it 'return 403 if the member is not in the classroom', utils.wrap (done) ->
    url = getURL("/db/course_instance/#{@courseInstance.id}/members")
    [res, body] = yield request.postAsync {uri: url, json: {userID: @student.id}}
    expect(res.statusCode).toBe(403)
    done()

  it 'returns 403 if the user does not own the course instance and is not adding self', utils.wrap (done) ->
    @classroom.set('members', [@student._id])
    yield @classroom.save()
    otherUser = yield utils.initUser()
    yield utils.loginUser(otherUser)
    url = getURL("/db/course_instance/#{@courseInstance.id}/members")
    [res, body] = yield request.postAsync {uri: url, json: {userID: @student.id}}
    expect(res.statusCode).toBe(403)
    done()

  it 'returns 200 if the user is a member of the classroom and is adding self', ->

  it 'return 402 if the course is not free and the user is not in a prepaid', utils.wrap (done) ->
    @classroom.set('members', [@student._id])
    yield @classroom.save()
    @course.set('free', false)
    yield @course.save()
    url = getURL("/db/course_instance/#{@courseInstance.id}/members")
    [res, body] = yield request.postAsync {uri: url, json: {userID: @student.id}}
    expect(res.statusCode).toBe(402)
    done()
          
  it 'works if the course is not free and the user is in a prepaid', utils.wrap (done) ->
    @classroom.set('members', [@student._id])
    yield @classroom.save()
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