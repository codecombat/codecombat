wrap = require 'co-express'
errors = require '../commons/errors'
co = require 'co'

healthcheckRoute = wrap (req, res) ->
  yield runHealthcheck()
  res.status(200).send('OK')
  
runHealthcheck = co.wrap ->
  User = require '../models/User'
  user = yield User.findOne({})
  throw new errors.InternalServerError('No users found') unless user
  hcUser = yield User.findOne(slug: 'healthcheck')
  if not hcUser
    hcUser = new User({
      anonymous: false
      name: 'healthcheck'
      nameLower: 'healthcheck'
      slug: 'healthcheck'
      email: 'rob+healthcheck@codecombat.com'
      emailLower: 'rob+healthcheck@codecombat.com'
    })
    hcUser.set 'testGroupNumber', Math.floor(Math.random() * 256)  # also in app/core/auth
    yield hcUser.save()
  activity = hcUser.trackActivity('healthcheck', 1)
  yield hcUser.update({activity: activity})
  return true

module.exports = {
  healthcheckRoute
  runHealthcheck
}
