config = require '../../server_config'
log = require 'winston'
User = require '../users/User'
sendwithus = require '../sendwithus'

module.exports.setup = (app) ->
  app.post '/contact', (req, res) ->
    return res.end() unless req.user
    #log.info "Sending mail from #{req.body.email} saying #{req.body.message}"
    createMailContext req.body.email, req.body.message, req.user, req.body.recipientID, req.body.subject, (context) ->
      sendwithus.api.send context, (err, result) ->
        if err
          log.error "Error sending contact form email: #{err.message or err}"
    return res.end()

createMailContext = (sender, message, user, recipientID, subject, done) ->
  level = if user?.get('points') > 0 then Math.floor(5 * Math.log((1 / 100) * (xp + 100))) + 1 else 0
  premium = user?.isPremium()
  content = """
    #{message}

    #{user.get('name') or 'Anonymous'} - Level #{level}#{if premium then ' - Subscriber' else ''} - #{user._id}
  """

  context =
    email_id: sendwithus.templates.plain_text_email
    recipient:
      address: if premium then config.mail.supportPremium else config.mail.supportPrimary
    sender:
      address: config.mail.username
      reply_to: sender
      name: user.get('name')
    email_data:
      subject: "[CodeCombat] #{subject ? ('Feedback - ' + sender)}"
      content: content

  if recipientID and (user.isAdmin() or ('employer' in (user.get('permissions') ? [])))
    User.findById(recipientID, 'email').exec (err, document) ->
      if err
        log.error "Error looking up recipient to email from #{recipientID}: #{err}" if err
      else
        context.bcc = [context.to, sender]
        context.to = document.get('email')
      done context
  else
    done context
