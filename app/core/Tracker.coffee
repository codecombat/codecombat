{me} = require 'core/auth'
SuperModel = require 'models/SuperModel'
utils = require 'core/utils'
CocoClass = require 'core/CocoClass'
api = require('core/api')

debugAnalytics = false

module.exports = class Tracker extends CocoClass
  initialized: false
  cookies: {required: false, answered: false, consented: false, declined: false}
  constructor: ->
    super()
    @supermodel = new SuperModel()
    @isProduction = document.location.href.search('codecombat.com') isnt -1

  finishInitialization: ->
    return if @initialized
    @initialized = true
    @trackReferrers()
    @identify() # Needs supermodel to exist first

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
    # Save explicit traits for internal tracking
    @explicitTraits ?= {}
    @explicitTraits[key] = value for key, value of traits

    traitsToReport = [
      'email', 'anonymous', 'dateCreated', 'hourOfCode', 'name', 'referrer', 'testGroupNumber', 'testGroupNumberUS',
      'gender', 'lastLevel', 'siteref', 'ageRange', 'schoolName', 'coursePrepaidID', 'role'
    ]

    if me.isTeacher(true)
      traitsToReport.push('firstName', 'lastName')
    for userTrait in traitsToReport
      traits[userTrait] ?= me.get(userTrait) if me.get(userTrait)?
    if me.isTeacher(true)
      traits.teacher = true
    traits.host = document.location.host

    console.log 'Would identify', me.id, traits if debugAnalytics
    @trackEventInternal('Identify', {id: me.id, traits})
    return unless @shouldTrackExternalEvents()

  trackPageView: (includeIntegrations = []) ->
    name = Backbone.history.getFragment()
    url = "/#{name}"

    console.log "Would track analytics pageview: #{url}" if debugAnalytics
    @trackEventInternal 'Pageview', url: name, href: window.location.href
    return unless @shouldTrackExternalEvents()

    # Google Analytics
    # https://developers.google.com/analytics/devguides/collection/analyticsjs/pages
    ga? 'send', 'pageview', url

  trackEvent: (action, properties={}, includeIntegrations=[]) =>
    console.log 'Tracking external analytics event:', action, properties, includeIntegrations if debugAnalytics
    return unless @shouldTrackExternalEvents()

    @trackEventInternal action, _.cloneDeep properties

    unless action in ['View Load', 'Script Started', 'Script Ended', 'Heard Sprite']
      # Google Analytics
      # https://developers.google.com/analytics/devguides/collection/analyticsjs/events
      gaFieldObject =
        hitType: 'event'
        eventCategory: properties.category ? 'All'
        eventAction: action
      gaFieldObject.eventLabel = properties.label if properties.label?
      gaFieldObject.eventValue = properties.value if properties.value?

      ga? 'send', gaFieldObject

  trackEventInternal: (event, properties) =>
    return if @shouldBlockAllTracking()
    return if @isProduction and me.isAdmin()
    return unless @supermodel?
    # Skipping heavily logged actions we don't use internally
    # TODO: 'Error in ssoConfirmView' event is only for detecting an error in prod. Tracking this only via GA. Remove when not required.
    return if event in ['Simulator Result', 'Started Level Load', 'Finished Level Load', 'View Load', 'Error in ssoConfirmView']
    # Trimming properties we don't use internally
    # TODO: delete properites.level for 'Saw Victory' after 2/8/15.  Should be using levelID instead.
    if event in ['Clicked Start Level', 'Inventory Play', 'Heard Sprite', 'Started Level', 'Saw Victory', 'Click Play', 'Choose Inventory', 'Homepage Loaded', 'Change Hero']
      delete properties.category
      delete properties.label
    else if event in ['Loaded World Map', 'Started Signup', 'Finished Signup', 'Login', 'Facebook Login', 'Google Login', 'Show subscription modal']
      delete properties.category

    properties[key] = value for key, value of @explicitTraits if @explicitTraits?
    console.log 'Tracking internal analytics event:', event, properties if debugAnalytics

    api.analyticsLogEvents.post({event, properties})

  trackTiming: (duration, category, variable, label) ->
    # https://developers.google.com/analytics/devguides/collection/analyticsjs/user-timings
    return console.warn "Duration #{duration} invalid for trackTiming call." unless duration >= 0 and duration < 60 * 60 * 1000
    console.log 'Would track timing event:', arguments if debugAnalytics
    if @shouldTrackExternalEvents()
      ga? 'send', 'timing', category, variable, duration, label

  shouldBlockAllTracking: ->
    doNotTrack = (navigator?.doNotTrack or window?.doNotTrack) and not (navigator?.doNotTrack is 'unspecified' or window?.doNotTrack is 'unspecified')
    return me.isSmokeTestUser() or window.serverSession.amActually or doNotTrack or @cookies.declined
    # Should we include application.testing in this?

  shouldTrackExternalEvents: ->
    return not @shouldBlockAllTracking() and @isProduction and not me.isAdmin()
