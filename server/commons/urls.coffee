makeHostUrl = (req, path) ->
  host = req.headers.host ? 'codecombat.com'
  protocol = req.headers['x-forwarded-proto'] ? 'https'
  port = req.headers['x-forwarded-port'] ? ''
  port = ':'+port if port
  return "#{protocol}://#{host}#{port}#{path}"

module.exports = {
  makeHostUrl
}
