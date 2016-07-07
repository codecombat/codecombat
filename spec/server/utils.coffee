async = require 'async'
utils = require '../../server/lib/utils'
co = require 'co'
Promise = require 'bluebird'
User = require '../../server/models/User'
Level = require '../../server/models/Level'
Achievement = require '../../server/models/Achievement'
Campaign = require '../../server/models/Campaign'
Course = require '../../server/models/Course'
Prepaid = require '../../server/models/Prepaid'
Classroom = require '../../server/models/Classroom'
CourseInstance = require '../../server/models/CourseInstance'
moment = require 'moment'
Classroom = require '../../server/models/Classroom'
TrialRequest = require '../../server/models/TrialRequest'
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
      email: 'user'+_.uniqueId()+'@gmail.com'
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
      username: user.get('email')
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
    fn = co.wrap(gen)
    return (done) ->
      fn.apply(@, [done]).catch (err) -> done.fail(err)
      
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

  makeAchievement: Promise.promisify (data, sources, done) ->
    args = Array.from(arguments)
    [done, [data, sources]] = [args.pop(), args]

    data = _.extend({}, {
      name: _.uniqueId('Achievement ')
    }, data)
    if sources.related and not data.related
      related = sources.related
      data.related = (related.get('original') or related._id).valueOf()

    request.post { uri: getURL('/db/achievement'), json: data }, (err, res) ->
      return done(err) if err
      Achievement.findById(res.body._id).exec done
      
  makeCampaign: Promise.promisify (data, sources, done) ->
    args = Array.from(arguments)
    [done, [data, sources]] = [args.pop(), args]
    
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
      
  makeCourse: (data={}, sources={}) ->
    
    if sources.campaign and not data.campaignID
      data.campaignID = sources.campaign._id
    
    course = new Course(data)
    return course.save()

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
