mail = require '../commons/mail'
map = _.invert mail.MAILCHIMP_GROUP_MAP
User = require '../users/User.coffee'
errors = require '../commons/errors'
request = require 'request'
config = require '../../server_config'

module.exports.setupRoutes = (app) ->
  app.all config.mail.mailchimpWebhook, (req, res) ->
    post = req.body
    return res.end() unless post.type in ['unsubscribe', 'profile']
    return res.end() unless post.data.email
    User.findOne {'mailChimp.euid':post.data.id}, (err, user) ->
      return errors.serverError(res) if err
      return errors.notFound(res) if not user
      handleProfileUpdate(user, post) if post.type is 'profile'
      handleUnsubscribe(user) if post.type is 'unsubscribe'
      user.updatedMailChimp = true # so as not to echo back to mailchimp
      user.save (err) ->
        return errors.serverError(res) if err
        res.end()


handleProfileUpdate = (user, post) ->
  groups = post.data.merges.INTERESTS.split(', ')
  groups = (map[g] for g in groups when map[g])
  user.set 'emailSubscriptions', groups
  
  mailChimpInfo = user.get 'mailChimp'
  mailChimpInfo.email = post.data.email
  user.set 'mailChimp', mailChimpInfo
    
handleUnsubscribe = (user) ->
  user.set 'emailSubscriptions', []
