async = require 'async'
utils = require '../../server/lib/utils'
co = require 'co'
Promise = require 'bluebird'
User = require '../../server/models/User'


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

  loginUser: Promise.promisify  (user, options={}, done) ->
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
  
