{me} = require 'core/auth'
SuperModel = require 'models/SuperModel'
utils = require 'core/utils'

debugAnalytics = false

module.exports = class Tracker
  constructor: ->
    if window.tracker
      console.error 'Overwrote our Tracker!', window.tracker
    window.tracker = @
    @isProduction = document.location.href.search('codecombat.com') isnt -1
    @trackReferrers()
    @identify()
    @supermodel = new SuperModel()

  trackReferrers: ->
    elapsed = new Date() - new Date(me.get('dateCreated'))
    return unless elapsed < 5 * 60 * 1000
    return if me.get('siteref') or me.get('referrer')
    changed = false
    if siteref = utils.getQueryVariable '_r'
      me.set 'siteref', siteref
      changed = true
    if referrer = document.referrer
      me.set 'referrer', referrer
      changed = true
    me.patch() if changed

  identify: (traits={}) ->
    return unless me

    # Save explicit traits for internal tracking
    @explicitTraits ?= {}
    @explicitTraits[key] = value for key, value of traits

    for userTrait in ['email', 'anonymous', 'dateCreated', 'name', 'testGroupNumber', 'gender', 'lastLevel', 'siteref', 'ageRange']
      traits[userTrait] ?= me.get(userTrait)
    console.log 'Would identify', traits if debugAnalytics
    return unless @isProduction and not me.isAdmin()

    # Errorception
    # https://errorception.com/docs/meta
    _errs?.meta = traits

    # Inspectlet
    # https://www.inspectlet.com/docs#identifying_users
    __insp?.push ['identify', me.id]
    __insp?.push ['tagSession', traits]

  trackPageView: ->
    name = Backbone.history.getFragment()
    console.log "Would track analytics pageview: '/#{name}'" if debugAnalytics
    return unless @isProduction and not me.isAdmin()

    # Google Analytics
    # https://developers.google.com/analytics/devguides/collection/analyticsjs/pages
    ga? 'send', 'pageview', "/#{name}"

    # Inspectlet
    # http://www.inspectlet.com/docs#virtual_pageviews
    __insp?.push ['virtualPage']

  trackEvent: (action, properties={}) =>
    @trackEventInternal action, _.cloneDeep properties unless me?.isAdmin() and @isProduction
    console.log 'Tracking external analytics event:', action, properties if debugAnalytics
    return unless me and @isProduction and not me.isAdmin()

    # Google Analytics
    # https://developers.google.com/analytics/devguides/collection/analyticsjs/events
    gaFieldObject =
      hitType: 'event'
      eventCategory: properties.category ? 'All'
      eventAction: action
    gaFieldObject.eventLabel = properties.label if properties.label?
    gaFieldObject.eventValue = properties.value if properties.value?
    ga? 'send', gaFieldObject

    # Inspectlet
    # http://www.inspectlet.com/docs#tagging
    __insp?.push ['tagSession', action: action, properies: properties]

  trackEventInternal: (event, properties) =>
    # Skipping heavily logged actions we don't use internally
    unless event in ['Simulator Result', 'Started Level Load', 'Finished Level Load']
      # Trimming properties we don't use internally
      # TODO: delete properites.level for 'Saw Victory' after 2/8/15.  Should be using levelID instead.
      if event in ['Clicked Start Level', 'Inventory Play', 'Heard Sprite', 'Started Level', 'Saw Victory', 'Click Play', 'Choose Inventory', 'Homepage Loaded', 'Change Hero']
        delete properties.category
        delete properties.label
      else if event in ['Loaded World Map', 'Started Signup', 'Finished Signup', 'Login', 'Facebook Login', 'Google Login', 'Show subscription modal']
        delete properties.category

      properties[key] = value for key, value of @explicitTraits if @explicitTraits?
      console.log 'Tracking internal analytics event:', event, properties if debugAnalytics
      if @isProduction
        eventObject = {}
        eventObject["event"] = event
        eventObject["properties"] = properties unless _.isEmpty properties
        eventObject["user"] = me.id
        dataToSend = JSON.stringify eventObject
        # console.log dataToSend if debugAnalytics
        $.post("http://analytics.codecombat.com/analytics", dataToSend).fail ->
          console.error "Analytics post failed!"
      else
        request = @supermodel.addRequestResource 'log_event', {
          url: '/db/analytics_log_event/-/log_event'
          data: {event: event, properties: properties}
          method: 'POST'
        }, 0
        request.load()

  trackTiming: (duration, category, variable, label) ->
    # https://developers.google.com/analytics/devguides/collection/analyticsjs/user-timings
    return console.warn "Duration #{duration} invalid for trackTiming call." unless duration >= 0 and duration < 60 * 60 * 1000
    console.log 'Would track timing event:', arguments if debugAnalytics
    return unless me and @isProduction and not me.isAdmin()
    ga? 'send', 'timing', category, variable, duration, label
