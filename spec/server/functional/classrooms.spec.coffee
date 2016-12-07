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
    clearModels [User, Classroom, Course, Campaign], (err) ->
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
    levelJSONJSPrimer1 = { name: 'JS Primer 1', permissions: [{access: 'owner', target: admin.id}], type: 'hero', primerLanguage: 'javascript' }
    [res, body] = yield request.postAsync({uri: getURL('/db/level'), json: levelJSONJSPrimer1})
    expect(res.statusCode).toBe(200)
    @levelJSPrimer1 = yield Level.findById(res.body._id)

    campaignJSON = { name: 'Campaign', levels: {} }
    paredLevelJSPrimer1 = _.pick(@levelJSPrimer1.toObject(), 'name', 'original', 'type', 'slug', 'primerLanguage')
    paredLevelJSPrimer1.campaignIndex = 3
    campaignJSON.levels[@levelJSPrimer1.get('original').toString()] = paredLevelJSPrimer1
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
    @course = Course({name: 'Course', campaignID: @campaign._id, releasePhase: 'released'})
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

  describe 'when javascript classroom', ->

    beforeEach utils.wrap (done) ->
      teacher = yield utils.initUser({role: 'teacher'})
      yield utils.loginUser(teacher)
      data = { name: 'Classroom 2', aceConfig: { language: 'javascript' }   }
      [res, body] = yield request.postAsync {uri: classroomsURL, json: data }
      @classroom = yield Classroom.findById(res.body._id)
      done()

    it 'makes a copy of the list of all levels in all courses', utils.wrap (done) ->
      expect(@classroom.get('courses')[0].levels.length).toEqual(3)
      expect(@classroom.get('courses')[0].levels[0].original.toString()).toBe(@levelA.get('original').toString())
      expect(@classroom.get('courses')[0].levels[0].type).toBe('course')
      expect(@classroom.get('courses')[0].levels[0].slug).toBe('level-a')
      expect(@classroom.get('courses')[0].levels[0].name).toBe('Level A')
      done()

  describe 'when python classroom', ->

    beforeEach utils.wrap (done) ->
      teacher = yield utils.initUser({role: 'teacher'})
      yield utils.loginUser(teacher)
      data = { name: 'Classroom 2', aceConfig: { language: 'python' }   }
      [res, body] = yield request.postAsync {uri: classroomsURL, json: data }
      @classroom = yield Classroom.findById(res.body._id)
      done()

    it 'makes a copy all levels in all courses', utils.wrap (done) ->
      expect(@classroom.get('courses')[0].levels.length).toEqual(4)
      expect(@classroom.get('courses')[0].levels[0].original.toString()).toBe(@levelA.get('original').toString())
      expect(@classroom.get('courses')[0].levels[0].type).toBe('course')
      expect(@classroom.get('courses')[0].levels[0].slug).toBe('level-a')
      expect(@classroom.get('courses')[0].levels[0].name).toBe('Level A')
      done()


  describe 'when there are unreleased courses', ->
    beforeEach utils.wrap (done) ->
      admin = yield utils.initAdmin()
      yield utils.loginUser(admin)

      betaLevelJSON = { name: 'Beta Level', permissions: [{access: 'owner', target: admin.id}], type: 'course' }
      [res, body] = yield request.postAsync({uri: getURL('/db/level'), json: betaLevelJSON})
      expect(res.statusCode).toBe(200)
      @betaLevel = yield Level.findById(res.body._id)

      betaCampaignJSON = { name: 'Beta Campaign', levels: {} }
      paredBetaLevel = _.pick(@betaLevel.toObject(), 'name', 'original', 'type', 'slug')
      paredBetaLevel.campaignIndex = 0
      betaCampaignJSON.levels[@betaLevel.get('original').toString()] = paredBetaLevel

      [res, body] = yield request.postAsync({uri: getURL('/db/campaign'), json: betaCampaignJSON})
      @betaCampaign = yield Campaign.findById(res.body._id)
      @betaCourse = Course({name: 'Beta Course', campaignID: @betaCampaign._id, releasePhase: 'beta'})
      yield @betaCourse.save()
      done()

    it 'includes unreleased courses for admin teachers', utils.wrap (done) ->
      adminTeacher = yield utils.initUser({ role: 'teacher', permissions: ['admin'] })
      yield utils.loginUser(adminTeacher)
      data = { name: 'Classroom 3' }
      [res, body] = yield request.postAsync {uri: classroomsURL, json: data }
      classroom = yield Classroom.findById(res.body._id)
      expect(classroom.get('courses').length).toBe(2)
      expect(classroom.get('courses')[0].levels[0].original.toString()).toBe(@levelA.get('original').toString())
      expect(classroom.get('courses')[0].levels[0].type).toBe('course')
      expect(classroom.get('courses')[0].levels[0].slug).toBe('level-a')
      expect(classroom.get('courses')[0].levels[0].name).toBe('Level A')
      expect(classroom.get('courses')[1].levels[0].original.toString()).toBe(@betaLevel.get('original').toString())
      expect(classroom.get('courses')[1].levels[0].type).toBe('course')
      expect(classroom.get('courses')[1].levels[0].slug).toBe('beta-level')
      expect(classroom.get('courses')[1].levels[0].name).toBe('Beta Level')
      done()

    it 'does not include unreleased courses for non-admin teachers', utils.wrap (done) ->
      teacher = yield utils.initUser({role: 'teacher'})
      yield utils.loginUser(teacher)
      data = { name: 'Classroom 4' }
      [res, body] = yield request.postAsync {uri: classroomsURL, json: data }
      classroom = yield Classroom.findById(res.body._id)
      expect(classroom.get('courses').length).toBe(1)
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

    levelJSON = { name: 'JS Primer 1', permissions: [{access: 'owner', target: admin.id}], type: 'course', primerLanguage: 'javascript' }
    [res, body] = yield request.postAsync({uri: getURL('/db/level'), json: levelJSON})
    expect(res.statusCode).toBe(200)
    @levelJSPrimer1 = yield Level.findById(res.body._id)
    paredLevelJSPrimer1 = _.pick(res.body, 'name', 'original', 'type')

    campaignJSONA = { name: 'Campaign A', levels: {} }
    campaignJSONA.levels[paredLevelA.original] = paredLevelA
    [res, body] = yield request.postAsync({uri: getURL('/db/campaign'), json: campaignJSONA})
    @campaignA = yield Campaign.findById(res.body._id)

    campaignJSONB = { name: 'Campaign B', levels: {} }
    campaignJSONB.levels[paredLevelB.original] = paredLevelB
    campaignJSONB.levels[paredLevelJSPrimer1.original] = paredLevelJSPrimer1
    [res, body] = yield request.postAsync({uri: getURL('/db/campaign'), json: campaignJSONB})
    @campaignB = yield Campaign.findById(res.body._id)

    @courseA = Course({name: 'Course A', campaignID: @campaignA._id, releasePhase: 'released'})
    yield @courseA.save()

    @courseB = Course({name: 'Course B', campaignID: @campaignB._id, releasePhase: 'released'})
    yield @courseB.save()

    done()

  describe 'when javascript classroom', ->

    beforeEach utils.wrap (done) ->
      teacher = yield utils.initUser({role: 'teacher'})
      yield utils.loginUser(teacher)
      data = { name: 'Classroom 1', aceConfig: { language: 'javascript' } }
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

  describe 'when python classroom', ->

    beforeEach utils.wrap (done) ->
      teacher = yield utils.initUser({role: 'teacher'})
      yield utils.loginUser(teacher)
      data = { name: 'Classroom 1', aceConfig: { language: 'python' } }
      [res, body] = yield request.postAsync {uri: classroomsURL, json: data }
      expect(res.statusCode).toBe(201)
      @classroom = yield Classroom.findById(res.body._id)
      done()

    it 'returns all levels referenced in in the classroom\'s copy of course levels', utils.wrap (done) ->
      [res, body] = yield request.getAsync { uri: getURL("/db/classroom/#{@classroom.id}/levels"), json: true }
      expect(res.statusCode).toBe(200)
      levels = res.body
      expect(levels.length).toBe(3)

      [res, body] = yield request.getAsync { uri: getURL("/db/classroom/#{@classroom.id}/courses/#{@courseA.id}/levels"), json: true }
      expect(res.statusCode).toBe(200)
      levels = res.body
      expect(levels.length).toBe(1)
      expect(levels[0].original).toBe(@levelA.get('original').toString())

      [res, body] = yield request.getAsync { uri: getURL("/db/classroom/#{@classroom.id}/courses/#{@courseB.id}/levels"), json: true }
      expect(res.statusCode).toBe(200)
      levels = res.body
      expect(levels.length).toBe(2)
      expect(levels[0].original).toBe(@levelB.get('original').toString())
      expect(levels[1].original).toBe(@levelJSPrimer1.get('original').toString())

      done()

describe 'PUT /db/classroom/:handle', ->

  beforeEach utils.wrap (done) ->
    yield utils.clearModels([User, Classroom])
    teacher = yield utils.initUser({role: 'teacher'})
    yield utils.loginUser(teacher)
    @classroom = yield utils.makeClassroom()
    @url = utils.getURL("/db/classroom/#{@classroom.id}")
    done()

  it 'edits name and description', utils.wrap (done) ->
    json = { name: 'New Name!', description: 'New Description' }
    [res, body] = yield request.putAsync { @url, json }
    expect(body.name).toBe('New Name!')
    expect(body.description).toBe('New Description')
    done()
    
  it 'is not allowed if you are just a member', utils.wrap (done) ->
    student = yield utils.initUser()
    yield utils.loginUser(student)
    joinUrl = getURL("/db/classroom/~/members")
    joinJson = { code: @classroom.get('code') }
    [res, body] = yield request.postAsync { url: joinUrl, json: joinJson }
    expect(res.statusCode).toBe(200)

    json = { name: 'New Name!', description: 'New Description' }
    [res, body] = yield request.putAsync { @url, json }
    expect(res.statusCode).toBe(403)
    done()

describe 'POST /db/classroom/-/members', ->

  beforeEach utils.wrap (done) ->
    yield utils.clearModels([User, Classroom, Course, Campaign])
    @campaign = new Campaign({levels: {}})
    yield @campaign.save()
    @course = new Course({free: true, campaignID: @campaign._id, releasePhase: 'released'})
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

  beforeEach utils.wrap (done) ->
    yield utils.clearModels([User, Classroom])
    @teacher = yield utils.initUser({role: 'teacher'})
    yield utils.loginUser(@teacher)
    @student = yield utils.initUser()
    @classroom = yield utils.makeClassroom({}, {members:[@student]})
    @url = utils.getURL("/db/classroom/#{@classroom.id}/members")
    done()

  it 'removes the given user from the list of members in the classroom', utils.wrap (done) ->
    expect(@classroom.get('members').length).toBe(1)
    json = { userID: @student.id }
    [res, body] = yield request.delAsync { @url, json }
    expect(res.statusCode).toBe(200)
    classroom = yield Classroom.findById(@classroom.id)
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
    yield utils.clearModels([CourseInstance, Course, User, Classroom, Campaign, Level, LevelSession])
    @teacher = yield utils.initUser({role: 'teacher'})
    admin = yield utils.initAdmin()
    yield utils.loginUser(admin)
    @levelA = yield utils.makeLevel({type: 'course'})
    @levelB = yield utils.makeLevel({type: 'course', primerLanguage: 'python'})
    @campaignA = yield utils.makeCampaign({}, {levels: [@levelA]})
    @campaignB = yield utils.makeCampaign({}, {levels: [@levelB]})
    @courseA = yield utils.makeCourse({free: true, releasePhase: 'released'}, {campaign: @campaignA})
    @courseB = yield utils.makeCourse({free: true, releasePhase: 'released'}, {campaign: @campaignB})
    @student1 = yield utils.initUser({role: 'student'})
    @student2 = yield utils.initUser({role: 'student'})
    @session1A = yield utils.makeLevelSession({codeLanguage: 'javascript', state: { complete: true }}, {creator: @student1, level: @levelA})
    @session1B = yield utils.makeLevelSession({codeLanguage: 'python', state: { complete: false }}, {creator: @student1, level: @levelB})
    @session2A = yield utils.makeLevelSession({codeLanguage: 'javascript', state: { complete: true }}, {creator: @student2, level: @levelA})
    @session2B = yield utils.makeLevelSession({codeLanguage: 'python', state: { complete: false }}, {creator: @student2, level: @levelB})
    yield utils.loginUser(@teacher)
    @classroom = yield utils.makeClassroom({aceConfig: {language: 'javascript'}}, { members: [@student1, @student2] })
    @courseInstanceA = yield utils.makeCourseInstance({courseID: @courseA.id, classroomID: @classroom.id}, { members: [@student1, @student2] })
    @courseInstanceB = yield utils.makeCourseInstance({courseID: @courseB.id, classroomID: @classroom.id}, { members: [@student1] })
    yield utils.logout()
    done()

  it 'returns all sessions for all members in the classroom with assigned courses', utils.wrap (done) ->
    yield utils.loginUser(@teacher)
    [res, body] =  yield request.getAsync getURL("/db/classroom/#{@classroom.id}/member-sessions"), { json: true }
    expect(res.statusCode).toBe(200)
    expect(body.length).toBe(3)
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
    expect(body.length).toBe(1)
    expect(session.creator).toBe(@student2.id) for session in body
    done()

describe 'GET /db/classroom/:handle/members', ->

  beforeEach utils.wrap (done) ->
    yield utils.clearModels([User, Classroom])
    @teacher = yield utils.initUser()
    @student1 = yield utils.initUser({ name: "Firstname Lastname", firstName: "Firstname", lastName: "L" })
    @student2 = yield utils.initUser({ name: "Student Nameynamington", firstName: "Student", lastName: "N" })
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

  it 'returns all members with name, email, firstName and lastName', utils.wrap (done) ->
    yield utils.loginUser(@teacher)
    [res, body] = yield request.getAsync getURL("/db/classroom/#{@classroom.id}/members?name=true&email=true"), { json: true }
    expect(res.statusCode).toBe(200)
    expect(body.length).toBe(2)
    for user in body
      expect(user.name).toBeDefined()
      expect(user.email).toBeDefined()
      expect(user.firstName).toBeDefined()
      expect(user.lastName).toBeDefined()
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

describe 'GET /db/classroom/:handle/update-courses', ->

  it 'updates the courses property for that classroom', utils.wrap (done) ->
    yield utils.clearModels [User, Classroom, Course, Level, Campaign]

    admin = yield utils.initAdmin()
    teacher = yield utils.initUser({role: 'teacher'})

    # make a single course
    yield utils.loginUser(admin)
    yield utils.makeCourse({releasePhase: 'released'}, {campaign: yield utils.makeCampaign()})

    # make a classroom, make sure it has the one course
    yield utils.loginUser(teacher)
    data = { name: 'Classroom 2' }
    [res, body] = yield request.postAsync {uri: classroomsURL, json: data }
    classroom = yield Classroom.findById(res.body._id)
    expect(classroom.get('courses').length).toBe(1)

    # make a second course
    yield utils.loginUser(admin)
    yield utils.makeCourse({releasePhase: 'released'}, {campaign: yield utils.makeCampaign()})

    # make sure classroom still has one course
    classroom = yield Classroom.findById(res.body._id)
    expect(classroom.get('courses').length).toBe(1)

    # update, check update happens
    yield utils.loginUser(teacher)
    [res, body] = yield request.postAsync { uri: classroomsURL + "/#{classroom.id}/update-courses", json: true }
    expect(body.courses.length).toBe(2)
    classroom = yield Classroom.findById(res.body._id)
    expect(classroom.get('courses').length).toBe(2)

    done()

  it 'allows admins to also update a classroom, but uses the owner\'s admin status', utils.wrap (done) ->
    yield utils.clearModels [User, Classroom, Course, Level, Campaign]

    admin = yield utils.initAdmin()
    teacher = yield utils.initUser({role: 'teacher'})

    # make two courses, one released, one beta
    yield utils.loginUser(admin)
    yield utils.makeCourse({releasePhase: 'released'}, {campaign: yield utils.makeCampaign()})
    yield utils.makeCourse({releasePhase: 'beta'}, {campaign: yield utils.makeCampaign()})

    # make a classroom, make sure it has the one course
    yield utils.loginUser(teacher)
    data = { name: 'Classroom 2' }
    [res, body] = yield request.postAsync {uri: classroomsURL, json: data }
    classroom = yield Classroom.findById(res.body._id)
    expect(classroom.get('courses').length).toBe(1)

    # make another released course
    yield utils.loginUser(admin)
    yield utils.makeCourse({releasePhase: 'released'}, {campaign: yield utils.makeCampaign()})

    # make sure classroom still has one course
    classroom = yield Classroom.findById(res.body._id)
    expect(classroom.get('courses').length).toBe(1)

    # update, check that classroom has the two released courses
    [res, body] = yield request.postAsync { uri: classroomsURL + "/#{classroom.id}/update-courses", json: true }
    expect(body.courses.length).toBe(2)
    classroom = yield Classroom.findById(res.body._id)
    expect(classroom.get('courses').length).toBe(2)

    done()

  describe 'addNewCoursesOnly', ->
    it 'only adds new courses, but leaves existing courses intact', utils.wrap (done) ->
      yield utils.clearModels [User, Classroom, Course, Level, Campaign]

      admin = yield utils.initAdmin()
      teacher = yield utils.initUser({role: 'teacher'})
  
      # make a single course
      yield utils.loginUser(admin)
      levels = yield _.times(3, -> utils.makeLevel())
      firstCampaign = yield utils.makeCampaign({}, {levels: [levels[0]]})
      yield utils.makeCourse({releasePhase: 'released'}, {campaign: firstCampaign})
  
      # make a classroom, make sure it has the one course
      yield utils.loginUser(teacher)
      data = { name: 'Classroom 2' }
      [res, body] = yield request.postAsync {uri: classroomsURL, json: data }
      classroom = yield Classroom.findById(res.body._id)
      expect(classroom.get('courses').length).toBe(1)
      expect(classroom.get('courses')[0].levels.length).toBe(1)
      
      # make a second course
      yield utils.loginUser(admin)
      yield utils.makeCourse({releasePhase: 'released'}, {campaign: yield utils.makeCampaign({}, {levels: [levels[1]]})})
      
      # add level to first course
      campaignSchema = require '../../../app/schemas/models/campaign.schema'
      campaignLevelProperties = _.keys(campaignSchema.properties.levels.additionalProperties.properties)
      levelAdding = levels[2]
      campaignLevels = _.clone(firstCampaign.get('levels'))
      campaignLevels[levelAdding.get('original').valueOf()] = _.pick levelAdding.toObject(), campaignLevelProperties
      yield firstCampaign.update({$set: {levels: campaignLevels}})
  
      # make sure classroom still has one course
      classroom = yield Classroom.findById(res.body._id)
      expect(classroom.get('courses').length).toBe(1)
  
      # update with addNewCoursesOnly, make sure second course is added but first keeps the same # of levels
      yield utils.loginUser(teacher)
      [res, body] = yield request.postAsync { uri: classroomsURL + "/#{classroom.id}/update-courses", json: { addNewCoursesOnly:true } }
      expect(body.courses.length).toBe(2)
      classroom = yield Classroom.findById(res.body._id)
      expect(classroom.get('courses').length).toBe(2)
      expect(classroom.get('courses')[0].levels.length).toBe(1)

      # update without addNewCoursesOnly, make sure first course still updates
      [res, body] = yield request.postAsync { uri: classroomsURL + "/#{classroom.id}/update-courses", json: true }
      expect(body.courses.length).toBe(2)
      classroom = yield Classroom.findById(res.body._id)
      expect(classroom.get('courses').length).toBe(2)
      expect(classroom.get('courses')[0].levels.length).toBe(2)
      done()
