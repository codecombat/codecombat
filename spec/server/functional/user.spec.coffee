require '../common'
request = require 'request'
User = require '../../../server/users/User'

urlUser = '/db/user'


describe 'Server user object', ->

  it 'uses the schema defaults to fill in email preferences', (done) ->
    user = new User()
    expect(user.isEmailSubscriptionEnabled('generalNews')).toBeTruthy()
    expect(user.isEmailSubscriptionEnabled('anyNotes')).toBeTruthy()
    expect(user.isEmailSubscriptionEnabled('recruitNotes')).toBeTruthy()
    expect(user.isEmailSubscriptionEnabled('archmageNews')).toBeFalsy()
    done()

  it 'uses old subs if they\'re around', (done) ->
    user = new User()
    user.set 'emailSubscriptions', ['tester']
    expect(user.isEmailSubscriptionEnabled('adventurerNews')).toBeTruthy()
    expect(user.isEmailSubscriptionEnabled('generalNews')).toBeFalsy()
    done()

  it 'maintains the old subs list if it\'s around', (done) ->
    user = new User()
    user.set 'emailSubscriptions', ['tester']
    user.setEmailSubscription('artisanNews', true)
    expect(JSON.stringify(user.get('emailSubscriptions'))).toBe(JSON.stringify(['tester', 'level_creator']))
    done()

describe 'User.updateServiceSettings', ->
  makeMC = (callback) ->
    spyOn(mc.lists, 'subscribe').and.callFake callback

  it 'uses emails to determine what to send to MailChimp', (done) ->
    makeMC (params) ->
      expect(JSON.stringify(params.merge_vars.groupings[0].groups)).toBe(JSON.stringify(['Announcements']))
      done()

    user = new User({emailSubscriptions: ['announcement'], email: 'tester@gmail.com'})
    User.updateServiceSettings(user)

describe 'POST /db/user', ->

  createAnonNameUser = (name, done)->
    request.post getURL('/auth/logout'), ->
      request.get getURL('/auth/whoami'), ->
        req = request.post(getURL('/db/user'), (err, response) ->
          expect(response.statusCode).toBe(200)
          request.get getURL('/auth/whoami'), (request, response, body) ->
            res = JSON.parse(response.body)
            expect(res.anonymous).toBeTruthy()
            expect(res.name).toEqual(name)
            done()
        )
        form = req.form()
        form.append('name', name)

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
      request.post getURL('/auth/logout'), ->
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
    req = request.post(getURL('/db/user'), (err, response, body) ->
      expect(response.statusCode).toBe(200)
      request.get getURL('/auth/whoami'), (request, response, body) ->
        res = JSON.parse(response.body)
        expect(res.anonymous).toBeFalsy()
        createAnonNameUser 'Jim', done
    )
    form = req.form()
    form.append('email', 'new@user.com')
    form.append('password', 'new')

describe 'PUT /db/user', ->

  it 'logs in as normal joe', (done) ->
    request.post getURL('/auth/logout'),
      loginJoe -> done()

  it 'denies requests without any data', (done) ->
    request.put getURL(urlUser),
      (err, res) ->
        expect(res.statusCode).toBe(422)
        expect(res.body).toBe('No input.')
        done()

  it 'denies requests to edit someone who is not joe', (done) ->
    unittest.getAdmin (admin) ->
      req = request.put getURL(urlUser),
      (err, res) ->
        expect(res.statusCode).toBe(403)
        done()
      req.form().append('_id', admin.id)

  it 'denies invalid data', (done) ->
    unittest.getNormalJoe (joe) ->
      req = request.put getURL(urlUser),
      (err, res) ->
        expect(res.statusCode).toBe(422)
        expect(res.body.indexOf('too long')).toBeGreaterThan(-1)
        done()
      form = req.form()
      form.append('_id', joe.id)
      form.append('email', 'farghlarghlfarghlarghlfarghlarghlfarghlarghlfarghlarghlfarghlar
ghlfarghlarghlfarghlarghlfarghlarghlfarghlarghlfarghlarghlfarghlarghlfarghlarghlfarghlarghl')

  it 'logs in as admin', (done) ->
    loginAdmin -> done()

  it 'denies non-existent ids', (done) ->
    req = request.put getURL(urlUser),
    (err, res) ->
      expect(res.statusCode).toBe(404)
      done()
    form = req.form()
    form.append('_id', '513108d4cb8b610000000004')
    form.append('email', 'perfectly@good.com')

  it 'denies if the email being changed is already taken', (done) ->
    unittest.getNormalJoe (joe) ->
      unittest.getAdmin (admin) ->
        req = request.put getURL(urlUser), (err, res) ->
          expect(res.statusCode).toBe(409)
          expect(res.body.indexOf('already used')).toBeGreaterThan(-1)
          done()
        form = req.form()
        form.append('_id', String(admin._id))
        form.append('email', joe.get('email').toUpperCase())

  it 'does not care if you include your existing name', (done) ->
    unittest.getNormalJoe (joe) ->
      req = request.put getURL(urlUser+'/'+joe._id), (err, res) ->
        expect(res.statusCode).toBe(200)
        done()
      form = req.form()
      form.append('_id', String(joe._id))
      form.append('name', 'Joe')

  it 'accepts name and email changes', (done) ->
    unittest.getNormalJoe (joe) ->
      req = request.put getURL(urlUser), (err, res) ->
        expect(res.statusCode).toBe(200)
        unittest.getUser('Wilhelm', 'New@email.com', 'null', (joe) ->
          expect(joe.get('name')).toBe('Wilhelm')
          expect(joe.get('emailLower')).toBe('new@email.com')
          expect(joe.get('email')).toBe('New@email.com')
          done())
      form = req.form()
      form.append('_id', String(joe._id))
      form.append('email', 'New@email.com')
      form.append('name', 'Wilhelm')

  it 'should not allow two users with the same name slug', (done) ->
    loginSam (sam) ->
      samsName = sam.get 'name'
      sam.set 'name', 'admin'
      request.put {uri:getURL(urlUser + '/' + sam.id), json: sam.toObject()}, (err, response) ->
        expect(err).toBeNull()
        expect(response.statusCode).toBe 409

        # Restore Sam
        sam.set 'name', samsName
        done()

  it 'should silently rename an anonymous user if their name conflicts upon signup', (done) ->
    request.post getURL('/auth/logout'), ->
      request.get getURL('/auth/whoami'), ->
        req = request.post getURL('/db/user'), (err, response) ->
          expect(response.statusCode).toBe(200)
          request.get getURL('/auth/whoami'), (err, response) ->
            expect(err).toBeNull()
            guy = JSON.parse(response.body)
            expect(guy.anonymous).toBeTruthy()
            expect(guy.name).toEqual 'admin'

            guy.email = 'blub@blub' # Email means registration
            req = request.post {url: getURL('/db/user'), json: guy}, (err, response) ->
              expect(err).toBeNull()
              finalGuy = response.body
              expect(finalGuy.anonymous).toBeFalsy()
              expect(finalGuy.name).not.toEqual guy.name
              expect(finalGuy.name.length).toBe guy.name.length + 1
              done()
        form = req.form()
        form.append('name', 'admin')

  it 'should be able to unset a slug by setting an empty name', (done) ->
    loginSam (sam) ->
      samsName = sam.get 'name'
      sam.set 'name', ''
      request.put {uri:getURL(urlUser + '/' + sam.id), json: sam.toObject()}, (err, response) ->
        expect(err).toBeNull()
        expect(response.statusCode).toBe 200
        newSam = response.body

        # Restore Sam
        sam.set 'name', samsName
        request.put {uri:getURL(urlUser + '/' + sam.id), json: sam.toObject()}, (err, response) ->
          expect(err).toBeNull()
          done()

describe 'GET /db/user', ->

  it 'logs in as admin', (done) ->
    req = request.post(getURL('/auth/login'), (error, response) ->
      expect(response.statusCode).toBe(200)
      done()
    )
    form = req.form()
    form.append('username', 'admin@afc.com')
    form.append('password', '80yqxpb38j')

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

  xit 'can fetch another user with restricted fields'

describe 'DELETE /db/user', ->
  it 'can delete a user', (done) ->
    loginNewUser (user1) ->
      beforeDeleted = new Date()
      request.del {uri: "#{getURL(urlUser)}/#{user1.id}"}, (err, res) ->
        expect(err).toBeNull()
        return done() if err
        User.findById user1.id, (err, user1) ->
          expect(err).toBeNull()
          return done() if err
          expect(user1.get('deleted')).toBe(true)
          expect(user1.get('dateDeleted')).toBeGreaterThan(beforeDeleted)
          expect(user1.get('dateDeleted')).toBeLessThan(new Date())
          for key, value of user1.toObject()
            continue if key in ['_id', 'deleted', 'dateDeleted']
            expect(_.isEmpty(value)).toEqual(true)
          done()

describe 'Statistics', ->
  LevelSession = require '../../../server/levels/sessions/LevelSession'
  Article = require '../../../server/articles/Article'
  Level = require '../../../server/levels/Level'
  LevelSystem = require '../../../server/levels/systems/LevelSystem'
  LevelComponent = require '../../../server/levels/components/LevelComponent'
  ThangType = require '../../../server/levels/thangs/ThangType'
  User = require '../../../server/users/User'
  UserHandler = require '../../../server/users/user_handler'

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

      # Create major version 1.0
      request.post {uri:url, json: article}, (err, res, body) ->
        expect(err).toBeNull()
        expect(res.statusCode).toBe 200
        article = body

        User.findById carl.get('id'), (err, guy) ->
          expect(err).toBeNull()
          expect(guy.get User.statsMapping.edits.article).toBe 1

          # Create minor version 1.1
          request.post {uri:url, json: article}, (err, res, body) ->
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
