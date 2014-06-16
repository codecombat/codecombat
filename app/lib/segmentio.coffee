module.exports = initializeSegmentio = ->
  analytics = analytics or []
  (->
    e = [
      "identify"
      "track"
      "trackLink"
      "trackForm"
      "trackClick"
      "trackSubmit"
      "page"
      "pageview"
      "ab"
      "alias"
      "ready"
      "group"
    ]
    t = (e) ->
      ->
        analytics.push [e].concat(Array::slice.call(arguments, 0))
        return

    n = 0

    while n < e.length
      analytics[e[n]] = t(e[n])
      n++
    return
  )()
  analytics.load = (e) ->
    t = document.createElement("script")
    t.type = "text/javascript"
    t.async = not 0
    t.src = ((if "https:" is document.location.protocol then "https://" else "http://")) + "d2dq2ahtl5zl1z.cloudfront.net/analytics.js/v1/" + e + "/analytics.min.js"

    n = document.getElementsByTagName("script")[0]
    n.parentNode.insertBefore t, n
    return


  analytics.load "jsjzx9n4d2"
