wrap = require 'co-express'
errors = require '../commons/errors'
database = require '../commons/database'
config = require '../../server_config'
request = require 'request'

getAPCSPFile = wrap (req, res) ->
  if not req.user
    throw new errors.Unauthorized('You must be logged in')

  unless req.user.get('verifiedTeacher') or req.user.isAdmin()
    throw new errors.Forbidden('You cannot access this file')

  rest = req.params['0']
  if _.str.endsWith(rest, '/')
    rest = rest.slice(0, rest.length-1)
  url = "#{config.apcspFileUrl}#{rest}.md"
  [proxyRes] = yield request.getAsync({url})
  if proxyRes.statusCode is 404 or proxyRes.statusCode is 403
    throw new errors.NotFound('Document could not be found.')
  else if proxyRes.statusCode >= 400
    console.log 'proxy res:', proxyRes.statusCode, proxyRes.body
    throw new errors.BadGatewayError()
  res.send(proxyRes.body)

  
module.exports = {
  getAPCSPFile
}
