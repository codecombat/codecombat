{backboneFailure, genericFailure, parseServerError} = require 'core/errors'
User = require 'models/User'
storage = require 'core/storage'
BEEN_HERE_BEFORE_KEY = 'beenHereBefore'

init = ->
  module.exports.me = window.me = new User(window.userObject) # inserted into main.html
  module.exports.me.onLoaded()
  trackFirstArrival()
  if me and not me.get('testGroupNumber')?
    # Assign testGroupNumber to returning visitors; new ones in server/routes/auth
    me.set 'testGroupNumber', Math.floor(Math.random() * 256)
    me.patch()

  Backbone.listenTo me, 'sync', -> Backbone.Mediator.publish('auth:me-synced', me: me)

module.exports.createUser = (userObject, failure=backboneFailure, nextURL=null) ->
  user = new User(userObject)
  user.notyErrors = false
  user.save({}, {
    error: (model, jqxhr, options) ->
      error = parseServerError(jqxhr.responseText)
      property = error.property if error.property
      if jqxhr.status is 409 and property is 'name'
        anonUserObject = _.omit(userObject, 'name')
        module.exports.createUser anonUserObject, failure, nextURL
      else
        genericFailure(jqxhr)
    success: -> if nextURL then window.location.href = nextURL else window.location.reload()
  })

module.exports.createUserWithoutReload = (userObject, failure=backboneFailure) ->
  user = new User(userObject)
  user.save({}, {
    error: failure
    success: ->
      Backbone.Mediator.publish('created-user-without-reload')
  })

module.exports.loginUser = (userObject, failure=genericFailure, nextURL=null) ->
  console.log 'logging in as', userObject.email
  jqxhr = $.post('/auth/login',
    {
      username: userObject.email,
      password: userObject.password
    },
    (model) -> if nextURL then window.location.href = nextURL else window.location.reload()
  )
  jqxhr.fail(failure)

module.exports.logoutUser = ->
  # TODO: Refactor to use User.logout
  FB?.logout?()
  callback = ->
    location = _.result(currentView, 'logoutRedirectURL')
    if location
      window.location = location
    else
      window.location.reload()
  res = $.post('/auth/logout', {}, callback)
  res.fail(genericFailure)

onSetVolume = (e) ->
  return if e.volume is me.get('volume')
  me.set('volume', e.volume)
  me.save()

Backbone.Mediator.subscribe('level:set-volume', onSetVolume, module.exports)

trackFirstArrival = ->
  # will have to filter out users who log in with existing accounts separately
  # but can at least not track logouts as first arrivals using local storage
  beenHereBefore = storage.load(BEEN_HERE_BEFORE_KEY)
  return if beenHereBefore
  window.tracker?.trackEvent 'First Arrived'
  storage.save(BEEN_HERE_BEFORE_KEY, true)

init()
