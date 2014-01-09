CocoClass = require 'lib/CocoClass'
{me, CURRENT_USER_KEY} = require 'lib/auth'
{backboneFailure} = require 'lib/errors'
{saveObjectToStorage} = require 'lib/storage'

# gplus user object props to
userPropsToSave =
  'name.givenName': 'firstName'
  'name.familyName': 'lastName'
  'gender': 'gender'
  'id': 'gplusID'

fieldsToFetch = 'displayName,gender,image,name(familyName,givenName),id'
plusURL = '/plus/v1/people/me?fields='+fieldsToFetch
revokeUrl = 'https://accounts.google.com/o/oauth2/revoke?token='
clientID = "800329290710-j9sivplv2gpcdgkrsis9rff3o417mlfa.apps.googleusercontent.com"

module.exports = GPlusHandler = class GPlusHandler extends CocoClass
  constructor: ->
    super()

  subscriptions:
    'gplus-logged-in':'onGPlusLogin'

  onGPlusLogin: (e) =>
    return if e._aa # this seems to show that it was auto generated on page load
    return if not me
    @accessToken = e.access_token

    # email and profile data loaded separately
    @responsesComplete = 0
    gapi.client.request(path:plusURL, callback:@onPersonEntityReceived)
    gapi.client.load('oauth2', 'v2', =>
      gapi.client.oauth2.userinfo.get().execute(@onEmailReceived))

  shouldSave: false
  responsesComplete: 0

  onPersonEntityReceived: (r) =>
    for gpProp, userProp of userPropsToSave
      keys = gpProp.split('.')
      value = r
      value = value[key] for key in keys
      if value and not me.get(userProp)
        @shouldSave = true
        me.set(userProp, value)

    @responsesComplete += 1
    @saveIfAllDone()

  onEmailReceived: (r) =>
    newEmail = r.email and r.email isnt me.get('email')
    return unless newEmail or me.get('anonymous')
    me.set('email', r.email)
    @shouldSave = true
    @responsesComplete += 1
    @saveIfAllDone()

  saveIfAllDone: =>
    return unless @responsesComplete is 2
    return unless me.get('email') and me.get('gplusID')

    Backbone.Mediator.publish('logging-in-with-gplus')
    gplusID = me.get('gplusID')
    window.tracker?.trackEvent 'Google Login'
    window.tracker?.identify()
    patch = {}
    patch[key] = me.get(key) for gplusKey, key of userPropsToSave
    patch._id = me.id
    patch.email = me.get('email')
    me.save(patch, {
      patch: true
      error: backboneFailure,
      url: "/db/user?gplusID=#{gplusID}&gplusAccessToken=#{@accessToken}"
      success: (model) ->
        saveObjectToStorage(CURRENT_USER_KEY, model.attributes)
        window.location.reload()
    })

  destroy: ->
    super()
