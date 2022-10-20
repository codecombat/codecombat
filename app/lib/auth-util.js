import jwtDecode from 'jwt-decode'

function parseGoogleJwtResponse (token) {
  const decoded = jwtDecode(token)
  return {
    gplusID: decoded.sub,
    firstName: decoded.given_name,
    lastName: decoded.family_name,
    email: decoded.email
  }
}

module.exports = {
  parseGoogleJwtResponse
}
