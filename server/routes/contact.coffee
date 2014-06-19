config = require '../../server_config'
log = require 'winston'
mail = require '../commons/mail'
User = require '../users/User'

module.exports.setup = (app) ->
  app.post '/contact', (req, res) ->
    return res.end() unless req.user
    log.info "Sending mail from #{req.body.email} saying #{req.body.message}"
    if config.isProduction
      createMailOptions req.body.email, req.body.message, req.user, req.body.recipientID, req.body.subject, (options) ->
        mail.transport.sendMail options, (error, response) ->
          if error
            log.error "Error sending mail: #{error.message or error}"
          else
            log.info "Mail sent successfully. Response: #{response.message}"
    return res.end()

createMailOptions = (sender, message, user, recipientID, subject, done) ->
  # TODO: use email templates here
  options =
    from: config.mail.username
    to: config.mail.username
    replyTo: sender
    subject: "[CodeCombat] #{subject ? ('Feedback - ' + sender)}"
    text: "#{message}\n\nUsername: #{user.get('name') or 'Anonymous'}\nID: #{user._id}"
    #html: message.replace '\n', '<br>\n'

  if recipientID and (user.isAdmin() or ('employer' in (user.get('permissions') ? [])))
    User.findById(recipientID, 'email').exec (err, document) ->
      if err
        log.error "Error looking up recipient to email from #{recipientID}: #{err}" if err
      else
        options.bcc = options.to
        options.to = document.get('email')
      done options
  else
    done options
