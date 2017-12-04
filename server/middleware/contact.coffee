sendwithus = require '../sendwithus'
utils = require '../lib/utils'
errors = require '../commons/errors'
wrap = require 'co-express'
database = require '../commons/database'
parse = require '../commons/parse'

module.exports =
  sendParentSignupInstructions: wrap (req, res, next) ->
    context =
      email_id: sendwithus.templates.coppa_deny_parent_signup
      recipient:
        address: req.body.parentEmail
    if /@codecombat.com/.test(context.recipient.address) or not _.str.trim context.recipient.address
      console.error "Somehow sent an email with bogus recipient? #{context.recipient.address}"
      return next(new errors.InternalServerError("Error sending email. Need a valid recipient."))
    sendwithus.api.send context, (err, result) ->
      if err
        return next(new errors.InternalServerError("Error sending email. Check that it's valid and try again."))
      else
        res.status(200).send()

  sendTeacherSignupInstructions: wrap (req, res, next) ->
    context =
      email_id: sendwithus.templates.teacher_signup_instructions
      recipient:
        address: req.body.teacherEmail
      bcc: [{address: 'schools@codecombat.com'}]
      template_data:
        student_name: req.body.studentName
    if /@codecombat.com/.test(context.recipient.address) or not _.str.trim context.recipient.address
      console.error "Somehow sent an email with bogus recipient? #{context.recipient.address}"
      return next(new errors.InternalServerError("Error sending email. Need a valid recipient."))
    sendwithus.api.send context, (err, result) ->
      if err
        return next(new errors.InternalServerError("Error sending email. Check that it's valid and try again."))
      else
        res.status(200).send()

  sendTeacherGameDevProjectShare: wrap (req, res, next) ->
    context =
      email_id: sendwithus.templates.teacher_game_dev_project_share
      recipient:
        address: req.body.teacherEmail
      bcc: [{address: 'schools@codecombat.com'}]
      template_data:
        student_name: req.user.broadName()
        code_language: req.body.codeLanguage
        level_link: "https://codecombat.com/play/game-dev-level/#{req.body.sessionId}"
        level_name: req.body.levelName
    if /@codecombat.com/.test(context.recipient.address) or not _.str.trim context.recipient.address
      console.error "Somehow sent an email with bogus recipient? #{context.recipient.address}"
      return next(new errors.InternalServerError("Error sending email. Need a valid recipient."))
    sendwithus.api.send context, (err, result) ->
      if err
        return next(new errors.InternalServerError("Error sending email. Check that it's valid and try again."))
      else
        res.status(200).send()
