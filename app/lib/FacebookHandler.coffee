CocoClass = require 'lib/CocoClass'
{me} = require 'lib/auth'
{backboneFailure} = require 'lib/errors'
storage = require 'lib/storage'

# facebook user object props to
userPropsToSave =
  'first_name': 'firstName'
  'last_name': 'lastName'
  'gender': 'gender'
  'email': 'email'
  'id': 'facebookID'


module.exports = FacebookHandler = class FacebookHandler extends CocoClass
  subscriptions:
    'facebook-logged-in':'onFacebookLogin'
    'facebook-logged-out': 'onFacebookLogout'

  onFacebookLogin: (e) =>
    # user is logged in also when the page first loads, so check to see
    # if we really need to do the lookup
    return if not me

    doIt = false
    @authResponse = e.response.authResponse
    for fbProp, userProp of userPropsToSave
      unless me.get(userProp)
        doIt = true
        break
    FB.api('/me', @onReceiveMeInfo) if doIt

  onFacebookLogout: (e) =>
    console.warn('On facebook logout not implemented.')

  onReceiveMeInfo: (r) =>
    unless r.email
      console.error('could not get data, since no email provided')
      return

    oldEmail = me.get('email')
    me.set('firstName', r.first_name) if r.first_name
    me.set('lastName', r.last_name) if r.last_name
    me.set('gender', r.gender) if r.gender
    me.set('email', r.email) if r.email
    me.set('facebookID', r.id) if r.id
    
    Backbone.Mediator.publish('logging-in-with-facebook')
    window.tracker?.trackEvent 'Facebook Login'
    window.tracker?.identify()
    me.patch({
      error: backboneFailure,
      url: "/db/user/#{me.id}?facebookID=#{r.id}&facebookAccessToken=#{@authResponse.accessToken}"
      success: (model) ->
        window.location.reload() if model.get('email') isnt oldEmail
    })

  destroy: ->
    super()
