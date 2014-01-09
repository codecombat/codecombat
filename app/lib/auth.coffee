{backboneFailure, genericFailure} = require 'lib/errors'
User = require 'models/User'
{saveObjectToStorage, loadObjectFromStorage} = require 'lib/storage'

module.exports.CURRENT_USER_KEY = CURRENT_USER_KEY = 'whoami'
BEEN_HERE_BEFORE_KEY = 'beenHereBefore'

module.exports.createUser = (userObject, failure=backboneFailure) ->
  user = new User(userObject)
  user.save({}, {
  error: failure,
  success: (model) ->
    saveObjectToStorage(CURRENT_USER_KEY, model)
    window.location.reload()
  })

module.exports.loginUser = (userObject, failure=genericFailure) ->
  jqxhr = $.post('/auth/login',
    {
      username:userObject.email,
      password:userObject.password
    },
  (model) ->
    saveObjectToStorage(CURRENT_USER_KEY, model)
    window.location.reload()
  )
  jqxhr.fail(failure)

module.exports.logoutUser = ->
  FB?.logout?()
  res = $.post('/auth/logout', {}, ->
    saveObjectToStorage(CURRENT_USER_KEY, null)
    window.location.reload()
  )
  res.fail(genericFailure)

init = ->
  # Load the user from local storage, and refresh it from the server.
  # Also refresh and cache the gravatar info.

  storedUser = loadObjectFromStorage(CURRENT_USER_KEY)
  firstTime = not storedUser
  module.exports.me = window.me = new User(storedUser)
  me.url = -> '/auth/whoami'
  me.fetch()
  me.on 'sync', ->
    me.url = -> "/db/user/#{me.id}"
    trackFirstArrival() if firstTime
    if me and not me.get('testGroupNumber')?
      # Assign testGroupNumber to returning visitors; new ones in server/handlers/user
      me.set 'testGroupNumber', Math.floor(Math.random() * 256)
      me.save()
    saveObjectToStorage(CURRENT_USER_KEY, me.attributes)

  me.loadGravatarProfile() if me.get('email')
  me.on('sync', userSynced)

userSynced = (user) ->
  Backbone.Mediator.publish('me:synced', {me:user})
  saveObjectToStorage(CURRENT_USER_KEY, user)

init()

onSetVolume = (e) ->
  return if e.volume is me.get('volume')
  me.set('volume', e.volume)
  me.save()

Backbone.Mediator.subscribe('level-set-volume', onSetVolume, module.exports)

trackFirstArrival = ->
  # will have to filter out users who log in with existing accounts separately
  # but can at least not track logouts as first arrivals using local storage
  beenHereBefore = loadObjectFromStorage(BEEN_HERE_BEFORE_KEY)
  return if beenHereBefore
  window.tracker?.trackEvent 'First Arrived'
  saveObjectToStorage(BEEN_HERE_BEFORE_KEY, true)
