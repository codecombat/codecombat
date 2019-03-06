CocoClass = require 'core/CocoClass'
{me} = require 'core/auth'
{backboneFailure} = require 'core/errors'
storage = require 'core/storage'
GPLUS_TOKEN_KEY = 'gplusToken'

clientID = '800329290710-j9sivplv2gpcdgkrsis9rff3o417mlfa.apps.googleusercontent.com'

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
      po.src = 'https://apis.google.com/js/client:platform.js?onload=init'
      s = document.getElementsByTagName('script')[0]
      s.parentNode.insertBefore po, s
      @startedLoading = true
      window.init = =>
        @apiLoaded = true
        @trigger 'load-api'


  connect: (options={}) ->
    options.success ?= _.noop
    options.context ?= options
    authOptions = {
      client_id: clientID
      scope: options.scope || 'profile email'
      response_type: 'permission'
    }
    if me.get('gplusID') and me.get('email')  # when already logged in and reauthorizing for new scopes or new access token
      authOptions.login_hint = me.get('email')
    gapi.auth2.authorize authOptions, (e) =>
      if (e.error and options.error)
        options.error.bind(options.context)()
        return
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
    gapi.client.load 'people', 'v1', =>
      gapi.client.people.people.get({
          'resourceName': 'people/me'
          'personFields': 'names,genders,emailAddresses'
        }).execute (r) =>
          attrs = {}
          if r.resourceName
            attrs.gplusID = r.resourceName.split('/')[1]   # resourceName is of the form 'people/<id>'
          if r.names?.length
            attrs.firstName = r.names[0].givenName
            attrs.lastName = r.names[0].familyName
          if r.emailAddresses?.length
            attrs.email = r.emailAddresses[0].value
          if r.genders?.length
            attrs.gender = r.genders[0].value
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
