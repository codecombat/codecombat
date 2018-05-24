sendgrid = require '../sendgrid'
utils = require '../lib/utils'
errors = require '../commons/errors'
wrap = require 'co-express'
database = require '../commons/database'
parse = require '../commons/parse'
config = require '../../server_config'

module.exports =
  sendParentSignupInstructions: wrap (req, res, next) ->
    message =
      templateId: sendgrid.templates.coppa_deny_parent_signup
      to:
        email: req.body.parentEmail
      from:
        email: config.mail.username
        name: 'CodeCombat'
    if /@codecombat.com/.test(message.to.email) or not _.str.trim message.to.email
      console.error "Somehow sent an email with bogus recipient? #{message.to.email}"
      return next(new errors.InternalServerError("Error sending email. Need a valid recipient."))
    try
      yield sendgrid.api.send message
      res.status(200).send()
    catch err
      console.log 'Tried to send:', message
      console.error err
      return next(new errors.InternalServerError("Error sending email. Check that it's valid and try again."))

  sendTeacherSignupInstructions: wrap (req, res, next) ->
    message =
      templateId: sendgrid.templates.teacher_signup_instructions
      to:
        email: req.body.teacherEmail
      from:
        email: config.mail.username
        name: 'CodeCombat'
      bcc: [{email: 'schools@codecombat.com'}]
      substitutions:
        student_name: req.body.studentName
    if /@codecombat.com/.test(message.to.email) or not _.str.trim message.to.email
      console.error "Somehow sent an email with bogus recipient? #{message.to.email}"
      return next(new errors.InternalServerError("Error sending email. Need a valid recipient."))
    try
      yield sendgrid.api.send message
      res.status(200).send()
    catch err
      console.error err
      return next(new errors.InternalServerError("Error sending email. Check that it's valid and try again."))

  sendTeacherGameDevProjectShare: wrap (req, res, next) ->
    message =
      templateId: sendgrid.templates.teacher_game_dev_project_share
      to:
        email: req.body.teacherEmail
      from:
        email: config.mail.username
        name: 'CodeCombat'
      bcc: [{email: 'schools@codecombat.com'}]
      substitutions:
        student_name: req.user.broadName() or 'who is very excited'
        code_language: req.body.codeLanguage
        level_link: "https://codecombat.com/play/game-dev-level/#{req.body.sessionId}"
        level_name: req.body.levelName
    if /@codecombat.com/.test(message.to.email) or not _.str.trim message.to.email
      console.error "Somehow sent an email with bogus recipient? #{message.to.email}"
      return next(new errors.InternalServerError("Error sending email. Need a valid recipient."))
    try
      yield sendgrid.api.send message
      res.status(200).send()
    catch err
      console.error err
      return next(new errors.InternalServerError("Error sending email. Check that it's valid and try again."))
