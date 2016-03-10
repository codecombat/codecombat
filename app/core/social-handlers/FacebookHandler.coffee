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
  subscriptions:
    'auth:logged-in-with-facebook': 'onFacebookLoggedIn'

  loggedIn: false
  
  token: -> @authResponse?.accessToken

  fakeFacebookLogin: ->
    @onFacebookLoggedIn({
      response:
        authResponse: { accessToken: '1234' }
    })

  onFacebookLoggedIn: (e) ->
    # user is logged in also when the page first loads, so check to see
    # if we really need to do the lookup
    @loggedIn = false
    @authResponse = e.response.authResponse
    for fbProp, userProp of userPropsToSave
      unless me.get(userProp)
        @loggedIn = true
        break

    @trigger 'logged-into-facebook'

  loginThroughFacebook: ->
    if @loggedIn
      return true
    else
      FB.login ((response) ->
        console.log 'Received FB login response:', response
      ), scope: 'email'

  loadPerson: ->
    FB.api '/me', {fields: 'email,last_name,first_name,gender'}, (person) =>
      attrs = {}
      for fbProp, userProp of userPropsToSave
        value = person[fbProp]
        if value
          attrs[userProp] = value
      @trigger 'person-loaded', attrs
