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
  FB.logout()
  res = $.post('/auth/logout', {}, ->
    saveObjectToStorage(CURRENT_USER_KEY, null)
    window.location.reload()
  )
  res.fail(genericFailure)

init = ->
  # load the user from local storage, and refresh it from the server.
  # If the server info doesn't match the local storage, refresh the page.
  # Also refresh and cache the gravatar info.

  loadedUser = loadObjectFromStorage(CURRENT_USER_KEY)
  module.exports.me = window.me = if loadedUser then new User(loadedUser) else null
  me.set('wizardColor1', Math.random()) if me and not me.get('wizardColor1')
  $.get('/auth/whoami', (downloadedUser) ->
    trackFirstArrival() # should happen after trackEvent has loaded, due to the callback
    changedState = Boolean(downloadedUser) isnt Boolean(loadedUser)
    switchedUser = downloadedUser and loadedUser and downloadedUser._id isnt loadedUser._id
    if changedState or switchedUser
      saveObjectToStorage(CURRENT_USER_KEY, downloadedUser)
      window.location.reload()
    if me and not me.get('testGroupNumber')?
      # Assign testGroupNumber to returning visitors; new ones in server/handlers/user
      me.set 'testGroupNumber', Math.floor(Math.random() * 256)
      me.save()
    saveObjectToStorage(CURRENT_USER_KEY, downloadedUser)
  )
  if module.exports.me
    module.exports.me.loadGravatarProfile()
    module.exports.me.on('sync', userSynced)

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
  window.tracker?.trackEvent 'First Arrived' if not me
  saveObjectToStorage(BEEN_HERE_BEFORE_KEY, true)
