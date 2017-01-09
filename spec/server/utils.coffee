async = require 'async'
utils = require '../../server/lib/utils'
co = require 'co'
Promise = require 'bluebird'
Article = require '../../server/models/Article'
LevelComponent = require '../../server/models/LevelComponent'
LevelSystem = require '../../server/models/LevelSystem'
Poll = require '../../server/models/Poll'
ThangType = require '../../server/models/ThangType'
User = require '../../server/models/User'
Level = require '../../server/models/Level'
LevelSession = require '../../server/models/LevelSession'
Achievement = require '../../server/models/Achievement'
Campaign = require '../../server/models/Campaign'
Product = require '../../server/models/Product'
{ productStubs } = require '../../server/routes/db/product'
Course = require '../../server/models/Course'
Prepaid = require '../../server/models/Prepaid'
Payment = require '../../server/models/Payment'
Classroom = require '../../server/models/Classroom'
CourseInstance = require '../../server/models/CourseInstance'
moment = require 'moment'
Classroom = require '../../server/models/Classroom'
TrialRequest = require '../../server/models/TrialRequest'
APIClient = require '../../server/models/APIClient'
campaignSchema = require '../../app/schemas/models/campaign.schema'
campaignLevelProperties = _.keys(campaignSchema.properties.levels.additionalProperties.properties)
campaignAdjacentCampaignProperties = _.keys(campaignSchema.properties.adjacentCampaigns.additionalProperties.properties)

module.exports = mw =
  getURL: (path) -> 'http://localhost:3001' + path

  clearModels: Promise.promisify (models, done) ->
    funcs = []
    for model in models
      wrapped = (m) ->
        (callback) ->
          m.remove {}, (err) ->
            callback(err, true)
      funcs.push(wrapped(model))
    async.parallel funcs, done

  initUser: (options, done) ->
    if _.isFunction(options)
      done = options
      options = {}
    options = _.extend({
      permissions: []
      name: 'Name Nameyname '+_.uniqueId()
      email: 'user'+_.uniqueId()+'@example.com'
      password: 'password'
      anonymous: false
    }, options)
    user = new User(options)
    promise = user.save()
    return promise

  loginUser: Promise.promisify (user, options={}, done) ->
    if _.isFunction(options)
      done = options
      options = {}
    form = {
      username: user.get('email') or user.get('name')
      password: 'password'
    }
    (options.request or request).post mw.getURL('/auth/login'), { form: form }, (err, res) ->
      expect(err).toBe(null)
      expect(res.statusCode).toBe(200)
      mw.lastLogin = user
      done(err, user)

  initAdmin: (options) ->
    if _.isFunction(options)
      done = options
      options = {}
    options = _.extend({permissions: ['admin']}, options)
    return @initUser(options)

  initArtisan: (options) ->
    if _.isFunction(options)
      done = options
      options = {}
    options = _.extend({permissions: ['artisan']}, options)
    return @initUser(options)

  becomeAnonymous: Promise.promisify (done) ->
    request.post mw.getURL('/auth/logout'), ->
      request.get mw.getURL('/auth/whoami'), {json: true}, (err, res) ->
        User.findById(res.body._id).exec(done)

  logout: Promise.promisify (done) ->
    request.post mw.getURL('/auth/logout'), done

  wrap: (gen) ->
    arity = gen.length
    fn = co.wrap(gen)
    return (done) ->
      # Run the wrapped, Promise returning test function
      fn.apply(@, if arity is 0 then [] else [done])
      
      # Finish the test if it doesn't include a 'done' argument
      .then -> done() if arity is 0
        
      # Fail on runtime error
      .catch (err) -> done.fail(err)

  makeLevel: Promise.promisify (data, sources, done) ->
    args = Array.from(arguments)
    [done, [data, sources]] = [args.pop(), args]

    data = _.extend({}, {
      name: _.uniqueId('Level ')
      permissions: [{target: mw.lastLogin.id, access: 'owner'}]
    }, data)

    request.post { uri: getURL('/db/level'), json: data }, (err, res) ->
      return done(err) if err
      Level.findById(res.body._id).exec done

  makeLevelSession: Promise.promisify (data, sources, done) ->
    args = Array.from(arguments)
    [done, [data, sources]] = [args.pop(), args]

    data = _.extend({}, {
      state:
        complete: false
        scripts:
          currentScript: null
    }, data)

    if sources?.level and not data.level
      data.level = {
        original: sources.level.get('original').toString()
        majorVersion: sources.level.get('version').major
      }

    if sources?.creator and not data.creator
      data.creator = sources.creator.id

    if data.creator and not data.permissions
      data.permissions = [
        { target: data.creator, access: 'owner' }
        { target: 'public', access: 'write' }
      ]

    if not data.codeLanguage
      data.codeLanguage = 'javascript'

    session = new LevelSession(data)
    session.save(done)

  makeArticle: Promise.promisify (data, sources, done) ->
    args = Array.from(arguments)
    [done, [data, sources]] = [args.pop(), args]

    data = _.extend({}, {
      name: _.uniqueId('Article ')
    }, data)

    request.post { uri: getURL('/db/article'), json: data }, (err, res) ->
      return done(err) if err
      expect(res.statusCode).toBe(201)
      Article.findById(res.body._id).exec done

  makeLevelComponent: Promise.promisify (data, sources, done) ->
    args = Array.from(arguments)
    [done, [data, sources]] = [args.pop(), args]

    data = _.extend({}, {
      name: _.uniqueId('LevelComponent')
      system: 'ai'
      code: 'let const = var'
      permissions: [{target: mw.lastLogin.id, access: 'owner'}]
    }, data)

    request.post { uri: getURL('/db/level.component'), json: data }, (err, res) ->
      return done(err) if err
      expect(res.statusCode).toBe(200)
      LevelComponent.findById(res.body._id).exec done

  makeLevelSystem: Promise.promisify (data, sources, done) ->
    args = Array.from(arguments)
    [done, [data, sources]] = [args.pop(), args]

    data = _.extend({}, {
      name: _.uniqueId('LevelSystem')
      permissions: [{target: mw.lastLogin.id, access: 'owner'}]
      code: 'let const = var'
    }, data)

    request.post { uri: getURL('/db/level.system'), json: data }, (err, res) ->
      return done(err) if err
      expect(res.statusCode).toBe(200)
      LevelSystem.findById(res.body._id).exec done

  makePoll: Promise.promisify (data, sources, done) ->
    args = Array.from(arguments)
    [done, [data, sources]] = [args.pop(), args]

    data = _.extend({}, {
      name: _.uniqueId('Poll ')
      permissions: [{target: mw.lastLogin.id, access: 'owner'}]
    }, data)

    request.post { uri: getURL('/db/poll'), json: data }, (err, res) ->
      return done(err) if err
      expect(res.statusCode).toBe(200)
      Poll.findById(res.body._id).exec done

  makeThangType: Promise.promisify (data, sources, done) ->
    args = Array.from(arguments)
    [done, [data, sources]] = [args.pop(), args]

    data = _.extend({}, {
      name: _.uniqueId('Thang Type ')
      permissions: [{target: mw.lastLogin.id, access: 'owner'}]
    }, data)

    request.post { uri: getURL('/db/thang.type'), json: data }, (err, res) ->
      return done(err) if err
      expect(res.statusCode).toBe(200)
      ThangType.findById(res.body._id).exec done

  makeAchievement: Promise.promisify (data, sources, done) ->
    args = Array.from(arguments)
    [done, [data, sources]] = [args.pop(), args]

    data = _.extend({}, {
      name: _.uniqueId('Achievement ')
    }, data)
    if sources?.related and not data.related
      related = sources.related
      data.related = (related.get('original') or related._id).valueOf()

    request.post { uri: getURL('/db/achievement'), json: data }, (err, res) ->
      return done(err) if err
      expect(res.statusCode).toBe(201)
      Achievement.findById(res.body._id).exec done

  makeCampaign: Promise.promisify (data, sources, done) ->
    args = Array.from(arguments)
    [done, [data, sources]] = [args.pop(), args]
    
    unless mw.lastLogin?.isAdmin()
      # TODO: Make this function transparently turn into an admin if necessary
      done("Must be logged in as an admin to create a campaign") 

    data = _.extend({}, {
      name: _.uniqueId('Campaign ')
    }, data)
    if not data.levels
      data.levels = {}
      for level in sources?.levels or []
        data.levels[level.get('original').valueOf()] = _.pick level.toObject(), campaignLevelProperties

    if not data.adjacentCampaigns
      data.adjacentCampaigns = {}
      for campaign in sources?.adjacentCampaigns or []
        data.adjacentCampaigns[campaign.id] = _.pick campaign.toObject(), campaignAdjacentCampaignProperties

    request.post { uri: getURL('/db/campaign'), json: data }, (err, res) ->
      return done(err) if err
      Campaign.findById(res.body._id).exec done

  makeCourse: (data={}, sources={}) -> co ->

    if sources.campaign and not data.campaignID
      data.campaignID = sources.campaign._id
      
    # need a Campaign since logic depends on its existence
    if not data.campaignID
      campaign = yield mw.makeCampaign()
      data.campaignID = campaign._id

    data = _.extend({}, {
      name: _.uniqueId('Course ')
      releasePhase: 'released'
      i18nCoverage: []
      i18n: {'-':{'-':'-'}}
    }, data)

    course = new Course(data)
    yield course.save()
    return course

  makePrepaid: Promise.promisify (data, sources, done) ->
    args = Array.from(arguments)
    [done, [data, sources]] = [args.pop(), args]

    data = _.extend({}, {
      type: 'course'
      maxRedeemers: 9001
      endDate: moment().add(1, 'month').toISOString()
      startDate: new Date().toISOString()
    }, data)

    request.post { uri: getURL('/db/prepaid'), json: data }, (err, res) ->
      return done(err) if err
      expect(res.statusCode).toBe(201)
      Prepaid.findById(res.body._id).exec done

  makePayment: (data={}) ->
    data = _.extend({}, {
      created: new Date()
    }, data)

    payment = new Payment(data)
    payment.save()

  makeClassroom: (data={}, sources={}) -> co ->
    data = _.extend({}, {
      name: _.uniqueId('Classroom ')
    }, data)

    [res, body] = yield request.postAsync { uri: getURL('/db/classroom'), json: data }
    expect(res.statusCode).toBe(201)
    classroom = yield Classroom.findById(res.body._id)
    if sources.members
      classroom.set('members', _.map(sources.members, '_id'))
      yield classroom.save()
    return classroom
    
  makeAPIClient: (data={}, sources={}) -> co ->
    data = _.extend({}, {
      name: _.uniqueId('API Client ')
    }, data)

    client = new APIClient(data)
    client.secret = client.setNewSecret()
    client.auth = { user: client.id, pass: client.secret }
    yield client.save()
    return client

  makeCourseInstance: (data={}, sources={}) -> co ->
    if sources.course and not data.courseID
      data.courseID = sources.course.id
    if sources.classroom and not data.classroomID
      data.classroomID = sources.classroom.id

    [res, body] = yield request.postAsync({ uri: getURL('/db/course_instance'), json: data })
    expect(res.statusCode).toBe(200)
    courseInstance = yield CourseInstance.findById(res.body._id)
    if sources.members
      userIDs = _.map(sources.members, 'id')
      [res, body] = yield request.postAsync({
        url: getURL("/db/course_instance/#{courseInstance.id}/members")
        json: { userIDs: userIDs }
      })
      expect(res.statusCode).toBe(200)
      courseInstance = yield CourseInstance.findById(res.body._id)
    return courseInstance

  makeTrialRequest: Promise.promisify (data, sources, done) ->
    args = Array.from(arguments)
    [done, [data, sources]] = [args.pop(), args]

    data = _.extend({}, {
      type: 'course'
      properties: {}
    }, data)

    request.post { uri: getURL('/db/trial.request'), json: data }, (err, res) ->
      return done(err) if err
      expect(res.statusCode).toBe(201)
      TrialRequest.findById(res.body._id).exec done

  createDay: (offset) ->
    day = new Date()
    day.setUTCDate(day.getUTCDate() + offset)
    day.toISOString().substring(0, 10)

  populateProducts: _.once co.wrap ->
    promises = []
    for stub in productStubs
      promises.push Product(stub).save()
    yield promises
