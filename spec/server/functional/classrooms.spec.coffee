config = require '../../../server_config'
require '../common'
clientUtils = require '../../../app/core/utils' # Must come after require /common
mongoose = require 'mongoose'
utils = require '../utils'
_ = require 'lodash'
Promise = require 'bluebird'
requestAsync = Promise.promisify(request, {multiArgs: true})

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
          expect(res.statusCode).toBe(200)
          classroomID = body._id
          request.get {uri: classroomsURL + '/'  + body._id }, (err, res, body) ->
            expect(res.statusCode).toBe(200)
            expect(body._id).toBe(classroomID = body._id)
            done()

describe 'POST /db/classroom', ->

  it 'clears database users and classrooms', (done) ->
    clearModels [User, Classroom], (err) ->
      throw err if err
      done()

  it 'creates a new classroom for the given user', (done) ->
    loginNewUser (user1) ->
      user1.set('role', 'teacher')
      user1.save (err) ->
        data = { name: 'Classroom 1' }
        request.post {uri: classroomsURL, json: data }, (err, res, body) ->
          expect(res.statusCode).toBe(200)
          expect(body.name).toBe('Classroom 1')
          expect(body.members.length).toBe(0)
          expect(body.ownerID).toBe(user1.id)
          done()

  it 'does not work for anonymous users', (done) ->
    logoutUser ->
      data = { name: 'Classroom 2' }
      request.post {uri: classroomsURL, json: data }, (err, res, body) ->
        expect(res.statusCode).toBe(401)
        done()

  it 'does not work for non-teacher users', (done) ->
    loginNewUser (user1) ->
      data = { name: 'Classroom 1' }
      request.post {uri: classroomsURL, json: data }, (err, res, body) ->
        expect(res.statusCode).toBe(403)
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
          expect(res.statusCode).toBe(200)
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
          expect(res.statusCode).toBe(200)
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

describe 'POST /db/classroom/~/members', ->

  it 'clears database users and classrooms', (done) ->
    clearModels [User, Classroom], (err) ->
      throw err if err
      done()

  it 'adds the signed in user to the list of members in the classroom', (done) ->
    loginNewUser (user1) ->
      user1.set('role', 'teacher')
      user1.save (err) ->
        data = { name: 'Classroom 5' }
        request.post {uri: classroomsURL, json: data }, (err, res, body) ->
          classroomCode = body.code
          classroomID = body._id
          expect(res.statusCode).toBe(200)
          loginNewUser (user2) ->
            url = getURL("/db/classroom/~/members")
            data = { code: classroomCode }
            request.post { uri: url, json: data }, (err, res, body) ->
              expect(res.statusCode).toBe(200)
              Classroom.findById classroomID, (err, classroom) ->
                expect(classroom.get('members').length).toBe(1)
                expect(classroom.get('members')?[0]?.equals(user2.get('_id'))).toBe(true)
                User.findById user2.get('_id'), (err, user2) ->
                  expect(user2.get('role')).toBe('student')
                  done()

  it 'does not work if the user is a teacher', (done) ->
    loginNewUser (user1) ->
      user1.set('role', 'teacher')
      user1.save (err) ->
        data = { name: 'Classroom 5' }
        request.post {uri: classroomsURL, json: data }, (err, res, body) ->
          classroomCode = body.code
          classroomID = body._id
          expect(res.statusCode).toBe(200)
          loginNewUser (user2) ->
            user2.set('role', 'teacher')
            user2.save (err, user2) ->
              url = getURL("/db/classroom/~/members")
              data = { code: classroomCode }
              request.post { uri: url, json: data }, (err, res, body) ->
                expect(res.statusCode).toBe(403)
                Classroom.findById classroomID, (err, classroom) ->
                  expect(classroom.get('members').length).toBe(0)
                  done()

  it 'does not work if the user is anonymous', utils.wrap (done) ->
    yield utils.clearModels([User, Classroom])
    teacher = yield utils.initUser({role: 'teacher'})
    yield utils.loginUser(teacher)
    [res, body] = yield request.postAsync {uri: classroomsURL, json: { name: 'Classroom' } }
    expect(res.statusCode).toBe(200)
    classroomCode = body.code
    yield utils.becomeAnonymous()
    [res, body] = yield request.postAsync { uri: getURL("/db/classroom/~/members"), json: { code: classroomCode } }
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
          expect(res.statusCode).toBe(200)
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

  it 'takes a list of emails and sends invites', (done) ->
    loginNewUser (user1) ->
      user1.set('role', 'teacher')
      user1.save (err) ->
        data = { name: 'Classroom 6' }
        request.post {uri: classroomsURL, json: data }, (err, res, body) ->
          expect(res.statusCode).toBe(200)
          url = classroomsURL + '/' + body._id + '/invite-members'
          data = { emails: ['test@test.com'] }
          request.post { uri: url, json: data }, (err, res, body) ->
            expect(res.statusCode).toBe(200)
            done()


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