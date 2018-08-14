module.exports = loadSegmentio = if not me.useSocialSignOn() then -> Promise.resolve([]) else _.once ->
  return new Promise (accept, reject) ->
    analytics = window.analytics = window.analytics or []
    analytics.invoked = true
    analytics.methods = [
      'trackSubmit'
      'trackClick'
      'trackLink'
      'trackForm'
      'pageview'
      'identify'
      'reset'
      'group'
      'track'
      'ready'
      'alias'
      'page'
      'once'
      'off'
      'on'
    ]

    analytics.factory = (t) ->
      ->
        e = Array::slice.call(arguments)
        e.unshift t
        analytics.push e
        analytics

    for method in analytics.methods
      analytics[method] = analytics.factory method

    analytics.load = (t) ->
      e = document.createElement 'script'
      e.type = 'text/javascript'
      e.async = true
      e.src = (if document.location.protocol is 'https:' then 'https://' else 'http://') + 'cdn.segment.com/analytics.js/v1/' + t + '/analytics.min.js'
      n = document.getElementsByTagName('script')[0]
      n.parentNode.insertBefore e, n
      # Backbone.Mediator.publish 'application:service-loaded', service: 'segment'
      accept(analytics)
      return

    analytics.SNIPPET_VERSION = '3.1.0'
    analytics.load 'yJpJZWBw68fEj0aPSv8ffMMgof5kFnU9'
    #analytics.page()  # Don't track the page view on initial inclusion
