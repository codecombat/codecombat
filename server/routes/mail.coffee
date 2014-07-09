mail = require '../commons/mail'
MailTask = require '../mail/tasks/MailTask'
User = require '../users/User'
errors = require '../commons/errors'
config = require '../../server_config'
LevelSession = require '../levels/sessions/LevelSession'
Level = require '../levels/Level'
log = require 'winston'
sendwithus = require '../sendwithus'
if config.isProduction || true
  redis = require 'redis'
  redisClient = redis.createClient(config.redis.port,config.redis.host)

module.exports.setup = (app) ->
  app.all config.mail.mailchimpWebhook, handleMailchimpWebHook
  app.get '/mail/cron/ladder-update', handleLadderUpdate
  app.post '/mail/task', createMailTask

  #setInterval(handleScheduledMail, 5000)
  

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

createMailTask = (req, res) ->
  #unless req.user?.isAdmin() then return errors.forbidden(res)
  unless req.body.url and req.body.frequency then return errors.badInput(res)
  console.log "Creating mail task with url #{req.body.url} and frequency #{req.body.frequency}"
  newMailTask = new MailTask {}
  newMailTask.set("url",req.body.url)
  newMailTask.set("frequency",req.body.frequency)
  newMailTask.save (err) ->
    if err? then return errors.serverError(res, err)
    res.send("Created mail task!")
    res.end()
  
handleLadderUpdate = (req, res) ->
  log.info('Going to see about sending ladder update emails.')
  requestIsFromDesignatedCronHandler = isRequestFromDesignatedCronHandler req, res
  return unless requestIsFromDesignatedCronHandler or DEBUGGING

  res.send('Great work, Captain Cron! I can take it from here.')
  res.end()
  # TODO: somehow fetch the histograms
  emailDays = [1, 2, 4, 7, 14, 30]
  now = new Date()
  for daysAgo in emailDays
    # Get every session that was submitted in a 5-minute window after the time.
    startTime = getTimeFromDaysAgo now, daysAgo
    endTime = startTime + 5 * 60 * 1000
    if DEBUGGING
      endTime = startTime + 15 * 60 * 1000  # Debugging: make sure there's something to send
    findParameters = {submitted: true, submitDate: {$gt: new Date(startTime), $lte: new Date(endTime)}}
    # TODO: think about putting screenshots in the email
    selectString = 'creator team levelName levelID totalScore matches submitted submitDate scoreHistory'
    query = LevelSession.find(findParameters)
      .select(selectString)
      .lean()
    do (daysAgo) ->
      query.exec (err, results) ->
        if err
          log.error "Couldn't fetch ladder updates for #{findParameters}\nError: #{err}"
          return errors.serverError res, "Ladder update email query failed: #{JSON.stringify(err)}"
        log.info "Found #{results.length} ladder sessions to email updates about for #{daysAgo} day(s) ago."
        sendLadderUpdateEmail result, now, daysAgo for result in results

sendLadderUpdateEmail = (session, now, daysAgo) ->
  User.findOne({_id: session.creator}).select('name email firstName lastName emailSubscriptions emails preferredLanguage').exec (err, user) ->
    if err
      log.error "Couldn't find user for #{session.creator} from session #{session._id}"
      return
    allowNotes = user.isEmailSubscriptionEnabled 'anyNotes'
    unless user.get('email') and allowNotes and not session.unsubscribed
      log.info "Not sending email to #{user.get('email')} #{user.get('name')} because they only want emails about #{user.get('emailSubscriptions')}, #{user.get('emails')} - session unsubscribed: #{session.unsubscribed}"
      return
    unless session.levelName
      log.info "Not sending email to #{user.get('email')} #{user.get('name')} because the session had no levelName in it."
      return
    name = if user.get('firstName') and user.get('lastName') then "#{user.get('firstName')}" else user.get('name')
    name = 'Wizard' if not name or name is 'Anoner'

    # Fetch the most recent defeat and victory, if there are any.
    # (We could look at strongest/weakest, but we'd have to fetch everyone, or denormalize more.)
    matches = _.filter session.matches, (match) -> match.date >= getTimeFromDaysAgo now, daysAgo
    defeats = _.filter matches, (match) -> match.metrics.rank is 1 and match.opponents[0].metrics.rank is 0
    victories = _.filter matches, (match) -> match.metrics.rank is 0 and match.opponents[0].metrics.rank is 1

    defeat = _.last defeats
    victory = _.last victories

    sendEmail = (defeatContext, victoryContext) ->
      # TODO: do something with the preferredLanguage?
      context =
        email_id: sendwithus.templates.ladder_update_email
        recipient:
          address: if DEBUGGING then 'nick@codecombat.com' else user.get('email')
          name: name
        email_data:
          name: name
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
      log.info "Sending ladder update email to #{context.recipient.address} with #{context.email_data.wins} wins and #{context.email_data.losses} losses since #{daysAgo} day(s) ago."
      sendwithus.api.send context, (err, result) ->
        log.error "Error sending ladder update email: #{err} with result #{result}" if err

    urlForMatch = (match) ->
      "http://codecombat.com/play/level/#{session.levelID}?team=#{session.team}&session=#{session._id}&opponent=#{match.opponents[0].sessionID}"

    onFetchedDefeatedOpponent = (err, defeatedOpponent) ->
      if err
        log.error "Couldn't find defeateded opponent: #{err}"
        defeatedOpponent = null
      victoryContext = {opponent_name: defeatedOpponent?.name ? 'Anoner', url: urlForMatch(victory)} if victory

      onFetchedVictoriousOpponent = (err, victoriousOpponent) ->
        if err
          log.error "Couldn't find victorious opponent: #{err}"
          victoriousOpponent = null
        defeatContext = {opponent_name: victoriousOpponent?.name ? 'Anoner', url: urlForMatch(defeat)} if defeat
        sendEmail defeatContext, victoryContext

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

handleMailchimpWebHook = (req, res) ->
  post = req.body

  unless post.type in ['unsubscribe', 'profile']
    res.send 'Bad post type'
    return res.end()

  unless post.data.email
    res.send 'No email provided'
    return res.end()

  query = {'mailChimp.leid': post.data.web_id}
  User.findOne query, (err, user) ->
    return errors.serverError(res) if err
    if not user
      return errors.notFound(res)

    handleProfileUpdate(user, post) if post.type is 'profile'
    handleUnsubscribe(user) if post.type is 'unsubscribe'

    user.updatedMailChimp = true # so as not to echo back to mailchimp
    user.save (err) ->
      return errors.serverError(res) if err
      res.end('Success')

module.exports.handleProfileUpdate = handleProfileUpdate = (user, post) ->
  mailchimpSubs = post.data.merges.INTERESTS.split(', ')

  for [mailchimpEmailGroup, emailGroup] in _.zip(mail.MAILCHIMP_GROUPS, mail.NEWS_GROUPS)
    user.setEmailSubscription emailGroup, mailchimpEmailGroup in mailchimpSubs

  fname = post.data.merges.FNAME
  user.set('firstName', fname) if fname

  lname = post.data.merges.LNAME
  user.set('lastName', lname) if lname

  user.set 'mailChimp.email', post.data.email
  user.set 'mailChimp.euid', post.data.id


module.exports.handleUnsubscribe = handleUnsubscribe = (user) ->
  user.set 'emailSubscriptions', []
  for emailGroup in mail.NEWS_GROUPS
    user.setEmailSubscription emailGroup, false
