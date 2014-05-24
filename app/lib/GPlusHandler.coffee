CocoClass = require 'lib/CocoClass'
{me} = require 'lib/auth'
{backboneFailure} = require 'lib/errors'
storage = require 'lib/storage'
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
clientID = "800329290710-j9sivplv2gpcdgkrsis9rff3o417mlfa.apps.googleusercontent.com"
scope = "https://www.googleapis.com/auth/plus.login https://www.googleapis.com/auth/userinfo.email"

module.exports = GPlusHandler = class GPlusHandler extends CocoClass
  constructor: ->
    @accessToken = storage.load GPLUS_TOKEN_KEY
    super()

  subscriptions:
    'gplus-logged-in':'onGPlusLogin'
    'gapi-loaded':'onGPlusLoaded'

  onGPlusLoaded: ->
    session_state = null
    if @accessToken
      # We need to check the current state, given our access token
      gapi.auth.setToken 'token', @accessToken
      session_state = @accessToken.session_state
      gapi.auth.checkSessionState({client_id:clientID, session_state:session_state}, @onCheckedSessionState)
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
    storage.save(GPLUS_TOKEN_KEY, e)
    @accessToken = e
    @trigger 'logged-in'
    return if (not me) or me.get 'gplusID' # so only get more data

    # email and profile data loaded separately
    @responsesComplete = 0
    gapi.client.request(path:plusURL, callback:@onPersonEntityReceived)
    gapi.client.load('oauth2', 'v2', =>
      gapi.client.oauth2.userinfo.get().execute(@onEmailReceived))

  shouldSave: false
  responsesComplete: 0

  onPersonEntityReceived: (r) =>
    for gpProp, userProp of userPropsToSave
      keys = gpProp.split('.')
      value = r
      value = value[key] for key in keys
      if value and not me.get(userProp)
        @shouldSave = true
        me.set(userProp, value)

    @responsesComplete += 1
    @saveIfAllDone()

  onEmailReceived: (r) =>
    newEmail = r.email and r.email isnt me.get('email')
    return unless newEmail or me.get('anonymous')
    me.set('email', r.email)
    @shouldSave = true
    @responsesComplete += 1
    @saveIfAllDone()

  saveIfAllDone: =>
    return unless @responsesComplete is 2
    return unless me.get('email') and me.get('gplusID')

    Backbone.Mediator.publish('logging-in-with-gplus')
    gplusID = me.get('gplusID')
    window.tracker?.trackEvent 'Google Login'
    window.tracker?.identify()
    patch = {}
    patch[key] = me.get(key) for gplusKey, key of userPropsToSave
    patch._id = me.id
    patch.email = me.get('email')
    wasAnonymous = me.get('anonymous')
    me.save(patch, {
      patch: true
      error: backboneFailure,
      url: "/db/user?gplusID=#{gplusID}&gplusAccessToken=#{@accessToken.access_token}"
      success: (model) ->
        window.location.reload() if wasAnonymous and not model.get('anonymous')
    })

  loadFriends: (friendsCallback) ->
    return friendsCallback() unless @loggedIn
    expiresIn = if @accessToken then parseInt(@accessToken.expires_at) - new Date().getTime()/1000 else -1
    onReauthorized = => gapi.client.request({path:'/plus/v1/people/me/people/visible', callback: friendsCallback})
    if expiresIn < 0
      # TODO: this tries to open a popup window, which might not ever finish or work, so the callback may never be called.
      @reauthorize()
      @listenToOnce(@, 'logged-in', onReauthorized)
    else
      onReauthorized()
