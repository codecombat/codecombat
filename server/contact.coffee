config = require '../server_config'
winston = require 'winston'
nodemailer = require 'nodemailer'

module.exports.setupRoutes = (app) ->
  app.post '/contact', (req, res) ->
    winston.info "Sending mail from #{req.body.email} saying #{req.body.message}"
    if config.isProduction or true
      transport = createSMTPTransport()
      options = createMailOptions req.body.email, req.body.message, req.user
      transport.sendMail options, (error, response) ->
        if error
          winston.error "Error sending mail: #{error.message or error}"
        else
          winston.info "Mail sent successfully. Response: #{response.message}"
    return res.end()

createMailOptions = (sender, message, user) ->
  # TODO: use email templates here
  console.log 'text is now', "#{message}\n\n#{user.get('name')}\nID: #{user._id}"
  options =
    from: config.mail.username
    to: config.mail.username
    replyTo: sender
    subject: "[CodeCombat] Feedback - #{sender}"
    text: "#{message}\n\nUsername: #{user.get('name') or 'Anonymous'}\nID: #{user._id}"
    #html: message.replace '\n', '<br>\n'

smtpTransport = null
createSMTPTransport = ->
  return smtpTransport if smtpTransport
  smtpTransport = nodemailer.createTransport "SMTP",
      service: config.mail.service
      user: config.mail.username
      pass: config.mail.password
      authMethod: "LOGIN"
  smtpTransport