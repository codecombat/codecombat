async = require 'async'
utils = require '../../server/lib/utils'
co = require 'co'

module.exports = mw =
  getURL: (path) -> 'http://localhost:3001' + path
      
  clearModels: (models, done) ->
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
    options = _.extend({permissions: []}, options)
    doc = {
      email: 'user'+_.uniqueId()+'@gmail.com'
      password: 'password'
      permissions: options.permissions
    }
    new User(doc).save (err, user) ->
      expect(err).toBe(null)
      done(err, user)

  loginUser: (user, done) ->
    form = {
      username: user.get('email')
      password: 'password'
    }
    request.post mw.getURL('/auth/login'), { form: form }, (err, res) ->
      expect(err).toBe(null)
      expect(res.statusCode).toBe(200)
      done(err, user)

  initAdmin: (options, done) ->
    if _.isFunction(options)
      done = options
      options = {}
    options = _.extend({permissions: ['admin']}, options)
    return @initUser(options, done)

  initArtisan: (options, done) ->
    if _.isFunction(options)
      done = options
      options = {}
    options = _.extend({permissions: ['artisan']}, options)
    return @initUser(options, done)
    
  logout: (done) ->
    request.post mw.getURL('/auth/logout'), done

  wrap: (gen) ->
    fn = co.wrap(gen)
    return (done) ->
      fn.apply(@, [done]).catch (err) -> done.fail(err)
  


Promise = require 'bluebird'
Promise.promisifyAll(module.exports)