CocoClass = require 'core/CocoClass'
{me} = require 'core/auth'
{backboneFailure} = require 'core/errors'
storage = require 'core/storage'
GPLUS_TOKEN_KEY = 'gplusToken'
authUtils = require '../../lib/auth-util'

clientID = '800329290710-j9sivplv2gpcdgkrsis9rff3o417mlfa.apps.googleusercontent.com'
API_KEY = 'AIzaSyDW8CsHHJbAREZw8uXg0Hix8dtlJnuutls'

module.exports = GPlusHandler = class GPlusHandler extends CocoClass
  constructor: ->
    unless me.useSocialSignOn() then throw new Error('Social single sign on not supported')
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
        init: ->
        load: (api, version, cb) -> cb()
        people:
          people:
            get: -> {
              execute: (cb) ->
                cb({
                  resourceName: 'people/abcd'
                  names: [{
                    givenName: 'Mr'
                    familyName: 'Bean'
                  }]
                  emailAddresses: [{value: 'some@email.com'}]
                })
            }

      auth2:
        authorize: (opts, cb) ->
          cb({access_token: '1234'})

    window.google =
      accounts:
        id:
          initialize: ->
          renderButton: ->
          prompt: ->

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
      window.init = =>
        @apiLoaded = true
        @trigger 'load-api'
      po = document.createElement('script')
      po.type = 'text/javascript'
      po.async = true
      po.defer = true
      po.src = 'https://accounts.google.com/gsi/client'
      s = document.getElementsByTagName('script')[0]
      s.parentNode.insertBefore po, s
      po.addEventListener('load', window.init)

      window.initGapi = =>
        window.gapi.load('client', () ->
          window.gapi.client.init({
            apiKey: API_KEY
          })
        )
      po1 = document.createElement('script')
      po1.type = 'text/javascript'
      po1.async = true
      po1.defer = true
      po1.src = 'https://apis.google.com/js/api.js'
      s1 = document.getElementsByTagName('script')[0]
      s1.parentNode.insertBefore po1, s1
      po1.addEventListener('load', window.initGapi)

      @startedLoading = true

  connect: (options={}) ->
    options.success ?= _.noop
    options.context ?= options
    window.google.accounts.id.initialize({
      client_id: clientID,
      callback: (resp) =>
        @trigger 'connect'
        options.success.bind(options.context)(resp)
    })
    elementId = options.elementId || 'google-login-button'
    if document.getElementById(elementId)
      window.google.accounts.id.renderButton(
        document.getElementById(elementId),
        { theme: "outline", size: "large" }
      )
    window.google.accounts.id.prompt()

  loadPerson: (options={}) ->
    options.success ?= _.noop
    options.context ?= options
    options.resp ?= null
    if options.resp
      attrs = authUtils.parseGoogleJwtResponse(options.resp.credential)
      @trigger 'load-person', attrs
      options.success.bind(options.context)(attrs)
    else
      console.error 'gplus login failed', options

  renderButtons: ->
    return false unless gapi?.plusone?
    gapi.plusone.go?()  # Handles +1 button

  requestGoogleAuthorization: (scope, callbackFn)->
    authClient = window.google.accounts.oauth2.initTokenClient({
      client_id: clientID,
      scope: scope,
      callback: (resp) =>
        @accessToken = resp
        setTimeout () =>
          @accessToken = null
        ,@accessToken.expires_in * 1000
        if callbackFn
          callbackFn()
    })
    authClient.requestAccessToken({ prompt: 'consent' })

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
