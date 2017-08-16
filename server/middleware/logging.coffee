log = require 'winston'

logErrors = (title) -> (err, req, res, next) ->
  userString = if req.user then "#{req.user.get('slug')} (#{req.user.id})" else '(no user)'
  log.warn "#{title} error: #{userString}: '#{err.message}'"
  next(err)

module.exports = {
  logErrors
}
