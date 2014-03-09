mail = require '../commons/mail'
map = _.invert mail.MAILCHIMP_GROUP_MAP
User = require '../users/User.coffee'
errors = require '../commons/errors'
#request = require 'request'
config = require '../../server_config'
LevelSession = require '../levels/sessions/LevelSession.coffee'
log = require 'winston'
sendwithus = require '../sendwithus'

#badLog = (text) ->
#  console.log text
#  request.post 'http://requestb.in/1brdpaz1', { form: {log: text} }

module.exports.setup = (app) ->
  app.all config.mail.mailchimpWebhook, handleMailchimpWebHook
  app.get '/mail/cron/ladder-update', handleLadderUpdate

handleLadderUpdate = (req, res) ->
  emailDays = [1, 2, 4, 7, 30]
  now = new Date()
  getTimeFromDaysAgo = (daysAgo) ->
    # 2 hours before the date
    t = now - (86400 * daysAgo + 2 * 3600) * 1000
  for daysAgo in emailDays
    startTime = getTimeFromDaysAgo daysAgo
    endTime = startTime + 5 * 60 * 1000
    # Get every session that was submitted in a 5-minute window after the time.
    findParameters = {submitted: true, submitDate: {$gt: startTime, $lte: endTime}}
    # TODO: think about putting screenshots in the email
    selectString = "creator team levelID totalScore matches"
    query = LevelSession.find(findParameters)
      .select(selectString)
      .lean()
    mongoose = require 'mongoose'
    mongoose.set 'debug', true
    query.exec (err, results) ->
      log.info "Yooooo got results: #{results.length}"
      if err
        log.error "Couldn't fetch ladder updates for", findParameters, "\nError: ", err
        return errors.serverError res, "Ladder update email query failed: #{JSON.stringify(err)}"
      sendLadderUpdateEmail result, daysAgo for result in results
      res.send('')
      res.end()

sendLadderUpdateEmail = (session, daysAgo) ->
  User.findOne({_id: session.creator}).select("name email firstName lastName emailSubscriptions preferredLanguage").lean().exec (err, user) ->
    if err
      log.error "Couldn't find user for", session.creator, "from session", session._id
      return
    return unless user.email and 'notification' in user.emailSubscriptions
    name = if user.firstName and user.lastName then "#{user.firstName} #{user.lastName}" else user.name
    name = "Wizard" if not name or name is "Anoner"

    sendEmail = (defeatContext, victoryContext) ->
      # TODO: do something with the preferredLanguage?
      context =
        email_id: sendwithus.templates.ladder_update_email
        #recipient:
        #  address: user.email
        recipient:
           address: 'nick@codecombat.com'
        days_ago: daysAgo
        name: name
        wins: session.numberOfWinsAndTies
        losses: session.numberOfLosses
        total_score: session.totalScore
        team: session.team
        level: id
        defeat: defeatContext
        victory: victoryContext
      sendwithus.api.send context, (err, result) ->
        log.error "Error sending ladder update email:", err, 'result', result

    defeats = _.filter session.matches, (match) -> match.metrics.rank is 1 and match.opponents[0].metrics.rank is 0
    victories = _.filter session.matches, (match) -> match.metrics.rank is 0
    defeat = _.sample defeats
    victory = _.sample victories
    urlForMatch = (match) ->
      "http://codecombat.com/play/ladder/#{session.levelID}?team=#{session.team}&session=#{session._id}&opponent=#{match.opponents[0].sessionID}"

    onFetchedDefeatedOpponent = (err, defeatedOpponent) ->
      if err
        log.error "Couldn't find defeateded opponent: #{err}"
        defeatedOpponent = null
      victoryContext = {opponent_name: defeatedOpponent?.name ? "Anoner", url: urlForMatch(victory)} if victory

      onFetchedVictoriousOpponent = (err, victoriousOpponent) ->
        if err
          log.error "Couldn't find victorious opponent: #{err}"
          victoriousOpponent = null
        defeatContext = {opponent_name: victoriousOpponent?.name ? "Anoner", url: urlForMatch(defeat)} if defeat
        sendEmail defeatContext, victoryContext

      if defeat
        User.findOne({_id: defeat.opponents[0].userID}).select("name").lean().exec onFetchedVictoriousOpponent
      else
        onFetchedVictoriousOpponent null, null

    if victory
      User.findOne({_id: victory.opponents[0].userID}).select("name").lean().exec onFetchedDefeatedOpponent
    else
      onFetchedDefeatedOpponent null, null


handleMailchimpWebHook = (req, res) ->
  post = req.body
  #badLog("Got post data: #{JSON.stringify(post, null, '\t')}")

  unless post.type in ['unsubscribe', 'profile']
    res.send 'Bad post type'
    return res.end()

  unless post.data.email
    res.send 'No email provided'
    return res.end()

  query = {'mailChimp.leid':post.data.web_id}
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


handleProfileUpdate = (user, post) ->
  groups = post.data.merges.INTERESTS.split(', ')
  groups = (map[g] for g in groups when map[g])
  otherSubscriptions = (g for g in user.get('emailSubscriptions') when not mail.MAILCHIMP_GROUP_MAP[g])
  groups = groups.concat otherSubscriptions
  user.set 'emailSubscriptions', groups

  fname = post.data.merges.FNAME
  user.set('firstName', fname) if fname

  lname = post.data.merges.LNAME
  user.set('lastName', lname) if lname

  user.set 'mailChimp.email', post.data.email
  user.set 'mailChimp.euid', post.data.id

#  badLog("Updating user object to: #{JSON.stringify(user.toObject(), null, '\t')}")

handleUnsubscribe = (user) ->
  user.set 'emailSubscriptions', []

#  badLog("Unsubscribing user object to: #{JSON.stringify(user.toObject(), null, '\t')}")
