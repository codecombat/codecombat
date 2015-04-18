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

  onFacebookLoggedIn: (e) ->
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

    Backbone.Mediator.publish 'auth:logging-in-with-facebook', {}
    window.tracker?.identify()
    beforeID = me.id
    me.patch({
      error: backboneFailure,
      url: "/db/user/#{me.id}?facebookID=#{r.id}&facebookAccessToken=#{@authResponse.accessToken}"
      success: (model) ->
        window.tracker?.trackEvent 'Facebook Login', category: "Signup", label: 'Facebook'
        if model.id is beforeID
          window.tracker?.trackEvent 'Finished Signup', category: "Signup", label: 'Facebook'
        window.location.reload() if model.get('email') isnt oldEmail
    })

  destroy: ->
    super()
