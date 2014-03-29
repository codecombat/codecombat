app = require 'application'
auth = require 'lib/auth'
editorSubscriptions = require './schemas/subscriptions/editor'
busSubscriptions = require './schemas/subscriptions/bus'
busDefinitions = require './schemas/definitions/bus'
miscDefinitions = require './schemas/definitions/misc'

init = ->
  app.initialize()
  Backbone.history.start({ pushState: true })
  handleNormalUrls()

  treemaExt = require 'treema-ext'
  treemaExt.setup()
  filepicker.setKey('AvlkNoldcTOU4PvKi2Xm7z')

  # Set up Backbone.Mediator schemas
  configureChannels()
  configureDefinitions()

$ ->
  # Make sure we're "logged in" first.
  if auth.me.id
    init()
  else
    Backbone.Mediator.subscribeOnce 'me:synced', init
  
window.init = init

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

configureChannels = ->
  Backbone.Mediator.addChannelSchemas(editorSubscriptions)
  # TODO implement bus channel schemas
  Backbone.Mediator.addChannelSchemas(busSubscriptions)

configureDefinitions = ->
  Backbone.Mediator.addDefSchemas(miscDefinitions)
  Backbone.Mediator.addDefSchemas(busDefinitions)
