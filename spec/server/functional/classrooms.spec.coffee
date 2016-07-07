config = require '../../../server_config'
require '../common'
clientUtils = require '../../../app/core/utils' # Must come after require /common
utils = require '../utils'
_ = require 'lodash'
Promise = require 'bluebird'
request = require '../request'
requestAsync = Promise.promisify(request, {multiArgs: true})
User = require '../../../server/models/User'
Classroom = require '../../../server/models/Classroom'
Course = require '../../../server/models/Course'
CourseInstance = require '../../../server/models/CourseInstance'
Campaign = require '../../../server/models/Campaign'
LevelSession = require '../../../server/models/LevelSession'
Level = require '../../../server/models/Level'

classroomsURL = getURL('/db/classroom')

describe 'GET /db/classroom?ownerID=:id', ->
  
  beforeEach utils.wrap (done) ->
    yield utils.clearModels([User, Classroom])
    @user1 = yield utils.initUser()
    yield utils.loginUser(@user1)
    @classroom1 = yield new Classroom({name: 'Classroom 1', ownerID: @user1.get('_id') }).save()
    @user2 = yield utils.initUser()
    yield utils.loginUser(@user2)
    @classroom2 = yield new Classroom({name: 'Classroom 2', ownerID: @user2.get('_id') }).save()
    done()
      
  it 'returns an array of classrooms with the given owner', utils.wrap (done) ->
    [res, body] =  yield request.getAsync getURL('/db/classroom?ownerID='+@user2.id), { json: true }
    expect(res.statusCode).toBe(200)
    expect(body.length).toBe(1)
    expect(body[0].name).toBe('Classroom 2')
    done()
              
  it 'returns 403 when a non-admin tries to get classrooms for another user', utils.wrap (done) ->
    [res, body] =  yield request.getAsync getURL('/db/classroom?ownerID='+@user1.id), { json: true }
    expect(res.statusCode).toBe(403)
    done()
  

describe 'GET /db/classroom/:id', ->
  it 'clears database users and classrooms', (done) ->
    clearModels [User, Classroom], (err) ->
      throw err if err
      done()

  it 'returns the classroom for the given id', (done) ->
    loginNewUser (user1) ->
      user1.set('role', 'teacher')
      user1.save (err) ->
        data = { name: 'Classroom 1' }
        request.post {uri: classroomsURL, json: data }, (err, res, body) ->
          expect(res.statusCode).toBe(201)
          classroomID = body._id
          request.get {uri: classroomsURL + '/'  + body._id }, (err, res, body) ->
            expect(res.statusCode).toBe(200)
            expect(body._id).toBe(classroomID = body._id)
            done()

describe 'GET /db/classroom by classCode', ->
  it 'Returns the class if you include spaces', utils.wrap (done) ->
    user = yield utils.initUser()
    yield utils.loginUser(user)
    teacher = yield utils.initUser()
    classroom = new Classroom({ name: "some class", ownerID: teacher.id, camelCode: "FooBarBaz", code: "foobarbaz" })
    yield classroom.save()
    [res, body] = yield request.getAsync(getURL('/db/classroom?code=foo bar baz'), { json: true })
    expect(res.statusCode).toBe(200)
    expect(res.body.data?.name).toBe(classroom.get('name'))
    done()

describe 'POST /db/classroom', ->
  
  beforeEach utils.wrap (done) ->
    yield utils.clearModels [User, Classroom, Course, Level, Campaign]
    admin = yield utils.initAdmin()
    yield utils.loginUser(admin)
    levelJSONA = { name: 'Level A', permissions: [{access: 'owner', target: admin.id}], type: 'course' }
    [res, body] = yield request.postAsync({uri: getURL('/db/level'), json: levelJSONA})
    expect(res.statusCode).toBe(200)
    @levelA = yield Level.findById(res.body._id)
    levelJSONB = { name: 'Level B', permissions: [{access: 'owner', target: admin.id}], type: 'course' }
    [res, body] = yield request.postAsync({uri: getURL('/db/level'), json: levelJSONB})
    expect(res.statusCode).toBe(200)
    @levelB = yield Level.findById(res.body._id)
    levelJSONC = { name: 'Level C', permissions: [{access: 'owner', target: admin.id}], type: 'hero', practice: true }
    [res, body] = yield request.postAsync({uri: getURL('/db/level'), json: levelJSONC})
    expect(res.statusCode).toBe(200)
    @levelC = yield Level.findById(res.body._id)
    campaignJSON = { name: 'Campaign', levels: {} }
    paredLevelC = _.pick(@levelC.toObject(), 'name', 'original', 'type', 'slug', 'practice')
    paredLevelC.campaignIndex = 2
    campaignJSON.levels[@levelC.get('original').toString()] = paredLevelC
    paredLevelB = _.pick(@levelB.toObject(), 'name', 'original', 'type', 'slug')
    paredLevelB.campaignIndex = 1
    campaignJSON.levels[@levelB.get('original').toString()] = paredLevelB
    paredLevelA = _.pick(@levelA.toObject(), 'name', 'original', 'type', 'slug')
    paredLevelA.campaignIndex = 0
    campaignJSON.levels[@levelA.get('original').toString()] = paredLevelA
    [res, body] = yield request.postAsync({uri: getURL('/db/campaign'), json: campaignJSON})
    @campaign = yield Campaign.findById(res.body._id)
    @course = Course({name: 'Course', campaignID: @campaign._id})
    yield @course.save()
    done()
  
  it 'creates a new classroom for the given user with teacher role', utils.wrap (done) ->
    teacher = yield utils.initUser({role: 'teacher'})
    yield utils.loginUser(teacher)
    data = { name: 'Classroom 1' }
    [res, body] = yield request.postAsync {uri: classroomsURL, json: data }
    expect(res.statusCode).toBe(201)
    expect(res.body.name).toBe('Classroom 1')
    expect(res.body.members.length).toBe(0)
    expect(res.body.ownerID).toBe(teacher.id)
    done()
        
  it 'returns 401 for anonymous users', utils.wrap (done) ->
    yield utils.logout()
    data = { name: 'Classroom 2' }
    [res, body] = yield request.postAsync {uri: classroomsURL, json: data }
    expect(res.statusCode).toBe(401)
    done()

  it 'does not work for non-teacher users', utils.wrap (done) ->
    user = yield utils.initUser()
    yield utils.loginUser(user)
    data = { name: 'Classroom 1' }
    [res, body] = yield request.postAsync {uri: classroomsURL, json: data }
    expect(res.statusCode).toBe(403)
    done()

  it 'makes a copy of the list of all levels in all courses', utils.wrap (done) ->
    teacher = yield utils.initUser({role: 'teacher'})
    yield utils.loginUser(teacher)
    data = { name: 'Classroom 2' }
    [res, body] = yield request.postAsync {uri: classroomsURL, json: data }
    classroom = yield Classroom.findById(res.body._id)
    expect(classroom.get('courses')[0].levels[0].original.toString()).toBe(@levelA.get('original').toString())
    expect(classroom.get('courses')[0].levels[0].type).toBe('course')
    expect(classroom.get('courses')[0].levels[0].slug).toBe('level-a')
    expect(classroom.get('courses')[0].levels[0].name).toBe('Level A')
    done()

describe 'GET /db/classroom/:handle/levels', ->

  beforeEach utils.wrap (done) ->
    yield utils.clearModels [User, Classroom, Course, Level, Campaign]
    admin = yield utils.initAdmin()
    yield utils.loginUser(admin)
    levelJSON = { name: 'King\'s Peak 3', permissions: [{access: 'owner', target: admin.id}], type: 'course' }
    [res, body] = yield request.postAsync({uri: getURL('/db/level'), json: levelJSON})
    expect(res.statusCode).toBe(200)
    @level = yield Level.findById(res.body._id)
    campaignJSON = { name: 'Campaign', levels: {} }
    paredLevel = _.pick(res.body, 'name', 'original', 'type')
    campaignJSON.levels[res.body.original] = paredLevel
    [res, body] = yield request.postAsync({uri: getURL('/db/campaign'), json: campaignJSON})
    @campaign = yield Campaign.findById(res.body._id)
    @course = Course({name: 'Course', campaignID: @campaign._id})
    yield @course.save()
    teacher = yield utils.initUser({role: 'teacher'})
    yield utils.loginUser(teacher)
    data = { name: 'Classroom 1' }
    [res, body] = yield request.postAsync {uri: classroomsURL, json: data }
    expect(res.statusCode).toBe(201)
    @classroom = yield Classroom.findById(res.body._id)
    done()
  
  it 'returns all levels referenced in in the classroom\'s copy of course levels', utils.wrap (done) ->
    [res, body] = yield request.getAsync { uri: getURL("/db/classroom/#{@classroom.id}/levels"), json: true }
    expect(res.statusCode).toBe(200)
    levels = res.body
    expect(levels.length).toBe(1)
    expect(levels[0].name).toBe("King's Peak 3")
    done()

describe 'GET /db/classroom/:handle/levels', ->

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
    campaignJSONA.levels[paredLevelA.original] = paredLevelA
    [res, body] = yield request.postAsync({uri: getURL('/db/campaign'), json: campaignJSONA})
    @campaignA = yield Campaign.findById(res.body._id)

    campaignJSONB = { name: 'Campaign B', levels: {} }
    campaignJSONB.levels[paredLevelB.original] = paredLevelB
    [res, body] = yield request.postAsync({uri: getURL('/db/campaign'), json: campaignJSONB})
    @campaignB = yield Campaign.findById(res.body._id)
    
    @courseA = Course({name: 'Course A', campaignID: @campaignA._id})
    yield @courseA.save()

    @courseB = Course({name: 'Course B', campaignID: @campaignB._id})
    yield @courseB.save()

    teacher = yield utils.initUser({role: 'teacher'})
    yield utils.loginUser(teacher)
    data = { name: 'Classroom 1' }
    [res, body] = yield request.postAsync {uri: classroomsURL, json: data }
    expect(res.statusCode).toBe(201)
    @classroom = yield Classroom.findById(res.body._id)
    done()

  it 'returns all levels referenced in in the classroom\'s copy of course levels', utils.wrap (done) ->
    [res, body] = yield request.getAsync { uri: getURL("/db/classroom/#{@classroom.id}/levels"), json: true }
    expect(res.statusCode).toBe(200)
    levels = res.body
    expect(levels.length).toBe(2)

    [res, body] = yield request.getAsync { uri: getURL("/db/classroom/#{@classroom.id}/courses/#{@courseA.id}/levels"), json: true }
    expect(res.statusCode).toBe(200)
    levels = res.body
    expect(levels.length).toBe(1)
    expect(levels[0].original).toBe(@levelA.get('original').toString())

    [res, body] = yield request.getAsync { uri: getURL("/db/classroom/#{@classroom.id}/courses/#{@courseB.id}/levels"), json: true }
    expect(res.statusCode).toBe(200)
    levels = res.body
    expect(levels.length).toBe(1)
    expect(levels[0].original).toBe(@levelB.get('original').toString())
    
    done()


describe 'PUT /db/classroom', ->

  it 'clears database users and classrooms', (done) ->
    clearModels [User, Classroom], (err) ->
      throw err if err
      done()

  it 'edits name and description', (done) ->
    loginNewUser (user1) ->
      user1.set('role', 'teacher')
      user1.save (err) ->
        data = { name: 'Classroom 2' }
        request.post {uri: classroomsURL, json: data }, (err, res, body) ->
          expect(res.statusCode).toBe(201)
          data = { name: 'Classroom 3', description: 'New Description' }
          url = classroomsURL + '/' + body._id
          request.put { uri: url, json: data }, (err, res, body) ->
            expect(body.name).toBe('Classroom 3')
            expect(body.description).toBe('New Description')
            done()
          
  it 'is not allowed if you are just a member', (done) ->
    loginNewUser (user1) ->
      user1.set('role', 'teacher')
      user1.save (err) ->
        data = { name: 'Classroom 4' }
        request.post {uri: classroomsURL, json: data }, (err, res, body) ->
          expect(res.statusCode).toBe(201)
          classroomCode = body.code
          loginNewUser (user2) ->
            url = getURL("/db/classroom/~/members")
            data = { code: classroomCode }
            request.post { uri: url, json: data }, (err, res, body) ->
              expect(res.statusCode).toBe(200)
              url = classroomsURL + '/' + body._id
              request.put { uri: url, json: data }, (err, res, body) ->
                expect(res.statusCode).toBe(403)
                done()
            
describe 'POST /db/classroom/-/members', ->
  
  beforeEach utils.wrap (done) ->
    yield utils.clearModels([User, Classroom, Course, Campaign])
    @campaign = new Campaign({levels: {}})
    yield @campaign.save()
    @course = new Course({free: true, campaignID: @campaign._id})
    yield @course.save()
    @teacher = yield utils.initUser({role: 'teacher'})
    yield utils.loginUser(@teacher)
    [res, body] = yield request.postAsync({uri: classroomsURL, json: { name: 'Classroom 5' } })
    expect(res.statusCode).toBe(201)
    @classroom = yield Classroom.findById(body._id)
    [res, body] = yield request.postAsync({uri: getURL('/db/course_instance'), json: { courseID: @course.id, classroomID: @classroom.id }})
    expect(res.statusCode).toBe(200)
    @courseInstance = yield CourseInstance.findById(res.body._id)
    @student = yield utils.initUser()
    done()
    
  it 'adds the signed in user to the classroom and any free courses and sets role to student', utils.wrap (done) ->
    yield utils.loginUser(@student)
    url = getURL("/db/classroom/anything-here/members")
    [res, body] = yield request.postAsync { uri: url, json: { code: @classroom.get('code') } }
    expect(res.statusCode).toBe(200)
    classroom = yield Classroom.findById(@classroom.id)
    expect(classroom.get('members').length).toBe(1)
    expect(classroom.get('members')?[0]?.equals(@student._id)).toBe(true)
    student = yield User.findById(@student.id)
    if student.get('role') isnt 'student'
      fail('student role should be "student"')
    unless student.get('courseInstances')?[0].equals(@courseInstance._id)
      fail('student should be added to the free course instance.')
    done()
    
  it 'joins the class even with spaces in the classcode', utils.wrap (done) ->
    yield utils.loginUser(@student)
    url = getURL("/db/classroom/anything-here/members")
    code = @classroom.get('code')
    codeWithSpaces = code.split("").join(" ")
    [res, body] = yield request.postAsync { uri: url, json: { code: codeWithSpaces } }
    expect(res.statusCode).toBe(200)
    classroom = yield Classroom.findById(@classroom.id)
    if classroom.get('members').length isnt 1
      fail 'expected classCode with spaces to work too'
    done()

  it 'returns 403 if the user is a teacher', utils.wrap (done) ->
    yield utils.loginUser(@teacher)
    url = getURL("/db/classroom/~/members")
    [res, body] = yield request.postAsync { uri: url, json: { code: @classroom.get('code') } }
    expect(res.statusCode).toBe(403)
    done()
                  
  it 'returns 401 if the user is anonymous', utils.wrap (done) ->
    yield utils.becomeAnonymous()
    [res, body] = yield request.postAsync { uri: getURL("/db/classroom/-/members"), json: { code: @classroom.get('code') } }
    expect(res.statusCode).toBe(401)
    done()


describe 'DELETE /db/classroom/:id/members', ->

  it 'clears database users and classrooms', (done) ->
    clearModels [User, Classroom], (err) ->
      throw err if err
      done()

  it 'removes the given user from the list of members in the classroom', (done) ->
    loginNewUser (user1) ->
      user1.set('role', 'teacher')
      user1.save (err) ->
        data = { name: 'Classroom 6' }
        request.post {uri: classroomsURL, json: data }, (err, res, body) ->
          classroomCode = body.code
          classroomID = body._id
          expect(res.statusCode).toBe(201)
          loginNewUser (user2) ->
            url = getURL("/db/classroom/~/members")
            data = { code: classroomCode }
            request.post { uri: url, json: data }, (err, res, body) ->
              expect(res.statusCode).toBe(200)
              Classroom.findById classroomID, (err, classroom) ->
                expect(classroom.get('members').length).toBe(1)
                url = getURL("/db/classroom/#{classroom.id}/members")
                data = { userID: user2.id }
                request.del { uri: url, json: data }, (err, res, body) ->
                  expect(res.statusCode).toBe(200)
                  Classroom.findById classroomID, (err, classroom) ->
                    expect(classroom.get('members').length).toBe(0)
                    done()


describe 'POST /db/classroom/:id/invite-members', ->

  it 'takes a list of emails and sends invites', utils.wrap (done) ->
    user = yield utils.initUser({role: 'teacher', name: 'Mr Professerson'})
    yield utils.loginUser(user)
    classroom = yield utils.makeClassroom()
    url = classroomsURL + "/#{classroom.id}/invite-members"
    data = { emails: ['test@test.com'] }
    sendwithus = require '../../../server/sendwithus'
    spyOn(sendwithus.api, 'send').and.callFake (context, cb) ->
      expect(context.email_id).toBe(sendwithus.templates.course_invite_email)
      expect(context.recipient.address).toBe('test@test.com')
      expect(context.email_data.teacher_name).toBe('Mr Professerson')
      done()
    [res, body] = yield request.postAsync { uri: url, json: data }
    expect(res.statusCode).toBe(200)

          
describe 'GET /db/classroom/:handle/member-sessions', ->
  
  beforeEach utils.wrap (done) ->
    yield utils.clearModels([User, Classroom, LevelSession, Level])
    @artisan = yield utils.initUser()
    @teacher = yield utils.initUser()
    @student1 = yield utils.initUser()
    @student2 = yield utils.initUser()
    @levelA = new Level({name: 'Level A', permissions: [{target: @artisan._id, access: 'owner'}]})
    @levelA.set('original', @levelA._id)
    @levelA = yield @levelA.save()
    @levelB = new Level({name: 'Level B', permissions: [{target: @artisan._id, access: 'owner'}]})
    @levelB.set('original', @levelB._id)
    @levelB = yield @levelB.save()
    @classroom = yield new Classroom({name: 'Classroom', ownerID: @teacher._id, members: [@student1._id, @student2._id] }).save()
    @session1A = yield new LevelSession({creator: @student1.id, state: { complete: true }, level: {original: @levelA._id}, permissions: [{target: @student1._id, access: 'owner'}]}).save()
    @session1B = yield new LevelSession({creator: @student1.id, state: { complete: false }, level: {original: @levelB._id}, permissions: [{target: @student1._id, access: 'owner'}]}).save()
    @session2A = yield new LevelSession({creator: @student2.id, state: { complete: true }, level: {original: @levelA._id}, permissions: [{target: @student2._id, access: 'owner'}]}).save()
    @session2B = yield new LevelSession({creator: @student2.id, state: { complete: false }, level: {original: @levelB._id}, permissions: [{target: @student2._id, access: 'owner'}]}).save()
    done()

  it 'returns all sessions for all members in the classroom with only properties level, creator and state.complete', utils.wrap (done) ->
    yield utils.loginUser(@teacher)
    [res, body] =  yield request.getAsync getURL("/db/classroom/#{@classroom.id}/member-sessions"), { json: true }
    expect(res.statusCode).toBe(200)
    expect(body.length).toBe(4)
    done()
    
  it 'does not work if you are not the owner of the classroom', utils.wrap (done) ->
    yield utils.loginUser(@student1)
    [res, body] =  yield request.getAsync getURL("/db/classroom/#{@classroom.id}/member-sessions"), { json: true }
    expect(res.statusCode).toBe(403)
    done()
    
  it 'does not work if you are not logged in', utils.wrap (done) ->
    [res, body] =  yield request.getAsync getURL("/db/classroom/#{@classroom.id}/member-sessions"), { json: true }
    expect(res.statusCode).toBe(401)
    done()
    
  it 'accepts memberSkip and memberLimit GET parameters', utils.wrap (done) ->
    yield utils.loginUser(@teacher)
    [res, body] =  yield request.getAsync getURL("/db/classroom/#{@classroom.id}/member-sessions?memberLimit=1"), { json: true }
    expect(res.statusCode).toBe(200)
    expect(body.length).toBe(2)
    expect(session.creator).toBe(@student1.id) for session in body
    [res, body] =  yield request.getAsync getURL("/db/classroom/#{@classroom.id}/member-sessions?memberSkip=1"), { json: true }
    expect(res.statusCode).toBe(200)
    expect(body.length).toBe(2)
    expect(session.creator).toBe(@student2.id) for session in body
    done()
    
describe 'GET /db/classroom/:handle/members', ->
  
  beforeEach utils.wrap (done) ->
    yield utils.clearModels([User, Classroom])
    @teacher = yield utils.initUser()
    @student1 = yield utils.initUser({ name: "Firstname Lastname" })
    @student2 = yield utils.initUser({ name: "Student Nameynamington" })
    @classroom = yield new Classroom({name: 'Classroom', ownerID: @teacher._id, members: [@student1._id, @student2._id] }).save()
    @emptyClassroom = yield new Classroom({name: 'Empty Classroom', ownerID: @teacher._id, members: [] }).save()
    done()
    
  it 'does not work if you are not the owner of the classroom', utils.wrap (done) ->
    yield utils.loginUser(@student1)
    [res, body] =  yield request.getAsync getURL("/db/classroom/#{@classroom.id}/member-sessions"), { json: true }
    expect(res.statusCode).toBe(403)
    done()
    
  it 'does not work if you are not logged in', utils.wrap (done) ->
    [res, body] =  yield request.getAsync getURL("/db/classroom/#{@classroom.id}/member-sessions"), { json: true }
    expect(res.statusCode).toBe(401)
    done()
  
  it 'works on an empty classroom', utils.wrap (done) ->
    yield utils.loginUser(@teacher)
    [res, body] = yield request.getAsync getURL("/db/classroom/#{@emptyClassroom.id}/members?name=true&email=true"), { json: true }
    expect(res.statusCode).toBe(200)
    expect(body).toEqual([])
    done()
    
  it 'returns all members with name and email', utils.wrap (done) ->
    yield utils.loginUser(@teacher)
    [res, body] = yield request.getAsync getURL("/db/classroom/#{@classroom.id}/members?name=true&email=true"), { json: true }
    expect(res.statusCode).toBe(200)
    expect(body.length).toBe(2)
    for user in body
      expect(user.name).toBeDefined()
      expect(user.email).toBeDefined()
      expect(user.passwordHash).toBeUndefined()
    done()

describe 'POST /db/classroom/:classroomID/members/:memberID/reset-password', ->
  it 'changes the password', utils.wrap (done) ->
    yield utils.clearModels([User, Classroom])
    teacher = yield utils.initUser()
    yield utils.loginUser(teacher)
    student = yield utils.initUser({ name: "Firstname Lastname" })
    newPassword = "this is a new password"
    classroom = yield new Classroom({name: 'Classroom', ownerID: teacher._id, members: [student._id] }).save()
    expect(student.get('passwordHash')).not.toEqual(User.hashPassword(newPassword))
    [res, body] = yield request.postAsync({
      uri: getURL("/db/classroom/#{classroom.id}/members/#{student.id}/reset-password")
      json: { password: newPassword }
    })
    expect(res.statusCode).toBe(200)
    changedStudent = yield User.findById(student.id)
    expect(changedStudent.get('passwordHash')).toEqual(User.hashPassword(newPassword))
    done()

  it "doesn't change the password if you're not their teacher", utils.wrap (done) ->
    yield utils.clearModels([User, Classroom])
    teacher = yield utils.initUser()
    yield utils.loginUser(teacher)
    student = yield utils.initUser({ name: "Firstname Lastname" })
    student2 = yield utils.initUser({ name: "Firstname Lastname 2" })
    newPassword = "this is a new password"
    classroom = yield new Classroom({name: 'Classroom', ownerID: teacher._id, members: [student2._id] }).save()
    expect(student.get('passwordHash')).not.toEqual(User.hashPassword(newPassword))
    [res, body] = yield request.postAsync({
      uri: getURL("/db/classroom/#{classroom.id}/members/#{student.id}/reset-password")
      json: { password: newPassword }
    })
    expect(res.statusCode).toBe(403)
    changedStudent = yield User.findById(student.id)
    expect(changedStudent.get('passwordHash')).toEqual(student.get('passwordHash'))
    done()

  it "doesn't change the password if their email is verified", utils.wrap (done) ->
    yield utils.clearModels([User, Classroom])
    teacher = yield utils.initUser()
    yield utils.loginUser(teacher)
    student = yield utils.initUser({ name: "Firstname Lastname", emailVerified: true })
    newPassword = "this is a new password"
    classroom = yield new Classroom({name: 'Classroom', ownerID: teacher._id, members: [student._id] }).save()
    expect(student.get('passwordHash')).not.toEqual(User.hashPassword(newPassword))
    [res, body] = yield request.postAsync({
      uri: getURL("/db/classroom/#{classroom.id}/members/#{student.id}/reset-password")
      json: { password: newPassword }
    })
    expect(res.statusCode).toBe(403)
    changedStudent = yield User.findById(student.id)
    expect(changedStudent.get('passwordHash')).toEqual(student.get('passwordHash'))
    done()

  it "doesn't let you set a 1-character password", utils.wrap (done) ->
    yield utils.clearModels([User, Classroom])
    teacher = yield utils.initUser()
    yield utils.loginUser(teacher)
    student = yield utils.initUser({ name: "Firstname Lastname" })
    newPassword = "e"
    classroom = yield new Classroom({name: 'Classroom', ownerID: teacher._id, members: [student._id] }).save()
    expect(student.get('passwordHash')).not.toEqual(User.hashPassword(newPassword))
    [res, body] = yield request.postAsync({
      uri: getURL("/db/classroom/#{classroom.id}/members/#{student.id}/reset-password")
      json: { password: newPassword }
    })
    expect(res.statusCode).toBe(422)
    changedStudent = yield User.findById(student.id)
    expect(changedStudent.get('passwordHash')).toEqual(student.get('passwordHash'))
    done()
