CocoClass = require 'core/CocoClass'
{me} = require 'core/auth'
{backboneFailure} = require 'core/errors'
storage = require 'core/storage'
GPLUS_TOKEN_KEY = 'gplusToken'

# gplus user object props to
userPropsToSave =
  'name.givenName': 'firstName'
  'name.familyName': 'lastName'
  'gender': 'gender'
  'id': 'gplusID'

fieldsToFetch = 'displayName,gender,image,name(familyName,givenName),id'
plusURL = '/plus/v1/people/me?fields='+fieldsToFetch
revokeUrl = 'https://accounts.google.com/o/oauth2/revoke?token='
clientID = '800329290710-j9sivplv2gpcdgkrsis9rff3o417mlfa.apps.googleusercontent.com'
scope = 'https://www.googleapis.com/auth/plus.login email'

module.exports = GPlusHandler = class GPlusHandler extends CocoClass
  constructor: ->
    @accessToken = storage.load GPLUS_TOKEN_KEY, false
    super()

  subscriptions:
    'auth:logged-in-with-gplus':'onGPlusLogin'
    'auth:gplus-api-loaded':'onGPlusLoaded'

  onGPlusLoaded: ->
    session_state = null
    if @accessToken and me.get('gplusID')
      # We need to check the current state, given our access token
      gapi.auth.setToken 'token', @accessToken
      session_state = @accessToken.session_state
      gapi.auth.checkSessionState({client_id: clientID, session_state: session_state}, @onCheckedSessionState)
    else
      # If we ran checkSessionState, it might return true, that the user is logged into Google, but has not authorized us
      @loggedIn = false
      func = => @trigger 'checked-state'
      setTimeout func, 1

  onCheckedSessionState: (@loggedIn) =>
    @trigger 'checked-state'

  reauthorize: ->
    params =
      'client_id' : clientID
      'scope' : scope
    gapi.auth.authorize params, @onGPlusLogin

  onGPlusLogin: (e) =>
    @loggedIn = true
    try
      # Without removing this, we sometimes get a cross-domain error
      d = _.omit(e, 'g-oauth-window')
      storage.save(GPLUS_TOKEN_KEY, d, 0)
    catch e
      console.error 'Unable to save G+ token key', e
    @accessToken = e
    @trigger 'logged-in'

  loginCodeCombat: ->
    # email and profile data loaded separately
    gapi.client.load('plus', 'v1', =>
      gapi.client.plus.people.get({userId: 'me'}).execute(@onPersonReceived))

  onPersonReceived: (r) =>
    for gpProp, userProp of userPropsToSave
      keys = gpProp.split('.')
      value = r
      for key in keys
        value = value[key]
      if value and not me.get(userProp)
        me.set(userProp, value)

    newEmail = r.emails?.length and r.emails[0] isnt me.get('email')
    return unless newEmail or me.get('anonymous', true)
    me.set('email', r.emails[0].value)
    @trigger 'person-loaded'
    @save()

  save: =>
    console.debug 'Email, gplusID:', me.get('email'), me.get('gplusID')
    return unless me.get('email') and me.get('gplusID')

    Backbone.Mediator.publish 'auth:logging-in-with-gplus', {}
    gplusID = me.get('gplusID')
    window.tracker?.identify()
    patch = {}
    patch[key] = me.get(key) for gplusKey, key of userPropsToSave
    patch._id = beforeID = me.id
    patch.email = me.get('email')
    wasAnonymous = me.get('anonymous')
    @trigger 'logging-into-codecombat'
    console.debug('Logging into GPlus.')
    me.save(patch, {
      patch: true
      type: 'PUT'
      error: ->
        console.warn('Logging into GPlus fail.', arguments)
        backboneFailure(arguments...)
      url: "/db/user?gplusID=#{gplusID}&gplusAccessToken=#{@accessToken.access_token}"
      success: (model) ->
        console.info('GPLus login success!')
        window.tracker?.trackEvent 'Google Login', category: "Signup"
        if model.id is beforeID
          window.tracker?.trackEvent 'Finished Signup', label: 'GPlus'
        window.location.reload() if wasAnonymous and not model.get('anonymous')
    })

  loadFriends: (friendsCallback) ->
    return friendsCallback() unless @loggedIn
    expiresIn = if @accessToken then parseInt(@accessToken.expires_at) - new Date().getTime()/1000 else -1
    onReauthorized = => gapi.client.request({path: '/plus/v1/people/me/people/visible', callback: friendsCallback})
    if expiresIn < 0
      # TODO: this tries to open a popup window, which might not ever finish or work, so the callback may never be called.
      @reauthorize()
      @listenToOnce(@, 'logged-in', onReauthorized)
    else
      onReauthorized()
