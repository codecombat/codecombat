# import this at the top of every file so we're not juggling connections
# and common libraries are available

console.log 'IT BEGINS'
if process.env.COCO_MONGO_HOST
  throw Error('Tests may not run with production environment')

require 'jasmine-spec-reporter'
jasmine.getEnv().defaultTimeoutInterval = 300000
jasmine.getEnv().reporter.subReporters_ = []
jasmine.getEnv().addReporter(new jasmine.SpecReporter({
  displayFailedSpec: true
  displayPendingSpec: true
  displaySpecDuration: true
  displaySuccessfulSpec: true
  }))

rep = new jasmine.JsApiReporter()
jasmine.getEnv().addReporter(rep)

GLOBAL._ = require 'lodash'
_.str = require 'underscore.string'
_.mixin(_.str.exports())
GLOBAL.mongoose = require 'mongoose'
mongoose.connect('mongodb://localhost/coco_unittest')
path = require 'path'
GLOBAL.testing = true
GLOBAL.tv4 = require 'tv4' # required for TreemaUtils to work

models_path = [
  '../../server/analytics/AnalyticsUsersActive'
  '../../server/articles/Article'
  '../../server/campaigns/Campaign'
  '../../server/clans/Clan'
  '../../server/courses/Course'
  '../../server/courses/CourseInstance'
  '../../server/levels/Level'
  '../../server/levels/components/LevelComponent'
  '../../server/levels/systems/LevelSystem'
  '../../server/levels/sessions/LevelSession'
  '../../server/levels/thangs/LevelThangType'
  '../../server/users/User'
  '../../server/patches/Patch'
  '../../server/achievements/Achievement'
  '../../server/achievements/EarnedAchievement'
  '../../server/payments/Payment'
  '../../server/prepaids/Prepaid'
  '../../server/trial_requests/TrialRequest'
]

for m in models_path
  model = path.basename(m)
  #console.log('model=' + model)
  GLOBAL[model] = require m

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
GLOBAL.request = require 'request'

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
  request = require 'request'
  request.post getURL('/auth/logout'), ->
    request.get getURL('/auth/whoami'), ->
      req = request.post(getURL('/db/user'), (err, response, body) ->
        throw err if err
        User.findOne({email: email}).exec((err, user) ->
          throw err if err
          user.set('permissions', if password is '80yqxpb38j' then ['admin'] else [])
          user.set('name', name)
          user.save (err) ->
            wrapUpGetUser(email, user, done)
        )
      )
      form = req.form()
      form.append('email', email)
      form.append('password', password)

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
  else if type is 'course'
    options.json.courseID = properties.courseID if properties?.courseID
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
      req = request.post(getURL('/auth/login'), (error, response) ->
        expect(response.statusCode).toBe(200)
        done(user)
      )
      form = req.form()
      form.append('username', email)
      form.append('password', password)
    , true

GLOBAL.loginJoe = (done) ->
  request.post getURL('/auth/logout'), ->
    unittest.getNormalJoe (user) ->
      req = request.post(getURL('/auth/login'), (error, response) ->
        expect(response.statusCode).toBe(200)
        done(user)
      )
      form = req.form()
      form.append('username', 'normal@jo.com')
      form.append('password', 'food')

GLOBAL.loginSam = (done) ->
  request.post getURL('/auth/logout'), ->
    unittest.getOtherSam (user) ->
      req = request.post(getURL('/auth/login'), (error, response) ->
        expect(response.statusCode).toBe(200)
        done(user)
      )
      form = req.form()
      form.append('username', 'other@sam.com')
      form.append('password', 'beer')

GLOBAL.loginAdmin = (done) ->
  request.post getURL('/auth/logout'), ->
    unittest.getAdmin (user) ->
      req = request.post(getURL('/auth/login'), (error, response) ->
        expect(response.statusCode).toBe(200)
        done(user)
      )
      form = req.form()
      form.append('username', 'admin@afc.com')
      form.append('password', '80yqxpb38j')
      # find some other way to make the admin object an admin... maybe directly?

GLOBAL.loginUser = (user, done) ->
  request.post getURL('/auth/logout'), ->
    req = request.post(getURL('/auth/login'), (error, response) ->
      expect(response.statusCode).toBe(200)
      done(user)
    )
    form = req.form()
    form.append('username', user.get('email'))
    form.append('password', user.get('name'))

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

tickInterval = null
tick = ->
  # When you want jasmine-node to exit after running the tests,
  # you have to close the connection first.
  if rep.finished
    mongoose.disconnect()
    clearTimeout tickInterval

tickInterval = setInterval tick, 1000
