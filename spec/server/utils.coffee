async = require 'async'
utils = require '../../server/lib/utils'
co = require 'co'
Promise = require 'bluebird'
User = require '../../server/models/User'
Level = require '../../server/models/Level'
Achievement = require '../../server/models/Achievement'
Campaign = require '../../server/models/Campaign'
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
      request.get mw.getURL('/auth/whoami'), done
    
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