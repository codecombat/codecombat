unsafePaths = [
  /^\/web-dev-iframe\.html$/
  /^\/javascripts\/web-dev-listener\.js$/
]

config = require '../../server_config'

domainFilter = (req, res, next) ->
  domainRegex = new RegExp("(.*\.)?(#{config.mainHostname}|#{config.unsafeContentHostname})")
  domainPrefix = req.hostname?.match(domainRegex)?[1] or ''
  if _.any(unsafePaths, (pathRegex) -> pathRegex.test(req.path)) and (req.host isnt domainPrefix + config.unsafeContentHostname)
    res.redirect('//' + domainPrefix + config.unsafeContentHostname + req.path)
  else if not _.any(unsafePaths, (pathRegex) -> pathRegex.test(req.path)) and req.host is domainPrefix + config.unsafeContentHostname
    res.redirect('//' + domainPrefix + config.mainHostname + req.path)
  else
    next()

module.exports = domainFilter
