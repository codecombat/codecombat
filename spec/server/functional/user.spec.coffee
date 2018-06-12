require '../common'
utils = require '../utils'
urlUser = '/db/user'
User = require '../../../server/models/User'
Clan = require '../../../server/models/Clan'
UserPollsRecord = require '../../../server/models/UserPollsRecord'
Classroom = require '../../../server/models/Classroom'
CourseInstance = require '../../../server/models/CourseInstance'
Course = require '../../../server/models/Course'
Campaign = require '../../../server/models/Campaign'
TrialRequest = require '../../../server/models/TrialRequest'
Prepaid = require '../../../server/models/Prepaid'
request = require '../request'
facebook = require '../../../server/lib/facebook'
intercom = require '../../../server/lib/intercom'
mailchimp = require '../../../server/lib/mail-chimp'
gplus = require '../../../server/lib/gplus'
sendgrid = require '../../../server/sendgrid'
Promise = require 'bluebird'
Achievement = require '../../../server/models/Achievement'
EarnedAchievement = require '../../../server/models/EarnedAchievement'
LevelSession = require '../../../server/models/LevelSession'
paypal = require '../../../server/lib/paypal'
mongoose = require 'mongoose'

describe 'POST /db/user', ->

  beforeEach utils.wrap ->
    yield utils.clearModels [User]

  it 'converts the password into a hash', utils.wrap ->
    yield utils.becomeAnonymous()
    email = 'some-name@email.com'
    password = 'food'
    [res] = yield request.postAsync({ url: utils.getURL('/db/user'), json: {email, password}})
    expect(res.statusCode).toBe(200)
    user = yield User.findById(res.body._id)
    expect(user).toBeTruthy()
    expect(user.get('password')).toBeUndefined()
    expect(user.get('passwordHash')[..5] in ['31dc3d', '948c7e']).toBeTruthy()
    expect(user.get('permissions')).toBeUndefined()


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
    email = _.times(50, -> 'farghlarghl').join('') + '@example.com'
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

  it 'returns 422 if both email and name would be unset for a student', utils.wrap ->
    user = yield utils.initUser({ role: 'student' })
    yield utils.loginUser(user)
    [res, body] = yield request.putAsync { uri: getURL('/db/user/'+user.id), json: { email: '', name: '' }}
    expect(body.code).toBe(422)
    expect(body.message).toEqual('User needs a username or email address')

  it 'allows unsetting email on student accounts, even when there\'s a user with email and emailLower set to empty string', utils.wrap ->
    invalidUser = yield utils.initUser()
    yield invalidUser.update({$set: {email: '', emailLower: ''}})
    user = yield utils.initUser({role: 'student'})
    yield utils.loginUser(user)
    [res, body] = yield request.putAsync { uri: getURL('/db/user/'+user.id), json: { email: '' }}
    expect(res.statusCode).toBe(200)
    expect(res.body.email).toBeUndefined()

  it 'does not allow unsetting email on individual accounts accounts', utils.wrap ->
    user = yield utils.initUser({ email: 'email@example.com' })
    yield utils.loginUser(user)
    [res, body] = yield request.putAsync { uri: getURL('/db/user/'+user.id), json: { email: undefined }}
    expect(res.statusCode).toBe(422)
    expect(res.body.email).toBeUndefined()
    [res, body] = yield request.putAsync { uri: getURL('/db/user/'+user.id), json: { email: '' }}
    expect(res.statusCode).toBe(422)
    expect(res.body.email).toBeUndefined()
    [res, body] = yield request.putAsync { uri: getURL('/db/user/'+user.id), json: { email: 'invalidemail' }}
    expect(res.statusCode).toBe(422)
    expect(res.body.email).toBeUndefined()
    expect((yield User.findById(user.id)).get('email')).toBe('email@example.com')

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

  it 'allows multiple anonymous users to have the same name, even with signed up users', utils.wrap ->
    name = 'Bob'
    yield utils.initUser({name}) # make an existing user

    user1 = yield utils.becomeAnonymous()
    [res] = yield request.putAsync { url: utils.getUrl("/db/user/#{user1.id}"), json: { name }}
    expect(res.statusCode).toBe(200)

    user2 = yield utils.becomeAnonymous()
    [res] = yield request.putAsync { url: utils.getUrl("/db/user/#{user2.id}"), json: { name }}
    expect(res.statusCode).toBe(200)


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

  it 'logs in as admin', utils.wrap ->
    admin = yield utils.initAdmin()
    yield utils.loginUser(admin)

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

  describe 'when get target is student', ->
    beforeEach utils.wrap ->
      @student = yield utils.initUser({ role: 'student' })
    describe 'and getter is same user', ->
      beforeEach utils.wrap ->
        yield utils.loginUser(@student)
      it 'get is allowed', utils.wrap ->
        url = utils.getURL("/db/user/#{@student.id}")
        [res, body] = yield request.getAsync({ url, json: true })
        expect(res.statusCode).toEqual(200)
    describe 'and getter is different non-admin user', ->
      beforeEach utils.wrap ->
        @getter = yield utils.initUser()
        yield utils.loginUser(@getter)
      it 'get is forbidden', utils.wrap ->
        url = utils.getURL("/db/user/#{@student.id}")
        [res, body] = yield request.getAsync({ url, json: true })
        expect(res.statusCode).toEqual(403)
    describe 'and getter is different admin user', ->
      beforeEach utils.wrap ->
        @getter = yield utils.initAdmin()
        yield utils.loginUser(@getter)
      it 'get is allowed', utils.wrap ->
        url = utils.getURL("/db/user/#{@student.id}")
        [res, body] = yield request.getAsync({ url, json: true })
        expect(res.statusCode).toEqual(200)
    describe 'and getter is their teacher', ->
      beforeEach utils.wrap ->
        @getter = yield utils.initUser({ role: 'teacher' })
        yield utils.loginUser(@getter)
        @classroom = yield utils.makeClassroom({aceConfig: { language: 'javascript' }}, { members: [@student] })
      it 'get is allowed', utils.wrap ->
        url = utils.getURL("/db/user/#{@student.id}")
        [res, body] = yield request.getAsync({ url, json: true })
        expect(res.statusCode).toEqual(200)
    xdescribe 'and getter is not their teacher', ->
      beforeEach utils.wrap ->
        @getter = yield utils.initUser({ role: 'teacher' })
        yield utils.loginUser(@getter)
      it 'get is forbidden', utils.wrap ->
        url = utils.getURL("/db/user/#{@student.id}")
        [res, body] = yield request.getAsync({ url, json: true })
        expect(res.statusCode).toEqual(403)

  # TODO Ruben should be able to fetch other users but probably with restricted data access
  # Add to the test case above an extra data check

#  xit 'can fetch another user with restricted fields'

describe 'GET /db/user?email=:email', ->
  beforeEach utils.wrap ->
    yield Promise.promisify(clearModels)([User])
    @admin = yield utils.initAdmin()
    @teacher1 = yield utils.initUser({ role: 'teacher' })
    @teacher2 = yield utils.initUser({
      role: 'teacher'
      email: 'teacher2@example.com'
      firstName: 'first'
      lastName: 'last'
    })
    @user = yield utils.initUser({
      email: 'user@example.com'
      firstName: 'user_first'
    })

  describe 'when user is a teacher', ->
    beforeEach utils.wrap ->
      yield utils.loginUser(@teacher1)

    describe 'and email matches a teacher', ->
      beforeEach utils.wrap ->
        @email = 'teacher2@example.com'
        @url = getURL("/db/user?email=#{@email}")

      it 'returns the user with username, full name, and email', utils.wrap ->
        [res, body] = yield request.getAsync({ url: @url, json: true })
        expect(res.statusCode).toBe(200)
        expect(body.email).toBe(@teacher2.get('email'))
        expect(body.name).toBe(@teacher2.get('name'))
        expect(body.firstName).toBe(@teacher2.get('firstName'))
        expect(body.lastName).toBe(@teacher2.get('lastName'))
        expect(body.passwordHash).toBeUndefined()

    describe 'and email matches a non-teacher', ->
      beforeEach utils.wrap ->
        @email = 'user@example.com'
        @url = getURL("/db/user?email=#{@email}")

      it 'returns 403', utils.wrap ->
        [res, body] = yield request.getAsync({ url: @url, json: true })
        expect(res.statusCode).toBe(403)

    describe "and email doesn't match any users", ->
      beforeEach utils.wrap ->
        @email = 'nobody@example.com'
        @url = getURL("/db/user?email=#{@email}")

      it 'returns 404', utils.wrap ->
        [res, body] = yield request.getAsync({ url: @url, json: true })
        expect(res.statusCode).toBe(404)

  describe 'when user is an admin', ->
    beforeEach utils.wrap ->
      yield utils.loginUser(@admin)

    describe 'and email matches a user', ->
      beforeEach utils.wrap ->
        @email = 'user@example.com'
        @url = getURL("/db/user?email=#{@email}")

      it 'returns the user with private attributes', utils.wrap ->
        [res, body] = yield request.getAsync({ url: @url, json: true })
        expect(res.statusCode).toBe(200)
        expect(body.role).toBe(@user.get('role'))
        expect(body.email).toBe(@user.get('email'))
        expect(body.name).toBe(@user.get('name'))
        expect(body.firstName).toBe(@user.get('firstName'))
        expect(body.permissions).toEqual(@user.get('permissions'))

    describe "and email doesn't match any users", ->
      beforeEach utils.wrap ->
        @email = 'nobody@example.com'
        @url = getURL("/db/user?email=#{@email}")

      it 'returns 404', utils.wrap ->
        [res, body] = yield request.getAsync({ url: @url, json: true })
        expect(res.statusCode).toBe(404)

  describe 'when user is not a teacher nor an admin', ->
    beforeEach utils.wrap ->
      yield utils.loginUser(@user)
      @email = 'whatever'
      @url = getURL("/db/user?email=#{@email}")

    it 'returns 403', utils.wrap ->
      [res, body] = yield request.getAsync({ url: @url, json: true })
      expect(res.statusCode).toBe(403)

describe 'GET /db/user/:handle', ->
  it 'populates coursePrepaid from coursePrepaidID', utils.wrap ->
    user = yield utils.initUser({coursePrepaidID: mongoose.Types.ObjectId()})
    yield utils.loginUser(user)
    [res, body] = yield request.getAsync({url: getURL("/db/user/#{user.id}"), json: true})
    expect(res.statusCode).toBe(200)
    expect(res.body.coursePrepaid._id).toBe(user.get('coursePrepaidID').toString())
    expect(res.body.coursePrepaid.startDate).toBe(Prepaid.DEFAULT_START_DATE)

  it 'looks up the user by id', utils.wrap ->
    user = yield utils.initUser()
    yield utils.becomeAnonymous()
    url = utils.getURL("/db/user/#{user.id}")
    [res] = yield request.getAsync({url, json: true})
    expect(res.statusCode).toBe(200)
    expect(res.body.name).toBe(user.get('name'))  # Anyone should be served the username.
    expect(res.body.email).toBeUndefined()  # Shouldn't be available to anonymous users.
    expect(res.body.passwordHash).toBeUndefined()


describe 'DELETE /db/user/:handle', ->
  beforeEach ->
    spyOn(intercom.users, 'delete')
    spyOn(mailchimp.api ,'delete')
  
  it 'can delete a user', utils.wrap ->
    user = yield utils.initUser()
    yield utils.loginUser(user)
    beforeDeleted = new Date()
    [res, body] = yield request.delAsync {uri: "#{getURL(urlUser)}/#{user.id}"}
    user = yield User.findById user.id
    expect(user.get('deleted')).toBe(true)
    expect(user.get('dateDeleted')).toBeGreaterThan(beforeDeleted)
    expect(user.get('dateDeleted')).toBeLessThan(new Date())
    expect(user.get('deletedEmailHash')).toBeDefined() # includes a hash for checking later if the email were deleted, and when
    for key, value of user.toObject()
      continue if key in ['_id', 'deleted', 'dateDeleted', 'deletedEmailHash', 'consentHistory']
      expect(_.isEmpty(value)).toEqual(true)
    expect(intercom.users.delete).toHaveBeenCalled()
    expect(mailchimp.api.delete).toHaveBeenCalled()

  it 'completely removes the user from any classroom or clan', utils.wrap ->

    clanOwner = yield utils.initUser()
    yield utils.loginUser(clanOwner)
    clan = yield utils.makeClan({type: 'public'})

    clanUrl = utils.getUrl("/db/clan/#{clan.id}/join")
    user = yield utils.initUser()
    yield utils.loginUser(user)
    [res] = yield request.putAsync { url:clanUrl, json: true }
    user2 = yield utils.initUser()
    yield utils.loginUser(user2)
    [res] = yield request.putAsync { url:clanUrl, json: true }

    clan = yield Clan.findById(clan.id)
    expect(clan.get('members').length).toBe(3) # includes owner

    user2 = yield utils.initUser()
    yield utils.loginUser(user)
    classroom = new Classroom({
      members: [user._id, user2._id]
    })
    yield classroom.save()
    [res, body] = yield request.delAsync {uri: "#{getURL(urlUser)}/#{user.id}"}
    classroom = yield Classroom.findById(classroom.id)
    expect(classroom.get('members').length).toBe(1)
    expect(classroom.get('members')[0].toString()).toEqual(user2.id)

    clan = yield Clan.findById(clan.id)
    expect(clan.get('members').length).toBe(2)

  it 'deletes all user sesions, poll responses, and trial requests of the user', utils.wrap ->
    admin = yield utils.initAdmin()
    yield utils.loginUser(admin)
    poll = yield utils.makePoll()
    user = yield utils.initUser()
    level = yield utils.makeLevel()
    otherUser = yield utils.initUser()

    # setup one user
    yield utils.loginUser(user)
    trialRequest = yield utils.makeTrialRequest()
    [res] = yield request.getAsync({ url: utils.getUrl("/db/user.polls.record/-/user/#{user.id}"), json: true })
    pollRecordId = res.body._id
    pollRecord = UserPollsRecord.findById(pollRecordId)
    expect(pollRecord).toBeTruthy()
    session = yield utils.makeLevelSession({code:'...', submittedCode: '...'}, { level, creator: user })

    # setup other user
    yield utils.loginUser(otherUser)
    otherTrialRequest = yield utils.makeTrialRequest()
    [res] = yield request.getAsync({ url: utils.getUrl("/db/user.polls.record/-/user/#{otherUser.id}"), json: true })
    otherPollRecordId = res.body._id
    otherPollRecord = UserPollsRecord.findById(otherPollRecordId)
    expect(otherPollRecord).toBeTruthy()
    otherSession = yield utils.makeLevelSession({code:'...', submittedCode: '...'}, { level, creator: otherUser })

    # check existence
    expect(yield TrialRequest.findById(trialRequest.id)).toBeTruthy()
    expect(yield UserPollsRecord.findById(pollRecordId)).toBeTruthy()
    expect(yield LevelSession.findById(session.id)).toBeTruthy()

    # delete user
    yield utils.loginUser(user)
    [res, body] = yield request.delAsync {uri: "#{getURL(urlUser)}/#{user.id}"}
    user = yield User.findById user.id
    expect(user.get('deleted')).toBe(true)

    # check that user's stuff is gone
    expect(yield TrialRequest.findById(trialRequest.id)).toBeFalsy()
    expect(yield UserPollsRecord.findById(pollRecordId)).toBeFalsy()
    expect(yield LevelSession.findById(session.id)).toBeFalsy()

    # check other user's stuff is still with us
    expect(yield TrialRequest.findById(otherTrialRequest.id)).toBeTruthy()
    expect(yield UserPollsRecord.findById(otherPollRecordId)).toBeTruthy()
    expect(yield LevelSession.findById(otherSession.id)).toBeTruthy()

  it 'returns 401 if no cookie session', utils.wrap ->
    yield utils.logout()
    [res, body] = yield request.delAsync {uri: "#{getURL(urlUser)}/1234"}
    expect(res.statusCode).toBe(401)

  it 'returns 403 if another non-admin user', utils.wrap ->
    user = yield utils.initUser()
    user2 = yield utils.initUser()
    yield utils.loginUser(user2)
    [res, body] = yield request.delAsync {uri: "#{getURL(urlUser)}/#{user.id}"}
    expect(res.statusCode).toBe(403)

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

  describe 'when PayPal subscribed', ->
    it 'deleting user unsubscribes', utils.wrap ->
      user = yield utils.initUser()
      user.set('payPal.billingAgreementID', 'foo')
      yield user.save()
      yield utils.loginUser(user)
      spyOn(paypal.billingAgreement, 'cancelAsync').and.returnValue(Promise.resolve({}))
      [res, body] = yield request.delAsync {uri: "#{getURL(urlUser)}/#{user.id}"}
      user = yield User.findById user.id
      expect(user.get('payPal.billingAgreementID')).not.toBeDefined()

  describe 'when the user is the recipient of a subscription', ->
    beforeEach utils.wrap ->
      yield utils.clearModels([User])
      @recipient1 = yield utils.initUser()
      @recipient2 = yield utils.initUser()
      @sponsor = yield utils.initUser({
        stripe: {
          customerID: 'a'
          sponsorSubscriptionID: '1'
          recipients: [
            {
              userID: @recipient1.id
              subscriptionID: '2'
              couponID: 'free'
            }
            {
              userID: @recipient2.id
              subscriptionID: '3'
              couponID: 'free'
            }
          ]
        }
      })
      yield @recipient1.update({$set: {stripe: {sponsorID: @sponsor.id}}})
      yield @recipient2.update({$set: {stripe: {sponsorID: @sponsor.id}}})
      yield utils.populateProducts()
      spyOn(stripe.customers, 'cancelSubscription').and.callFake (cId, sId, cb) -> cb(null)
      spyOn(stripe.customers, 'updateSubscription').and.callFake (cId, sId, opts, cb) -> cb(null)

    it 'unsubscribes the user', utils.wrap ->
      yield utils.loginUser(@recipient1)
      [res] = yield request.delAsync {uri: "#{getURL(urlUser)}/#{@recipient1.id}"}
      expect(res.statusCode).toBe(204)
      expect(stripe.customers.cancelSubscription).toHaveBeenCalled()
      expect(stripe.customers.updateSubscription).toHaveBeenCalled()
      expect((yield User.findById(@sponsor.id)).get('stripe').recipients.length).toBe(1)
      expect((yield User.findById(@recipient1.id)).get('stripe')).toBeUndefined()
      expect((yield User.findById(@recipient2.id)).get('stripe')).toBeDefined()

    describe 'when the sponsor id is incorrect', ->
      beforeEach utils.wrap ->
        admin = yield utils.initAdmin()
        yield utils.loginUser(admin)
        # Set it to another valid ID that isn't the sponsor's ID
        yield @recipient1.update({ $set: {stripe: {sponsorID: new ObjectId()}} })

      it 'returns 422', utils.wrap ->
        yield utils.loginUser(@recipient1)
        [res] = yield request.delAsync {uri: "#{getURL(urlUser)}/#{@recipient1.id}"}
        expect(res.statusCode).toBe(422)
        expect(stripe.customers.cancelSubscription).not.toHaveBeenCalled()
        expect(stripe.customers.updateSubscription).not.toHaveBeenCalled()

describe 'Statistics', ->
  LevelSession = require '../../../server/models/LevelSession'
  Article = require '../../../server/models/Article'
  Level = require '../../../server/models/Level'
  LevelSystem = require '../../../server/models/LevelSystem'
  LevelComponent = require '../../../server/models/LevelComponent'
  ThangType = require '../../../server/models/ThangType'
  User = require '../../../server/models/User'
  UserHandler = require '../../../server/handlers/user_handler'

  beforeEach utils.wrap ->
    session = new LevelSession
      name: 'Beat Gandalf'
      permissions: simplePermissions
      state: complete: true

    @user = yield utils.initUser()
    expect(@user.get 'stats.gamesCompleted').toBeUndefined()
    session.set 'creator', @user.get 'id'
    yield session.save()
    yield new Promise((resolve) -> setTimeout(resolve, 100)) # give time for update to happen

  it 'keeps track of games completed', utils.wrap ->
    user = yield User.findById(@user.id)
    expect(user.get 'stats.gamesCompleted').toBe 1

  it 'recalculates games completed', utils.wrap (done) ->
    admin = yield utils.initAdmin()
    yield utils.loginUser(admin)
    user = yield User.findByIdAndUpdate(@user.get('id'), {$unset:'stats.gamesCompleted': ''}, {new: true})
    expect(user.get 'stats.gamesCompleted').toBeUndefined()
    UserHandler.statRecalculators.gamesCompleted ->
      User.findById user.get('id'), (err, user) ->
        expect(err).toBeNull()
        expect(user.get 'stats.gamesCompleted').toBe 1
        done()

  it 'keeps track of article edits', utils.wrap ->
    article =
      name: 'My very first'
      body: 'I don\'t have much to say I\'m afraid'
    url = getURL('/db/article')

    admin = yield utils.initAdmin()
    yield utils.loginUser(admin)

    expect(admin.get User.statsMapping.edits.article).toBeUndefined()
    article.creator = admin.get 'id'

    [res] = yield request.postAsync {uri:url, json: article}
    expect(res.statusCode).toBe 201
    article = res.body

    guy = yield User.findById admin.get('id')
    expect(guy.get User.statsMapping.edits.article).toBe 1

    # Create minor version 0.1
    newVersionURL = "#{url}/#{article._id}/new-version"
    [res] = yield request.postAsync {uri:newVersionURL, json: article}

    guy = yield User.findById admin.get('id')
    expect(guy.get User.statsMapping.edits.article).toBe 2

  it 'recalculates article edits', utils.wrap (done) ->
    article =
      name: 'Second article'
      body: '...'
    url = getURL('/db/article')

    admin = yield utils.initAdmin()
    yield utils.loginUser(admin)

    [res] = yield request.postAsync {uri:url, json: article}
    expect(res.statusCode).toBe 201

    guy = yield User.findByIdAndUpdate(admin.get('id'), {$unset:'stats.articleEdits': ''}, {new: true})
    expect(guy.get User.statsMapping.edits.article).toBeUndefined()

    UserHandler.statRecalculators.articleEdits ->
      User.findById admin.get('id'), (err, guy) ->
        expect(err).toBeNull()
        expect(guy.get User.statsMapping.edits.article).toBe 1
        done()

  it 'keeps track of and recalculates level edits', utils.wrap (done) ->
    level = new Level
      name: "King's Peak 3"
      description: 'Climb a mountain.'
      permissions: simplePermissions
      scripts: []
      thangs: []

    admin = yield utils.initAdmin()
    yield utils.loginUser(admin)

    expect(admin.get User.statsMapping.edits.level).toBeUndefined()
    level.creator = admin.get 'id'
    yield level.save()
    guy = yield User.findById admin.get('id')
    expect(guy.get User.statsMapping.edits.level).toBe 1

    guy = yield User.findByIdAndUpdate(admin.get('id'), {$unset:'stats.levelEdits':''}, {new: true})
    expect(guy.get User.statsMapping.edits.level).toBeUndefined()

    UserHandler.statRecalculators.levelEdits ->
      User.findById admin.get('id'), (err, guy) ->
        expect(guy.get User.statsMapping.edits.level).toBe 1
        done()



describe 'GET /db/user/:handle/level.sessions', ->
  url = getURL('/db/level.session/')
  session =
    permissions: simplePermissions

  beforeEach utils.wrap ->
    yield utils.clearModels([LevelSession, User])
    @user = yield utils.initUser()
    session = new LevelSession({
      permissions: simplePermissions,
      creator: @user.id
    })
    yield session.save()
    yield utils.loginUser(@user)

  it 'gets a user\'s level sessions by id', utils.wrap ->
    [res] = yield request.getAsync {
      url: getURL("/db/user/#{@user.id}/level.sessions")
      json: true
    }
    expect(res.statusCode).toBe 200
    sessions = res.body
    expect(sessions.length).toBe 1

  it 'gets a user\'s level sessions by slug', utils.wrap ->
    [res] = yield request.getAsync {
      url: getURL("/db/user/#{@user.get('slug')}/level.sessions")
      json: true
    }
    expect(res.statusCode).toBe 200
    sessions = res.body
    expect(sessions.length).toBe 1

  it 'GET /db/user/<IDorSLUG>/level.sessions returns 404 if user not found', utils.wrap ->
    [res] = yield request.getAsync {
      url: getURL("/db/user/misterschtroumpf/level.sessions")
      json: true
    }
    expect(res.statusCode).toBe 404


describe 'POST /db/user/:handle/signup-with-password', ->

  beforeEach utils.wrap ->
    yield utils.clearModels([User])
    yield new Promise((resolve) -> setTimeout(resolve, 10))

  it 'signs up the user with the password and sends welcome emails', utils.wrap ->
    spyOn(sendgrid.api, 'send').and.returnValue(Promise.resolve())
    user = yield utils.becomeAnonymous()
    url = getURL("/db/user/#{user.id}/signup-with-password")
    email = 'some@email.com'
    name = 'someusername'
    json = { name, email, password: '12345' }
    [res, body] = yield request.postAsync({url, json, headers: {'host':'codecombat.com'}})
    expect(res.statusCode).toBe(200)
    updatedUser = yield User.findById(user.id)
    expect(updatedUser.get('email')).toBe(email)
    expect(updatedUser.get('passwordHash')).toBeDefined()
    expect(sendgrid.api.send).toHaveBeenCalled()
    context = sendgrid.api.send.calls.argsFor(0)[0]
    expect(_.str.startsWith(context.substitutions.verify_link, "https://codecombat.com/user/#{user.id}/verify/")).toBe(true)


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
    spyOn(sendgrid.api, 'send').and.returnValue(Promise.resolve())
    user = yield utils.becomeAnonymous()
    url = getURL("/db/user/#{user.id}/signup-with-facebook")
    json = { name, email: facebookEmail, facebookID, facebookAccessToken: '...' }
    [res, body] = yield request.postAsync({url, json})
    expect(res.statusCode).toBe(200)
    updatedUser = yield User.findById(user.id)
    expect(updatedUser.get('name')).toBe(name)
    expect(updatedUser.get('email')).toBe(facebookEmail)
    expect(updatedUser.get('facebookID')).toBe(facebookID)
    expect(sendgrid.api.send).toHaveBeenCalled()

  it 'signs up nameless user with the facebookID', utils.wrap ->
    spyOn(facebook, 'fetchMe').and.returnValue(validFacebookResponse)
    spyOn(sendgrid.api, 'send').and.returnValue(Promise.resolve())
    user = yield utils.becomeAnonymous()
    url = getURL("/db/user/#{user.id}/signup-with-facebook")
    json = { email: facebookEmail, facebookID, facebookAccessToken: '...' }
    [res, body] = yield request.postAsync({url, json})
    expect(res.statusCode).toBe(200)
    updatedUser = yield User.findById(user.id)
    expect(updatedUser.get('name')).toBeUndefined()
    expect(updatedUser.get('email')).toBe(facebookEmail)
    expect(updatedUser.get('facebookID')).toBe(facebookID)

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
    spyOn(sendgrid.api, 'send').and.returnValue(Promise.resolve())
    user = yield utils.becomeAnonymous()
    url = getURL("/db/user/#{user.id}/signup-with-gplus")
    json = { name, email: gplusEmail, gplusID, gplusAccessToken: '...' }
    [res, body] = yield request.postAsync({url, json})
    expect(res.statusCode).toBe(200)
    updatedUser = yield User.findById(user.id)
    expect(updatedUser.get('name')).toBe(name)
    expect(updatedUser.get('email')).toBe(gplusEmail)
    expect(updatedUser.get('gplusID')).toBe(gplusID)
    expect(sendgrid.api.send).toHaveBeenCalled()

  it 'signs up nameless user with the gplusID', utils.wrap ->
    spyOn(gplus, 'fetchMe').and.returnValue(validGPlusResponse)
    spyOn(sendgrid.api, 'send').and.returnValue(Promise.resolve())
    user = yield utils.becomeAnonymous()
    url = getURL("/db/user/#{user.id}/signup-with-gplus")
    json = { email: gplusEmail, gplusID, gplusAccessToken: '...' }
    [res, body] = yield request.postAsync({url, json})
    expect(res.statusCode).toBe(200)
    updatedUser = yield User.findById(user.id)
    expect(updatedUser.get('name')).toBeUndefined()
    expect(updatedUser.get('email')).toBe(gplusEmail)
    expect(updatedUser.get('gplusID')).toBe(gplusID)

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


describe 'POST /db/user/:userID/verify/:verificationCode', ->
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

describe 'POST /db/user/:userID/keep-me-updated/:verificationCode', ->
  beforeEach utils.wrap ->
    @user = yield utils.initUser({emails: {generalNews: {enabled: false}}})
    verificationCode = @user.verificationCode(new Date().getTime())
    @url = utils.getURL("/db/user/#{@user.id}/keep-me-updated/#{verificationCode}")

  it 'sets emails.generalNews.enabled to true', utils.wrap ->
    expect(@user.get('emails').generalNews.enabled).toEqual(false)
    [res, body] = yield request.postAsync({ @url, json: true })
    expect(res.statusCode).toBe(200)
    user = yield User.findById(@user.id)
    expect(user.get('emails').generalNews.enabled).toEqual(true)

describe 'POST /db/user/:userID/no-delete-eu/:verificationCode', ->
  beforeEach utils.wrap ->
    @user = yield utils.initUser()
    verificationCode = @user.verificationCode(new Date().getTime())
    @url = utils.getURL("/db/user/#{@user.id}/no-delete-eu/#{verificationCode}")

  it 'sets doNotDeleteEU to set date', utils.wrap ->
    [res, body] = yield request.postAsync({ @url, json: true })
    expect(res.statusCode).toBe(200)
    user = yield User.findById(@user.id)
    expect(user.get('doNotDeleteEU')).toBeTruthy()
    expect(user.get('doNotDeleteEU') < new Date()).toEqual(true)

describe 'POST /db/user/:userID/request-verify-email', ->
  beforeEach utils.wrap ->
    spyOn(sendgrid.api, 'send').and.returnValue(Promise.resolve())
    @user = yield utils.initUser()
    @url = utils.getURL("/db/user/#{@user.id}/request-verify-email")

  it 'sends an email with a verification link to the user', utils.wrap ->
    [res, body] = yield request.postAsync({ @url, json: true, headers: {'x-forwarded-proto': 'http'} })
    expect(res.statusCode).toBe(200)
    expect(sendgrid.api.send).toHaveBeenCalled()
    message = sendgrid.api.send.calls.argsFor(0)[0]
    expect(_.str.startsWith(message.substitutions.verify_link, "http://localhost:3001/user/#{@user.id}/verify/")).toBe(true)


describe 'POST /db/user/:userId/reset_progress', ->
  it 'clears the user\'s level sessions, earned achievements and various user settings', utils.wrap ->
    userSettings = {
      points: 10,
      stats: { gamesCompleted: 10 }
      earned: { gems: 10, levels: ['1234'] },
      purchased: { items: ['abcd'] }
      spent: 10
      heroConfig: {thangType: 'qwerty'}
    }

    user = yield utils.initUser(userSettings)
    otherUser = yield utils.initUser(userSettings)

    yield utils.loginUser(otherUser)
    otherSession = yield utils.makeLevelSession({}, {creator:otherUser})
    otherEarnedAchievement = new EarnedAchievement({ user: otherUser.id })
    yield otherEarnedAchievement.save()

    yield utils.loginUser(user)
    session = yield utils.makeLevelSession({}, {creator:user})
    earnedAchievement = new EarnedAchievement({ user: user.id })
    yield earnedAchievement.save()

    url = utils.getUrl("/db/user/#{user.id}/reset_progress")
    [res] = yield request.postAsync({ url })
    expect(res.statusCode).toBe(200)

    stillExist = yield [
      LevelSession.findById(session.id)
      EarnedAchievement.findById(earnedAchievement.id)
    ]
    expect(_.any(stillExist)).toBe(false)

    othersStillExist = yield [
      LevelSession.findById(otherSession.id)
      EarnedAchievement.findById(otherEarnedAchievement.id)
    ]
    expect(_.all(othersStillExist)).toBe(true) # did not delete other user stuff

    user = yield User.findById(user.id).lean()
    expect(user.points).toBe(0)
    expect(user.stats.gamesCompleted).toBe(0)
    expect(user.earned.gems).toBe(0)
    expect(user.earned.levels).toDeepEqual([])
    expect(user.purchased.items).toDeepEqual([])
    expect(user.spent).toBe(0)
    expect(user.heroConfig).toBeUndefined()

    otherUser = yield User.findById(otherUser.id).lean()
    expect(otherUser.points).toBe(10)

  it 'allows anonymous users to reset their progress', utils.wrap ->
    user = yield utils.becomeAnonymous()
    url = utils.getUrl("/db/user/#{user.id}/reset_progress")
    [res, body] = yield request.postAsync({ url })
    expect(res.statusCode).toBe(200)

  it 'returns 403 for other users', utils.wrap ->
    user1 = yield utils.initUser()
    user2 = yield utils.initUser()
    yield utils.loginUser(user1)
    url = utils.getUrl("/db/user/#{user2.id}/reset_progress")
    [res] = yield request.postAsync({ url })
    expect(res.statusCode).toBe(403)

  it 'returns 403 for admins', utils.wrap ->
    admin = yield utils.initAdmin()
    yield utils.loginUser(admin)
    url = utils.getUrl("/db/user/#{admin.id}/reset_progress")
    [res] = yield request.postAsync({ url })
    expect(res.statusCode).toBe(403)

  it 'returns 401 for non-logged in users', utils.wrap ->
    yield utils.logout()
    url = utils.getUrl("/db/user/12345/reset_progress")
    [res] = yield request.postAsync({ url })
    expect(res.statusCode).toBe(401)

  it 'allows admins to reset other accounts', utils.wrap ->
    admin = yield utils.initAdmin()
    user = yield utils.initUser()
    yield utils.loginUser(user)
    session = yield utils.makeLevelSession({}, {creator:user})
    earnedAchievement = new EarnedAchievement({ user: user.id })
    yield earnedAchievement.save()

    yield utils.loginUser(admin)
    url = utils.getUrl("/db/user/#{user.id}/reset_progress")
    [res] = yield request.postAsync({ url })
    expect(res.statusCode).toBe(200)
    stillExist = yield [
      LevelSession.findById(session.id)
      EarnedAchievement.findById(earnedAchievement.id)
    ]
    expect(_.any(stillExist)).toBe(false)

  it 'returns 404 for non-existent users', utils.wrap ->
    admin = yield utils.initAdmin()
    yield utils.loginUser(admin)
    url = utils.getUrl("/db/user/dne/reset_progress")
    [res] = yield request.postAsync({ url })
    expect(res.statusCode).toBe(404)


describe 'GET /db/user/:handle/clans', ->
  it 'returns that user\'s public clans only, unless fetching ones own clans', utils.wrap ->
    user = yield utils.initUser({stripe: {free: true}})
    url = utils.getUrl("/db/user/#{user.id}/clans")

    yield utils.loginUser(user)
    publicClan = yield utils.makeClan({type: 'public'})
    privateClan = yield utils.makeClan({type: 'private'})

    [res] = yield request.getAsync { url, json: true }
    expect(res.statusCode).toBe(200)
    expect(res.body.length).toBe(2)
    expect(_.find(res.body, {_id: publicClan.id})).toBeTruthy()
    expect(_.find(res.body, {_id: privateClan.id})).toBeTruthy()

    otherUser = yield utils.initUser()
    yield utils.loginUser(otherUser)
    [res] = yield request.getAsync { url, json: true }
    expect(res.statusCode).toBe(200)
    expect(res.body.length).toBe(1)
    expect(_.find(res.body, {_id: publicClan.id})).toBeTruthy()
    expect(_.find(res.body, {_id: privateClan.id})).toBeFalsy()




describe 'GET /db/user/:handle/avatar', ->
  it 'defaults to a wizard if no hero is set', utils.wrap ->
    user = yield utils.initUser({email:'test@gmail.com'})
    url = utils.getUrl("/db/user/#{user.id}/avatar")
    [res] = yield request.getAsync({url, followRedirect: false})
    expect(res.statusCode).toBe(302)
    expect(res.headers.location).toBe('http://localhost:3001/file/db/thang.type/52a00d55cf1818f2be00000b/portrait.png')

  it 'defaults to a hero portrait if the user has one set', utils.wrap ->
    user = yield utils.initUser({heroConfig:{thangType:'1234'}})
    url = utils.getUrl("/db/user/#{user.id}/avatar")
    [res] = yield request.getAsync({url, followRedirect: false})
    expect(res.statusCode).toBe(302)
    expect(res.headers.location).toBe('http://localhost:3001/file/db/thang.type/1234/portrait.png')

  it 'allows overriding the fallback value', utils.wrap ->
    user = yield utils.initUser()
    url = utils.getUrl("/db/user/#{user.id}/avatar")
    [res] = yield request.getAsync({url, followRedirect: false, qs: {fallback: '/some/other/url.jpg'}})
    expect(res.statusCode).toBe(302)
    expect(res.headers.location).toBe('http://localhost:3001/some/other/url.jpg')

  it 'adjusts the host based on the given protocol and host', utils.wrap ->
    user = yield utils.initUser()
    url = utils.getUrl("/db/user/#{user.id}/avatar")
    [res] = yield request.getAsync({url, followRedirect: false, headers: {'x-forwarded-proto': 'http', host: 'subdomain.codecombat.com', 'x-forwarded-port': '8080'}})
    expect(res.statusCode).toBe(302)
    expect(_.str.startsWith(res.headers.location, 'http://subdomain.codecombat.com:8080/')).toBe(true)


describe 'GET /db/user/:handle/course-instances', ->
  beforeEach utils.wrap ->
    @campaignSlug = 'intro'
    @student = yield utils.initUser({ role: 'student' })
    @admin = yield utils.initAdmin()
    yield utils.loginUser(@admin)
    @campaign = yield utils.makeCampaign({ name: 'Intro' })
    @course = yield utils.makeCourse({free: true, releasePhase: 'released'}, { @campaign })
    @teacher = yield utils.initUser({ role: 'teacher' })
    yield utils.loginUser(@teacher)
    @classroom = yield utils.makeClassroom({}, { members: [@student] })
    @courseInstance = yield utils.makeCourseInstance({}, { @course, @classroom, members: [@student] })
    yield utils.loginUser(@student)

  it "returns a corresponding courseInstance for the classroom version's course", utils.wrap ->
    url = utils.getUrl("/db/user/#{@student.id}/course-instances")
    qs = {campaignSlug: @campaign.get('slug')}
    [res] = yield request.getAsync({url, qs, json: true})
    expect(res.body.length).toBe(1)
    expect(res.body[0]._id).toBe(@courseInstance.id)


describe 'PUT /db/user/:handle/verifiedTeacher', ->
  it 'sets the verifiedTeacher property on the given user', utils.wrap ->
    user = yield utils.initUser()
    admin = yield utils.initAdmin()
    yield utils.loginUser(admin)
    url = utils.getUrl("/db/user/#{user.id}/verifiedTeacher")
    [res] = yield request.putAsync({url, json: true, body: true})
    expect(res.statusCode).toBe(200)
    expect(res.body.verifiedTeacher).toBe(true)
    user = yield User.findById(user.id)
    expect(user.get('verifiedTeacher')).toBe(true)

  it 'returns 403 unless you are an admin', utils.wrap ->
    user = yield utils.initUser()
    yield utils.loginUser(user)
    url = utils.getUrl("/db/user/#{user.id}/verifiedTeacher")
    [res] = yield request.putAsync({url, json: true, body: true})
    expect(res.statusCode).toBe(403)
