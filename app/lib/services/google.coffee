module.exports = initializeGoogle = ->
  window.onGPlusLoaded = ->
    Backbone.Mediator.publish 'gapi-loaded'
    return
  window.signinCallback = (authResult) ->
    Backbone.Mediator.publish 'gplus-logged-in', authResult if authResult['access_token']
    return
  (->
    po = document.createElement('script')
    po.type = 'text/javascript'
    po.async = true
    po.src = 'https://apis.google.com/js/client:plusone.js?onload=onGPlusLoaded'
    s = document.getElementsByTagName('script')[0]
    s.parentNode.insertBefore po, s
    return
  )()
