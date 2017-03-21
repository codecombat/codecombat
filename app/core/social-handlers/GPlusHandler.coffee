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

  token: -> @accessToken?.access_token
    
  startedLoading: false
  apiLoaded: false
  connected: false
  person: null

  fakeAPI: ->
    window.gapi =
      client:
        load: (api, version, cb) -> cb()
        plus:
          people:
            get: -> {
              execute: (cb) ->
                cb({
                  name: {
                    givenName: 'Mr'
                    familyName: 'Bean'
                  }
                  id: 'abcd'
                  emails: [{value: 'some@email.com'}]
                })
            }
              
      auth:
        authorize: (opts, cb) ->
          cb({access_token: '1234'})
          
    @startedLoading = true
    @apiLoaded = true
    
  fakeConnect: ->
    @accessToken = {access_token: '1234'}
    @trigger 'connect'

  loadAPI: (options={}) ->
    options.success ?= _.noop
    options.context ?= options
    if @apiLoaded
      options.success.bind(options.context)()
    else
      @once 'load-api', options.success, options.context
    
    if not @startedLoading
      po = document.createElement('script')
      po.type = 'text/javascript'
      po.async = true
      po.src = 'https://apis.google.com/js/client:platform.js?onload=onGPlusLoaded'
      s = document.getElementsByTagName('script')[0]
      s.parentNode.insertBefore po, s
      @startedLoading = true
      window.onGPlusLoaded = =>
        @apiLoaded = true
        if @accessToken and me.get('gplusID')
          # We need to check the current state, given our access token
          gapi.auth.setToken 'token', @accessToken
          session_state = @accessToken.session_state
          gapi.auth.checkSessionState {client_id: clientID, session_state: session_state}, (connected) =>
            @connected = connected
            @trigger 'load-api'
        else
          @connected = false
          @trigger 'load-api'
    

  connect: (options={}) ->
    options.success ?= _.noop
    options.context ?= options
    authOptions = {
      client_id: clientID
      scope: 'https://www.googleapis.com/auth/plus.login email'
    }
    gapi.auth.authorize authOptions, (e) =>
      return unless e.access_token
      @connected = true
      try
      # Without removing this, we sometimes get a cross-domain error
        d = _.omit(e, 'g-oauth-window')
        storage.save(GPLUS_TOKEN_KEY, d, 0)
      catch e
        console.error 'Unable to save G+ token key', e
      @accessToken = e
      @trigger 'connect'
      options.success.bind(options.context)()
      

  loadPerson: (options={}) ->
    options.success ?= _.noop
    options.context ?= options
    # email and profile data loaded separately
    gapi.client.load 'plus', 'v1', =>
      gapi.client.plus.people.get({userId: 'me'}).execute (r) =>
        attrs = {}
        for gpProp, userProp of userPropsToSave
          keys = gpProp.split('.')
          value = r
          for key in keys
            value = value[key]
          if value
            attrs[userProp] = value
    
        if r.emails?.length
          attrs.email = r.emails[0].value
        @trigger 'load-person', attrs
        options.success.bind(options.context)(attrs)


  renderButtons: ->
    return false unless gapi?.plusone?
    gapi.plusone.go?()  # Handles +1 button
  
  # Friends logic, not in use
    
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

  reauthorize: ->
    params =
      'client_id' : clientID
      'scope' : scope
    gapi.auth.authorize params, @onGPlusLogin
