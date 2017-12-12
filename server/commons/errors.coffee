log = require 'winston'
_ = require 'lodash'

# NOTE: Prefer using these errors instead of the legacy ones at the bottom of the File
# eg: throw new errors.Forbidden('You must be an administrator to do that')

errorResponseSchema = {
  type: 'object'
  required: ['errorName', 'code', 'message']
  properties: {
    error: {
      description: 'Error object which the callback returned'
    }
    errorName: {
      type: 'string'
      description: 'Human readable error code name'
    }
    code: {
      type: 'integer'
      description: 'HTTP error code'
    }
    validationErrors: {
      type: 'array'
      description: 'TV4 array of validation error objects'
    }
    message: {
      type: 'string'
      description: 'Human readable descripton of the error'
    }
    i18n: {
      type: 'string'
      description: 'i18n tag to get a translated human readable description of the error'
    }
    property: {
      type: 'string'
      description: 'Property which is related to the error (conflict, validation).'
    }
    name: {
      type: 'string'
      description: 'Provided for /auth/name.' # TODO: refactor out
    }
    errorID: {
      type: 'string'
      description: 'Error id to be used by the client to handle specific errors'
    }
  }
}
errorProps = _.keys(errorResponseSchema.properties)

class NetworkError extends Error
  code: 0

  constructor: (@message, options) ->
    @stack = (new Error()).stack
    _.assign(@, options)
  
  toJSON: ->
    _.pick(@, errorProps...)

module.exports.NetworkError = NetworkError

module.exports.Unauthorized = class Unauthorized extends NetworkError
  code: 401
  errorName: 'Unauthorized'
  
module.exports.PaymentRequired = class PaymentRequired extends NetworkError
  code: 402
  errorName: 'PaymentRequired'

module.exports.Forbidden = class Forbidden extends NetworkError
  code: 403
  errorName: 'Forbidden'

module.exports.NotFound = class NotFound extends NetworkError
  code: 404
  errorName: 'Not Found'

module.exports.MethodNotAllowed = class MethodNotAllowed extends NetworkError
  code: 405
  errorName: 'Method Not Allowed'

module.exports.RequestTimeout = class RequestTimeout extends NetworkError
  code: 407
  errorName: 'Request Timeout'

module.exports.Conflict = class Conflict extends NetworkError
  code: 409
  errorName: 'Conflict'

module.exports.UnprocessableEntity = class UnprocessableEntity extends NetworkError
  code: 422
  errorName: 'Unprocessable Entity'

module.exports.InternalServerError = class InternalServerError extends NetworkError
  code: 500
  errorName: 'Internal Server Error'

module.exports.BadGatewayError = class BadGatewayError extends NetworkError
  code: 502
  errorName: 'Bad Gateway Error'
  
module.exports.ServiceUnavailable = class ServiceUnavailable extends NetworkError
  code: 503
  errorName: 'Service Unavailable'

module.exports.GatewayTimeout = class GatewayTimeout extends NetworkError
  code: 504
  errorName: 'Gateway Timeout'



# NOTE: These are the legacy error response handlers; prefer not to use them.
# They are generally sent from Handler using eg. sendForbiddenError

module.exports.custom = (res, code=500, message='Internal Server Error') ->
  log.debug "#{code}: #{message}"
  res.status(code).send message
  res.end()

module.exports.unauthorized = (res, message='Unauthorized') ->
  # TODO: The response MUST include a WWW-Authenticate header field
  log.debug "401: #{message}"
  res.status(401).send message
  res.end()

module.exports.forbidden = (res, message='Forbidden') ->
  log.debug "403: #{message}"
  res.status(403).send message
  res.end()
  
module.exports.paymentRequired = (res, message='Payment required') ->
  log.debug "402: #{message}"
  res.status(402).send message
  res.end()

module.exports.notFound = (res, message='Not found.') ->
  res.status(404).send message
  res.end()

module.exports.badMethod = (res, allowed=['GET', 'POST', 'PUT', 'PATCH'], message='Method Not Allowed') ->
  log.debug "405: #{message}"
  allowHeader = _.reduce allowed, ((str, current) -> str += ', ' + current)
  res.set 'Allow', allowHeader # TODO not sure if these are always the case
  res.status(405).send message
  res.end()

module.exports.conflict = (res, message='Conflict. File exists') ->
  log.debug "409: #{message}"
  res.status(409).send message
  res.end()

module.exports.badInput = (res, message='Unprocessable Entity. Bad Input.') ->
  log.debug "422: #{message}"
  res.status(422).send message
  res.end()

module.exports.serverError = (res, message='Internal Server Error') ->
  log.debug "500: #{message}"
  res.status(500).send message
  res.end()

module.exports.gatewayTimeoutError = (res, message='Gateway timeout') ->
  log.debug "504: #{message}"
  res.status(504).send message
  res.end()

module.exports.clientTimeout = (res, message='The server did not receive the client response in a timely manner') ->
  log.debug "408: #{message}"
  res.status(408).send message
  res.end()
