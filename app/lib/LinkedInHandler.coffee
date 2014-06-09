CocoClass = require 'lib/CocoClass'
{me} = require 'lib/auth'
{backboneFailure} = require 'lib/errors'
storage = require 'lib/storage'


module.exports = LinkedInHandler = class LinkedInHandler extends CocoClass
  constructor: ->
    super()

  subscriptions:
    'linkedin-loaded': 'onLinkedInLoaded'

  onLinkedInLoaded: (e) ->
    IN.Event.on IN, "auth", @onLinkedInAuth

  onLinkedInAuth: (e) => console.log "Authorized with LinkedIn"

  constructEmployerAgreementObject: (cb) =>
    IN.API.Profile("me")
    .fields(["positions","public-profile-url","id","first-name","last-name","email-address"])
    .error(cb)
    .result (profiles) =>
      cb null, profiles.values[0]
      
  getProfileData: (cb) =>
    IN.API.Profile("me")
    .fields(["formatted-name","educations","skills","headline","summary","positions","public-profile-url"])
    .error(cb)
    .result (profiles) =>
      cb null, profiles.values[0]

  destroy: ->
    super()
