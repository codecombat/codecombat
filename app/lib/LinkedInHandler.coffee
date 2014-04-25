CocoClass = require 'lib/CocoClass'
{me} = require 'lib/auth'
{backboneFailure} = require 'lib/errors'
storage = require 'lib/storage'


module.exports = LinkedInHandler = class LinkedInHandler extends CocoClass
  constructor: ->
    super()
    @linkedInData = {}
    @loaded = false
  subscriptions:
    'linkedin-loaded':'onLinkedInLoaded'
    
  onLinkedInLoaded: (e) =>
    console.log "Loaded LinkedIn!"
    IN.Event.on IN, "auth", @onLinkedInAuth

  onLinkedInAuth: (e) => IN.API.Profile("me").result(@cacheProfileInformation)
    
  cacheProfileInformation: (profiles) =>
    @linkedInData = profiles.values[0]
    me.set("linkedIn", @linkedInData)
    console.log "LinkedIn data is #{@linkedInData}"
    
  constructEmployerAgreementObject: (cb) =>
    IN.API.Profile("me")
    .fields(["positions","public-profile-url","id","first-name","last-name","email-address"])
    .error(cb)
    .result (profiles) =>
      cb null, profiles.values[0]
      
    
  destroy: ->
    super()
