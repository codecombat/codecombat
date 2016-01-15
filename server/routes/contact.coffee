config = require '../../server_config'
log = require 'winston'
User = require '../users/User'
sendwithus = require '../sendwithus'
async = require 'async'
LevelSession = require '../levels/sessions/LevelSession'
moment = require 'moment'
hipchat = require '../hipchat'

module.exports.setup = (app) ->
  app.post '/contact', (req, res) ->
    return res.end() unless req.user
    #log.info "Sending mail from #{req.body.email} saying #{req.body.message}"
    createMailContext req, (context) ->
      sendwithus.api.send context, (err, result) ->
        if err
          log.error "Error sending contact form email: #{err.message or err}"
    return res.end()

createMailContext = (req, done) ->
  sender = req.body.sender or req.body.email
  message = req.body.message
  user = req.user
  recipientID = req.body.recipientID
  subject = req.body.subject
  country = req.body.country
  sentFromLevel = levelID: req.body.levelID, courseID: req.body.courseID, courseInstanceID: req.body.courseInstanceID

  level = if user?.get('points') > 0 then Math.floor(5 * Math.log((1 / 100) * (user.get('points') + 100))) + 1 else 0
  premium = user?.isPremium()
  content = """
    #{message}

    --
    <a href='http://codecombat.com/user/#{user.get('slug') or user.get('_id')}'>#{user.get('name') or 'Anonymous'}</a> - Level #{level}#{if premium then ' - Subscriber' else ''}#{if country then ' - ' + country else ''}
  """
  if req.body.browser
    content += "\n#{req.body.browser} - #{req.body.screenSize}"

  context =
    email_id: sendwithus.templates.plain_text_email
    recipient:
      address: if premium then config.mail.supportPremium else config.mail.supportPrimary
    sender:
      address: config.mail.username
      reply_to: sender or user.get('email')
      name: user.get('name')
    email_data:
      subject: "[CodeCombat] #{subject ? ('Feedback - ' + (sender or user.get('email')))}"
      content: content
  if recipientID and (user.isAdmin() or ('employer' in (user.get('permissions') ? [])))
    User.findById(recipientID, 'email').exec (err, document) ->
      if err
        log.error "Error looking up recipient to email from #{recipientID}: #{err}" if err
      else
        context.recipient.bcc = [context.recipient.address, sender]
        context.recipient.address = document.get('email')
        context.email_data.content = message
      done context
  else
    async.waterfall [
      fetchRecentSessions.bind undefined, user, context, sentFromLevel
      # Can add other data-grabbing stuff here if we want.
    ], (err, results) ->
      console.error "Error getting contact message context for #{sender}: #{err}" if err
      if req.body.screenshotURL
        context.email_data.content += "\n<img src='#{req.body.screenshotURL}' />"
      done context

fetchRecentSessions = (user, context, sentFromLevel, callback) ->
  query = creator: user.get('_id') + ''
  projection = levelID: 1, levelName: 1, changed: 1, team: 1, codeLanguage: 1, 'state.complete': 1, playtime: 1
  sort = changed: -1
  LevelSession.find(query).select(projection).sort(sort).limit(3).lean().exec (err, sessions) ->
    return callback err if err
    for s in sessions
      if s.playtime < 120 then playtime = "#{s.playtime}s played"
      else if s.playtime < 7200 then playtime = "#{Math.round(s.playtime / 60)}m played"
      else playtime = "#{Math.round(s.playtime / 3600)}h played"
      ago = moment(s.changed).fromNow()
      url = "http://codecombat.com/play/level/#{s.levelID}?session=#{s._id}&team=#{s.team or 'humans'}&dev=true"
      urlName = "#{s.levelName}#{if s.team is 'ogres' then ' ' + s.team else ''}"
      sessionStatus = "#{if s.state?.complete then ' complete ' else ''}- #{s.codeLanguage}, #{playtime}, #{ago}"
      if sentFromLevel?.levelID is s.levelID and sentFromLevel?.courseID
        url += "&course=#{sentFromLevel.courseID}&course-instance=#{sentFromLevel.courseInstanceID}"
        urlName += ' (course)'
      context.email_data.content += "\n<a href='#{url}'>#{urlName}</a>#{sessionStatus}"
    callback null
