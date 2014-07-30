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
  watchForErrors()
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
  setUpMoment() # Set up i18n for moment

  treemaExt = require 'treema-ext'
  treemaExt.setup()

handleNormalUrls = ->
  # http://artsy.github.com/blog/2012/06/25/replacing-hashbang-routes-with-pushstate/
  $(document).on 'click', "a[href^='/']", (event) ->

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

setUpMoment = ->
  {me} = require 'lib/auth'
  moment.lang me.lang(), {}
  me.on 'change', (me) ->
    moment.lang me.lang(), {} if me._previousAttributes.preferredLanguage isnt me.get 'preferredLanguage'

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

watchForErrors = ->
  currentErrors = 0
  window.onerror = (msg, url, line, col, error) ->
    return if currentErrors >= 3
    return unless me.isAdmin() or document.location.href.search(/codecombat.com/) is -1 or document.location.href.search(/\/editor\//) isnt -1
    ++currentErrors
    msg = "Error: #{msg}<br>Check the JS console for more."
    #msg += "\nLine: #{line}" if line?
    #msg += "\nColumn: #{col}" if col?
    #msg += "\nError: #{error}" if error?
    #msg += "\nStack: #{stack}" if stack = error?.stack
    noty text: msg, layout: 'topCenter', type: 'error', killer: false, timeout: 5000, dismissQueue: true, maxVisible: 3, callback: {onClose: -> --currentErrors}

$ -> init()
