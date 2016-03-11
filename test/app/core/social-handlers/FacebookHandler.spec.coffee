FacebookHandler = require 'core/social-handlers/FacebookHandler'

mockAuthEvent =
  response:
    authResponse:
      accessToken: 'aksdhjflkqjrj245234b52k345q344le4j4k5l45j45s4dkljvdaskl'
      userID: '4301938'
      expiresIn: 5138
      signedRequest: 'akjsdhfjkhea.3423nkfkdsejnfkd'
    status: 'connected'

window.FB ?= {
  api: ->
  login: ->
}

describe 'lib/FacebookHandler.coffee', ->
  it 'on facebook-logged-in, gets data from FB and sends a patch to the server', ->
    me.clear({silent: true})
    me.markToRevert()
    me.set({_id: '12345'})

    facebookHandler = new FacebookHandler()
    facebookHandler.loginThroughFacebook()
    Backbone.Mediator.publish 'auth:logged-in-with-facebook', mockAuthEvent

