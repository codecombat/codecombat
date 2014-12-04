log = require 'winston'

module.exports.custom = (res, code=500, message='Internal Server Error') ->
  log.debug "#{code}: #{message}"
  res.send code, message
  res.end()

module.exports.unauthorized = (res, message='Unauthorized') ->
  # TODO: The response MUST include a WWW-Authenticate header field
  log.debug "401: #{message}"
  res.send 401, message
  res.end()

module.exports.forbidden = (res, message='Forbidden') ->
  log.debug "403: #{message}"
  res.send 403, message
  res.end()
  
module.exports.paymentRequired = (res, message='Payment required') ->
  log.debug "402: #{message}"
  res.send 402, message
  res.end()

module.exports.notFound = (res, message='Not found.') ->
  res.send 404, message
  res.end()

module.exports.badMethod = (res, allowed=['GET', 'POST', 'PUT', 'PATCH'], message='Method Not Allowed') ->
  log.debug "405: #{message}"
  allowHeader = _.reduce allowed, ((str, current) -> str += ', ' + current)
  res.set 'Allow', allowHeader # TODO not sure if these are always the case
  res.send 405, message
  res.end()

module.exports.conflict = (res, message='Conflict. File exists') ->
  log.debug "409: #{message}"
  res.send 409, message
  res.end()

module.exports.badInput = (res, message='Unprocessable Entity. Bad Input.') ->
  log.debug "422: #{message}"
  res.send 422, message
  res.end()

module.exports.serverError = (res, message='Internal Server Error') ->
  log.debug "500: #{message}"
  res.send 500, message
  res.end()

module.exports.gatewayTimeoutError = (res, message='Gateway timeout') ->
  log.debug "504: #{message}"
  res.send 504, message
  res.end()

module.exports.clientTimeout = (res, message='The server did not receive the client response in a timely manner') ->
  log.debug "408: #{message}"
  res.send 408, message
  res.end()
