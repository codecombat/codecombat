

module.exports.custom = (res, code=500, message='Internal Server Error') ->
  res.send code, message
  res.end()

module.exports.unauthorized = (res, message='Unauthorized') ->
  # TODO: The response MUST include a WWW-Authenticate header field
  res.send 401, message
  res.end()

module.exports.forbidden = (res, message='Forbidden') ->
  res.send 403, message
  res.end()

module.exports.notFound = (res, message='Not found.') ->
  res.send 404, message
  res.end()

module.exports.badMethod = (res, message='Method Not Allowed') ->
  # TODO: The response MUST include an Allow header containing a list of valid methods for the requested resource
  res.send 405, message
  res.end()

module.exports.conflict = (res, message='Conflict. File exists') ->
  res.send 409, message
  res.end()

module.exports.badInput = (res, message='Unprocessable Entity. Bad Input.') ->
  res.send 422, message
  res.end()

module.exports.serverError = (res, message='Internal Server Error') ->
  res.send 500, message
  res.end()

module.exports.gatewayTimeoutError = (res, message="Gateway timeout") ->
  res.send 504, message
  res.end()
