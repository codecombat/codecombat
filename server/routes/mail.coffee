mail = require '../commons/mail'
map = _.invert mail.MAILCHIMP_GROUP_MAP
User = require '../users/User.coffee'
errors = require '../commons/errors'
request = require 'request'

badLog = (text) ->
  console.log text
  request.post 'http://requestb.in/1brdpaz1', { form: {log: text} }
  
module.exports.setupRoutes = (app) ->
  app.all '/mail/webhook', (req, res) ->
    post = req.body
    
    unless post.type in ['unsubscribe', 'profile']
      badLog("Bad post type: #{post.type}")
      return res.end()

    unless post['data[email]']
      badLog("Ignoring because no email: #{JSON.stringify(req.body, null, '\t')}")
      return res.end()

    unless post['data[email]'] is 'sderickson@gmail.com'
      badLog("Ignoring because this is a test: #{JSON.stringify(req.body, null, '\t')}")
      return res.end()
    
    User.findOne {'mailChimp.euid':post['data[id]']}, (err, user) ->
      return errors.serverError(res) if err
      if not user
        badLog("could not find user for...: #{{'mailChimp.euid':post['data[id]']}}")
        return res.end()
      
      handleProfileUpdate(post, user) if post.type is 'profile'
      handleUnsubscribe(post, user) if post.type is 'unsubscribe'

      res.end()
      user.updatedMailChimp = true # so as not to echo back to mailchimp
      user.save (err) ->
        badLog("Error updating profile: #{error.message or error}") if err
        res.end()


handleProfileUpdate = (data, user) ->
  groups = data['data[merges][INTERESTS]'].split(', ')
  groups = (map[g] for g in groups when map[g])
  user.set 'emailSubscriptions', groups
  
  mailChimpInfo = user.get 'mailChimp'
  mailChimpInfo.email = data['data[email]']
  user.set 'mailChimp', mailChimpInfo

  badLog("Updating user object to: #{JSON.stringify(user.toObject(), null, '\t')}")
    
handleUnsubscribe = (data, user) ->
  user.set 'emailSubscriptions', []

  badLog("Unsubscribing user object to: #{JSON.stringify(user.toObject(), null, '\t')}") 