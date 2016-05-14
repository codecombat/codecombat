wrap = require 'co-express'
errors = require '../commons/errors'

module.exports = wrap (req, res) ->
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
  res.status(200).send('OK')
