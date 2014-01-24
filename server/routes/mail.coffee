mail = require '../commons/mail'
map = _.invert mail.MAILCHIMP_GROUP_MAP
User = require '../users/User.coffee'
errors = require '../commons/errors'
request = require 'request'

badLog = (text) ->
  options.text = text
  request.post 'http://requestb.in/1brdpaz1', { form: {log: text} }
  
module.exports.setupRoutes = (app) ->
  app.all '/mail/webhook', (req, res) ->
    post = req.body
    unless post['data[email]'] is 'sderickson+test@gmail.com'
      badLog("Ignoring because no email: #{JSON.stringify(req.body, null, '\t')}")
      return res.end()
    return handleProfileUpdate(post, res) if post.type is 'profile'
    return handleUnsubscribe(post, res) if post.type is 'unsubscribe'
    console.log 'unrecognized...', post
    return res.end()
    
handleProfileUpdate: (data, res) ->
  User.findOne {'mailChimp.euid':data['data[id]']}, (err, user) ->
    return errors.serverError(res) if err
    
    groups = data['data[merges][INTERESTS]'].split(', ')
    groups = (map[g] for g in groups when map[g])
    user.set 'emailSubscriptions', groups
    
    mailChimpInfo = user.get 'mailChimp'
    mailChimpInfo.email = data['data[email]']
    user.set 'mailChimp', mailChimpInfo

    badLog("Updating user object to: #{JSON.stringify(user.toObject(), null, '\t')}")
    res.end()
    
    
handleUnsubscribe: (data) ->
  User.findOne {'mailChimp.euid':data['data[id]']}, (err, user) ->
    return errors.serverError(res) if err
    
    user.set 'emailSubscriptions', []
    user.set 'mailChimp', undefined

    badLog("Unsubscribing user object to: #{JSON.stringify(user.toObject(), null, '\t')}")
    res.end()