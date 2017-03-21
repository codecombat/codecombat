# import this at the top of every file so we're not juggling connections
# and common libraries are available

console.log '/spec/server/common.coffee - Setting up spec globals...'
if process.env.COCO_MONGO_HOST
  throw Error('Tests may not run with production environment')

require '../../server' # make lodash globally available
mongoose = require 'mongoose'
path = require 'path'
GLOBAL.testing = true
GLOBAL.tv4 = require 'tv4' # required for TreemaUtils to work

User = require '../../server/models/User'

async = require 'async'

GLOBAL.clearModels = (models, done) ->

  funcs = []
  for model in models
    if model is User
      unittest.users = {}
    wrapped = (m) -> (callback) ->
      m.remove {}, (err) ->
        callback(err, true)
    funcs.push(wrapped(model))

  async.parallel funcs, (err, results) ->
    done(err)

GLOBAL.saveModels = (models, done) ->

  funcs = []
  for model in models
    wrapped = (m) -> (callback) ->
      m.save (err) ->
        callback(err, true)
    funcs.push(wrapped(model))

  async.parallel funcs, (err, results) ->
    done(err)

GLOBAL.simplePermissions = [target: 'public', access: 'owner']
GLOBAL.ObjectId = mongoose.Types.ObjectId

GLOBAL.unittest = {}
unittest.users = unittest.users or {}

unittest.getNormalJoe = (done, force) ->
  unittest.getUser('Joe', 'normal@jo.com', 'food', done, force)
unittest.getOtherSam = (done, force) ->
  unittest.getUser('Sam', 'other@sam.com', 'beer', done, force)
unittest.getAdmin = (done, force) ->
  unittest.getUser('Admin', 'admin@afc.com', '80yqxpb38j', done, force)

unittest.getUser = (name, email, password, done, force) ->
  # Creates the user if it doesn't already exist.

  return done(unittest.users[email]) if unittest.users[email] and not force
  request.post getURL('/auth/logout'), ->
    request.get getURL('/auth/whoami'), ->
      req = request.post({url: getURL('/db/user'), json: {email, password}}, (err, response, body) ->
        throw err if err
        User.findOne({email: email}).exec((err, user) ->
          throw err if err
          user.set('permissions', if password is '80yqxpb38j' then ['admin'] else [])
          user.set('name', name)
          user.save (err) ->
            wrapUpGetUser(email, user, done)
        )
      )

wrapUpGetUser = (email, user, done) ->
  unittest.users[email] = user
  return done(unittest.users[email])

GLOBAL.getURL = (path) ->
  return 'http://localhost:3001' + path

nameCount = 0
GLOBAL.createName = (name) ->
  name + nameCount++

GLOBAL.createCourse = (pricePerSeat, done) ->
  name = createName 'course '
  course = new Course
    name: name
    campaignID: ObjectId("55b29efd1cd6abe8ce07db0d")
    concepts: ['basic_syntax', 'arguments', 'while_loops', 'strings', 'variables']
    description: "Learn basic syntax, while loops, and the CodeCombat environment."
    pricePerSeat: pricePerSeat
    screenshot: "/images/pages/courses/101_info.png"
  course.save (err, course) =>
    return done(err) if err
    done(err, course)

GLOBAL.createPrepaid = (type, maxRedeemers, months, done) ->
  options = uri: GLOBAL.getURL('/db/prepaid/-/create')
  options.json =
    type: type
    maxRedeemers: maxRedeemers
  if months
    options.json.months = months
  request.post options, done

GLOBAL.fetchPrepaid = (ppc, done) ->
  options = uri: GLOBAL.getURL('/db/prepaid/-/code/'+ppc)
  request.get options, done

GLOBAL.purchasePrepaid = (type, properties, maxRedeemers, token, done) ->
  options = uri: GLOBAL.getURL('/db/prepaid/-/purchase')
  options.json =
    type: type
    maxRedeemers: maxRedeemers
    stripe:
      timestamp: new Date().getTime()
  options.json.stripe.token = token if token?
  if type is 'terminal_subscription'
    options.json.months = properties.months
  request.post options, done

GLOBAL.subscribeWithPrepaid = (ppc, done) =>
  options = url: GLOBAL.getURL('/db/subscription/-/subscribe_prepaid')
  options.json =
    ppc: ppc
  request.post options, done

newUserCount = 0
GLOBAL.createNewUser = (done) ->
  name = password = "user#{newUserCount++}"
  email = "#{name}@foo.bar"
  unittest.getUser name, email, password, done, true
GLOBAL.loginNewUser = (done) ->
  name = password = "user#{newUserCount++}"
  email = "#{name}@me.com"
  request.post getURL('/auth/logout'), ->
    unittest.getUser name, email, password, (user) ->
      json = {username: email, password}
      req = request.post({url: getURL('/auth/login'), json}, (error, response) ->
        expect(response.statusCode).toBe(200)
        done(user)
      )
    , true

GLOBAL.loginJoe = (done) ->
  request.post getURL('/auth/logout'), ->
    unittest.getNormalJoe (user) ->
      json = {username: 'normal@jo.com', password: 'food'}
      req = request.post({url: getURL('/auth/login'), json}, (error, response) ->
        expect(response.statusCode).toBe(200)
        done(user)
      )

GLOBAL.loginSam = (done) ->
  request.post getURL('/auth/logout'), ->
    unittest.getOtherSam (user) ->
      json = { username: 'other@sam.com', password: 'beer'}
      req = request.post({url: getURL('/auth/login'), json}, (error, response) ->
        expect(response.statusCode).toBe(200)
        done(user)
      )

GLOBAL.loginAdmin = (done) ->
  request.post getURL('/auth/logout'), ->
    unittest.getAdmin (user) ->
      json = { username: 'admin@afc.com', password: '80yqxpb38j' }
      req = request.post({url: getURL('/auth/login'), json}, (error, response) ->
        expect(response.statusCode).toBe(200)
        done(user)
      )
      # find some other way to make the admin object an admin... maybe directly?

GLOBAL.loginUser = (user, done) ->
  request.post getURL('/auth/logout'), ->
    json = { username: user.get('email'), password: user.get('name') }
    req = request.post({ url: getURL('/auth/login'), json}, (error, response) ->
      expect(response.statusCode).toBe(200)
      done(user)
    )

GLOBAL.logoutUser = (done) ->
  request.post getURL('/auth/logout'), ->
    done()

GLOBAL.dropGridFS = (done) ->
  if mongoose.connection.readyState is 2
    mongoose.connection.once 'open', ->
      _drop(done)
  else
    _drop(done)

_drop = (done) ->
  files = mongoose.connection.db.collection('media.files')
  files.remove {}, ->
    chunks = mongoose.connection.db.collection('media.chunks')
    chunks.remove {}, ->
      done()
      
GLOBAL.resetUserIDCounter = (number=0) ->
  User.idCounter = number

console.log '/spec/server/common.coffee - Done'
