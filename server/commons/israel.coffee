jwt = require 'jsonwebtoken'
config = require '../../server_config'
errors = require '../commons/errors'

verifyToken = (israelToken) ->
  try
    result = jwt.verify(israelToken, config.israel.jwtSecret)
  catch e
    if e.name is 'JsonWebTokenError'
      throw new errors.UnprocessableEntity('Invalid JWT Token.')
    if e.name is 'TokenExpiredError'
      throw new errors.UnprocessableEntity('Expired JWT Token.')
    if e.name is 'NotBeforeError'
      throw new errors.UnprocessableEntity('Not yet valid JWT Token.')
    throw e
  { aud, iss, district } = result
  unless aud is config.israel.jwtAudience and iss is config.israel.jwtIssuer and district is config.israel.jwtDistrict
    throw new errors.UnprocessableEntity('JWT token info does not match.')
    
  # properties returned: 'sub' (israel id) and 'type'
  return result

module.exports = {
  verifyToken
}
