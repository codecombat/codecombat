{me} = require 'core/auth'
SuperModel = require 'models/SuperModel'
utils = require 'core/utils'
CocoClass = require 'core/CocoClass'
loadSegmentIo = require('core/services/segment')
api = require('core/api')

experiments = require('core/experiments')

debugAnalytics = false

module.exports = class Tracker extends CocoClass
  initialized: false
  cookies: {required: false, answered: false, consented: false, declined: false}
  constructor: ->
    super()
    if window.tracker
      console.error 'Overwrote our Tracker!', window.tracker
    window.tracker = @
    @supermodel = new SuperModel()
    @isProduction = document.location.href.search('codecombat.com') isnt -1
    @promptForCookieConsent()  # Will call finishInitialization

  promptForCookieConsent: ->
    return unless $.i18n.lng()  # Will initialize once we finish initializing translations
    return @finishInitialization() unless me.get('country') and me.inEU()
    @cookies.required = true
    @cookiePopup?.close()
    window.cookieconsent.hasTransition = false
    window.cookieconsent.initialise
      onPopupOpen: ->
        window.tracker.cookiePopup = @
      onInitialise: (status) ->
        window.tracker.cookiePopup = @
        window.tracker.cookies.answered = status in ['allow', 'dismiss', 'deny']
        window.tracker.cookies.consented = status in ['allow', 'dismiss']
        window.tracker.cookies.declined = status is 'deny'
        console.log 'Initial cookie consent status:', status, window.tracker.cookies if debugAnalytics
        window.tracker.finishInitialization()
      onStatusChange: (status) ->
        window.tracker.cookies.answered = status in ['allow', 'dismiss', 'deny']
        window.tracker.cookies.consented = status in ['allow', 'dismiss']
        window.tracker.cookies.declined = status is 'deny'
        console.log 'Cookie consent status change:', status, window.tracker.cookies if debugAnalytics
      container: document.getElementById('#page-container')
      palette: {popup: {background: "#000"}, button: {background: "#f1d600"}}
      hasTransition: false
      revokable: true
      law: false
      location: false
      type: 'opt-out'
      content:
        message: $.i18n.t 'legal.cookies_message'
        dismiss: $.i18n.t 'general.accept'
        deny: $.i18n.t 'legal.cookies_deny'
        link: $.i18n.t 'nav.privacy'
        href: '/privacy'

  finishInitialization: ->
    return if @initialized
    @initialized = true
    @trackReferrers()
    @identify() # Needs supermodel to exist first
    @updateRole() if me.get('role')
    if me.isTeacher(true) and not me.get('unsubscribedFromMarketingEmails')
      @updateIntercomRegularly()

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

    if me.isTeacher(true) and @segmentLoaded and not me.get('unsubscribedFromMarketingEmails')
      traits.createdAt = me.get 'dateCreated'  # Intercom, at least, wants this
      analytics.identify me.id, traits

  trackPageView: (includeIntegrations=[]) ->
    name = Backbone.history.getFragment()
    url = "/#{name}"

    console.log "Would track analytics pageview: #{url}" if debugAnalytics
    @trackEventInternal 'Pageview', url: name, href: window.location.href
    return unless @shouldTrackExternalEvents()

    # Google Analytics
    # https://developers.google.com/analytics/devguides/collection/analyticsjs/pages
    ga? 'send', 'pageview', url
    ga?('codeplay.send', 'pageview', url) if features.codePlay
    window.snowplow 'trackPageView'

    if me.isTeacher(true) and @segmentLoaded
      options = {}
      if includeIntegrations?.length
        options.integrations = All: false
        for integration in includeIntegrations
          options.integrations[integration] = true
      analytics.page url, {}, options

  trackEvent: (action, properties={}, includeIntegrations=[]) =>
    console.log 'Tracking external analytics event:', action, properties, includeIntegrations if debugAnalytics
    return unless @shouldTrackExternalEvents()

    @trackEventInternal action, _.cloneDeep properties
    @trackSnowplow action, _.cloneDeep properties

    unless action in ['View Load', 'Script Started', 'Script Ended', 'Heard Sprite']
      # Google Analytics
      # https://developers.google.com/analytics/devguides/collection/analyticsjs/events
      gaFieldObject =
        hitType: 'event'
        eventCategory: properties.category ? 'All'
        eventAction: action
      gaFieldObject.eventLabel = properties.label if properties.label?
      gaFieldObject.eventValue = properties.value if properties.value?

      # NOTE these custom dimensions need to be configured in GA prior to being reported
      try
        gaFieldObject.dimension1 = experiments.getRequestAQuoteGroup(me)
      catch e
        # TODO handle_error_ozaria
        console.error(e)

      ga? 'send', gaFieldObject
      ga? 'codeplay.send', gaFieldObject if features.codePlay

    if me.isTeacher(true) and @segmentLoaded
      options = {}
      if includeIntegrations
        # https://segment.com/docs/libraries/analytics.js/#selecting-integrations
        options.integrations = All: false
        for integration in includeIntegrations
          options.integrations[integration] = true
      analytics?.track action, {}, options

  trackSnowplow: (event, properties) =>
    return if @shouldBlockAllTracking()
    return if event in [
      'Simulator Result',
      'Started Level Load', 'Finished Level Load',
      'Start HoC Campaign', 'Show Amazon Modal Button', 'Click Amazon Modal Button', 'Click Amazon link',
      'Error in ssoConfirmView'  # TODO: Event for only detecting an error in prod. Tracking this only via GA. Remove when not required.
    ]
    # Trimming properties we don't use internally
    # TODO: delete properites.level for 'Saw Victory' after 2/8/15.  Should be using levelID instead.
    if event in ['Clicked Start Level', 'Inventory Play', 'Heard Sprite', 'Started Level', 'Saw Victory', 'Click Play', 'Choose Inventory', 'Homepage Loaded', 'Change Hero']
      delete properties.label

    if event is 'View Load' # TODO: Update snowplow schema to include these
      delete properties.totalEssentialEncodedBodySize
      delete properties.totalEssentialTransferSize
      delete properties.cachedEssentialResources
      delete properties.totalEssentialResources

    # Remove personally identifiable data
    delete properties.name
    delete properties.email

    # SnowPlow
    snowplowAction = event.toLowerCase().replace(/[^a-z0-9]+/ig, '_')
    properties.user = me.id
    delete properties.category
    #console.log "SnowPlow", snowplowAction, properties

    try
      schema = require("schemas/events/" + snowplowAction + ".json")
    catch
      console.warn('Schema not found for snowplow action: ', snowplowAction, properties)
      return

    unless @isProduction
      result = tv4.validateResult(properties, schema)
      if not result.valid
        text = 'Snowplow event schema validation failed! See console'
        console.log 'Snowplow event failure info:', {snowplowAction, properties, error: result.error}
        noty {text, layout: 'center', type: 'error', killer: false, timeout: 5000, dismissQueue: true, maxVisible: 3}

    window.snowplow 'trackUnstructEvent',
      schema: "iglu:com.codecombat/#{snowplowAction}/jsonschema/#{schema.self.version}"
      data: properties

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

  updateIntercomRegularly: ->
    return if @shouldBlockAllTracking() or application.testing or not @isProduction
    timesChecked = 0
    updateIntercom = =>
      # Check for new Intercom messages!
      # Intercom only allows 10 updates for free per page refresh; then 1 per 30min
      # https://developers.intercom.com/docs/intercom-javascript#section-intercomupdate
      window.Intercom?('update')
      timesChecked += 1
      timeUntilNext = (if timesChecked < 10 then 5*60*1000 else 30*60*1000)
      setTimeout(updateIntercom, timeUntilNext)
    setTimeout(updateIntercom, 5*60*1000)

  updateRole: ->
    return if me.isAdmin() or @shouldBlockAllTracking()
    return unless me.isTeacher(true)
    loadSegmentIo()
    .then =>
      @segmentLoaded = true and me.useSocialSignOn()
      @identify()
    #analytics.page()  # It looks like we don't want to call this here because it somehow already gets called once in addition to this.
    # TODO: record any events and pageviews that have built up before we knew we were a teacher.

  updateTrialRequestData: (attrs) ->
    return if @shouldBlockAllTracking()
    loadSegmentIo()
    .then =>
      @segmentLoaded = true and me.useSocialSignOn()
      @identify(attrs)

  shouldBlockAllTracking: ->
    doNotTrack = (navigator?.doNotTrack or window?.doNotTrack) and not (navigator?.doNotTrack is 'unspecified' or window?.doNotTrack is 'unspecified')
    return me.isSmokeTestUser() or window.serverSession.amActually or doNotTrack or @cookies.declined
    # Should we include application.testing in this?

  shouldTrackExternalEvents: ->
    return not @shouldBlockAllTracking() and @isProduction and not me.isAdmin()
