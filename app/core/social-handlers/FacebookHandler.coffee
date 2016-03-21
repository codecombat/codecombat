CocoClass = require 'core/CocoClass'
{me} = require 'core/auth'
{backboneFailure} = require 'core/errors'
storage = require 'core/storage'

# facebook user object props to
userPropsToSave =
  'first_name': 'firstName'
  'last_name': 'lastName'
  'gender': 'gender'
  'email': 'email'
  'id': 'facebookID'


module.exports = FacebookHandler = class FacebookHandler extends CocoClass

  token: -> @authResponse?.accessToken

  startedLoading: false
  apiLoaded: false
  connected: false
  person: null
  
  fakeAPI: ->
    window.FB =
      login: (cb, options) ->
        cb({status: 'connected', authResponse: { accessToken: '1234' }})
      api: (url, options, cb) ->
        cb({ 
          first_name: 'Mr'
          last_name: 'Bean'
          id: 'abcd'
          email: 'some@email.com'
        })

    @startedLoading = true
    @apiLoaded = true

  loadAPI: (options={}) ->
    options.success ?= _.noop
    options.context ?= options
    if @apiLoaded
      options.success.bind(options.context)()
    else
      @once 'load-api', options.success, options.context
    
    if not @startedLoading
      # Load the SDK asynchronously
      @startedLoading = true
      ((d) ->
        js = undefined
        id = 'facebook-jssdk'
        ref = d.getElementsByTagName('script')[0]
        return  if d.getElementById(id)
        js = d.createElement('script')
        js.id = id
        js.async = true
        js.src = '//connect.facebook.net/en_US/all.js'
    
        #js.src = '//connect.facebook.net/en_US/all/debug.js'
        ref.parentNode.insertBefore js, ref
        return
      )(document)

      window.fbAsyncInit = =>
        FB.init
          appId: (if document.location.origin is 'http://localhost:3000' then '607435142676437' else '148832601965463') # App ID
          channelUrl: document.location.origin + '/channel.html' # Channel File
          cookie: true # enable cookies to allow the server to access the session
          xfbml: true # parse XFBML

        FB.getLoginStatus (response) =>
          if response.status is 'connected'
            @connected = true
            @authResponse = response.authResponse
            @trigger 'connect', { response: response }
          @apiLoaded = true
          @trigger 'load-api'


  connect: (options={}) ->
    options.success ?= _.noop
    options.context ?= options
    FB.login ((response) =>
      if response.status is 'connected'
        @connected = true
        @authResponse = response.authResponse
        @trigger 'connect', { response: response }
        options.success.bind(options.context)()
    ), scope: 'email'


  loadPerson: (options={}) ->
    options.success ?= _.noop
    options.context ?= options
    FB.api '/me', {fields: 'email,last_name,first_name,gender'}, (person) =>
      attrs = {}
      for fbProp, userProp of userPropsToSave
        value = person[fbProp]
        if value
          attrs[userProp] = value
      @trigger 'load-person', attrs
      options.success.bind(options.context)(attrs)

  renderButtons: ->
    setTimeout(FB.XFBML.parse, 10) if FB?.XFBML?.parse  # Handles FB login and Like