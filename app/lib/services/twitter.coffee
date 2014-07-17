module.exports = initializeTwitter = ->
  ((d, s, id) ->
    js = undefined
    fjs = d.getElementsByTagName(s)[0]
    p = (if /^http:/.test(d.location) then 'http' else 'https')
    unless d.getElementById(id)
      js = d.createElement(s)
      js.id = id
      js.src = p + '://platform.twitter.com/widgets.js'
      fjs.parentNode.insertBefore js, fjs
    return
  ) document, 'script', 'twitter-wjs'
