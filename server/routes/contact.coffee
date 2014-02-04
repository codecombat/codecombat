config = require '../../server_config'
log = require 'winston'
mail = require '../commons/mail'

module.exports.setup = (app) ->
  app.post '/contact', (req, res) ->
    log.info "Sending mail from #{req.body.email} saying #{req.body.message}"
    if config.isProduction
      options = createMailOptions req.body.email, req.body.message, req.user
      mail.transport.sendMail options, (error, response) ->
        if error
          log.error "Error sending mail: #{error.message or error}"
        else
          log.info "Mail sent successfully. Response: #{response.message}"
    return res.end()

createMailOptions = (sender, message, user) ->
  # TODO: use email templates here
  options =
    from: config.mail.username
    to: config.mail.username
    replyTo: sender
    subject: "[CodeCombat] Feedback - #{sender}"
    text: "#{message}\n\nUsername: #{user.get('name') or 'Anonymous'}\nID: #{user._id}"
    #html: message.replace '\n', '<br>\n' 