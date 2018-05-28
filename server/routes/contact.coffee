config = require '../../server_config'
log = require 'winston'
User = require '../models/User'
sendgrid = require '../sendgrid'
async = require 'async'
moment = require 'moment'
LevelSession = require '../models/LevelSession'
Product = require '../models/Product'
closeIO = require '../lib/closeIO'
co = require 'co'

module.exports.setup = (app) ->
  app.post '/contact', (req, res) ->
    return res.end() unless req.user
    # log.info "Sending mail from #{req.body.email} saying #{req.body.message}"
    fromAddress = req.body.sender or req.body.email or req.user.get('email')
    createMailContent req, fromAddress, (subject, content) ->
      if (req.body.licensesNeeded or req.user.isTeacher()) and subject.indexOf('Level Load Error:') < 0
        closeIO.getSalesContactEmail fromAddress, (err, salesContactEmail, userID, leadID) ->
          if not leadID
            log.debug "No close.io lead found for #{fromAddress}; sending license request via sendgrid"
            createSendGridLicenseRequestMessage req, fromAddress, salesContactEmail, subject, content, co.wrap (err, message) ->
              try
                yield sendgrid.api.send message
              catch err
                console.error "Error sending license request form email via sendgrid:", err, message
              req.user.update({$set: { enrollmentRequestSent: true }}).exec(_.noop)
            return res.end()
          return console.error("Error getting sales contact for #{fromAddress}:", err) if err
          closeIO.sendMail fromAddress, subject, content, salesContactEmail, leadID, (err) ->
            return console.error("Error sending contact form email via Close.io:", err) if err
            if licensesNeeded = req.body.licensesNeeded
              Product.findOne({name: 'course'}).exec (err, product) =>
                return log.error(err) if err
                return log.error('course product not found') if not product
                amount = product.get('amount')
                closeIO.processLicenseRequest fromAddress, userID, leadID, licensesNeeded, amount, (err) ->
                  return console.error("Error processing license request via Close.io:", err) if err
                  req.user.update({$set: { enrollmentRequestSent: true }}).exec(_.noop)
      else
        createMailMessage req, fromAddress, subject, content, co.wrap (message) ->
          try
            yield sendgrid.api.send message
          catch err
            console.error "Error sending contact form email via sendgrid", err, message
    return res.end()

createMailContent = (req, fromAddress, done) ->
  country = req.body.country
  licensesNeeded = req.body.licensesNeeded
  message = req.body.message
  user = req.user
  subject = switch
    when licensesNeeded then "#{licensesNeeded} Licenses needed for #{fromAddress}"
    when req.body.subject then req.body.subject
    else "Contact Us Form: #{fromAddress}"
  level = if user?.get('points') > 0 then Math.floor(5 * Math.log((1 / 100) * (user.get('points') + 100))) + 1 else 0
  premium = user?.isPremium()
  teacher = user?.isTeacher()
  content = """
    #{message}

    --
    http://codecombat.com/user/#{user.get('slug') or user.get('_id')}
    #{fromAddress} - #{user.get('name') or 'Anonymous'} - Level #{level}#{if teacher then ' - Teacher' else ''}#{if premium then ' - Subscriber' else ''}#{if country then ' - ' + country else ''}
  """ # TODO: Dynamically generate URL with server/commons/urls.makeHostUrl
  if req.body.browser
    content += "\n#{req.body.browser} - #{req.body.screenSize}"
  done(subject, content)

createSendGridLicenseRequestMessage = (req, fromAddress, salesContactEmail, subject, content, done) ->
  user = req.user
  message =
    templateId: sendgrid.templates.plain_text_email
    to:
      email: salesContactEmail
    from:
      email: config.mail.username
      name: user.get('name')
    reply_to:
      email: fromAddress
    subject: subject
    content: [
      {type: 'text/plain', value: content}
      {type: 'text/html', value: content.replace /\n/g, '\n<br>'}
    ]
  return done(null, message)

createMailMessage = (req, fromAddress, subject, content, done) ->
  user = req.user
  sentFromLevel = levelID: req.body.levelID, courseID: req.body.courseID, courseInstanceID: req.body.courseInstanceID
  premium = user?.isPremium()
  teacher = user?.isTeacher()

  if teacher or req.body.licensesNeeded
    return done("Tried to send a teacher contact us email via sendgrid #{fromAddress} #{subject}")

  toAddress = switch
    when premium then config.mail.supportPremium
    else config.mail.supportPrimary

  message =
    templateId: sendgrid.templates.plain_text_email
    to:
      email: toAddress
    from:
      email: config.mail.username
      name: user.get('name')
    reply_to:
      email: fromAddress
    subject: subject
    content: [
      {type: 'text/plain', value: content}
      {type: 'text/html', value: content.replace /\n/g, '\n<br>'}
    ]
  async.waterfall [
    fetchRecentSessions.bind undefined, user, message, sentFromLevel
    # Can add other data-grabbing stuff here if we want.
  ], (err, results) ->
    console.error "Error getting contact message context for #{fromAddress}: #{err}" if err
    if req.body.screenshotURL
      _.find(message.content, {type: 'text/html'}).value += "\n<br><img src='#{req.body.screenshotURL}' />"
    done message

fetchRecentSessions = (user, message, sentFromLevel, callback) ->
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
      # TODO: Dynamically generate URL with server/commons/urls.makeHostUrl
      url = "http://codecombat.com/play/level/#{s.levelID}?session=#{s._id}&team=#{s.team or 'humans'}&dev=true"
      urlName = "#{s.levelName}#{if s.team is 'ogres' then ' ' + s.team else ''}"
      sessionStatus = "#{if s.state?.complete then ' complete ' else ''}- #{s.codeLanguage}, #{playtime}, #{ago}"
      if sentFromLevel?.levelID is s.levelID and sentFromLevel?.courseID
        url += "&course=#{sentFromLevel.courseID}&course-instance=#{sentFromLevel.courseInstanceID}"
        urlName += ' (course)'
      _.find(message.content, {type: 'text/html'}).value += "\n<br><a href='#{url}'>#{urlName}</a>#{sessionStatus}"
    callback null
