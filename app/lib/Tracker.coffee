{me} = require 'lib/auth'

debugAnalytics = false

module.exports = class Tracker
  constructor: ->
    if window.tracker
      console.error 'Overwrote our Tracker!', window.tracker
    window.tracker = @
    @isProduction = document.location.href.search('codecombat.com') isnt -1
    @identify()

  identify: (traits) ->
    console.log 'Would identify', traits if debugAnalytics
    return unless me and @isProduction and analytics?
    # https://segment.io/docs/methods/identify
    traits ?= {}
    for userTrait in ['email', 'anonymous', 'dateCreated', 'name', 'wizardColor1', 'testGroupNumber', 'gender']
      traits[userTrait] ?= me.get(userTrait)
    analytics.identify me.id, traits

  trackPageView: ->
    return unless @isProduction and analytics?
    url = Backbone.history.getFragment()
    console.log 'Going to track visit for', "/#{url}" if debugAnalytics
    analytics.pageview "/#{url}"

  trackEvent: (event, properties, includeProviders=null) =>
    console.log 'Would track analytics event:', event, properties if debugAnalytics
    return unless me and @isProduction and analytics?
    console.log 'Going to track analytics event:', event, properties if debugAnalytics
    properties = properties or {}
    context = {}
    if includeProviders
      context.providers = {'All': false}
      for provider in includeProviders
        context.providers[provider] = true
    event.label = properties.label if properties.label
    analytics?.track event, properties, context

  trackTiming: (duration, category, variable, label, samplePercentage=5) ->
    # https://developers.google.com/analytics/devguides/collection/gajs/gaTrackingTiming
    return console.warn "Duration #{duration} invalid for trackTiming call." unless duration >= 0 and duration < 60 * 60 * 1000
    console.log 'Would track timing event:', arguments if debugAnalytics
    window._gaq?.push ['_trackTiming', category, variable, duration, label, samplePercentage]
