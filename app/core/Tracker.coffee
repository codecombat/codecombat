{me} = require 'core/auth'
SuperModel = require 'models/SuperModel'

debugAnalytics = false

module.exports = class Tracker
  constructor: ->
    if window.tracker
      console.error 'Overwrote our Tracker!', window.tracker
    window.tracker = @
    @isProduction = document.location.href.search('codecombat.com') isnt -1
    @identify()
    @supermodel = new SuperModel()

  identify: (traits) ->
    console.log 'Would identify', traits if debugAnalytics
    return unless me and @isProduction and analytics? and not me.isAdmin()
    # https://segment.io/docs/methods/identify
    traits ?= {}
    for userTrait in ['email', 'anonymous', 'dateCreated', 'name', 'wizardColor1', 'testGroupNumber', 'gender']
      traits[userTrait] ?= me.get(userTrait)
    analytics.identify me.id, traits

  trackPageView: (virtualName=null, includeIntegrations=null) ->
    # console.log 'trackPageView', virtualName, includeIntegrations
    # Google Analytics does not support event-based funnels, so we have to use virtual pageviews instead
    # https://support.google.com/analytics/answer/1032720?hl=en
    name = virtualName ? Backbone.history.getFragment()

    properties = {}
    if virtualName?
      # Override title and path properties for virtual page view
      # https://segment.com/docs/libraries/analytics.js/#page
      properties =
        title: name
        path: "/#{name}"

    options = {}
    if includeIntegrations?
      options = integrations: {'All': false}
      for integration in includeIntegrations
        options.integrations[integration] = true

    console.log "Would track analytics pageview: '/#{name}'", properties, options, includeIntegrations if debugAnalytics
    return unless @isProduction and analytics? and not me.isAdmin()

    # Ok to pass empty properties, but maybe not options
    # TODO: What happens when we pass empty options?
    if _.isEmpty options
      # console.log "trackPageView without options '/#{name}'", properties, options
      analytics.page "/#{name}"
    else
      # console.log "trackPageView with options '/#{name}'", properties, options
      analytics.page "/#{name}", properties, options

  trackEvent: (action, properties, includeIntegrations=null) =>
    # 'action' is a string
    # Google Analytics properties format: {category: 'Account', label: 'Premium', value: 50 }
    # https://segment.com/docs/integrations/google-analytics/#track
    # https://developers.google.com/analytics/devguides/collection/gajs/eventTrackerGuide#Anatomy
    # Mixpanel properties format: whatever you want unlike GA
    # https://segment.com/docs/integrations/mixpanel/
    properties = properties or {}

    @trackEventInternal action, _.cloneDeep properties unless me?.isAdmin() and @isProduction

    console.log 'Would track analytics event:', action, properties, includeIntegrations if debugAnalytics
    return unless me and @isProduction and analytics? and not me.isAdmin()
    context = {}
    if includeIntegrations
      # https://segment.com/docs/libraries/analytics.js/#selecting-integrations
      context.integrations = {'All': false}
      for integration in includeIntegrations
        context.integrations[integration] = true
    analytics?.track action, properties, context

  trackEventInternal: (event, properties) =>
    # Skipping heavily logged actions we don't use internally
    unless event in ['Simulator Result', 'Started Level Load', 'Finished Level Load']
      # Trimming properties we don't use internally
      # TODO: delete internalProperites.level for 'Saw Victory' after 2/8/15.  Should be using levelID instead.
      if event in ['Clicked Level', 'Inventory Play', 'Heard Sprite', 'Started Level', 'Saw Victory', 'Click Play', 'Choose Inventory', 'Loaded World Map', 'Homepage Loaded', 'Change Hero']
        delete properties.category 
        delete properties.label
      else if event in ['Started Signup', 'Finished Signup', 'Login', 'Facebook Login', 'Google Login']
        delete properties.category 

      console.log 'Tracking internal analytics event:', event, properties if debugAnalytics
      request = @supermodel.addRequestResource 'log_event', {
        url: '/db/analytics_log_event/-/log_event'
        data: {event: event, properties: properties}
        method: 'POST'
      }, 0
      request.load()

  trackTiming: (duration, category, variable, label, samplePercentage=5) ->
    # https://developers.google.com/analytics/devguides/collection/gajs/gaTrackingTiming
    return console.warn "Duration #{duration} invalid for trackTiming call." unless duration >= 0 and duration < 60 * 60 * 1000
    console.log 'Would track timing event:', arguments if debugAnalytics
    window._gaq?.push ['_trackTiming', category, variable, duration, label, samplePercentage]
