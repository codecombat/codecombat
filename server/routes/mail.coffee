mail = require '../commons/mail'
map = _.invert mail.MAILCHIMP_GROUP_MAP
User = require '../users/User.coffee'
errors = require '../commons/errors'
request = require 'request'
config = require '../../server_config'

badLog = (text) ->
  console.log text
  request.post 'http://requestb.in/1brdpaz1', { form: {log: text} }
  
module.exports.setupRoutes = (app) ->
  app.all config.mail.mailchimpWebhook, (req, res) ->
    post = req.body
    badLog("Got post data: #{JSON.stringify(post, null, '\t')}")
    
    unless post.type in ['unsubscribe', 'profile']
      badLog("Bad post type: #{post.type}")
      return errors.badInput(res, 'Bad post type')

    unless post.data.email
      badLog("Ignoring because no email: #{JSON.stringify(req.body, null, '\t')}")
      return errors.badInput(res, 'No email provided')

    unless post.data.email is 'sderickson@gmail.com'
      badLog("Ignoring because this is a test: #{JSON.stringify(req.body, null, '\t')}")
      return res.end()
    
    User.findOne {'mailChimp.euid':post.data.id}, (err, user) ->
      return errors.serverError(res) if err
      if not user
        badLog("could not find user for...: #{{'mailChimp.euid':post.data.id}}")
        return errors.notFound(res) if err

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

  badLog("Updating user object to: #{JSON.stringify(user.toObject(), null, '\t')}")
    
handleUnsubscribe = (user) ->
  user.set 'emailSubscriptions', []

  badLog("Unsubscribing user object to: #{JSON.stringify(user.toObject(), null, '\t')}") 