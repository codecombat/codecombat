{backboneFailure, genericFailure, parseServerError} = require 'core/errors'
User = require 'models/User'
storage = require 'core/storage'
BEEN_HERE_BEFORE_KEY = 'beenHereBefore'
{ getQueryVariable } = require('core/utils')
api = require('core/api')

init = ->
  module.exports.me = window.me = new User(window.userObject) # inserted into main.html
  module.exports.me.onLoaded()
  trackFirstArrival()
  # set country and geo fields for returning users if not set during account creation (/server/models/User - makeNew)
  if not me.get('country')
    api.users.setCountryGeo()
    .then (res) ->
      me.set(res)
      setTestGroupNumberUS()
    .catch((e) => console.error("Error in setting country and geo:", e))
  if me and not me.get('testGroupNumber')?
    # Assign testGroupNumber to returning visitors; new ones in server/routes/auth
    me.set 'testGroupNumber', Math.floor(Math.random() * 256)
    me.patch()
  setTestGroupNumberUS()
  preferredLanguage = getQueryVariable('preferredLanguage')
  if me and features.codePlay and preferredLanguage
    me.set('preferredLanguage', preferredLanguage)
    me.save()

  Backbone.listenTo me, 'sync', -> Backbone.Mediator.publish('auth:me-synced', me: me)

module.exports.logoutUser = (options={}) ->
  return if features.codePlay
  options.error ?= genericFailure
  me.logout(options)

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

setTestGroupNumberUS = ->
  if me and me.get("country") == 'united-states' and not me.get('testGroupNumberUS')?
    # Assign testGroupNumberUS to returning visitors; new ones in server/models/User
    me.set 'testGroupNumberUS', Math.floor(Math.random() * 256)
    me.patch()

init()
