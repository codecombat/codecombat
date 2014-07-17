module.exports = initializeFacebook = ->
  # Additional JS functions here
  window.fbAsyncInit = ->
    FB.init
      appId: (if document.location.origin is 'http://localhost:3000' then '607435142676437' else '148832601965463') # App ID
      channelUrl: document.location.origin + '/channel.html' # Channel File
      status: true # check login status
      cookie: true # enable cookies to allow the server to access the session
      xfbml: true # parse XFBML

    Backbone.Mediator.publish 'fbapi-loaded'

    # This is fired for any auth related change, such as login, logout or session refresh.
    FB.Event.subscribe 'auth.authResponseChange', (response) ->

      # Here we specify what we do with the response anytime this event occurs.
      if response.status is 'connected'

        # They have logged in to the app.
        Backbone.Mediator.publish 'facebook-logged-in',
          response: response

      else if response.status is 'not_authorized'
        #
      else
	      #

  # Load the SDK asynchronously
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
  ) document
