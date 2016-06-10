{me} = require 'core/auth'
SuperModel = require 'models/SuperModel'
utils = require 'core/utils'
CocoClass = require 'core/CocoClass'

debugAnalytics = false
targetInspectJSLevelSlugs = ['cupboards-of-kithgard']

module.exports = class Tracker extends CocoClass
  subscriptions:
    'application:service-loaded': 'onServiceLoaded'

  constructor: ->
    super()
    if window.tracker
      console.error 'Overwrote our Tracker!', window.tracker
    window.tracker = @
    @isProduction = document.location.href.search('codecombat.com') isnt -1
    @trackReferrers()
    @identify()
    @supermodel = new SuperModel()
    @updateRole() if me.get 'role'

  enableInspectletJS: (levelSlug) ->
    # InspectletJS loading is delayed and targeting specific levels for more focused investigations
    return @disableInspectletJS() unless levelSlug in targetInspectJSLevelSlugs

    scriptLoaded = =>
      # Identify and track pageview here, because inspectlet is loaded too late for standard Tracker calls
      @identify()
      # http://www.inspectlet.com/docs#virtual_pageviews
      window.__insp?.push(['virtualPage'])
    window.__insp = [['wid', 2102699786]]
    insp = document.createElement('script')
    insp.type = 'text/javascript'
    insp.async = true
    insp.id = 'inspsync'
    insp.src = (if 'https:' == document.location.protocol then 'https' else 'http') + '://cdn.inspectlet.com/inspectlet.js'
    insp.onreadystatechange = -> scriptLoaded() if insp.readyState is 'complete'
    insp.onload = scriptLoaded
    x = document.getElementsByTagName('script')[0]
    @inspectletScriptNode = x.parentNode.insertBefore insp, x

  disableInspectletJS: ->
    if @inspectletScriptNode
      x = document.getElementsByTagName('script')[0]
      x.parentNode.removeChild(@inspectletScriptNode)
      @inspectletScriptNode = null
    delete window.__insp

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

    for userTrait in ['email', 'anonymous', 'dateCreated', 'name', 'testGroupNumber', 'gender', 'lastLevel', 'siteref', 'ageRange', 'schoolName', 'coursePrepaidID', 'role']
      traits[userTrait] ?= me.get(userTrait)
    if me.isTeacher()
      traits.teacher = true

    console.log 'Would identify', me.id, traits if debugAnalytics
    return unless @isProduction and not me.isAdmin()

    # Errorception
    # https://errorception.com/docs/meta
    _errs?.meta = traits

    # Inspectlet
    # https://www.inspectlet.com/docs#identifying_users
    __insp?.push ['identify', me.id]
    __insp?.push ['tagSession', traits]

    # Mixpanel
    # https://mixpanel.com/help/reference/javascript
    mixpanel.identify(me.id)
    mixpanel.register(traits)

    if me.isTeacher() and @segmentLoaded
      traits.createdAt = me.get 'dateCreated'  # Intercom, at least, wants this
      analytics.identify me.id, traits

  trackPageView: (includeIntegrations=[]) ->
    includeMixpanel = (name) ->
      mixpanelIncludes = ['', 'schools', 'play', 'play/level/dungeons-of-kithgard']
      name in mixpanelIncludes or /courses|students|teachers/ig.test(name)

    name = Backbone.history.getFragment()
    url = "/#{name}"
    console.log "Would track analytics pageview: #{url} Mixpanel=#{includeMixpanel(name)}" if debugAnalytics
    @trackEventInternal 'Pageview', url: name unless me?.isAdmin() and @isProduction
    return unless @isProduction and not me.isAdmin()

    # Google Analytics
    # https://developers.google.com/analytics/devguides/collection/analyticsjs/pages
    ga? 'send', 'pageview', url

    # Mixpanel
    mixpanel.track('page viewed', 'page name' : name, url : url) if includeMixpanel(name)

    if me.isTeacher() and @segmentLoaded
      options = {}
      if includeIntegrations?.length
        options.integrations = All: false
        for integration in includeIntegrations
          options.integrations[integration] = true
      analytics.page url, {}, options

  trackEvent: (action, properties={}, includeIntegrations=[]) =>
    @trackEventInternal action, _.cloneDeep properties unless me?.isAdmin() and @isProduction
    console.log 'Tracking external analytics event:', action, properties, includeIntegrations if debugAnalytics
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

    # Mixpanel
    # Only log explicit events for now
    mixpanel.track(action, properties) if 'Mixpanel' in includeIntegrations

    if me.isTeacher() and @segmentLoaded
      options = {}
      if includeIntegrations
        # https://segment.com/docs/libraries/analytics.js/#selecting-integrations
        options.integrations = All: false
        for integration in includeIntegrations
          options.integrations[integration] = true
      analytics?.track action, {}, options

  trackEventInternal: (event, properties) =>
    # Skipping heavily logged actions we don't use internally
    return if event in ['Simulator Result', 'Started Level Load', 'Finished Level Load']
    # Trimming properties we don't use internally
    # TODO: delete properites.level for 'Saw Victory' after 2/8/15.  Should be using levelID instead.
    if event in ['Clicked Start Level', 'Inventory Play', 'Heard Sprite', 'Started Level', 'Saw Victory', 'Click Play', 'Choose Inventory', 'Homepage Loaded', 'Change Hero']
      delete properties.category
      delete properties.label
    else if event in ['Loaded World Map', 'Started Signup', 'Finished Signup', 'Login', 'Facebook Login', 'Google Login', 'Show subscription modal']
      delete properties.category

    properties[key] = value for key, value of @explicitTraits if @explicitTraits?
    console.log 'Tracking internal analytics event:', event, properties if debugAnalytics

    request = @supermodel.addRequestResource {
      url: '/db/analytics.log.event/-/log_event'
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

  updateRole: ->
    return unless me.isTeacher()
    return require('core/services/segment')() unless @segmentLoaded
    @identify()
    #analytics.page()  # It looks like we don't want to call this here because it somehow already gets called once in addition to this.
    # TODO: record any events and pageviews that have built up before we knew we were a teacher.

  onServiceLoaded: (e) ->
    return unless e.service is 'segment'
    @segmentLoaded = true
    @updateRole()
