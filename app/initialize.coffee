Backbone.Mediator.setValidationEnabled false
app = require 'application'

channelSchemas =
  'app': require './schemas/subscriptions/app'
  'bus': require './schemas/subscriptions/bus'
  'editor': require './schemas/subscriptions/editor'
  'errors': require './schemas/subscriptions/errors'
  'misc': require './schemas/subscriptions/misc'
  'play': require './schemas/subscriptions/play'
  'surface': require './schemas/subscriptions/surface'
  'tome': require './schemas/subscriptions/tome'
  'user': require './schemas/subscriptions/user'
  'world': require './schemas/subscriptions/world'

definitionSchemas =
  'bus': require './schemas/definitions/bus'
  'misc': require './schemas/definitions/misc'

init = ->
  path = document.location.pathname
  testing = path.startsWith '/test'
  demoing = path.startsWith '/demo'
  initializeServices() unless testing or demoing
 
  # Set up Backbone.Mediator schemas
  setUpDefinitions()
  setUpChannels()
  Backbone.Mediator.setValidationEnabled document.location.href.search(/codecombat.com/) is -1
  app.initialize()
  Backbone.history.start({ pushState: true })
  handleNormalUrls()

  treemaExt = require 'treema-ext'
  treemaExt.setup()

$ -> init()
  
handleNormalUrls = ->
  # http://artsy.github.com/blog/2012/06/25/replacing-hashbang-routes-with-pushstate/
  $(document).on "click", "a[href^='/']", (event) ->

    href = $(event.currentTarget).attr('href')

    # chain 'or's for other black list routes
    passThrough = href.indexOf('sign_out') >= 0

    # Allow shift+click for new tabs, etc.
    if !passThrough && !event.altKey && !event.ctrlKey && !event.metaKey && !event.shiftKey
      event.preventDefault()

      # Remove leading slashes and hash bangs (backward compatablility)
      url = href.replace(/^\//,'').replace('\#\!\/','')

      # Instruct Backbone to trigger routing events
      app.router.navigate url, { trigger: true }

      return false

setUpChannels = ->
  for channel of channelSchemas
    Backbone.Mediator.addChannelSchemas channelSchemas[channel]

setUpDefinitions = ->
  for definition of definitionSchemas
    Backbone.Mediator.addDefSchemas definitionSchemas[definition]

initializeServices = ->
  services = [
    './lib/services/filepicker'
    './lib/services/segmentio'
    './lib/services/olark'
    './lib/services/facebook'
    './lib/services/google'
    './lib/services/twitter'
    './lib/services/linkedin'
  ]

  for service in services
    service = require service
    service()
