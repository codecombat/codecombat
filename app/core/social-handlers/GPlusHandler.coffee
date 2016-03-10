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
    window.onGPlusLogin = _.bind(@onGPlusLogin, @)
    super()

  token: -> @accessToken?.access_token

  loadAPI: ->
    return if @loadedAPI
    @loadedAPI = true
    (=>
      po = document.createElement('script')
      po.type = 'text/javascript'
      po.async = true
      po.src = 'https://apis.google.com/js/client:platform.js?onload=onGPlusLoaded'
      s = document.getElementsByTagName('script')[0]
      s.parentNode.insertBefore po, s
      window.onGPlusLoaded = _.bind(@onLoadAPI, @)
      return
    )()
    
  onLoadAPI: ->
    Backbone.Mediator.publish 'auth:gplus-api-loaded', {}
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

  renderLoginButtons: ->
    return false unless gapi?.plusone?
    gapi.plusone.go?()  # Handles +1 button
    if not gapi.signin?.render
      console.warn 'Didn\'t have gapi.signin to render G+ login button. (DoNotTrackMe extension?)'
      return
      
    for gplusButton in $('.gplus-login-button')
      params = {
        callback: 'onGPlusLogin',
        clientid: clientID,
        cookiepolicy: 'single_host_origin',
        scope: 'https://www.googleapis.com/auth/plus.login email',
        height: 'short',
      }
      if gapi.signin?.render
        gapi.signin.render(gplusButton, params)
        
    @trigger 'render-login-buttons'

  onCheckedSessionState: (@loggedIn) =>
    @trigger 'checked-state'

  reauthorize: ->
    params =
      'client_id' : clientID
      'scope' : scope
    gapi.auth.authorize params, @onGPlusLogin
    
  fakeGPlusLogin: ->
    @onGPlusLogin({
      access_token: '1234'
    })

  onGPlusLogin: (e) ->
    return unless e.access_token
    @loggedIn = true
    Backbone.Mediator.publish 'auth:logged-in-with-gplus', e
    try
      # Without removing this, we sometimes get a cross-domain error
      d = _.omit(e, 'g-oauth-window')
      storage.save(GPLUS_TOKEN_KEY, d, 0)
    catch e
      console.error 'Unable to save G+ token key', e
    @accessToken = e
    @trigger 'logged-in'
    @trigger 'logged-into-google'

  loadPerson: (options={}) ->
    @reloadOnLogin = options.reloadOnLogin
    # email and profile data loaded separately
    gapi.client.load('plus', 'v1', =>
      gapi.client.plus.people.get({userId: 'me'}).execute(@onPersonReceived))

  onPersonReceived: (r) =>
    attrs = {}
    for gpProp, userProp of userPropsToSave
      keys = gpProp.split('.')
      value = r
      for key in keys
        value = value[key]
      if value
        attrs[userProp] = value

    newEmail = r.emails?.length and r.emails[0] isnt me.get('email')
    return unless newEmail or me.get('anonymous', true)
    if r.emails?.length
      attrs.email = r.emails[0].value
    @trigger 'person-loaded', attrs

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
