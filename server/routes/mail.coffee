mailChimp = require '../lib/mail-chimp'
User = require '../models/User'
errors = require '../commons/errors'
config = require '../../server_config'
LevelSession = require '../models/LevelSession'
Level = require '../models/Level'
log = require 'winston'
sendgrid = require '../sendgrid'
wrap = require 'co-express'
unsubscribe = require '../commons/unsubscribe'
co = require 'co'

module.exports.setup = (app) ->
  app.all config.mail.mailChimpWebhook, handleMailChimpWebHook
  app.get '/mail/cron/ladder-update', handleLadderUpdate
  app.get '/mail/cron/next-steps', handleNextSteps

DEBUGGING = false
LADDER_PREGAME_INTERVAL = 2 * 3600 * 1000  # Send emails two hours before players last submitted.
getTimeFromDaysAgo = (now, daysAgo) ->
  t = now - 86400 * 1000 * daysAgo - LADDER_PREGAME_INTERVAL

isRequestFromDesignatedCronHandler = (req, res) ->
  requestIP = req.headers['x-forwarded-for']?.replace(' ', '').split(',')[0]
  if requestIP isnt config.mail.cronHandlerPublicIP and requestIP isnt config.mail.cronHandlerPrivateIP
    console.log "RECEIVED REQUEST FROM IP #{requestIP}(headers indicate #{req.headers['x-forwarded-for']}"
    console.log 'UNAUTHORIZED ATTEMPT TO SEND TRANSACTIONAL LADDER EMAIL THROUGH CRON MAIL HANDLER'
    res.send('You aren\'t authorized to perform that action. Only the specified Cron handler may perform that action.')
    res.end()
    return false
  return true

### Ladder Update Email ###

handleLadderUpdate = (req, res) ->
  return unless DEBUGGING or isRequestFromDesignatedCronHandler req, res
  res.send('Great work, Captain Cron! I can take it from here.')
  res.end()
  # TODO: Sendgrid cannot do the kind of logical conditions and collection iteration that Sendwithus could, so we need to do the template in our code. For now, these emails are disabled.
  return

  # TODO: somehow fetch the histograms
  #emailDays = [1, 2, 4, 7, 14, 30]
  emailDays = [1, 3, 7]  # Reduced to keep smaller monthly recipient footprint
  now = new Date()
  for daysAgo in emailDays
    # Get every session that was submitted in a 5-minute window after the time.
    startTime = getTimeFromDaysAgo now, daysAgo
    endTime = startTime + 5 * 60 * 1000
    if DEBUGGING
      endTime = startTime + 15 * 60 * 1000  # Debugging: make sure there's something to send
    findParameters = {submitted: true, submitDate: {$gt: new Date(startTime), $lte: new Date(endTime)}}
    # TODO: think about putting screenshots in the email
    selectString = 'creator team levelName levelID totalScore matches submitted submitDate scoreHistory level.original unsubscribed'
    query = LevelSession.find(findParameters)
      .select(selectString)
      .lean()
    do (daysAgo) ->
      query.exec (err, results) ->
        if err
          log.error "Couldn't fetch ladder updates for #{findParameters}\nError: #{err}"
          return errors.serverError res, "Ladder update email query failed: #{JSON.stringify(err)}"
        #log.info "Found #{results.length} ladder sessions to email updates about for #{daysAgo} day(s) ago."
        sendLadderUpdateEmail result, now, daysAgo for result in results

sendLadderUpdateEmail = (session, now, daysAgo) ->
  User.findOne({_id: session.creator}).select('name email firstName lastName emailSubscriptions emails preferredLanguage').exec (err, user) ->
    return if not user.get('email')
    if err
      log.error "Couldn't find user for #{session.creator} from session #{session._id}"
      return
    allowNotes = user.isEmailSubscriptionEnabled 'anyNotes'
    unless user.get('email') and allowNotes and not session.unsubscribed
      #log.info "Not sending email to #{user.get('email')} #{user.get('name')} because they only want emails about #{user.get('emailSubscriptions')}, #{user.get('emails')} - session unsubscribed: #{session.unsubscribed}"
      return
    unless session.levelName and session.team
      #log.info "Not sending email to #{user.get('email')} #{user.get('name')} because the session had levelName #{session.levelName} or team #{session.team} in it."
      return
    name = if user.get('firstName') and user.get('lastName') then "#{user.get('firstName')}" else user.get('name')
    name = 'Wizard' if not name or name is 'Anonymous'

    # Fetch the most recent defeat and victory, if there are any.
    # (We could look at strongest/weakest, but we'd have to fetch everyone, or denormalize more.)
    matches = _.filter session.matches, (match) -> match.date >= getTimeFromDaysAgo now, daysAgo
    defeats = _.filter matches, (match) -> match.metrics.rank is 1 and match.opponents[0].metrics.rank is 0
    victories = _.filter matches, (match) -> match.metrics.rank is 0 and match.opponents[0].metrics.rank is 1

    defeat = _.last defeats
    victory = _.last victories

    sendEmail = co.wrap (defeatContext, victoryContext, levelVersionsContext) ->
      message =
        templateId: sendgrid.templates.ladder_update_email
        to:
          email: if DEBUGGING then 'nick@codecombat.com' else user.get('email')
          name: name
        from:
          email: config.mail.username
          name: 'CodeCombat'
        subject: "Your #{session.levelName} #{session.team[0].toUpperCase() + session.team.substr(1)} Scores"
        substitutions:
          username: name
          days_ago: daysAgo
          wins: victories.length
          losses: defeats.length
          total_score: Math.round(session.totalScore * 100)
          team: session.team
          team_name: session.team[0].toUpperCase() + session.team.substr(1)
          level_name: session.levelName
          session_id: session._id
          ladder_url: "http://codecombat.com/play/ladder/#{session.levelID}#my-matches"
          score_history_graph_url: getScoreHistoryGraphURL session, daysAgo
          defeat: defeatContext
          victory: victoryContext
          levelVersions: levelVersionsContext
      #log.info "Sending ladder update email to #{message.to.email} with #{message.substitutions.wins} wins and #{message.substitutions.losses} losses since #{daysAgo} day(s) ago."
      try
        yield sendgrid.api.send message
      catch err
        console.error "Error sending ladder update email:", err

    urlForMatch = (match) ->
      "http://codecombat.com/play/level/#{session.levelID}?team=#{session.team}&opponent=#{match.opponents[0].sessionID}"

    onFetchedDefeatedOpponent = (err, defeatedOpponent) ->
      if err
        log.error "Couldn't find defeateded opponent: #{err}"
        defeatedOpponent = null
      victoryContext = {opponent_name: defeatedOpponent?.name ? 'Anonymous', url: urlForMatch(victory)} if victory

      onFetchedVictoriousOpponent = (err, victoriousOpponent) ->
        if err
          log.error "Couldn't find victorious opponent: #{err}"
          victoriousOpponent = null
        defeatContext = {opponent_name: victoriousOpponent?.name ? 'Anonymous', url: urlForMatch(defeat)} if defeat

        Level.find({original: session.level.original, created: {$gt: session.submitDate}}).select('created commitMessage version').sort('-created').lean().exec (err, levelVersions) ->
          sendEmail defeatContext, victoryContext, (if levelVersions.length then levelVersions else null)

      if defeat
        User.findOne({_id: defeat.opponents[0].userID}).select('name').lean().exec onFetchedVictoriousOpponent
      else
        onFetchedVictoriousOpponent null, null

    if victory
      User.findOne({_id: victory.opponents[0].userID}).select('name').lean().exec onFetchedDefeatedOpponent
    else
      onFetchedDefeatedOpponent null, null

getScoreHistoryGraphURL = (session, daysAgo) ->
  # Totally duplicated in My Matches tab for now until we figure out what we're doing.
  since = new Date() - 86400 * 1000 * daysAgo
  scoreHistory = (s for s in session.scoreHistory ? [] when s[0] >= since)
  return '' unless scoreHistory.length > 1
  scoreHistory = _.last scoreHistory, 100  # Chart URL needs to be under 2048 characters for GET
  times = (s[0] for s in scoreHistory)
  times = ((100 * (t - times[0]) / (times[times.length - 1] - times[0])).toFixed(1) for t in times)
  scores = (s[1] for s in scoreHistory)
  lowest = _.min scores  #.concat([0])
  highest = _.max scores  #.concat(50)
  scores = (Math.round(100 * (s - lowest) / (highest - lowest)) for s in scores)
  currentScore = Math.round scoreHistory[scoreHistory.length - 1][1] * 100
  minScore = Math.round(100 * lowest)
  maxScore = Math.round(100 * highest)
  chartData = times.join(',') + '|' + scores.join(',')
  "https://chart.googleapis.com/chart?chs=600x75&cht=lxy&chtt=Score%3A+#{currentScore}&chts=222222,12,r&chf=a,s,000000FF&chls=2&chd=t:#{chartData}&chxt=y&chxr=0,#{minScore},#{maxScore}"

### End Ladder Update Email ###

### Next Steps Email ###

handleNextSteps = (req, res) ->
  return unless DEBUGGING or isRequestFromDesignatedCronHandler req, res
  res.send('Great work, Captain Cron! I can take it from here.')
  res.end()
  emailDays = [1]
  now = new Date()
  for daysAgo in emailDays
    # Get every User that was created in a 5-minute window after the time.
    startTime = getTimeFromDaysAgo now, daysAgo
    endTime = startTime + 5 * 60 * 1000
    findParameters = {dateCreated: {$gt: new Date(startTime), $lte: new Date(endTime)}, emailLower: {$exists: true}}
    selectString = 'name firstName lastName lastLevel points email gender emailSubscriptions emails dateCreated preferredLanguage aceConfig.language activity stats earned testGroupNumber ageRange courseInstances'
    query = User.find(findParameters).select(selectString)
    do (daysAgo) ->
      query.exec (err, results) ->
        if err
          log.error "Couldn't fetch next steps users for #{findParameters}\nError: #{err}"
          return errors.serverError res, "Next steps email query failed: #{JSON.stringify(err)}"
        log.info "Found #{results.length} next-steps users to email updates about for #{daysAgo} day(s) ago." if DEBUGGING
        sendNextStepsEmail result, now, daysAgo for result in results

module.exports.sendNextStepsEmail = sendNextStepsEmail = (user, now, daysAgo) ->
  return log.info "Not sending next steps email to user with no email address" if not user.get('email')
  return log.debug "Not sending next steps email to teacher based on role" if user.isTeacher()
  unless user.isEmailSubscriptionEnabled('generalNews') and user.isEmailSubscriptionEnabled('anyNotes')
    log.info "Not sending email to #{user.get('email')} #{user.get('name')} because they only want emails about #{JSON.stringify(user.get('emails'))}" if DEBUGGING
    return

  LevelSession.find({creator: user.get('_id') + ''}).select('levelName levelID changed state.complete playtime').lean().exec (err, sessions) ->
    return log.error "Couldn't find sessions for #{user.get('email')} #{user.get('name')}: #{err}" if err
    complete = (s for s in sessions when s.state?.complete)
    incomplete = (s for s in sessions when not s.state?.complete)
    return if complete.length < 2

    # TODO: find the next level to do somehow, for real
    if incomplete.length
      nextLevel = name: incomplete[0].levelName, slug: incomplete[0].levelID
    else
      nextLevel = null
    err = null
    do co.wrap (err, nextLevel) ->
      return log.error "Couldn't find next level for #{user.get('email')} #{user.get('name')}: #{err}" if err
      name = if user.get('firstName') and user.get('lastName') then "#{user.get('firstName')}" else user.get('name')
      name = 'Hero' if not name or name in ['Anoner', 'Anonymous']
      #secretLevel = switch user.get('testGroupNumber') % 8
      #  when 0, 1, 2, 3 then name: 'Forgetful Gemsmith', slug: 'forgetful-gemsmith'
      #  when 4, 5, 6, 7 then name: 'Signs and Portents', slug: 'signs-and-portents'
      secretLevel = name: 'Signs and Portents', slug: 'signs-and-portents'  # We turned off this test for now and are sending everyone to forgetful-gemsmith

      # TODO: make this smarter, actually data-driven, looking at all available sessions
      shadowGuardSession = _.find sessions, levelID: 'shadow-guard'
      isFast = shadowGuardSession and shadowGuardSession.playtime < 90  # Average is 107s
      isVeryFast = shadowGuardSession and shadowGuardSession.playtime < 75
      isAdult = user.get('ageRange') in ['18-24', '25-34', '35-44', '45-100']
      isKid = not isAdult  # Assume kid if not specified
      # Used to use these categories to customize the email; not doing it right now. TODO: customize it again in Sendgrid.
      # TODO: do something with the preferredLanguage?

      message =
        templateId: sendgrid.templates.next_steps_email
        to:
          email: if DEBUGGING then 'nick@codecombat.com' else user.get('email')
          name: name
        from:
          email: config.mail.username
          name: 'CodeCombat'
        substitutions:
          username: name
          days_ago: daysAgo
          nextLevelName: nextLevel?.name
          nextLevelLink: if nextLevel then "http://codecombat.com/play/level/#{nextLevel.slug}" else null
          secretLevelName: secretLevel.name
          secretLevelLink: "http://codecombat.com/play/level/#{secretLevel.slug}"
          levelsComplete: complete.length
          isCoursePlayer: user.get('role') is 'student'
      # I hate Sendgrid variable interpolation; it works so inconsistently. Hack around it for now.
      message.substitutions.nextLevelTemplate = """
        <p>Hail, #{message.substitutions.username}!</p>
        <p>You've done #{message.substitutions.levelsComplete} levels; now what?</p>
        <ul>
          #{if message.substitutions.nextLevelLink then '<li>Play the next level: <strong><a href="{{ message.substitutions.nextLevelLink }}">{{ message.substitutions.nextLevelName }}</a></strong></li' else ''}
          <li>Play this <em>secret</em> level: <strong><a href="#{message.substitutions.secretLevelLink}">#{message.substitutions.secretLevelName}</a></strong></li>
          <li><strong><a href="http://codecombat.com/#{if message.substitutions.isCoursePlayer then 'students">Choose a level</a></strong> to play next</li>' else 'play">Choose a level</a></strong> from one of the five worlds</li>'}
        </ul>
        """

      log.info "Sending next steps email to #{message.to.email} with #{message.substitutions.nextLevelName} next and #{message.substitutions.levelsComplete} levels complete since #{daysAgo} day(s) ago." if DEBUGGING
      try
        yield sendgrid.api.send message
      catch err
        console.error "Error sending next steps email:", err

### End Next Steps Email ###

handleMailChimpWebHook = wrap (req, res) ->
  post = req.body

  unless post.type in ['unsubscribe', 'profile', 'upemail']
    res.send 'Bad post type'
    return res.end()

  email = post.data.email or post.data.old_email
  unless email
    res.send 'No email provided'
    return res.end()

  if post.data.web_id
    user = yield User.findOne { 'mailChimp.leid': post.data.web_id }
  if not user
    user = yield User.findOne { 'mailChimp.email': email }

  if not user
    throw new errors.NotFound('MailChimp subscriber not found')

  if not user.get('emailVerified')
    return res.send('User email unverified')

  if post.type is 'profile'
    handleProfileUpdate(user, post)
  else if post.type is 'upemail'
    handleUnsubscribe(user) # just unsubscribe from MailChimp
  else if post.type is 'unsubscribe'
    yield unsubscribe.unsubscribeEmailFromMarketingEmails(user.get('emailLower')) # unsubscribe all emails

  user.updatedMailChimp = true # so as not to echo back to mailchimp
  yield user.save()
  res.end('Success')

module.exports.handleProfileUpdate = handleProfileUpdate = (user, post) ->
  mailChimpSubs = post.data.merges.INTERESTS.split(', ')

  for interest in mailChimp.interests
    user.setEmailSubscription interest.property, interest.mailChimpLabel in mailChimpSubs

  fname = post.data.merges.FNAME
  user.set('firstName', fname) if fname

  lname = post.data.merges.LNAME
  user.set('lastName', lname) if lname

  user.set 'mailChimp.email', post.data.email
  user.set 'mailChimp.euid', post.data.id


module.exports.handleUnsubscribe = handleUnsubscribe = (user) ->
  user.set 'emailSubscriptions', []
  for interest in mailChimp.interests
    user.setEmailSubscription interest.property, false
  user.set 'mailChimp', undefined
