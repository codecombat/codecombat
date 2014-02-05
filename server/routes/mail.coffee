mail = require '../commons/mail'
map = _.invert mail.MAILCHIMP_GROUP_MAP
User = require '../users/User.coffee'
errors = require '../commons/errors'
#request = require 'request'
config = require '../../server_config'

#badLog = (text) ->
#  console.log text
#  request.post 'http://requestb.in/1brdpaz1', { form: {log: text} }
  
module.exports.setup = (app) ->
  app.all config.mail.mailchimpWebhook, (req, res) ->
    post = req.body
#    badLog("Got post data: #{JSON.stringify(post, null, '\t')}")
    
    unless post.type in ['unsubscribe', 'profile']
      res.send 'Bad post type'
      return res.end()

    unless post.data.email
      res.send 'No email provided'
      return res.end()

    query = {'mailChimp.leid':post.data.web_id}
    User.findOne query, (err, user) ->
      return errors.serverError(res) if err
      if not user
        return errors.notFound(res)

      handleProfileUpdate(user, post) if post.type is 'profile'
      handleUnsubscribe(user) if post.type is 'unsubscribe'

      user.updatedMailChimp = true # so as not to echo back to mailchimp
      user.save (err) ->
        return errors.serverError(res) if err
        res.end('Success')


handleProfileUpdate = (user, post) ->
  groups = post.data.merges.INTERESTS.split(', ')
  groups = (map[g] for g in groups when map[g])
  otherSubscriptions = (g for g in user.get('emailSubscriptions') when not mail.MAILCHIMP_GROUP_MAP[g])
  groups = groups.concat otherSubscriptions
  user.set 'emailSubscriptions', groups
  
  fname = post.data.merges.FNAME
  user.set('firstName', fname) if fname

  lname = post.data.merges.LNAME
  user.set('lastName', lname) if lname
  
  user.set 'mailChimp.email', post.data.email
  user.set 'mailChimp.euid', post.data.id
  
#  badLog("Updating user object to: #{JSON.stringify(user.toObject(), null, '\t')}")
    
handleUnsubscribe = (user) ->
  user.set 'emailSubscriptions', []

#  badLog("Unsubscribing user object to: #{JSON.stringify(user.toObject(), null, '\t')}") 