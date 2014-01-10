{me} = require 'lib/auth'

module.exports = class Tracker
  constructor: ->
    if window.tracker
      console.error "Overwrote our Tracker!", window.tracker
    window.tracker = @
    @isProduction = document.location.href.search("codecombat.com") isnt -1
    @identify()
    @updateOlark()

  identify: (traits) ->
    #console.log "Would identify", traits
    return unless me and @isProduction and analytics?
    # https://segment.io/docs/methods/identify
    traits ?= {}
    for userTrait in ['email', 'anonymous', 'dateCreated', 'name', 'wizardColor1', 'testGroupNumber', 'gender']
      traits[userTrait] ?= me.get(userTrait)
    analytics.identify me.id, traits

  updateOlark: ->
    return unless me and olark?
    olark 'api.chat.updateVisitorStatus', snippet: ["User ID: #{me.id}"]
    return if me.get("anonymous")
    olark 'api.visitor.updateEmailAddress', emailAddress: me.get("email")
    olark 'api.chat.updateVisitorNickname', snippet: me.displayName()

  updatePlayState: (level, session) ->
    link = "codecombat.com/play/level/#{level.get('slug') or level.id}?session=#{session.id}"
    snippet = [
      "#{link}"
      "User ID: #{me.id}"
      "Session ID: #{session.id}"
      "Level: #{level.get('name')}"

    ]
    olark 'api.chat.updateVisitorStatus', snippet: snippet

  trackPageView: ->
    return unless @isProduction and analytics?
    url = Backbone.history.getFragment()
    #console.log "Going to track visit for", "/#{url}"
    analytics.pageview "/#{url}"

  trackEvent: (event, properties, includeProviders=null) =>
    #console.log "Would track analytics event:", event, properties
    return unless me and @isProduction and analytics?
    #console.log "Going to track analytics event:", event, properties
    properties = properties or {}
    context = {}
    if includeProviders
      context.providers = {'All': false}
      for provider in includeProviders
        context.providers[provider] = true
    event.label = properties.label if properties.label
    analytics?.track event, properties, context
