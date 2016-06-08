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

module.exports.sendRecoveryEmail = (email, options={}) ->
  options = _.merge(options,
    {method: 'POST', url: '/auth/reset', data: { email }}
  )
  $.ajax(options)

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
