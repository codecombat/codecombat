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
scope = 'https://www.googleapis.com/auth/plus.login https://www.googleapis.com/auth/userinfo.email'

module.exports = GPlusHandler = class GPlusHandler extends CocoClass
  constructor: ->
    @accessToken = storage.load GPLUS_TOKEN_KEY
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
      d = JSON.stringify(_.omit(e, 'g-oauth-window'))
      storage.save(GPLUS_TOKEN_KEY, d)
    catch e
      console.error 'Unable to save G+ token key', e
    @accessToken = e
    @trigger 'logged-in'

  loginCodeCombat: ->
    # email and profile data loaded separately
    gapi.client.request(path: plusURL, callback: @onPersonEntityReceived)
    gapi.client.load('oauth2', 'v2', =>
      gapi.client.oauth2.userinfo.get().execute(@onEmailReceived))

  shouldSave: false

  onPersonEntityReceived: (r) =>
    for gpProp, userProp of userPropsToSave
      keys = gpProp.split('.')
      value = r
      for key in keys
        value = value[key]
      if value and not me.get(userProp)
        @shouldSave = true
        me.set(userProp, value)

    @responsesComplete += 1
    @personLoaded = true
    @trigger 'person-loaded'
    @saveIfAllDone()

  onEmailReceived: (r) =>
    newEmail = r.email and r.email isnt me.get('email')
    return unless newEmail or me.get('anonymous', true)
    me.set('email', r.email)
    @shouldSave = true
    @emailLoaded = true
    @trigger 'email-loaded'
    @saveIfAllDone()

  saveIfAllDone: =>
    console.debug 'Save if all done. Person loaded:', @personLoaded, 'and email loaded:', @emailLoaded
    return unless @personLoaded and @emailLoaded
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
        window.tracker?.trackEvent 'Google Login', category: "Signup", ['Google Analytics']
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
