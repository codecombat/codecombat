CocoClass = require 'lib/CocoClass'
{me, CURRENT_USER_KEY} = require 'lib/auth'
{backboneFailure} = require 'lib/errors'
{saveObjectToStorage} = require 'lib/storage'

# facebook user object props to
userPropsToSave =
  'first_name': 'firstName'
  'last_name': 'lastName'
  'gender': 'gender'
  'email': 'email'
  'id': 'facebookID'


module.exports = FacebookHandler = class FacebookHandler extends CocoClass
  constructor: ->
    super()

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
    patch = {}
    patch.firstName = r.first_name if r.first_name
    patch.lastName = r.last_name if r.last_name
    patch.gender = r.gender if r.gender
    patch.email = r.email if r.email
    patch.facebookID = r.id if r.id
    me.set(patch)
    patch._id = me.id

    Backbone.Mediator.publish('logging-in-with-facebook')
    window.tracker?.trackEvent 'Facebook Login'
    window.tracker?.identify()
    me.save(patch, {
      patch: true
      error: backboneFailure,
      url: "/db/user?facebookID=#{r.id}&facebookAccessToken=#{@authResponse.accessToken}"
      success: (model) ->
        saveObjectToStorage(CURRENT_USER_KEY, model.attributes)
        window.location.reload() if model.get('email') isnt oldEmail
    })

  destroy: ->
    super()
