require '../common'
utils = require '../utils'
urlUser = '/db/user'
User = require '../../../server/models/User'
Classroom = require '../../../server/models/Classroom'
CourseInstance = require '../../../server/models/CourseInstance'
Course = require '../../../server/models/Course'
Campaign = require '../../../server/models/Campaign'
TrialRequest = require '../../../server/models/TrialRequest'
Prepaid = require '../../../server/models/Prepaid'
request = require '../request'
facebook = require '../../../server/lib/facebook'
gplus = require '../../../server/lib/gplus'
sendwithus = require '../../../server/sendwithus'
Promise = require 'bluebird'
Achievement = require '../../../server/models/Achievement'
EarnedAchievement = require '../../../server/models/EarnedAchievement'
LevelSession = require '../../../server/models/LevelSession'
mongoose = require 'mongoose'

describe 'POST /db/user', ->

  createAnonNameUser = (name, done)->
    request.post getURL('/auth/logout'), ->
      request.get getURL('/auth/whoami'), ->
        req = request.post({ url: getURL('/db/user'), json: {name}}, (err, response) ->
          expect(response.statusCode).toBe(200)
          request.get { url: getURL('/auth/whoami'), json: true }, (request, response, body) ->
            expect(body.anonymous).toBeTruthy()
            expect(body.name).toEqual(name)
            done()
        )

  it 'preparing test : clears the db first', (done) ->
    clearModels [User], (err) ->
      throw err if err
      done()

  it 'converts the password into a hash', (done) ->
    unittest.getNormalJoe (user) ->
      expect(user).toBeTruthy()
      expect(user.get('password')).toBeUndefined()
      expect(user?.get('passwordHash')).not.toBeUndefined()
      if user?.get('passwordHash')?
        expect(user.get('passwordHash')[..5] in ['31dc3d', '948c7e']).toBeTruthy()
        expect(user.get('permissions').length).toBe(0)
      done()

  it 'serves the user through /db/user/id', (done) ->
    unittest.getNormalJoe (user) ->
      utils.becomeAnonymous().then ->
        url = getURL(urlUser+'/'+user._id)
        request.get url, (err, res, body) ->
          expect(res.statusCode).toBe(200)
          user = JSON.parse(body)
          expect(user.name).toBe('Joe')  # Anyone should be served the username.
          expect(user.email).toBeUndefined()  # Shouldn't be available to just anyone.
          expect(user.passwordHash).toBeUndefined()
          done()

  it 'creates admins based on passwords', (done) ->
    request.post getURL('/auth/logout'), ->
      unittest.getAdmin (user) ->
        expect(user).not.toBeUndefined()
        if user
          expect(user.get('permissions').length).toBe(1)
          expect(user.get('permissions')[0]).toBe('admin')
        done()

  it 'does not return the full user object for regular users.', (done) ->
    loginJoe ->
      unittest.getAdmin (user) ->

        url = getURL(urlUser+'/'+user._id)
        request.get url, (err, res, body) ->
          expect(res.statusCode).toBe(200)
          user = JSON.parse(body)
          expect(user.email).toBeUndefined()
          expect(user.passwordHash).toBeUndefined()
          done()

  it 'should allow setting anonymous user name', (done) ->
    createAnonNameUser('Jim', done)

  it 'should allow multiple anonymous users with same name', (done) ->
    createAnonNameUser('Jim', done)

  it 'should allow setting existing user name to anonymous user', (done) ->
    req = request.post({url: getURL('/db/user'), json: {email: 'new@user.com', password: 'new'}}, (err, response, body) ->
      expect(response.statusCode).toBe(200)
      request.get getURL('/auth/whoami'), (request, response, body) ->
        res = JSON.parse(response.body)
        expect(res.anonymous).toBeFalsy()
        createAnonNameUser 'Jim', done
    )

describe 'PUT /db/user', ->

  it 'returns 422 when no data is provided', utils.wrap ->
    user = yield utils.initUser()
    yield utils.loginUser(user)
    [res] = yield request.putAsync utils.getUrl('/db/user')
    expect(res.statusCode).toBe(422)
    expect(res.body).toBe('No input.')

  it 'returns 403 for trying to modify another user', utils.wrap ->
    user1 = yield utils.initUser()
    yield utils.loginUser(user1)
    user2 = yield utils.initUser()
    [res] = yield request.putAsync(utils.getUrl('/db/user'), json: {_id: user2.id})
    expect(res.statusCode).toBe(403)
    
  it 'returns 422 for invalid data', utils.wrap ->
    user = yield utils.initUser()
    yield utils.loginUser(user)
    email = _.times(50, -> 'farghlarghl').join('')
    json = { _id: user.id, email }
    [res] = yield request.putAsync utils.getUrl('/db/user'), { json }
    expect(res.statusCode).toBe(422)
    expect(res.body[0].message.indexOf('too long')).toBeGreaterThan(-1)
    
  it 'does not allow permission editing', utils.wrap ->
    user = yield utils.initUser()
    yield utils.loginUser(user)
    [res] = yield request.putAsync { uri: getURL('/db/user/'+user.id), json: { permissions: ['admin'] }}
    expect(_.contains(res.body.permissions, 'admin')).toBe(false)

  it 'returns 404 for non-existent ids', utils.wrap ->
    admin = yield utils.initAdmin()
    yield utils.loginUser(admin)
    json = {
      _id: '513108d4cb8b610000000004',
      email: 'perfectly@good.com'
    }
    [res] = yield request.putAsync {url: getURL('/db/user'), json}
    expect(res.statusCode).toBe(404)

  it 'returns 409 if setting to a taken email', utils.wrap ->
    user1 = yield utils.initUser()
    yield utils.loginUser(user1)
    user2 = yield utils.initUser()
    json = { _id: user1.id, email: user2.get('email') }
    [res] = yield request.putAsync { url: getURL('/db/user'), json }
    expect(res.statusCode).toBe(409)
    expect(res.body.message.indexOf('already used')).toBeGreaterThan(-1)

  it 'returns 200 if you are setting to your own, current name', utils.wrap ->
    user = yield utils.initUser()
    yield utils.loginUser(user)
    expect(user.get('name')).toBeDefined()
    json = { name: user.get('name') }
    [res] = yield request.putAsync { uri: getURL('/db/user/'+user.id), json: { permissions: ['admin'] }}
    expect(res.statusCode).toBe(200)

  it 'accepts name and email changes', utils.wrap ->
    user = yield utils.initUser()
    yield utils.loginUser(user)
    json = {
      _id: user.id
      email: 'New@email.com'
      name: 'Wilhelm'
    }
    [res] = yield request.putAsync { url: getURL('/db/user'), json }
    expect(res.statusCode).toBe(200)
    user = yield User.findById(user.id)
    expect(user.get('name')).toBe('Wilhelm')
    expect(user.get('emailLower')).toBe('new@email.com')
    expect(user.get('email')).toBe('New@email.com')
      
  it 'returns 409 if setting to a taken username ', utils.wrap ->
    user1 = yield utils.initUser()
    yield utils.loginUser(user1)
    user2 = yield utils.initUser()
    json = { _id: user1.id, name: user2.get('name') }
    [res] = yield request.putAsync { url: getURL('/db/user'), json }
    expect(res.statusCode).toBe(409)

  it 'unsets user "slug" if username is cleared', utils.wrap ->
    user = yield utils.initUser()
    yield utils.loginUser(user)
    json = { _id: user.id, name: '' }
    [res] = yield request.putAsync { url: getURL('/db/user'), json }
    expect(res.statusCode).toBe(200)
    user = yield User.findById(user.id)
    expect(user.get('slug')).toBeUndefined

  describe 'when role is changed to teacher or other school administrator', ->
    it 'removes the user from all classrooms they are in', utils.wrap ->
      user = yield utils.initUser()
      classroom = new Classroom({members: [user._id]})
      yield classroom.save()
      expect(classroom.get('members').length).toBe(1)
      yield utils.loginUser(user)
      [res, body] = yield request.putAsync { uri: getURL('/db/user/'+user.id), json: { role: 'teacher' }}
      yield new Promise (resolve) -> setTimeout(resolve, 10)
      classroom = yield Classroom.findById(classroom.id)
      expect(classroom.get('members').length).toBe(0)
    
    it 'changes the role regardless of emailVerified', utils.wrap ->
      user = yield utils.initUser()
      user.set('emailVerified', true)
      yield user.save()
      yield utils.loginUser(user)
      attrs = user.toObject()
      attrs.role = 'teacher'
      [res, body] = yield request.putAsync { uri: getURL('/db/user/'+user.id), json: attrs }
      user = yield User.findById(user.id)
      expect(user.get('role')).toBe('teacher')

  it 'ignores attempts to change away from a teacher role', utils.wrap ->
    user = yield utils.initUser()
    yield utils.loginUser(user)
    url = getURL('/db/user/'+user.id)
    [res, body] = yield request.putAsync { uri: url, json: { role: 'teacher' }}
    expect(body.role).toBe('teacher')
    [res, body] = yield request.putAsync { uri: url, json: { role: 'advisor' }}
    expect(body.role).toBe('advisor')
    [res, body] = yield request.putAsync { uri: url, json: { role: 'student' }}
    expect(body.role).toBe('advisor')

  it 'returns 422 if both email and name would be unset for a registered user', utils.wrap ->
    user = yield utils.initUser()
    yield utils.loginUser(user)
    [res, body] = yield request.putAsync { uri: getURL('/db/user/'+user.id), json: { email: '', name: '' }}
    expect(body.code).toBe(422)
    expect(body.message).toEqual('User needs a username or email address')
    
  it 'allows unsetting email, even when there\'s a user with email and emailLower set to empty string', utils.wrap ->
    invalidUser = yield utils.initUser()
    yield invalidUser.update({$set: {email: '', emailLower: ''}})
    user = yield utils.initUser()
    yield utils.loginUser(user)
    [res, body] = yield request.putAsync { uri: getURL('/db/user/'+user.id), json: { email: '' }}
    expect(res.statusCode).toBe(200)
    expect(res.body.email).toBeUndefined()

  it 'allows unsetting name, even when there\'s a user with name and nameLower set to empty string', utils.wrap ->
    invalidUser = yield utils.initUser()
    yield invalidUser.update({$set: {name: '', nameLower: ''}})
    user = yield utils.initUser()
    yield utils.loginUser(user)
    [res, body] = yield request.putAsync { uri: getURL('/db/user/'+user.id), json: { name: '' }}
    expect(res.statusCode).toBe(200)
    expect(res.body.name).toBeUndefined()
    
  it 'works even when user object does not pass validation', utils.wrap ->
    invalidUser = yield utils.initUser()
    yield invalidUser.update({$set: {propNotInSchema: '...'}})
    yield utils.loginUser(invalidUser)
    [res] = yield request.putAsync { uri: getURL('/db/user/'+invalidUser.id), json: { name: 'A new name' }}
    expect(res.statusCode).toBe(200)
    expect(res.body.name).toBe('A new name')
    

describe 'PUT /db/user/-/become-student', ->
  beforeEach utils.wrap ->
    @url = getURL('/db/user/-/become-student')
    @user = yield utils.initUser()
    yield utils.loginUser(@user)

  describe 'when a user is in a classroom', ->
    beforeEach utils.wrap ->
      classroom = new Classroom({
        members: [@user._id]
      })
      yield classroom.save()
    it 'keeps the user in their classroom and sets their role to student', utils.wrap ->
      [res, body] = yield request.putAsync { uri: @url}
      expect(res.statusCode).toEqual(200)
      expect(JSON.parse(body).role).toEqual('student')
      user = yield User.findById @user._id
      expect(user.get('role')).toEqual('student')
      classrooms = yield Classroom.find members: @user._id
      expect(classrooms.length).toEqual(1)

    describe 'when a teacher', ->
      beforeEach utils.wrap ->
        @user.set('role', 'student')
        yield @user.save()
      it 'keeps the user in their classroom and sets their role to student', utils.wrap ->
        [res, body] = yield request.putAsync { uri: @url}
        expect(res.statusCode).toEqual(200)
        expect(JSON.parse(body).role).toEqual('student')
        user = yield User.findById @user._id
        expect(user.get('role')).toEqual('student')
        classrooms = yield Classroom.find members: @user._id
        expect(classrooms.length).toEqual(1)

    describe 'when a student', ->
      beforeEach utils.wrap ->
        @user.set('role', 'student')
        yield @user.save()
      it 'keeps the user in their classroom and sets their role to student', utils.wrap ->
        [res, body] = yield request.putAsync { uri: @url}
        expect(res.statusCode).toEqual(200)
        expect(JSON.parse(body).role).toEqual('student')
        user = yield User.findById @user._id
        expect(user.get('role')).toEqual('student')
        classrooms = yield Classroom.find members: @user._id
        expect(classrooms.length).toEqual(1)

  describe 'when a user owns a classroom', ->
    beforeEach utils.wrap ->
      classroom = new Classroom({
        ownerID: @user._id
      })
      yield classroom.save()
    it 'removes the classroom and sets their role to student', utils.wrap ->
      [res, body] = yield request.putAsync { uri: @url}
      expect(res.statusCode).toEqual(200)
      expect(JSON.parse(body).role).toEqual('student')
      user = yield User.findById @user._id
      expect(user.get('role')).toEqual('student')
      classrooms = yield Classroom.find ownerID: @user._id
      expect(classrooms.length).toEqual(0)

    describe 'when a student', ->
      beforeEach utils.wrap ->
        @user.set('role', 'student')
        yield @user.save()
      it 'removes the classroom and sets their role to student', utils.wrap ->
        [res, body] = yield request.putAsync { uri: @url}
        expect(res.statusCode).toEqual(200)
        expect(JSON.parse(body).role).toEqual('student')
        user = yield User.findById @user._id
        expect(user.get('role')).toEqual('student')
        classrooms = yield Classroom.find ownerID: @user._id
        expect(classrooms.length).toEqual(0)

    describe 'when a teacher', ->
      beforeEach utils.wrap ->
        @user.set('role', 'teacher')
        yield @user.save()
      it 'removes the classroom and sets their role to student', utils.wrap ->
        [res, body] = yield request.putAsync { uri: @url}
        expect(res.statusCode).toEqual(200)
        expect(JSON.parse(body).role).toEqual('student')
        user = yield User.findById @user._id
        expect(user.get('role')).toEqual('student')
        classrooms = yield Classroom.find ownerID: @user._id
        expect(classrooms.length).toEqual(0)

  describe 'when a user in a classroom and owns a classroom', ->
    beforeEach utils.wrap ->
      classroom = new Classroom({
        members: [@user._id]
      })
      yield classroom.save()
      classroom = new Classroom({
        ownerID: @user._id
      })
      yield classroom.save()
    it 'removes owned classrooms, keeps in classrooms, and sets their role to student', utils.wrap ->
      [res, body] = yield request.putAsync { uri: @url}
      expect(res.statusCode).toEqual(200)
      expect(JSON.parse(body).role).toEqual('student')
      user = yield User.findById @user._id
      expect(user.get('role')).toEqual('student')
      classrooms = yield Classroom.find ownerID: @user._id
      expect(classrooms.length).toEqual(0)
      classrooms = yield Classroom.find members: @user._id
      expect(classrooms.length).toEqual(1)

  describe 'when a student in a classroom and owns a classroom', ->
    beforeEach utils.wrap ->
      @user.set('role', 'student')
      yield @user.save()
      classroom = new Classroom({
        members: [@user._id]
      })
      yield classroom.save()
      classroom = new Classroom({
        ownerID: @user._id
      })
      yield classroom.save()
    it 'removes owned classrooms, keeps in classrooms, and sets their role to student', utils.wrap ->
      [res, body] = yield request.putAsync { uri: @url}
      expect(res.statusCode).toEqual(200)
      expect(JSON.parse(body).role).toEqual('student')
      user = yield User.findById @user._id
      expect(user.get('role')).toEqual('student')
      classrooms = yield Classroom.find ownerID: @user._id
      expect(classrooms.length).toEqual(0)
      classrooms = yield Classroom.find members: @user._id
      expect(classrooms.length).toEqual(1)

  describe 'when a teacher in a classroom and owns a classroom', ->
    beforeEach utils.wrap ->
      @user.set('role', 'teacher')
      yield @user.save()
      classroom = new Classroom({
        members: [@user._id]
      })
      yield classroom.save()
      classroom = new Classroom({
        ownerID: @user._id
      })
      yield classroom.save()
    it 'removes owned classrooms, keeps in classrooms, and sets their role to student', utils.wrap ->
      [res, body] = yield request.putAsync { uri: @url}
      expect(res.statusCode).toEqual(200)
      expect(JSON.parse(body).role).toEqual('student')
      user = yield User.findById @user._id
      expect(user.get('role')).toEqual('student')
      classrooms = yield Classroom.find ownerID: @user._id
      expect(classrooms.length).toEqual(0)
      classrooms = yield Classroom.find members: @user._id
      expect(classrooms.length).toEqual(1)

describe 'PUT /db/user/-/remain-teacher', ->

  describe 'when a teacher in classroom and owns a classroom', ->
    beforeEach utils.wrap ->
      @url = getURL('/db/user/-/remain-teacher')
      @user = yield utils.initUser()
      yield utils.loginUser(@user)
      @user.set('role', 'teacher')
      yield @user.save()
      classroom = new Classroom({
        members: [@user._id]
      })
      yield classroom.save()
      classroom = new Classroom({
        ownerID: @user._id
      })
      yield classroom.save()
    it 'removes from classrooms', utils.wrap ->
      [res, body] = yield request.putAsync { uri: @url}
      expect(res.statusCode).toEqual(200)
      expect(JSON.parse(body).role).toEqual('teacher')
      user = yield User.findById @user._id
      expect(user.get('role')).toEqual('teacher')
      classrooms = yield Classroom.find ownerID: @user._id
      expect(classrooms.length).toEqual(1)
      classrooms = yield Classroom.find members: @user._id
      expect(classrooms.length).toEqual(0)

describe 'GET /db/user', ->

  it 'logs in as admin', (done) ->
    json = {
      username: 'admin@afc.com'
      password: '80yqxpb38j'
    }
    request.post { url: getURL('/auth/login'), json }, (error, response) ->
      expect(response.statusCode).toBe(200)
      done()

  it 'get schema', (done) ->
    request.get {uri: getURL(urlUser+'/schema')}, (err, res, body) ->
      expect(res.statusCode).toBe(200)
      body = JSON.parse(body)
      expect(body.type).toBeDefined()
      done()

  it 'is able to do a semi-sweet query', (done) ->
    options = {
      url: getURL(urlUser) + "?conditions[limit]=20&conditions[sort]=-dateCreated"
    }
    req = request.get(options, (error, response) ->
      expect(response.statusCode).toBe(200)
      res = JSON.parse(response.body)
      expect(res.length).toBeGreaterThan(0)
      done()
    )

  it 'rejects bad conditions', (done) ->
    options = {
      url: getURL(urlUser) + "?conditions[lime]=20&conditions[sort]=-dateCreated"
    }

    req = request.get(options, (error, response) ->
      expect(response.statusCode).toBe(422)
      done()
    )

  it 'can fetch myself by id completely', (done) ->
    loginSam (sam) ->
      request.get {url: getURL(urlUser + '/' + sam.id)}, (err, response) ->
        expect(err).toBeNull()
        expect(response.statusCode).toBe(200)
        done()

  it 'can fetch myself by slug completely', (done) ->
    loginSam (sam) ->
      request.get {url: getURL(urlUser + '/sam')}, (err, response) ->
        expect(err).toBeNull()
        expect(response.statusCode).toBe(200)
        guy = JSON.parse response.body
        expect(guy._id).toBe sam.get('_id').toHexString()
        expect(guy.name).toBe sam.get 'name'
        done()

  # TODO Ruben should be able to fetch other users but probably with restricted data access
  # Add to the test case above an extra data check

#  xit 'can fetch another user with restricted fields'
  
  
describe 'GET /db/user/:handle', ->
  it 'populates coursePrepaid from coursePrepaidID', utils.wrap ->
    user = yield utils.initUser({coursePrepaidID: mongoose.Types.ObjectId()})
    yield utils.loginUser(user)
    [res, body] = yield request.getAsync({url: getURL("/db/user/#{user.id}"), json: true})
    expect(res.statusCode).toBe(200)
    expect(res.body.coursePrepaid._id).toBe(user.get('coursePrepaidID').toString())
    expect(res.body.coursePrepaid.startDate).toBe(Prepaid.DEFAULT_START_DATE)
    

describe 'DELETE /db/user', ->
  it 'can delete a user', utils.wrap ->
    user = yield utils.initUser()
    yield utils.loginUser(user)
    beforeDeleted = new Date()
    [res, body] = yield request.delAsync {uri: "#{getURL(urlUser)}/#{user.id}"}
    user = yield User.findById user.id
    expect(user.get('deleted')).toBe(true)
    expect(user.get('dateDeleted')).toBeGreaterThan(beforeDeleted)
    expect(user.get('dateDeleted')).toBeLessThan(new Date())
    for key, value of user.toObject()
      continue if key in ['_id', 'deleted', 'dateDeleted']
      expect(_.isEmpty(value)).toEqual(true)

  it 'moves user to classroom.deletedMembers', utils.wrap ->
    user = yield utils.initUser()
    user2 = yield utils.initUser()
    yield utils.loginUser(user)
    classroom = new Classroom({
      members: [user._id, user2._id]
    })
    yield classroom.save()
    [res, body] = yield request.delAsync {uri: "#{getURL(urlUser)}/#{user.id}"}
    classroom = yield Classroom.findById(classroom.id)
    expect(classroom.get('members').length).toBe(1)
    expect(classroom.get('deletedMembers').length).toBe(1)
    expect(classroom.get('members')[0].toString()).toEqual(user2.id)
    expect(classroom.get('deletedMembers')[0].toString()).toEqual(user.id)
    
  it 'returns 401 if no cookie session', utils.wrap ->
    yield utils.logout()
    [res, body] = yield request.delAsync {uri: "#{getURL(urlUser)}/1234"}
    expect(res.statusCode).toBe(401)

  it 'prevents further edits to the deleted user', utils.wrap ->
    user = yield utils.initUser()
    yield utils.loginUser(user)
    otherLogin = request.defaults({jar:request.jar()})
    Promise.promisifyAll(otherLogin)
    yield utils.loginUser(user, { request: otherLogin })
    [res] = yield request.delAsync {uri: "#{getURL(urlUser)}/#{user.id}"}
    expect(res.statusCode).toBe(204)
    json = { email: 'newEmail@email.com' }
    res = yield otherLogin.putAsync { url: getURL('/db/user/'+user.id), json }
    expect(res.statusCode).toBe(401) # other login no longer valid
    expect(res.body._id).not.toBe(user.id)
    user = yield User.findById(user.id)
    expect(user.email).toBeUndefined()

  it 'allows edits to deleted users who have already made previous edits', utils.wrap ->
    user = yield utils.initUser()
    yield utils.loginUser(user)
    otherLogin = request.defaults({jar:request.jar()})
    Promise.promisifyAll(otherLogin)
    yield utils.loginUser(user, { request: otherLogin })
    [res] = yield request.delAsync {uri: "#{getURL(urlUser)}/#{user.id}"}
    expect(res.statusCode).toBe(204)
    yield user.update({ $set: { someProp: 1 }})
    json = { email: 'newEmail@email.com' }
    res = yield otherLogin.putAsync { url: getURL('/db/user/'+user.id), json }
    expect(res.statusCode).toBe(200) # other login no longer valid
    user = yield User.findById(user.id)
    expect(user.get('email')).toBe(json.email)


describe 'Statistics', ->
  LevelSession = require '../../../server/models/LevelSession'
  Article = require '../../../server/models/Article'
  Level = require '../../../server/models/Level'
  LevelSystem = require '../../../server/models/LevelSystem'
  LevelComponent = require '../../../server/models/LevelComponent'
  ThangType = require '../../../server/models/ThangType'
  User = require '../../../server/models/User'
  UserHandler = require '../../../server/handlers/user_handler'

  it 'keeps track of games completed', (done) ->
    session = new LevelSession
      name: 'Beat Gandalf'
      permissions: simplePermissions
      state: complete: true

    unittest.getNormalJoe (joe) ->
      expect(joe.get 'stats.gamesCompleted').toBeUndefined()

      session.set 'creator', joe.get 'id'
      session.save (err) ->
        expect(err).toBeNull()

        f = ->
          User.findById joe.get('id'), (err, guy) ->
            expect(err).toBeNull()
            expect(guy.get 'id').toBe joe.get 'id'
            expect(guy.get 'stats.gamesCompleted').toBe 1
            done()

        setTimeout f, 100

  it 'recalculates games completed', (done) ->
    unittest.getNormalJoe (joe) ->
      loginAdmin ->
        User.findByIdAndUpdate joe.get('id'), {$unset:'stats.gamesCompleted': ''}, {new: true}, (err, guy) ->
          expect(err).toBeNull()
          expect(guy.get 'stats.gamesCompleted').toBeUndefined()

          UserHandler.statRecalculators.gamesCompleted ->
            User.findById joe.get('id'), (err, guy) ->
              expect(err).toBeNull()
              expect(guy.get 'stats.gamesCompleted').toBe 1
              done()

  it 'keeps track of article edits', (done) ->
    article =
      name: 'My very first'
      body: 'I don\'t have much to say I\'m afraid'
    url = getURL('/db/article')

    loginAdmin (carl) ->
      expect(carl.get User.statsMapping.edits.article).toBeUndefined()
      article.creator = carl.get 'id'

      # Create major version 0.0
      request.post {uri:url, json: article}, (err, res, body) ->
        expect(err).toBeNull()
        expect(res.statusCode).toBe 201
        article = body

        User.findById carl.get('id'), (err, guy) ->
          expect(err).toBeNull()
          expect(guy.get User.statsMapping.edits.article).toBe 1

          # Create minor version 0.1
          newVersionURL = "#{url}/#{article._id}/new-version"
          request.post {uri:newVersionURL, json: article}, (err, res, body) ->
            expect(err).toBeNull()

            User.findById carl.get('id'), (err, guy) ->
              expect(err).toBeNull()
              expect(guy.get User.statsMapping.edits.article).toBe 2

              done()

  it 'recalculates article edits', (done) ->
    loginAdmin (carl) ->
      User.findByIdAndUpdate carl.get('id'), {$unset:'stats.articleEdits': ''}, {new: true}, (err, guy) ->
        expect(err).toBeNull()
        expect(guy.get User.statsMapping.edits.article).toBeUndefined()

        UserHandler.statRecalculators.articleEdits ->
          User.findById carl.get('id'), (err, guy) ->
            expect(err).toBeNull()
            expect(guy.get User.statsMapping.edits.article).toBe 2
            done()

  it 'keeps track of level edits', (done) ->
    level = new Level
      name: "King's Peak 3"
      description: 'Climb a mountain.'
      permissions: simplePermissions
      scripts: []
      thangs: []

    loginAdmin (carl) ->
      expect(carl.get User.statsMapping.edits.level).toBeUndefined()
      level.creator = carl.get 'id'
      level.save (err) ->
        expect(err).toBeNull()

        User.findById carl.get('id'), (err, guy) ->
          expect(err).toBeNull()
          expect(guy.get 'id').toBe carl.get 'id'
          expect(guy.get User.statsMapping.edits.level).toBe 1

          done()

  it 'recalculates level edits', (done) ->
    unittest.getAdmin (jose) ->
      User.findByIdAndUpdate jose.get('id'), {$unset:'stats.levelEdits':''}, {new: true}, (err, guy) ->
        expect(err).toBeNull()
        expect(guy.get User.statsMapping.edits.level).toBeUndefined()

        UserHandler.statRecalculators.levelEdits ->
          User.findById jose.get('id'), (err, guy) ->
            expect(err).toBeNull()
            expect(guy.get User.statsMapping.edits.level).toBe 1
            done()

  it 'cleans up', (done) ->
    clearModels [LevelSession, Article, Level, LevelSystem, LevelComponent, ThangType], (err) ->
      expect(err).toBeNull()

      done()
      
      
describe 'POST /db/user/:handle/signup-with-password', ->
  
  beforeEach utils.wrap ->
    yield utils.clearModels([User])
    yield new Promise((resolve) -> setTimeout(resolve, 10))
  
  it 'signs up the user with the password and sends welcome emails', utils.wrap ->
    spyOn(sendwithus.api, 'send')
    user = yield utils.becomeAnonymous()
    url = getURL("/db/user/#{user.id}/signup-with-password")
    email = 'some@email.com'
    name = 'someusername'
    json = { name, email, password: '12345' }
    [res, body] = yield request.postAsync({url, json})
    expect(res.statusCode).toBe(200)
    updatedUser = yield User.findById(user.id)
    expect(updatedUser.get('email')).toBe(email)
    expect(updatedUser.get('passwordHash')).toBeDefined()
    expect(sendwithus.api.send).toHaveBeenCalled()

  it 'signs up the user with just a name and password', utils.wrap ->
    user = yield utils.becomeAnonymous()
    url = getURL("/db/user/#{user.id}/signup-with-password")
    name = 'someusername'
    json = { name, password: '12345' }
    [res, body] = yield request.postAsync({url, json})
    expect(res.statusCode).toBe(200)
    updatedUser = yield User.findById(user.id)
    expect(updatedUser.get('name')).toBe(name)
    expect(updatedUser.get('nameLower')).toBe(name.toLowerCase())
    expect(updatedUser.get('slug')).toBe(name.toLowerCase())
    expect(updatedUser.get('passwordHash')).toBeDefined()
    expect(updatedUser.get('email')).toBeUndefined()
    expect(updatedUser.get('emailLower')).toBeUndefined()

  it 'signs up the user with a username, email, and password', utils.wrap ->
    user = yield utils.becomeAnonymous()
    url = getURL("/db/user/#{user.id}/signup-with-password")
    name = 'someusername'
    email = 'user@example.com'
    json = { name, email, password: '12345' }
    [res, body] = yield request.postAsync({url, json})
    expect(res.statusCode).toBe(200)
    updatedUser = yield User.findById(user.id)
    expect(updatedUser.get('name')).toBe(name)
    expect(updatedUser.get('nameLower')).toBe(name.toLowerCase())
    expect(updatedUser.get('slug')).toBe(name.toLowerCase())
    expect(updatedUser.get('email')).toBe(email)
    expect(updatedUser.get('emailLower')).toBe(email.toLowerCase())
    expect(updatedUser.get('passwordHash')).toBeDefined()

  it 'returns 422 if neither username or email were provided', utils.wrap ->
    user = yield utils.becomeAnonymous()
    url = getURL("/db/user/#{user.id}/signup-with-password")
    json = { password: '12345' }
    [res, body] = yield request.postAsync({url, json})
    expect(res.statusCode).toBe(422)
    updatedUser = yield User.findById(user.id)
    expect(updatedUser.get('anonymous')).toBe(true)
    expect(updatedUser.get('passwordHash')).toBeUndefined()

  it 'returns 409 if there is already a user with the given email', utils.wrap ->
    email = 'some@email.com'
    initialUser = yield utils.initUser({email})
    expect(initialUser.get('emailLower')).toBeDefined()
    user = yield utils.becomeAnonymous()
    url = getURL("/db/user/#{user.id}/signup-with-password")
    json = { email, password: '12345' }
    [res, body] = yield request.postAsync({url, json})
    expect(res.statusCode).toBe(409)

  it 'returns 409 if there is already a user with the given username', utils.wrap ->
    name = 'someusername'
    initialUser = yield utils.initUser({name})
    expect(initialUser.get('nameLower')).toBeDefined()
    user = yield utils.becomeAnonymous()
    url = getURL("/db/user/#{user.id}/signup-with-password")
    json = { name, password: '12345' }
    [res, body] = yield request.postAsync({url, json})
    expect(res.statusCode).toBe(409)
    expect(res.body.message).toBe('Username already taken')
  
  it 'returns 409 if there is already a user with the same slug', utils.wrap ->
    name = 'some username'
    name2 = 'Some.    User.Namé'
    initialUser = yield utils.initUser({name})
    expect(initialUser.get('nameLower')).toBeDefined()
    expect(initialUser.get('slug')).toBeDefined()
    user = yield utils.becomeAnonymous()
    url = getURL("/db/user/#{user.id}/signup-with-password")
    json = { name: name2, password: '12345' }
    [res, body] = yield request.postAsync({url, json})
    expect(res.statusCode).toBe(409)
    expect(res.body.message).toBe('Username already taken')
    
  it 'disassociates the user from their trial request if the trial request email and signup email do not match', utils.wrap ->
    user = yield utils.becomeAnonymous()
    trialRequest = yield utils.makeTrialRequest({ properties: { email: 'one@email.com' } })
    expect(trialRequest.get('applicant').equals(user._id)).toBe(true)
    url = getURL("/db/user/#{user.id}/signup-with-password")
    email = 'two@email.com'
    json = { email, password: '12345' }
    [res, body] = yield request.postAsync({url, json})
    expect(res.statusCode).toBe(200)
    trialRequest = yield TrialRequest.findById(trialRequest.id)
    expect(trialRequest.get('applicant')).toBeUndefined()

  it 'does NOT disassociate the user from their trial request if the trial request email and signup email DO match', utils.wrap ->
    user = yield utils.becomeAnonymous()
    trialRequest = yield utils.makeTrialRequest({ properties: { email: 'one@email.com' } })
    expect(trialRequest.get('applicant').equals(user._id)).toBe(true)
    url = getURL("/db/user/#{user.id}/signup-with-password")
    email = 'one@email.com'
    json = { email, password: '12345' }
    [res, body] = yield request.postAsync({url, json})
    expect(res.statusCode).toBe(200)
    trialRequest = yield TrialRequest.findById(trialRequest.id)
    expect(trialRequest.get('applicant').equals(user._id)).toBe(true)


describe 'POST /db/user/:handle/signup-with-facebook', ->
  facebookID = '12345'
  facebookEmail = 'some@email.com'
  name = 'someusername'
  
  validFacebookResponse = new Promise((resolve) -> resolve({
    id: facebookID,
    email: facebookEmail,
    first_name: 'Some',
    gender: 'male',
    last_name: 'Person',
    link: 'https://www.facebook.com/app_scoped_user_id/12345/',
    locale: 'en_US',
    name: 'Some Person',
    timezone: -7,
    updated_time: '2015-12-08T17:10:39+0000',
    verified: true
  }))
  
  invalidFacebookResponse = new Promise((resolve) -> resolve({
    error: {
      message: 'Invalid OAuth access token.',
      type: 'OAuthException',
      code: 190,
      fbtrace_id: 'EC4dEdeKHBH'
    }
  }))
  
  beforeEach utils.wrap ->
    yield utils.clearModels([User])
    yield new Promise((resolve) -> setTimeout(resolve, 50))
  
  it 'signs up the user with the facebookID and sends welcome emails', utils.wrap ->
    spyOn(facebook, 'fetchMe').and.returnValue(validFacebookResponse)
    spyOn(sendwithus.api, 'send')
    user = yield utils.becomeAnonymous()
    url = getURL("/db/user/#{user.id}/signup-with-facebook")
    json = { name, email: facebookEmail, facebookID, facebookAccessToken: '...' }
    [res, body] = yield request.postAsync({url, json})
    expect(res.statusCode).toBe(200)
    updatedUser = yield User.findById(user.id)
    expect(updatedUser.get('email')).toBe(facebookEmail)
    expect(updatedUser.get('facebookID')).toBe(facebookID)
    expect(sendwithus.api.send).toHaveBeenCalled()
    
  it 'returns 422 if facebook does not recognize the access token', utils.wrap ->
    spyOn(facebook, 'fetchMe').and.returnValue(invalidFacebookResponse)
    user = yield utils.becomeAnonymous()
    url = getURL("/db/user/#{user.id}/signup-with-facebook")
    json = { email: facebookEmail, facebookID, facebookAccessToken: '...' }
    [res, body] = yield request.postAsync({url, json})
    expect(res.statusCode).toBe(422)
    
  it 'returns 422 if the email or id do not match', utils.wrap ->
    spyOn(facebook, 'fetchMe').and.returnValue(validFacebookResponse)
    user = yield utils.becomeAnonymous()
    url = getURL("/db/user/#{user.id}/signup-with-facebook")
  
    json = { name, email: 'some-other@email.com', facebookID, facebookAccessToken: '...' }
    [res, body] = yield request.postAsync({url, json})
    expect(res.statusCode).toBe(422)
  
    json = { name, email: facebookEmail, facebookID: '54321', facebookAccessToken: '...' }
    [res, body] = yield request.postAsync({url, json})
    expect(res.statusCode).toBe(422)
  

  # TODO: Fix this test, res.statusCode is occasionally 200
#  it 'returns 409 if there is already a user with the given email', utils.wrap ->
#    initialUser = yield utils.initUser({email: facebookEmail})
#    expect(initialUser.get('emailLower')).toBeDefined()
#    spyOn(facebook, 'fetchMe').and.returnValue(validFacebookResponse)
#    user = yield utils.becomeAnonymous()
#    url = getURL("/db/user/#{user.id}/signup-with-facebook")
#    json = { name, email: facebookEmail, facebookID, facebookAccessToken: '...' }
#    [res, body] = yield request.postAsync({url, json})
#    expect(res.statusCode).toBe(409)    

    
describe 'POST /db/user/:handle/signup-with-gplus', ->
  gplusID = '12345'
  gplusEmail = 'some@email.com'
  name = 'someusername'

  validGPlusResponse = new Promise((resolve) -> resolve({
    id: gplusID
    email: gplusEmail,
    verified_email: true,
    name: 'Some Person',
    given_name: 'Some',
    family_name: 'Person',
    link: 'https://plus.google.com/12345',
    picture: 'https://lh6.googleusercontent.com/...',
    gender: 'male',
    locale: 'en'
  }))

  invalidGPlusResponse = new Promise((resolve) -> resolve({
    "error": {
      "errors": [
        {
          "domain": "global",
          "reason": "authError",
          "message": "Invalid Credentials",
          "locationType": "header",
          "location": "Authorization"
        }
      ],
      "code": 401,
      "message": "Invalid Credentials"
    }
  }))

  beforeEach utils.wrap ->
    yield utils.clearModels([User])
    yield new Promise((resolve) -> setTimeout(resolve, 50))

  it 'signs up the user with the gplusID and sends welcome emails', utils.wrap ->
    spyOn(gplus, 'fetchMe').and.returnValue(validGPlusResponse)
    spyOn(sendwithus.api, 'send')
    user = yield utils.becomeAnonymous()
    url = getURL("/db/user/#{user.id}/signup-with-gplus")
    json = { name, email: gplusEmail, gplusID, gplusAccessToken: '...' }
    [res, body] = yield request.postAsync({url, json})
    expect(res.statusCode).toBe(200)
    updatedUser = yield User.findById(user.id)
    expect(updatedUser.get('name')).toBe(name)
    expect(updatedUser.get('email')).toBe(gplusEmail)
    expect(updatedUser.get('gplusID')).toBe(gplusID)
    expect(sendwithus.api.send).toHaveBeenCalled()

  it 'returns 422 if gplus does not recognize the access token', utils.wrap ->
    spyOn(gplus, 'fetchMe').and.returnValue(invalidGPlusResponse)
    user = yield utils.becomeAnonymous()
    url = getURL("/db/user/#{user.id}/signup-with-gplus")
    json = { name, email: gplusEmail, gplusID, gplusAccessToken: '...' }
    [res, body] = yield request.postAsync({url, json})
    expect(res.statusCode).toBe(422)

  it 'returns 422 if the email or id do not match', utils.wrap ->
    spyOn(gplus, 'fetchMe').and.returnValue(validGPlusResponse)
    user = yield utils.becomeAnonymous()
    url = getURL("/db/user/#{user.id}/signup-with-gplus")

    json = { name, email: 'some-other@email.com', gplusID, gplusAccessToken: '...' }
    [res, body] = yield request.postAsync({url, json})
    expect(res.statusCode).toBe(422)

    json = { name, email: gplusEmail, gplusID: '54321', gplusAccessToken: '...' }
    [res, body] = yield request.postAsync({url, json})
    expect(res.statusCode).toBe(422)


  it 'returns 409 if there is already a user with the given email', utils.wrap ->
    conflictingUser = yield utils.initUser({name: 'someusername', email: gplusEmail})
    spyOn(gplus, 'fetchMe').and.returnValue(validGPlusResponse)
    user = yield utils.becomeAnonymous()
    url = getURL("/db/user/#{user.id}/signup-with-gplus")
    json = { name: 'differentusername', email: gplusEmail, gplusID, gplusAccessToken: '...' }
    [res, body] = yield request.postAsync({url, json})
    expect(res.statusCode).toBe(409)
    updatedUser = yield User.findById(user.id)
    
describe 'POST /db/user/:handle/destudent', ->
  beforeEach utils.wrap ->
    yield utils.clearModels([User, Classroom, CourseInstance, Course, Campaign])
  
  it 'removes a student user from all classrooms and unsets their role property', utils.wrap ->
    student1 = yield utils.initUser({role: 'student'})
    student2 = yield utils.initUser({role: 'student'})
    members = [student1._id, student2._id]

    classroom = new Classroom({members})
    yield classroom.save()
    courseInstance = new CourseInstance({members})
    yield courseInstance.save()

    admin = yield utils.initAdmin()
    yield utils.loginUser(admin)

    url = getURL("/db/user/#{student1.id}/destudent")
    [res, body] = yield request.postAsync({url, json:true})
    
    student1 = yield User.findById(student1.id)
    student2 = yield User.findById(student2.id)
    classroom = yield Classroom.findById(classroom.id)
    courseInstance = yield CourseInstance.findById(courseInstance.id)
    
    expect(student1.get('role')).toBeUndefined()
    expect(student2.get('role')).toBe('student')
    expect(classroom.get('members').length).toBe(1)
    expect(classroom.get('members')[0].toString()).toBe(student2.id)
    expect(courseInstance.get('members').length).toBe(1)
    expect(courseInstance.get('members')[0].toString()).toBe(student2.id)

describe 'POST /db/user/:handle/deteacher', ->
  beforeEach utils.wrap ->
    yield utils.clearModels([User, TrialRequest])

  it 'removes a student user from all classrooms and unsets their role property', utils.wrap ->
    teacher = yield utils.initUser({role: 'teacher'})
    yield utils.loginUser(teacher)
    trialRequest = yield utils.makeTrialRequest(teacher)

    admin = yield utils.initAdmin()
    yield utils.loginUser(admin)

    trialRequest = yield TrialRequest.findById(trialRequest.id)
    expect(trialRequest).toBeDefined()
    expect(teacher.get('role')).toBe('teacher')

    url = getURL("/db/user/#{teacher.id}/deteacher")
    [res, body] = yield request.postAsync({url, json:true})

    trialRequest = yield TrialRequest.findById(trialRequest.id)
    expect(trialRequest).toBeNull()
    teacher = yield User.findById(teacher.id)
    expect(teacher.get('role')).toBeUndefined()

    
describe 'POST /db/user/:handle/check-for-new-achievements', ->
  achievementURL = getURL('/db/achievement')
  achievementJSON = {
    collection: 'users'
    query: {'points': {$gt: 50}}
    userField: '_id'
    recalculable: true
    worth: 75
    rewards: {
      gems: 50
      levels: [new mongoose.Types.ObjectId().toString()]
    }
    name: 'Dungeon Arena Started'
    description: 'Started playing Dungeon Arena.'
    related: 'a'
  }
  
  
  beforeEach utils.wrap ->
    yield utils.clearModels [Achievement, EarnedAchievement, LevelSession, User]
    Achievement.resetAchievements()
    
  it 'finds new achievements and awards them to the user', utils.wrap ->
    user = yield utils.initUser({points: 100})
    yield utils.loginUser(user)
    url = utils.getURL("/db/user/#{user.id}/check-for-new-achievement")
    json = true
    [res, body] = yield request.postAsync({ url, json })

    earned = yield EarnedAchievement.count()
    expect(earned).toBe(0)

    admin = yield utils.initAdmin()
    yield utils.loginUser(admin)
    [res, body] = yield request.postAsync { uri: achievementURL, json: achievementJSON }
    achievementUpdated = res.body.updated
    expect(res.statusCode).toBe(201)
    
    user = yield User.findById(user.id)
    expect(user.get('earned')).toBeUndefined()
    
    yield utils.loginUser(user)
    [res, body] = yield request.postAsync({ url, json })
    expect(body.points).toBe(175)
    earned = yield EarnedAchievement.count()
    expect(earned).toBe(1)
    expect(body.lastAchievementChecked).toBe(achievementUpdated)
    
    
  it 'updates the user if they already earned the achievement but the rewards changed', utils.wrap ->
    user = yield utils.initUser({points: 100})
    yield utils.loginUser(user)
    url = utils.getURL("/db/user/#{user.id}/check-for-new-achievement")
    json = true
    [res, body] = yield request.postAsync({ url, json })

    admin = yield utils.initAdmin()
    yield utils.loginUser(admin)
    [res, body] = yield request.postAsync { uri: achievementURL, json: achievementJSON }
    achievement = yield Achievement.findById(body._id)
    expect(res.statusCode).toBe(201)

    user = yield User.findById(user.id)
    expect(user.get('rewards')).toBeUndefined()

    yield utils.loginUser(user)
    [res, body] = yield request.postAsync({ url, json })
    expect(res.body.points).toBe(175)
    expect(res.body.earned.gems).toBe(50)

    achievement.set({
      updated: new Date().toISOString()
      rewards: { gems: 100 }
      worth: 200
    })
    yield achievement.save()

    [res, body] = yield request.postAsync({ url, json })
    expect(res.body.earned.gems).toBe(100)
    expect(res.body.points).toBe(300)
    expect(res.statusCode).toBe(200)

    # special case: no worth, should default to 10
    
    yield achievement.update({
      $set: {updated: new Date().toISOString()},
      $unset: {worth:''}
    })
    [res, body] = yield request.postAsync({ url, json })
    expect(res.body.earned.gems).toBe(100)
    expect(res.body.points).toBe(110)
    expect(res.statusCode).toBe(200)
    
  it 'works for level sessions', utils.wrap ->
    admin = yield utils.initAdmin()
    yield utils.loginUser(admin)
    level = yield utils.makeLevel()
    achievement = yield utils.makeAchievement({
      collection: 'level.sessions'
      userField: 'creator'
      query: {
        'level.original': level.get('original').toString()
        'state': {complete: true}
      }
      worth: 100
      proportionalTo: 'state.difficulty'
    })
    levelSession = yield utils.makeLevelSession({state: {complete: true, difficulty:2}}, { creator:admin, level })
    url = utils.getURL("/db/user/#{admin.id}/check-for-new-achievement")
    json = true
    [res, body] = yield request.postAsync({ url, json })
    expect(body.points).toBe(200)
    
    # check idempotency
    achievement.set('updated', new Date().toISOString())
    yield achievement.save()
    [res, body] = yield request.postAsync({ url, json })
    expect(body.points).toBe(200)
    admin = yield User.findById(admin.id)

  it 'skips achievements which have not been satisfied', utils.wrap ->
    admin = yield utils.initAdmin()
    yield utils.loginUser(admin)
    level = yield utils.makeLevel()
    achievement = yield utils.makeAchievement({
      collection: 'level.sessions'
      userField: 'creator'
      query: {
        'level.original': 'does not matter'
      }
      worth: 100
    })
    expect(admin.get('lastAchievementChecked')).toBeUndefined()
    url = utils.getURL("/db/user/#{admin.id}/check-for-new-achievement")
    json = true
    [res, body] = yield request.postAsync({ url, json })
    expect(body.points).toBeUndefined()
    admin = yield User.findById(admin.id)
    expect(admin.get('lastAchievementChecked')).toBe(achievement.get('updated'))

  it 'skips achievements which are not either for the users collection or the level sessions collection with level.original included', utils.wrap ->
    admin = yield utils.initAdmin()
    yield utils.loginUser(admin)
    achievement = yield utils.makeAchievement({
      collection: 'not.supported'
      userField: 'creator'
      query: {}
      worth: 100
    })
    expect(admin.get('lastAchievementChecked')).toBeUndefined()
    url = utils.getURL("/db/user/#{admin.id}/check-for-new-achievement")
    json = true
    [res, body] = yield request.postAsync({ url, json })
    expect(body.points).toBeUndefined()
    admin = yield User.findById(admin.id)
    expect(admin.get('lastAchievementChecked')).toBe(achievement.get('updated'))

    
describe 'POST /db/user/:userID/request-verify-email', ->
  mailChimp = require '../../../server/lib/mail-chimp'
  
  beforeEach utils.wrap ->
    spyOn(mailChimp.api, 'put').and.returnValue(Promise.resolve())
    @user = yield utils.initUser()
    verificationCode = @user.verificationCode(new Date().getTime())
    @url = utils.getURL("/db/user/#{@user.id}/verify/#{verificationCode}")
  
  it 'sets emailVerified to true and updates MailChimp', utils.wrap ->
    [res, body] = yield request.postAsync({ @url, json: true })
    expect(res.statusCode).toBe(200)
    expect(mailChimp.api.put).toHaveBeenCalled()
    user = yield User.findById(@user.id)
    expect(user.get('emailVerified')).toBe(true)
